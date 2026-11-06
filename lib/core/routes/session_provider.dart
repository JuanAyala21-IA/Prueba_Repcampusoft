import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/results.dart';
import '../../features/auth/data/firebase_auth_messages.dart';
import '../../features/auth/data/providers/auth_providers.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/auth_usuario.dart';
import '../../features/auth/domain/registro_intentado.dart';
import '../../features/auth/domain/rol_enum.dart';
import '../../features/auth/domain/usuario.dart';

/// Estados de sesión según el gate de §5.3 de arquitectura.
enum SesionEstado {
  /// Sin autenticar: solo rutas públicas.
  sinSesion,

  /// Autenticado pero correo sin verificar (paso intermedio del gate §5.3).
  correoPendiente,

  /// Autenticado, correo verificado, pero sin perfil `users/{uid}`:
  /// hay que retomar el registro (crear perfil).
  rolPendiente,

  /// Autenticado, correo verificado y rol aplicado.
  rolAplicado,

  /// Autenticado, pero el superadministrador deshabilitó (eliminó) la cuenta.
  /// No puede acceder a ningún módulo; solo cerrar sesión.
  cuentaBloqueada,
}

/// Modelo de sesión derivado de Firebase Auth + `users/{uid}`.
class Sesion {
  const Sesion._(
    this.estado,
    this.uid,
    this.correo,
    this.rol,
    this.nombreSugerido, {
    this.autenticadoConGoogle = false,
  });

  const Sesion.sinSesion()
    : this._(SesionEstado.sinSesion, null, null, null, null);

  const Sesion.correoPendiente({required String uid, required String correo})
    : this._(SesionEstado.correoPendiente, uid, correo, null, null);

  const Sesion.rolPendiente({
    required String uid,
    required String correo,
    String? nombreSugerido,
    bool autenticadoConGoogle = false,
  }) : this._(
         SesionEstado.rolPendiente,
         uid,
         correo,
         null,
         nombreSugerido,
         autenticadoConGoogle: autenticadoConGoogle,
       );

  const Sesion.rolAplicado({
    required String uid,
    required String correo,
    required RolEnum rol,
  }) : this._(SesionEstado.rolAplicado, uid, correo, rol, null);

  const Sesion.cuentaBloqueada({required String uid, required String correo})
    : this._(SesionEstado.cuentaBloqueada, uid, correo, null, null);

  final SesionEstado estado;
  final String? uid;
  final String? correo;
  final RolEnum? rol;

  /// Nombre entregado por el proveedor de identidad (Google) para
  /// prellenar la pantalla de completar perfil.
  final String? nombreSugerido;

  /// `true` si la cuenta se creó/inició con Google y todavía no tiene
  /// contraseña propia (pantalla "Completa tu registro").
  final bool autenticadoConGoogle;

  bool get autenticado => estado != SesionEstado.sinSesion;

  bool get correoVerificado =>
      estado == SesionEstado.rolPendiente ||
      estado == SesionEstado.rolAplicado ||
      estado == SesionEstado.cuentaBloqueada;

  bool get esSuperadministrador => rol == RolEnum.superadministrador;

  bool get puedeGestionarReportes =>
      rol == RolEnum.administrativo || rol == RolEnum.mantenimiento;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sesion &&
        other.estado == estado &&
        other.uid == uid &&
        other.correo == correo &&
        other.rol == rol &&
        other.nombreSugerido == nombreSugerido &&
        other.autenticadoConGoogle == autenticadoConGoogle;
  }

  @override
  int get hashCode => Object.hash(
    estado,
    uid,
    correo,
    rol,
    nombreSugerido,
    autenticadoConGoogle,
  );
}

/// Controlador de sesión real: escucha `authStateChanges`, resuelve el gate
/// §5.3 (correo verificado → perfil → rol) y expone las operaciones de la
/// FASE 4 (registro, inicio/cierre, verificación, recuperación).
class SesionController extends Notifier<Sesion> {
  StreamSubscription<AuthUsuario?>? _suscripcion;

