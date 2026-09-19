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
  });

  final String texto;
  final VoidCallback? onPressed;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: cargando ? null : onPressed,
        child: cargando
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.textPrimary,
                ),
              )
            : Text(texto),
      ),
    );
  }
}