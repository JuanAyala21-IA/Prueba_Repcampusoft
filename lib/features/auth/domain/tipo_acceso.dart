import 'rol_enum.dart';

/// Tipo de acceso que se elige en el inicio de sesión.
///
/// El rol real sigue viviendo en `users/{uid}`: esta selección solo sirve para
/// validar que la cuenta corresponda al acceso solicitado. Un usuario con rol
/// administrativo entra por "Administrativo" y uno con rol persona por
/// "Estudiante"; el personal de mantenimiento y el superadministrador también
/// entran por "Administrativo".
enum TipoAcceso {
  estudiante('Estudiante', {RolEnum.persona}),
  administrativo('Administrativo', {
    RolEnum.administrativo,
    RolEnum.mantenimiento,
    RolEnum.superadministrador,
  });

  const TipoAcceso(this.etiqueta, this.rolesPermitidos);

  final String etiqueta;
  final Set<RolEnum> rolesPermitidos;

  /// `true` si una cuenta con [rol] puede iniciar sesión con este acceso.
  bool permite(RolEnum rol) => rolesPermitidos.contains(rol);

  /// Acceso que corresponde al [rol] real de la cuenta.
  static TipoAcceso paraRol(RolEnum rol) =>
      rol == RolEnum.persona ? TipoAcceso.estudiante : TipoAcceso.administrativo;
}
