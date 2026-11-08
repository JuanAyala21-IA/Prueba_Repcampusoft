import 'package:flutter/material.dart';

/// Paleta oficial del Design System (docs/diseno/pantallas.md §1.1).
abstract final class AppColors {
  /// Verde lima institucional UTS (primario).
  static const Color utsGreen = Color(0xFFB8D400);

  /// Verde lima institucional UTS (variante logo).
  static const Color utsGreenLogo = Color(0xFFC2D500);

  /// Fondo base de tarjetas y pantallas.
  static const Color background = Color(0xFFFFFFFF);

  /// Superficie / inputs / chips (gris suave).
  static const Color surface = Color(0xFFECEEF1);

  /// Superficie alternativa (gris más frío).
  static const Color surfaceAlt = Color(0xFFE8ECF2);

  /// Texto principal (negro carbón).
  static const Color textPrimary = Color(0xFF111111);

  /// Texto secundario (gris medio).
  static const Color textSecondary = Color(0xFF555555);

  /// Bordes y divisorias.
  static const Color divider = Color(0xFFD1D5DB);

  /// Líneas internas tenues.
  static const Color borderSubtle = Color(0xFFE5E7EB);

  /// Estado: Pendiente (coral).
  static const Color estadoPendiente = Color(0xFFFF6F61);

  /// Estado: En revisión (ámbar).
  static const Color estadoEnRevision = Color(0xFFFFD13B);

  /// Estado: En proceso (azul cielo).
  static const Color estadoEnProceso = Color(0xFF29B6F6);

  /// Estado: Solucionado (verde éxito).
  static const Color estadoSolucionado = Color(0xFF8CEE55);

  /// Gris oscuro neutro para mensajes de cuenta deshabilitada.
  static const Color grisOscuro = Color(0xFF616161);

  /// Fondo oliva oscuro para WelcomeScreen (variante oscura de utsGreen).
  static const Color welcomeBackground = Color(0xFF6B7C00);

  /// Sombra suave de las tarjetas (Design System §1.3).
  static Color sombraTarjeta(double opacidad) =>
      Colors.black.withValues(alpha: opacidad);
}
