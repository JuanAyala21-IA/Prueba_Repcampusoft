import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/firebase_auth_messages.dart';
import '../../features/auth/data/providers/auth_providers.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/auth_usuario.dart';
import '../../features/auth/domain/registro_intentado.dart';
import '../../features/auth/domain/rol_enum.dart';
import '../../features/auth/domain/usuario.dart';
import '../../core/utils/results.dart';

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
}

/// Modelo de sesión derivado de Firebase Auth + `users/{uid}`.
class Sesion {
  const Sesion._(this.estado, this.uid, this.correo, this.rol);

  const Sesion.sinSesion() : this._(SesionEstado.sinSesion, null, null, null);

  const Sesion.correoPendiente({required String uid, required String correo})
      : this._(SesionEstado.correoPendiente, uid, correo, null);

  const Sesion.rolPendiente({required String uid, required String correo})
      : this._(SesionEstado.rolPendiente, uid, correo, null);

  const Sesion.rolAplicado({
    required String uid,
    required String correo,
    required RolEnum rol,
  }) : this._(SesionEstado.rolAplicado, uid, correo, rol);

  final SesionEstado estado;
  final String? uid;
  final String? correo;
  final RolEnum? rol;

  bool get autenticado => estado != SesionEstado.sinSesion;

  bool get correoVerificado =>
      estado == SesionEstado.rolPendiente || estado == SesionEstado.rolAplicado;
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
    await auth.reload();
    final String correo = (auth.email ?? '').trim().toLowerCase();
    if (!auth.emailVerified) {
      state = Sesion.correoPendiente(uid: auth.uid, correo: correo);
      return;
    }
    final Usuario? perfil = await ref.read(authRepositoryProvider).obtenerPerfil(auth.uid);
    if (perfil == null) {
      state = Sesion.rolPendiente(uid: auth.uid, correo: correo);
      return;
    }
    state = Sesion.rolAplicado(uid: perfil.uid, correo: perfil.correo, rol: perfil.rol);
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
    required String? cargo,
    required RolEnum rolIntentado,
  }) async {
    final AuthRepository repo = ref.read(authRepositoryProvider);
    try {
      await repo.crearCuenta(correo: correo, contrasena: contrasena);
    } catch (error) {
      return mensajeFirebase(error);
    }
    ref.read(registroIntentadoProvider.notifier).guardar(RegistroIntentado(
          nombre: nombre.trim(),
          correo: correo.trim().toLowerCase(),
          cargo: (cargo == null || cargo.trim().isEmpty) ? null : cargo.trim(),
          rolIntentado: rolIntentado,
        ));
    try {
      await repo.enviarCorreoVerificacion();
    } catch (_) {
      // El gate continúa; el usuario puede "Reenviar" desde la pantalla.
    }
    return null;
  }

  Future<String?> iniciarSesion({required String correo, required String contrasena}) async {
    final AuthRepository repo = ref.read(authRepositoryProvider);
    try {
      await repo.iniciarSesion(correo: correo, contrasena: contrasena);
      return null;
    } catch (error) {
      return mensajeFirebase(error);
    }
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
  /// verificado, crea `users/{uid}` con el rol efectivo (reintentando como
  /// `persona` si el administrativo no está autorizado). Devuelve el rol
  /// asignado (o `null` si no se creó perfil aquí).
  Future<Result<RolEnum?>> completarVerificacion() async {
    final AuthRepository repo = ref.read(authRepositoryProvider);
    final AuthUsuario? auth = repo.usuarioActual();
    if (auth == null) {
      state = const Sesion.sinSesion();
      return const Failure('Tu sesión expiró. Inicia sesión de nuevo.');
    }
    await auth.reload();
    if (!auth.emailVerified) {
      return const Failure(
          'El correo aún no está verificado. Si ya confirmaste el enlace, espera unos segundos y vuelve a intentar.');
    }
    await auth.refrescarToken();

    final RegistroIntentado? intento = ref.read(registroIntentadoProvider);
    if (intento != null) {
      final Usuario perfil = Usuario(
        uid: auth.uid,
        nombre: intento.nombre,
        correo: intento.correo.isEmpty ? (auth.email ?? '') : intento.correo,
        rol: RolEnum.persona,
        cargo: intento.cargo,
      );
      final Result<RolEnum> resultado =
          await repo.crearPerfil(perfil, rolIntentado: intento.rolIntentado);
      if (resultado is Failure<RolEnum>) {
        final Usuario? existente = await repo.obtenerPerfil(auth.uid);
        if (existente != null) {
          ref.read(registroIntentadoProvider.notifier).limpiar();
          state = Sesion.rolAplicado(uid: auth.uid, correo: existente.correo, rol: existente.rol);
          return Success<RolEnum?>(existente.rol);
        }
        return Failure<RolEnum?>(resultado.message);
      }
      final RolEnum rol = (resultado as Success<RolEnum>).value;
      ref.read(registroIntentadoProvider.notifier).limpiar();
      state = Sesion.rolAplicado(uid: auth.uid, correo: perfil.correo, rol: rol);
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
    required String? cargo,
    required RolEnum rolIntentado,
  }) async {
    final AuthRepository repo = ref.read(authRepositoryProvider);
    final AuthUsuario? auth = repo.usuarioActual();
    if (auth == null) {
      state = const Sesion.sinSesion();
      return const Failure('Tu sesión expiró. Inicia sesión de nuevo.');
    }
    await auth.reload();
    if (!auth.emailVerified) {
      state = Sesion.correoPendiente(uid: auth.uid, correo: (auth.email ?? '').trim().toLowerCase());
      return const Failure('El correo aún no está verificado.');
    }
    final Usuario perfil = Usuario(
      uid: auth.uid,
      nombre: nombre.trim(),
      correo: correo.trim().toLowerCase(),
      rol: RolEnum.persona,
      cargo: (cargo == null || cargo.trim().isEmpty) ? null : cargo.trim(),
    );
    final Result<RolEnum> resultado = await repo.crearPerfil(perfil, rolIntentado: rolIntentado);
    if (resultado is Success<RolEnum>) {
      final RolEnum rol = resultado.value;
      state = Sesion.rolAplicado(uid: auth.uid, correo: perfil.correo, rol: rol);
    }
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
}

final sesionProvider = NotifierProvider<SesionController, Sesion>(SesionController.new);