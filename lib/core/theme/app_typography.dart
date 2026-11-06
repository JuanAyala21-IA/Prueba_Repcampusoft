import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografía del Design System (docs/diseno/pantallas.md §1.2).
/// Familia recomendada: Inter (Sans-Serif moderna).
abstract final class AppTypography {
  static const double pantalla = 22;
  static const double tituloTarjeta = 16;
  static const double cuerpo = 14;
  static const double metadato = 13;
  static const double fecha = 11;
  static const double boton = 15;

  static final TextTheme textTheme = GoogleFonts.interTextTheme()
      .apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      )
      .copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: pantalla,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: tituloTarjeta,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: metadato,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: cuerpo,
          color: AppColors.textPrimary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: metadato,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: boton,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );
}
