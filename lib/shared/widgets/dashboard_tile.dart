import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Tarjeta de acceso rápido del dashboard 2x2 (pantallas 4.png, 5.png).
class DashboardTile extends StatelessWidget {
  const DashboardTile({
    super.key,
    required this.icono,
    required this.titulo,
    this.destacado = false,
    this.onTap,
  });

  final IconData icono;
  final String titulo;

  /// [destacado] subraya el texto (ej. "Reportar daños").
  final bool destacado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.sombraTarjeta(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icono, color: AppColors.textPrimary, size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    decoration: destacado ? TextDecoration.underline : null,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
