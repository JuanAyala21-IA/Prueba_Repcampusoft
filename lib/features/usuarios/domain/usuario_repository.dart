import '../../../core/utils/results.dart';
import '../../auth/domain/rol_enum.dart';
import '../../auth/domain/usuario.dart';

/// Gestión de cuentas que realiza exclusivamente el superadministrador.
/// Los estudiantes pueden seguir creando su propia cuenta desde el registro
/// público; este repositorio cubre la creación/eliminación de estudiantes,
/// administrativos y encargados de mantenimiento desde el panel.
abstract interface class UsuarioRepository {
  /// Observa todos los usuarios activos (los eliminados se conservan como
  /// registro histórico con `activo == false`).
  Stream<List<Usuario>> watchUsuarios();

  /// Crea la cuenta de Firebase Auth y el perfil `users/{uid}` con el rol
  /// indicado. Envía el correo de verificación al nuevo usuario.
  Future<Result<Usuario>> crearUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
    required RolEnum rol,
    String? cargo,
    String? dependencia,
    String? telefono,
  });

  /// Deshabilita la cuenta (no borra el historial de Firebase Auth). El gate
  /// de sesión bloquea el acceso y las reglas de Firestore bloquean sus
  /// operaciones.
  Future<Result<void>> eliminarUsuario(Usuario usuario);
}
