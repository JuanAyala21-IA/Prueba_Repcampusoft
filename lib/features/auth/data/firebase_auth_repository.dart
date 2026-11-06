import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/utils/results.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_usuario.dart';
import '../domain/rol_enum.dart';
import '../domain/usuario.dart';

/// Implementación concreta sobre Firebase Auth + Cloud Firestore.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  /// Inicialización única del SDK nativo de Google (Credential Manager en
  /// Android toma el cliente web de `google-services.json`).
  Future<void>? _googleInicializacion;

  @override
  Stream<AuthUsuario?> authStateChanges() => _auth.authStateChanges().map(
    (user) => user == null ? null : _WrappedUser(user),
  );

  @override
  AuthUsuario? usuarioActual() {
    final User? user = _auth.currentUser;
    return user == null ? null : _WrappedUser(user);
  }

  @override
  Future<void> crearCuenta({
    required String correo,
    required String contrasena,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: correo.trim().toLowerCase(),
      password: contrasena,
    );
  }

  @override
  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: correo.trim().toLowerCase(),
      password: contrasena,
    );
  }

  Future<void> _inicializarGoogle() async {
    _googleInicializacion ??= _googleSignIn.initialize();
    try {
      await _googleInicializacion;
    } catch (_) {
      // Permite reintentar si la inicialización falló (por ejemplo, sin red).
      _googleInicializacion = null;
      rethrow;
    }
  }

  @override
  Future<void> iniciarSesionConGoogle() async {
    final GoogleSignInAccount cuenta;
    try {
      await _inicializarGoogle();
      // Selector nativo de cuentas (Credential Manager en Android), sin pasar
      // por Chrome ni por el handler web de Firebase.
      cuenta = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (error) {
      // El usuario cerró el selector de cuentas: se reutiliza el código de
      // cancelación que ya traduce `mensajeFirebase`.
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw FirebaseAuthException(code: 'web-context-canceled');
      }
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: error.description ?? error.code.name,
      );
    }

    final String? idToken = cuenta.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(code: 'google-sign-in-failed');
    }
    // Firebase valida el ID token de Google; no se envía nada a un backend
    // propio.
    final OAuthCredential credencial = GoogleAuthProvider.credential(
      idToken: idToken,
    );
    await _auth.signInWithCredential(credencial);
  }

  @override
  Future<void> establecerContrasena({required String contrasena}) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    final String correo = (user.email ?? '').trim().toLowerCase();
    if (correo.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-email');
    }

    final AuthCredential credencial = EmailAuthProvider.credential(
      email: correo,
      password: contrasena,
    );
    try {
      // Vincula el proveedor de contraseña a la cuenta de Google para que el
      // usuario pueda entrar con correo/contraseña en el futuro.
      await user.linkWithCredential(credencial);
    } on FirebaseAuthException catch (error) {
      // Si ya tenía contraseña vinculada (p. ej. reintentó el registro), solo
      // se actualiza.
      if (error.code == 'provider-already-linked') {
        await user.updatePassword(contrasena);
      } else {
        rethrow;
      }
    }
    await user.reload();
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
    final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
        .collection('users')
        .doc(uid)
        .get();
    final Map<String, dynamic>? data = doc.data();
    if (data == null) return null;
    return Usuario(
      uid: doc.id,
      nombre: data['nombre'] as String? ?? '',
      correo: data['correo'] as String? ?? '',
      rol: RolEnum.desdeFirestore(data['rol'] as String?),
      cargo: data['cargo'] as String?,
      dependencia: data['dependencia'] as String?,
      telefono: data['telefono'] as String?,
      activo: data['activo'] as bool? ?? true,
    );
  }

  @override
  Future<Result<RolEnum>> crearPerfil(Usuario perfil) async {
    // El autorregistro público solo puede crear `persona`. La única excepción
    // es el correo sembrado manualmente en `super_admins_permitidos`, que la
    // regla de Firestore autoriza como `superadministrador`.
    const List<RolEnum> intentos = [
      RolEnum.persona,
      RolEnum.superadministrador,
    ];
    for (final RolEnum rol in intentos) {
      try {
        await _firestore
            .collection('users')
            .doc(perfil.uid)
            .set(_mapPerfil(perfil, rol));
        return Success(rol);
      } on FirebaseException catch (error) {
        if (error.code == 'permission-denied') continue;
        return const Failure(
          'No se pudo guardar tu perfil. Inténtalo de nuevo.',
        );
      }
    }
    // Si el perfil ya existía (idempotencia), se reutiliza su rol.
    final Usuario? existente = await obtenerPerfil(perfil.uid);
    if (existente != null) return Success(existente.rol);
    return const Failure(
      'No se pudo crear tu perfil. Verifica tu correo e inténtalo de nuevo.',
    );
  }

  Map<String, dynamic> _mapPerfil(Usuario perfil, RolEnum rol) => {
    'nombre': perfil.nombre.trim(),
    'correo': perfil.correo.trim().toLowerCase(),
    'rol': rol.nombreFirestore,
    'activo': true,
    if (perfil.cargo != null && perfil.cargo!.trim().isNotEmpty)
      'cargo': perfil.cargo!.trim(),
    if (perfil.dependencia != null && perfil.dependencia!.trim().isNotEmpty)
      'dependencia': perfil.dependencia!.trim(),
    'creadoEn': FieldValue.serverTimestamp(),
    'actualizadoEn': FieldValue.serverTimestamp(),
  };

  @override
  Future<void> cerrarSesion() async {
    await _auth.signOut();
    try {
      // Limpia la credencial cacheada de Google para que el siguiente acceso
      // vuelva a mostrar el selector de cuentas.
      await _googleInicializacion;
      await _googleSignIn.signOut();
    } catch (_) {
      // Si Google no se inicializó o no había sesión, no hay nada que limpiar.
    }
  }

  @override
  Future<void> actualizarPerfil({
    required String uid,
    required String nombre,
    String? telefono,
    String? cargo,
    String? dependencia,
  }) async {
    final Map<String, dynamic> data = {
      'nombre': nombre.trim(),
      'actualizadoEn': FieldValue.serverTimestamp(),
    };
    if (telefono != null && telefono.trim().isNotEmpty) {
      data['telefono'] = telefono.trim();
    }
    if (cargo != null && cargo.trim().isNotEmpty) {
      data['cargo'] = cargo.trim();
    }
    if (dependencia != null && dependencia.trim().isNotEmpty) {
      data['dependencia'] = dependencia.trim();
    }
    await _firestore.collection('users').doc(uid).update(data);
  }

  @override
  Future<void> cambiarContrasena({
    required String uid,
    required String contrasenaActual,
    required String contrasenaNueva,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null || user.uid != uid) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    // Re-autenticar al usuario con la contraseña actual
    final AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: contrasenaActual,
    );
    await user.reauthenticateWithCredential(credential);

    // Cambiar la contraseña
    await user.updatePassword(contrasenaNueva);
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
  String? get displayName => _user.displayName;

  @override
  bool get autenticadoConGoogle =>
      _user.providerData.any((info) => info.providerId == 'google.com');

  @override
  bool get correoConfiable => emailVerified || autenticadoConGoogle;

  @override
  Future<void> reload() => _user.reload();

  @override
  Future<void> refrescarToken() async {
    await _user.getIdToken(true);
  }
}
