import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Tarjeta de notificación (pantallas 11.png, 13.png): icono, título, mensaje y fecha.
/// Si [leida] es true, se muestra atenuada; si false, destacada (no leída).
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    this.icono,
    this.onTap,
    this.leida = false,
  });

  final String titulo;
  final String mensaje;
  final String fecha;
  final IconData? icono;
  final VoidCallback? onTap;
  final bool leida;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = leida
        ? AppColors.background
        : Color.alphaBlend(
            AppColors.utsGreen.withValues(alpha: 0.16),
            Colors.white,
          );
    final Color iconBackgroundColor = leida
        ? AppColors.surface
        : Color.alphaBlend(
            AppColors.utsGreen.withValues(alpha: 0.22),
            Colors.white,
          );
    final Color iconColor = leida ? AppColors.textPrimary : AppColors.utsGreen;
    final Color titleColor = leida
        ? AppColors.textPrimary.withValues(alpha: 0.7)
        : AppColors.textPrimary;
    final Color messageColor = leida
        ? AppColors.textSecondary.withValues(alpha: 0.7)
        : AppColors.textSecondary;
    final Color dateColor = leida
        ? AppColors.textSecondary.withValues(alpha: 0.6)
        : AppColors.textSecondary;
    final Color chevronColor = leida
        ? AppColors.textSecondary.withValues(alpha: 0.6)
        : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: leida
            ? null
            : Border.all(
                color: AppColors.utsGreen.withValues(alpha: 0.3),
                width: 1.5,
              ),
        boxShadow: [
          BoxShadow(
            color: AppColors.sombraTarjeta(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icono ?? Icons.notifications_none,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        mensaje,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: messageColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: dateColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            fecha,
                            style: TextStyle(color: dateColor, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: chevronColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
