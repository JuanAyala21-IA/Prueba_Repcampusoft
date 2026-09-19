/// Validadores de formularios (Fase 3: solo reglas básicas de formato).
abstract final class Validators {
  static String? correo(String? valor) {
    final String texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Ingresa tu correo institucional';
    final bool valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto);
    return valido ? null : 'Correo no válido';
  }

  static String? requerido(String? valor) {
    return (valor == null || valor.trim().isEmpty) ? 'Este campo es obligatorio' : null;
  }

  static String? contrasena(String? valor) {
    final String texto = valor ?? '';
    if (texto.isEmpty) return 'Ingresa tu contraseña';
    if (texto.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  /// Valida que [valor] (confirmación) coincida con [campo] (contraseña).
  static String? confirmarContrasena({required String? campo, required String? valor}) {
    final String texto = valor ?? '';
    if (texto.isEmpty) return 'Confirma tu contraseña';
    if (texto != campo) return 'Las contraseñas no coinciden';
    return null;
  }
}