  @override
  Sesion build() {
    final AuthRepository repo = ref.watch(authRepositoryProvider);
    _suscripcion?.cancel();
    _suscripcion = repo.authStateChanges().listen(_resolverEstado);
    ref.onDispose(() => _suscripcion?.cancel());
    return const Sesion.sinSesion();
  }

  Future<void> _resolverEstado(AuthUsuario? auth) async {
    if (auth == null) {
      state = const Sesion.sinSesion();
      return;
    }
    final AuthRepository repo = ref.read(authRepositoryProvider);
    // No se llama a `auth.reload()` aquí: este método se ejecuta por cada
    // evento de `authStateChanges` y la recarga puede volver a emitir ese
    // evento, reiniciando la sesión en bucle (la pantalla actual se recargaba
    // sola). La recarga explícita se hace en `completarVerificacion` y
    // `completarPerfil`, que sí necesitan el estado más reciente del correo.
    final String correo = (auth.email ?? '').trim().toLowerCase();

    // Google valida el correo en su propio dominio; `correoConfiable` lo
    // exceptúa del paso de verificación por enlace, igual que hace Firebase
    // con los proveedores federados.
    if (!auth.correoConfiable) {
      state = Sesion.correoPendiente(uid: auth.uid, correo: correo);
      return;
    }
    final Usuario? perfil = await repo.obtenerPerfil(auth.uid);
    if (perfil == null) {
      state = Sesion.rolPendiente(
        uid: auth.uid,
        correo: correo,
        nombreSugerido: auth.displayName,
        autenticadoConGoogle: auth.autenticadoConGoogle,
      );
      return;
    }
    if (!perfil.activo) {
      state = Sesion.cuentaBloqueada(uid: perfil.uid, correo: perfil.correo);
      return;
    }
    state = Sesion.rolAplicado(
      uid: perfil.uid,
      correo: perfil.correo,
      rol: perfil.rol,
    );
  }

