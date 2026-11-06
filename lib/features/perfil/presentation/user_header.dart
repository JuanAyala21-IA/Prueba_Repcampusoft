import 'package:flutter/material.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_colors.dart';

/// Encabezado de las pantallas de inicio (4.png, 5.png): avatar, nombre y subtítulo.
class UserHeader extends StatelessWidget {
  const UserHeader({super.key, required this.nombre, required this.subtitulo});

  final String nombre;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 44),
            const Expanded(child: Center(child: SizedBox(height: 40))),
            SizedBox(
              width: 44,
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.textPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(nombre, style: AppTypography.textTheme.titleLarge),
        Text(subtitulo, style: AppTypography.textTheme.titleSmall),
        const SizedBox(height: 8),
        const Divider(color: AppColors.divider),
      ],
    );
  }
}
