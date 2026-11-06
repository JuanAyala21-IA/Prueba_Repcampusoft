import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Tarjeta de perfil con encabezado y filas con icono (pantallas 6.png, 7.png).
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.titulo,
    required this.iconoTitulo,
    this.hijos,
  });

  final String titulo;
  final IconData iconoTitulo;
  final List<Widget>? hijos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconoTitulo, size: 20, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(titulo, style: AppTypography.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 6),
          ...?hijos,
        ],
      ),
    );
  }
}

/// Fila icono + etiqueta + valor (y flecha opcional).
class ProfileRow extends StatelessWidget {
  const ProfileRow({
    super.key,
    required this.icono,
    required this.etiqueta,
    this.valor,
    this.onTap,
  });

  final IconData icono;
  final String etiqueta;
  final String? valor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icono, size: 20, color: AppColors.utsGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                valor == null ? etiqueta : '$etiqueta: $valor',
                style: valor == null
                    ? AppTypography.textTheme.bodyMedium
                    : AppTypography.textTheme.bodySmall,
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
