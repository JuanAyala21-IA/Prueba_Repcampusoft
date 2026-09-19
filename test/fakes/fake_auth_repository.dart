import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:repcampusoft/core/utils/results.dart';
import 'package:repcampusoft/features/auth/domain/auth_repository.dart';
import 'package:repcampusoft/features/auth/domain/auth_usuario.dart';
import 'package:repcampusoft/features/auth/domain/rol_enum.dart';
import 'package:repcampusoft/features/auth/domain/usuario.dart';

class FakeAuthUsuario implements AuthUsuario {
  FakeAuthUsuario({required this.uid, required this.email, this.emailVerified = false});

  @override
  final String uid;

  @override
  final String? email;

  @override
  bool emailVerified;

  @override
  Future<void> reload() async {}

  @override
  Future<void> refrescarToken() async {}
}

/// Repositorio en memoria que emula las reglas de Firestore del §4:
/// rol administrativo solo si el correo está en [whitelist].
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.whitelist = const <String>{}});

  final Set<String> whitelist;
  final Set<String> correosRegistrados = <String>{};
  final Map<String, bool> verificadoPorCorreo = <String, bool>{};
  final Map<String, Usuario> perfiles = <String, Usuario>{};
  final StreamController<AuthUsuario?> _stream = StreamController<AuthUsuario?>.broadcast();
  AuthUsuario? _actual;
  bool enviadoCorreoVerificacion = false;

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
  Future<void> crearCuenta({required String correo, required String contrasena}) async {
    final String key = correo.trim().toLowerCase();
    if (correosRegistrados.contains(key)) {
      throw FirebaseAuthException(code: 'email-already-in-use');
    }
    verificadoPorCorreo[key] = false;
    _actual = FakeAuthUsuario(uid: 'uid-$key', email: key);
    _emitir();
  }

  @override
  Future<void> iniciarSesion({required String correo, required String contrasena}) async {
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
  Future<void> enviarCorreoVerificacion() async {
    enviadoCorreoVerificacion = true;
  }

  @override
  Future<void> recuperarContrasena(String correo) async {}

  @override
  Future<Usuario?> obtenerPerfil(String uid) async => perfiles[uid];

  @override
  Future<Result<RolEnum>> crearPerfil(Usuario perfil, {required RolEnum rolIntentado}) async {
    final bool autorizado = whitelist.contains(perfil.correo.trim().toLowerCase());
    const List<RolEnum> orden = [RolEnum.persona, RolEnum.administrativo];
    final List<RolEnum> intentos = [
      rolIntentado,
      ...orden.where((rol) => rol != rolIntentado),
    ];
    final Set<RolEnum> vistos = <RolEnum>{};
    for (final RolEnum rol in intentos) {
      if (!vistos.add(rol)) continue;
      final bool ok = autorizado ? rol == RolEnum.administrativo : rol == RolEnum.persona;
      if (!ok) continue;
      perfiles[perfil.uid] = Usuario(
        uid: perfil.uid,
        nombre: perfil.nombre,
        correo: perfil.correo,
        rol: rol,
        cargo: perfil.cargo,
      );
      return Success(rol);
    }
    return const Failure('Rol no autorizado');
  }

  @override
  Future<void> cerrarSesion() async {
    _actual = null;
    _emitir();
  }
}