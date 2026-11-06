/// Rol de usuario (dominio en español; valores de Firestore en minúsculas).
enum RolEnum {
  persona('persona', 'Estudiante'),
  administrativo('administrativo', 'Administrativo'),
  mantenimiento('mantenimiento', 'Mantenimiento'),
  superadministrador('superadministrador', 'Superadministrador');

  const RolEnum(this.nombreFirestore, this.etiqueta);

  final String nombreFirestore;
  final String etiqueta;

  /// Roles que el superadministrador puede crear desde la app. El propio
  /// superadministrador no se crea desde la interfaz: se aprovisiona una sola
  /// vez de forma manual (ver docs/superadministrador.md).
  static const List<RolEnum> rolesGestionables = [
    RolEnum.persona,
    RolEnum.administrativo,
    RolEnum.mantenimiento,
  ];

  static RolEnum desdeFirestore(String? valor) {
    return RolEnum.values.firstWhere(
      (rol) => rol.nombreFirestore == valor,
      orElse: () => RolEnum.persona,
    );
  }

  bool get esPersonal => this != RolEnum.persona;

  bool get puedeGestionarReportes =>
      this == RolEnum.administrativo || this == RolEnum.mantenimiento;
}
