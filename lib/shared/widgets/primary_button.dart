import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Botón principal en píldora, fondo verde UTS con texto negro en negrita.
/// Con [cargando] muestra un indicador en lugar del texto.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.texto,
    required this.onPressed,
    this.cargando = false,
    this.variante = Variante.principal,
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool cargando;
  final Variante variante;

  @override
  Widget build(BuildContext context) {
    final (Color fondo, Color textoColor) = switch (variante) {
      Variante.principal => (AppColors.utsGreen, AppColors.textPrimary),
      Variante.secundario => (Colors.white, AppColors.utsGreen),
      Variante.peligro => (AppColors.estadoPendiente, Colors.white),
      Variante.verdeOscuro => (AppColors.welcomeBackground, Colors.white),
    };

    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: cargando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: fondo,
          foregroundColor: textoColor,
          side: variante == Variante.secundario
              ? BorderSide(color: AppColors.utsGreen, width: 2)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: cargando
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: textoColor,
                ),
              )
            : Text(
                texto,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textoColor,
                ),
              ),
      ),
    );
  }
}

enum Variante { principal, secundario, peligro, verdeOscuro }
