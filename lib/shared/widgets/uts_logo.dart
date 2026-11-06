import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Logo oficial UTS (pantallas.md §1.4): isotipo "uts" en verde lima,
/// divisor vertical esbelto y logotipo de texto en 3 líneas gris plomo.
class UtsLogo extends StatelessWidget {
  const UtsLogo({super.key, this.altura = 44, this.compacto = false});

  /// Altura total en píxeles del logotipo.
  final double altura;

  /// Modo compacto: solo el isotipo (para el header).
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    if (compacto) {
      return SizedBox(
        height: altura,
        child: Text(
          'uts',
          style: AppTypography.textTheme.titleLarge?.copyWith(
            color: AppColors.utsGreenLogo,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            height: 1,
          ),
        ),
      );
    }

    return SizedBox(
      height: altura,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'uts',
            style: AppTypography.textTheme.titleLarge?.copyWith(
              color: AppColors.utsGreenLogo,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              height: 1,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1.2, height: altura * 0.8, color: AppColors.divider),
          const SizedBox(width: 10),
          Text(
            'Unidades\nTecnológicas de\nSantander',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 9.5,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
