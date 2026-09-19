import '../../../core/utils/results.dart';
import 'auth_usuario.dart';
import 'rol_enum.dart';
import 'usuario.dart';

/// Contrato del repositorio de autenticación (arquitectura §1.1).
abstract class AuthRepository {
  Stream<AuthUsuario?> authStateChanges();

  AuthUsuario? usuarioActual();

  Future<void> crearCuenta({required String correo, required String contrasena});

  Future<void> iniciarSesion({required String correo, required String contrasena});

  Future<void> enviarCorreoVerificacion();

  Future<void> recuperarContrasena(String correo);

  Future<Usuario?> obtenerPerfil(String uid);

  /// Crea `users/{uid}` intentando [rolIntentado] primero; si la regla de
  /// Firestore lo rechaza (PERMISSION_DENIED, correo no autorizado), reintenta
  /// como `persona` (fallback de UX §4; la autoridad del rol es la regla).
  /// El rol retorna es el efectivamente almacenado.
  Future<Result<RolEnum>> crearPerfil(Usuario perfil, {required RolEnum rolIntentado});

  Future<void> cerrarSesion();
}