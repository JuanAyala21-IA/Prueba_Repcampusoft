/// Datos del registro pendiente de verificación (§4: `users/{uid}` se crea
/// solo después del `emailVerified`). Se conserva en memoria para construir el
/// perfil cuando el usuario confirma el enlace.
///
/// El autorregistro público solo crea estudiantes (`persona`). Los roles
/// administrativo, mantenimiento y superadministrador no se eligen desde el
/// formulario.
class RegistroIntentado {
  const RegistroIntentado({required this.nombre, required this.correo});

  final String nombre;
  final String correo;
}
