import 'rol_enum.dart';

/// Usuario con perfil creado en `users/{uid}` (arquitectura §2.1).
class Usuario {
  const Usuario({
    required this.uid,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.cargo,
    this.dependencia,
    this.telefono,
    this.activo = true,
  });

  final String uid;
  final String nombre;
  final String correo;
  final RolEnum rol;
  final String? cargo;
  final String? dependencia;
  final String? telefono;

  /// `false` cuando el superadministrador eliminó (desactivó) la cuenta.
  /// La cuenta de Firebase Auth se conserva para auditoría, pero el gate de
  /// sesión bloquea el acceso y las reglas de Firestore lo rechazan.
  final bool activo;

  bool get esSuperadministrador => rol == RolEnum.superadministrador;

  Usuario copyWith({
    String? nombre,
    RolEnum? rol,
    String? cargo,
    String? dependencia,
    String? telefono,
    bool? activo,
  }) => Usuario(
    uid: uid,
    nombre: nombre ?? this.nombre,
    correo: correo,
    rol: rol ?? this.rol,
    cargo: cargo ?? this.cargo,
    dependencia: dependencia ?? this.dependencia,
    telefono: telefono ?? this.telefono,
    activo: activo ?? this.activo,
  );
}
