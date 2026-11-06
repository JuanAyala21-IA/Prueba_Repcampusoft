import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Botón circular con fondo UTS (flecha de retroceso / botón de ayuda),
/// tal como se describe en pantallas.md §1.3.
class CircularButtonUts extends StatelessWidget {
  const CircularButtonUts({
    super.key,
    required this.onPressed,
    this.icono = Icons.arrow_back,
    this.fondo = AppColors.utsGreen,
    this.iconoColor = AppColors.textPrimary,
  });

  final VoidCallback onPressed;
  final IconData icono;
  final Color fondo;
  final Color iconoColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fondo,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icono, color: iconoColor, size: 22),
        ),
      ),
    );
  }
}
