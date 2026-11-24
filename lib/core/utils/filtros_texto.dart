import 'package:flutter/services.dart';

/// Filtros de entrada reutilizables para los formularios.
///
/// Se aplican mientras el usuario escribe (no solo al enviar) para que los
/// caracteres no permitidos ni siquiera aparezcan en el campo.
abstract final class FiltrosTexto {
  /// Letras (con tildes y ñ), espacios, guion y apóstrofo.
  static final RegExp _nombre = RegExp(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ\s'\-]");

  /// Letras, espacios y puntuación básica. Sin dígitos.
  static final RegExp _textoReporte = RegExp(
    r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ\s.,;:¿?¡!"\u0027()\-/]',
  );

  static final List<TextInputFormatter> nombre = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(_nombre),
  ];

  /// Textos libres de reportes: descripción, referencia y espacio «Otro».
  static final List<TextInputFormatter> textoReporte = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(_textoReporte),
  ];

  /// Teléfono: solo dígitos y máximo 10.
  static final List<TextInputFormatter> telefono = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ];
}
