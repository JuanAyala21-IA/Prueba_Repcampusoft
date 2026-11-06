import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:repcampusoft/core/utils/results.dart';
import 'package:repcampusoft/features/auth/domain/auth_repository.dart';
import 'package:repcampusoft/features/auth/domain/auth_usuario.dart';
import 'package:repcampusoft/features/auth/domain/rol_enum.dart';
import 'package:repcampusoft/features/auth/domain/usuario.dart';

class FakeAuthUsuario implements AuthUsuario {
  FakeAuthUsuario({
    required this.uid,
    required this.email,
    this.emailVerified = false,
    this.displayName,
    this.autenticadoConGoogle = false,
  });

  @override
  final String uid;

  @override
  final String? email;

  @override
  bool emailVerified;

  @override
  final String? displayName;

  @override
  final bool autenticadoConGoogle;

  @override
  bool get correoConfiable => emailVerified || autenticadoConGoogle;

  @override
  Future<void> reload() async {}

  @override
  Future<void> refrescarToken() async {}
}

/// Repositorio en memoria que emula las reglas de Firestore del §4:
/// el autorregistro solo crea `persona`; un correo en [whitelist]
/// (`super_admins_permitidos`) se crea como `superadministrador`.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.whitelist = const <String>{}});

  final Set<String> whitelist;
  final Set<String> correosRegistrados = <String>{};
  final Map<String, bool> verificadoPorCorreo = <String, bool>{};
  final Map<String, Usuario> perfiles = <String, Usuario>{};

  /// Contraseñas creadas en la pantalla "Completa tu registro" (Google).
  final Map<String, String> contrasenas = <String, String>{};

  /// `true` si al asignar la contraseña el perfil ya existía (el orden importa:
  /// vincular la contraseña marca el correo como no verificado en Firebase).
  bool perfilExistiaAlAsignarContrasena = false;
  final StreamController<AuthUsuario?> _stream =
      StreamController<AuthUsuario?>.broadcast();
  AuthUsuario? _actual;
  bool enviadoCorreoVerificacion = false;

  /// Correo que devuelve la cuenta Google simulada. `null` simula que el
  /// usuario canceló el flujo.
  String? correoGoogle = 'estudiante@gmail.com';
  String nombreGoogle = 'Estudiante UTS';

  @override
  Stream<AuthUsuario?> authStateChanges() => _stream.stream;

  @override
  AuthUsuario? usuarioActual() => _actual;

  void _emitir() => _stream.add(_actual);

  void marcarVerificado(String correo) {
    final String key = correo.trim().toLowerCase();
    verificadoPorCorreo[key] = true;
    final AuthUsuario? actual = _actual;
    if (actual is FakeAuthUsuario && actual.email == key) {
      actual.emailVerified = true;
    }
  }

  @override
  Future<void> crearCuenta({
    required String correo,
    required String contrasena,
  }) async {
    final String key = correo.trim().toLowerCase();
    if (correosRegistrados.contains(key)) {
      throw FirebaseAuthException(code: 'email-already-in-use');
    }
    verificadoPorCorreo[key] = false;
    _actual = FakeAuthUsuario(uid: 'uid-$key', email: key);
    _emitir();
  }

  @override
  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    final String key = correo.trim().toLowerCase();
    if (verificadoPorCorreo[key] == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    _actual = FakeAuthUsuario(
      uid: 'uid-$key',
      email: key,
      emailVerified: verificadoPorCorreo[key]!,
    );
    _emitir();
  }

  @override
  Future<void> iniciarSesionConGoogle() async {
    final String? correo = correoGoogle;
    if (correo == null) {
      throw FirebaseAuthException(code: 'web-context-canceled');
    }
    final String key = correo.trim().toLowerCase();
    _actual = FakeAuthUsuario(
      uid: 'uid-google-$key',
      email: key,
      displayName: nombreGoogle,
      autenticadoConGoogle: true,
    );
    _emitir();
  }

  @override
  Future<void> establecerContrasena({required String contrasena}) async {
    final AuthUsuario? actual = _actual;
    if (actual == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    contrasenas[actual.uid] = contrasena;
    perfilExistiaAlAsignarContrasena = perfiles.containsKey(actual.uid);
  }

  @override
  Future<void> enviarCorreoVerificacion() async {
    enviadoCorreoVerificacion = true;
  }

  @override
  Future<void> recuperarContrasena(String correo) async {}

  @override
  Future<Usuario?> obtenerPerfil(String uid) async => perfiles[uid];

  @override
  Future<Result<RolEnum>> crearPerfil(Usuario perfil) async {
    final bool esSuperadministrador = whitelist.contains(
      perfil.correo.trim().toLowerCase(),
    );
    final RolEnum rol = esSuperadministrador
        ? RolEnum.superadministrador
        : RolEnum.persona;
    perfiles[perfil.uid] = Usuario(
      uid: perfil.uid,
      nombre: perfil.nombre,
      correo: perfil.correo,
      rol: rol,
      cargo: perfil.cargo,
    );
    return Success(rol);
  }

  @override
  Future<void> cerrarSesion() async {
    _actual = null;
    _emitir();
  }

  @override
  Future<void> actualizarPerfil({
    required String uid,
    required String nombre,
    String? telefono,
    String? cargo,
    String? dependencia,
  }) async {
    final Usuario? perfil = perfiles[uid];
    if (perfil != null) {
      perfiles[uid] = Usuario(
        uid: perfil.uid,
        nombre: nombre,
        correo: perfil.correo,
        rol: perfil.rol,
        cargo: cargo,
        dependencia: dependencia,
        telefono: telefono,
      );
    }
  }

  @override
  Future<void> cambiarContrasena({
    required String uid,
    required String contrasenaActual,
    required String contrasenaNueva,
  }) async {
    // En el fake, solo verificamos que la contraseña actual coincida con la almacenada
    // Como no almacenamos contraseñas en el fake, permitimos cualquier cambio
    // siempre que la contraseña nueva no esté vacía
    if (contrasenaNueva.isEmpty) {
      throw FirebaseAuthException(code: 'weak-password');
    }
  }
}