  /// Crea la cuenta en Firebase Auth, envía el correo de verificación y
  /// conserva el registro pendiente. Devuelve `null` en éxito o el mensaje
  /// de error en español. Si el correo no pudo enviarse (p. ej. rate limit)
  /// la cuenta ya quedó creada: se continúa el gate igualmente y el usuario
  /// puede reenviar desde la pantalla de verificación.
  Future<String?> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    final AuthRepository repo = ref.read(authRepositoryProvider);
    try {
      await repo.crearCuenta(correo: correo, contrasena: contrasena);
    } catch (error) {
      return mensajeFirebase(error);
    }
    ref
        .read(registroIntentadoProvider.notifier)
        .guardar(
          RegistroIntentado(
            nombre: nombre.trim(),
            correo: correo.trim().toLowerCase(),
          ),
        );
    try {
      await repo.enviarCorreoVerificacion();
    } catch (_) {
      // El gate continúa; el usuario puede "Reenviar" desde la pantalla.
    }
    return null;
  }

  Future<String?> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final AuthRepository repo = ref.read(authRepositoryProvider);
    try {
      await repo.iniciarSesion(correo: correo, contrasena: contrasena);
      return null;
    } catch (error) {
      return mensajeFirebase(error);
    }
  }

  /// Inicia sesión o registra una cuenta con Google. El primer acceso queda
  /// en `rolPendiente` para completar el perfil.
  Future<String?> iniciarSesionConGoogle() async {
    final AuthRepository repo = ref.read(authRepositoryProvider);
    try {
      await repo.iniciarSesionConGoogle();
    } catch (error) {
      return mensajeFirebase(error);
    }

    final AuthUsuario? auth = repo.usuarioActual();
    if (auth == null) {
      return 'No se pudo completar el inicio de sesión con Google. Inténtalo de nuevo.';
    }
    return null;
  }

  Future<String?> reenviarCorreoVerificacion() async {
    final AuthRepository repo = ref.read(authRepositoryProvider);
    try {
      await repo.enviarCorreoVerificacion();
      return null;
    } catch (error) {
      return mensajeFirebase(error);
    }
  }

  Future<String?> recuperarContrasena(String correo) async {
    final AuthRepository repo = ref.read(authRepositoryProvider);
    try {
      await repo.recuperarContrasena(correo);
      return null;
    } catch (error) {
      return mensajeFirebase(error);
    }
  }

  /// "Ya verifiqué": recarga la sesión, refresca el token y, si el correo está
  /// verificado, resuelve el perfil. Si la cuenta fue creada por el
  /// superadministrador, el perfil ya existe y se aplica su rol; si es un
  /// autorregistro, se crea `users/{uid}` como `persona`. Devuelve el rol
  /// asignado (o `null` si no se creó perfil aquí).
  Future<Result<RolEnum?>> completarVerificacion() async {
    final AuthRepository repo = ref.read(authRepositoryProvider);
    final AuthUsuario? auth = repo.usuarioActual();
    if (auth == null) {
      state = const Sesion.sinSesion();
      return const Failure('Tu sesión expiró. Inicia sesión de nuevo.');
    }
    await auth.reload();
    if (!auth.correoConfiable) {
      return const Failure(
        'El correo aún no está verificado. Si ya confirmaste el enlace, espera unos segundos y vuelve a intentar.',
      );
    }
    await auth.refrescarToken();

    // Perfil ya creado por el superadministrador: no se vuelve a crear.
    final Usuario? existente = await repo.obtenerPerfil(auth.uid);
    if (existente != null) {
      ref.read(registroIntentadoProvider.notifier).limpiar();
      if (!existente.activo) {
        state = Sesion.cuentaBloqueada(
          uid: existente.uid,
          correo: existente.correo,
        );
        return const Failure(
          'Tu cuenta fue deshabilitada por el superadministrador.',
        );
      }
      state = Sesion.rolAplicado(
        uid: existente.uid,
        correo: existente.correo,
        rol: existente.rol,
      );
      return Success<RolEnum?>(existente.rol);
    }

    final RegistroIntentado? intento = ref.read(registroIntentadoProvider);
    if (intento != null) {
      final Usuario perfil = Usuario(
        uid: auth.uid,
        nombre: intento.nombre,
        correo: intento.correo.isEmpty ? (auth.email ?? '') : intento.correo,
        rol: RolEnum.persona,
      );
      final Result<RolEnum> resultado = await repo.crearPerfil(perfil);
      if (resultado is Failure<RolEnum>) {
        final Usuario? creado = await repo.obtenerPerfil(auth.uid);
        if (creado != null) {
          ref.read(registroIntentadoProvider.notifier).limpiar();
          state = Sesion.rolAplicado(
            uid: creado.uid,
            correo: creado.correo,
            rol: creado.rol,
          );
          return Success<RolEnum?>(creado.rol);
        }
        return Failure<RolEnum?>(resultado.message);
      }
      final RolEnum rol = (resultado as Success<RolEnum>).value;
      ref.read(registroIntentadoProvider.notifier).limpiar();
      state = Sesion.rolAplicado(
        uid: auth.uid,
        correo: perfil.correo,
        rol: rol,
      );
      return Success<RolEnum?>(rol);
    }

    await _resolverEstado(auth);
    return const Success<RolEnum?>(null);
  }

  /// Crear perfil desde la pantalla de "retomar registro" (gate §5.3, usuario
  /// verificado sin `users/{uid}`).
  Future<Result<RolEnum>> completarPerfil({
    required String nombre,
    required String correo,
    String? contrasena,
  }) async {
    final AuthRepository repo = ref.read(authRepositoryProvider);
    final AuthUsuario? auth = repo.usuarioActual();
    if (auth == null) {
      state = const Sesion.sinSesion();
      return const Failure('Tu sesión expiró. Inicia sesión de nuevo.');
    }
    await auth.reload();
    if (!auth.correoConfiable) {
      state = Sesion.correoPendiente(
        uid: auth.uid,
        correo: (auth.email ?? '').trim().toLowerCase(),
      );
      return const Failure('El correo aún no está verificado.');
    }
    // Refresca el token para que las reglas de Firestore vean
    // `email_verified` / `sign_in_provider` actualizados al crear el perfil.
    await auth.refrescarToken();

    // Si el superadministrador ya creó el perfil, se respeta ese rol.
    final Usuario? existente = await repo.obtenerPerfil(auth.uid);
    if (existente != null) {
      if (!existente.activo) {
        state = Sesion.cuentaBloqueada(
          uid: existente.uid,
          correo: existente.correo,
        );
        return const Failure(
          'Tu cuenta fue deshabilitada por el superadministrador.',
        );
      }
      state = Sesion.rolAplicado(
        uid: existente.uid,
        correo: existente.correo,
        rol: existente.rol,
      );
      return Success(existente.rol);
    }

    // Cuenta de Google: se le asigna contraseña para que también pueda
    // iniciar sesión con su correo y contraseña.
    final bool esGoogle = auth.autenticadoConGoogle;
    final String clave = contrasena?.trim() ?? '';
    if (esGoogle && clave.isEmpty) {
      return const Failure('Ingresa una contraseña para tu cuenta.');
    }

    final Usuario perfil = Usuario(
      uid: auth.uid,
      nombre: nombre.trim(),
      correo: correo.trim().toLowerCase(),
      rol: RolEnum.persona,
    );
    // Importante: el perfil se crea ANTES de vincular la contraseña. Al
    // vincularla, Firebase marca `email_verified = false`, y entonces la regla
    // de Firestore rechazaría la creación de `users/{uid}`. Con el token de
    // Google (recién refrescado) la regla sí autoriza.
    final Result<RolEnum> resultado = await repo.crearPerfil(perfil);
    if (resultado is Failure<RolEnum>) {
      return resultado;
    }

    if (esGoogle) {
      try {
        await repo.establecerContrasena(contrasena: clave);
      } catch (_) {
        // El perfil ya quedó creado; no se bloquea el acceso a la app. La
        // contraseña se puede volver a configurar desde el perfil.
      }
    }

    final RolEnum rol = (resultado as Success<RolEnum>).value;
    state = Sesion.rolAplicado(uid: auth.uid, correo: perfil.correo, rol: rol);
    return resultado;
  }

  Future<void> cerrarSesion() async {
    ref.read(registroIntentadoProvider.notifier).limpiar();
    final AuthRepository repo = ref.read(authRepositoryProvider);
    try {
      await repo.cerrarSesion();
    } catch (_) {
      // Incluso si falla el signOut remoto, se limpia el estado local.
    }
    state = const Sesion.sinSesion();
  }

  /// Actualiza los datos del perfil del usuario autenticado.
  Future<String?> actualizarPerfil({
    required String nombre,
    String? telefono,
    String? cargo,
    String? dependencia,
  }) async {
    final AuthRepository repo = ref.read(authRepositoryProvider);
    final AuthUsuario? auth = repo.usuarioActual();
    if (auth == null) {
      return 'Tu sesión expiró. Inicia sesión de nuevo.';
    }
    try {
      await repo.actualizarPerfil(
        uid: auth.uid,
        nombre: nombre,
        telefono: telefono,
        cargo: cargo,
        dependencia: dependencia,
      );
      // Refrescar el estado de sesión para reflejar los cambios
      await _resolverEstado(auth);
      return null;
    } on FirebaseException catch (e) {
      return 'Error de Firebase: ${e.message ?? e.code}';
    } catch (error) {
      return 'Error inesperado: $error';
    }
  }

  /// Cambia la contraseña del usuario autenticado.
  /// Requiere la contraseña actual para re-autenticar al usuario.
  Future<String?> cambiarContrasena({
    required String contrasenaActual,
    required String contrasenaNueva,
  }) async {
    final AuthRepository repo = ref.read(authRepositoryProvider);
    final AuthUsuario? auth = repo.usuarioActual();
    if (auth == null) {
      return 'Tu sesión expiró. Inicia sesión de nuevo.';
    }
    try {
      await repo.cambiarContrasena(
        uid: auth.uid,
        contrasenaActual: contrasenaActual,
        contrasenaNueva: contrasenaNueva,
      );
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'wrong-password') {
        return 'La contraseña actual es incorrecta.';
      }
      return 'Error de Firebase: ${e.message ?? e.code}';
    } catch (error) {
      return 'Error inesperado: $error';
    }
  }
}

final sesionProvider = NotifierProvider<SesionController, Sesion>(
  SesionController.new,
);
