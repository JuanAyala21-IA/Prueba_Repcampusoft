import '../../../core/utils/results.dart';
import 'auth_usuario.dart';
import 'rol_enum.dart';
import 'usuario.dart';

/// Contrato del repositorio de autenticación (arquitectura §1.1).
abstract class AuthRepository {
  Stream<AuthUsuario?> authStateChanges();

  AuthUsuario? usuarioActual();

  Future<void> crearCuenta({
    required String correo,
    required String contrasena,
  });

  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  });

  /// Inicia sesión (o crea la cuenta la primera vez) con Google. El primer
  /// acceso deja al usuario sin `users/{uid}` para que complete su perfil en
  /// el gate de sesión.
  Future<void> iniciarSesionConGoogle();

  /// Define la contraseña de una cuenta creada con Google, vinculando el
  /// proveedor de correo/contraseña para que el usuario pueda iniciar sesión
  /// también con su correo y contraseña.
  Future<void> establecerContrasena({required String contrasena});

  Future<void> enviarCorreoVerificacion();

  Future<void> recuperarContrasena(String correo);

  Future<Usuario?> obtenerPerfil(String uid);

  /// Crea `users/{uid}` para el autorregistro público. La regla de Firestore
  /// solo permite `persona` (o `superadministrador` si el correo está en la
  /// lista blanca manual `super_admins_permitidos`). Los demás roles los crea
  /// exclusivamente el superadministrador desde `UsuarioRepository`.
  Future<Result<RolEnum>> crearPerfil(Usuario perfil);

  /// Actualiza los datos editables del perfil del usuario.
  Future<void> actualizarPerfil({
    required String uid,
    required String nombre,
    String? telefono,
    String? cargo,
    String? dependencia,
  });

  /// Cambia la contraseña del usuario (requiere re-autenticación con contraseña actual).
  Future<void> cambiarContrasena({
    required String uid,
    required String contrasenaActual,
    required String contrasenaNueva,
  });

  Future<void> cerrarSesion();
}
