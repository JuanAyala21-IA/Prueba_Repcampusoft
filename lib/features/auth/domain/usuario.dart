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
  });

  final String uid;
  final String nombre;
  final String correo;
  final RolEnum rol;
  final String? cargo;
  final String? dependencia;
  final String? telefono;

  Usuario copyWith({RolEnum? rol}) => Usuario(
        uid: uid,
        nombre: nombre,
        correo: correo,
        rol: rol ?? this.rol,
        cargo: cargo,
        dependencia: dependencia,
        telefono: telefono,
      );
}