/// Validadores de formularios (Fase 3: solo reglas básicas de formato).
abstract final class Validators {
  static String? correo(String? valor) {
    final String texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Ingresa tu correo institucional';
    final bool valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto);
    return valido ? null : 'Correo no válido';
  }

  static String? requerido(String? valor) {
    return (valor == null || valor.trim().isEmpty)
        ? 'Este campo es obligatorio'
        : null;
  }

  /// Nombres: letras (con tildes y ñ), espacios, guion y apóstrofo.
  static String? nombre(String? valor) {
    final String texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Este campo es obligatorio';
    final bool valido = RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ\s'\-]+$")
        .hasMatch(texto);
    return valido ? null : 'Solo letras, espacios, guion y apóstrofo';
  }

  /// Teléfono opcional: vacío es válido; si se escribe, exige 10 dígitos.
  static String? telefono(String? valor) {
    final String texto = (valor ?? '').trim();
    if (texto.isEmpty) return null;
    return RegExp(r'^\d{10}$').hasMatch(texto)
        ? null
        : 'Ingresa exactamente 10 números';
  }

  /// Textos libres de reportes (descripción, referencia, espacio «Otro»).
  ///
  /// No admite dígitos. Sí admite letras, espacios y puntuación básica.
  static String? textoReporte(String? valor, {bool obligatorio = false}) {
    final String texto = valor?.trim() ?? '';
    if (texto.isEmpty) {
      return obligatorio ? 'Campo obligatorio' : null;
    }
    if (RegExp(r'\d').hasMatch(texto)) {
      return 'No se permiten números';
    }
    final bool valido = RegExp(
      r'^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ\s.,;:¿?¡!"\u0027()\-/]+$',
    ).hasMatch(texto);
    return valido ? null : 'Solo se permiten letras y puntuación básica';
  }

  static String? contrasena(String? valor) {
    final String texto = valor ?? '';
    if (texto.isEmpty) return 'Ingresa tu contraseña';
    if (texto.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  /// Valida que [valor] (confirmación) coincida con [campo] (contraseña).
  static String? confirmarContrasena({
    required String? campo,
    required String? valor,
  }) {
    final String texto = valor ?? '';
    if (texto.isEmpty) return 'Confirma tu contraseña';
    if (texto != campo) return 'Las contraseñas no coinciden';
    return null;
  }
}
