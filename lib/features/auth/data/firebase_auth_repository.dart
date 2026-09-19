import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/results.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_usuario.dart';
import '../domain/rol_enum.dart';
import '../domain/usuario.dart';

/// Implementación concreta sobre Firebase Auth + Cloud Firestore.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<AuthUsuario?> authStateChanges() =>
      _auth.authStateChanges().map((user) => user == null ? null : _WrappedUser(user));

  @override
  AuthUsuario? usuarioActual() {
    final User? user = _auth.currentUser;
    return user == null ? null : _WrappedUser(user);
  }

  @override
  Future<void> crearCuenta({required String correo, required String contrasena}) async {
    await _auth.createUserWithEmailAndPassword(
      email: correo.trim().toLowerCase(),
      password: contrasena,
    );
  }

  @override
  Future<void> iniciarSesion({required String correo, required String contrasena}) async {
    await _auth.signInWithEmailAndPassword(
      email: correo.trim().toLowerCase(),
      password: contrasena,
    );
  }

  @override
  Future<void> enviarCorreoVerificacion() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<void> recuperarContrasena(String correo) async {
    await _auth.sendPasswordResetEmail(email: correo.trim().toLowerCase());
  }

  @override
  Future<Usuario?> obtenerPerfil(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _firestore.collection('users').doc(uid).get();
    final Map<String, dynamic>? data = doc.data();
    if (data == null) return null;
    return Usuario(
      uid: doc.id,
      nombre: data['nombre'] as String? ?? '',
      correo: data['correo'] as String? ?? '',
      rol: data['rol'] == RolEnum.administrativo.nombreFirestore
          ? RolEnum.administrativo
          : RolEnum.persona,
      cargo: data['cargo'] as String?,
      dependencia: data['dependencia'] as String?,
      telefono: data['telefono'] as String?,
    );
  }

  @override
  Future<Result<RolEnum>> crearPerfil(Usuario perfil, {required RolEnum rolIntentado}) async {
    const List<RolEnum> orden = [RolEnum.persona, RolEnum.administrativo];
    final List<RolEnum> intentos = [
      rolIntentado,
      ...orden.where((rol) => rol != rolIntentado),
    ];
    final Set<RolEnum> vistos = <RolEnum>{};
    for (final RolEnum rol in intentos) {
      if (!vistos.add(rol)) continue;
      try {
        await _firestore.collection('users').doc(perfil.uid).set(_mapPerfil(perfil, rol));
        return Success(rol);
      } on FirebaseException catch (error) {
        // La regla valida la pertenencia a admins_permitidos con exists();
        // el rechazo solo significa que este rol no está autorizado y se
        // reintenta con el próximo (§4, fallback de UX).
        if (error.code == 'permission-denied') continue;
        return Failure('No se pudo guardar tu perfil. Inténtalo de nuevo.');
      }
    }
    // Todos los intentos fueron rechazados: si el perfil ya existía de un
    // intento previo (idempotencia), se reutiliza su rol.
    final Usuario? existente = await obtenerPerfil(perfil.uid);
    if (existente != null) return Success(existente.rol);
    return const Failure('No se pudo asignar tu rol. Verifica que tu correo esté autorizado.');
  }

  Map<String, dynamic> _mapPerfil(Usuario perfil, RolEnum rol) => {
        'nombre': perfil.nombre.trim(),
        'correo': perfil.correo.trim().toLowerCase(),
        'rol': rol.nombreFirestore,
        if (perfil.cargo != null && perfil.cargo!.trim().isNotEmpty)
          'cargo': perfil.cargo!.trim(),
        'creadoEn': FieldValue.serverTimestamp(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      };

  @override
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }
}

class _WrappedUser implements AuthUsuario {
  _WrappedUser(this._user);

  final User _user;

  @override
  String get uid => _user.uid;

  @override
  String? get email => _user.email?.trim().toLowerCase();

  @override
  bool get emailVerified => _user.emailVerified;

  @override
  Future<void> reload() => _user.reload();

  @override
  Future<void> refrescarToken() async {
    await _user.getIdToken(true);
  }
}