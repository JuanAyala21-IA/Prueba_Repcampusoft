import 'rol_enum.dart';

/// Datos del registro pendiente de verificación (§4: `users/{uid}` se crea
/// solo después del `emailVerified`). Se conserva en memoria para construir el
/// perfil cuando el usuario confirma el enlace.
class RegistroIntentado {
  const RegistroIntentado({
    required this.nombre,
    required this.correo,
    required this.rolIntentado,
    this.cargo,
  });

  final String nombre;
  final String correo;
  final RolEnum rolIntentado;
  final String? cargo;
}