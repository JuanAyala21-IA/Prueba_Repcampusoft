import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/mes_anio.dart';

/// Selector desplegable del mes visible en la bandeja de notificaciones.
///
/// La lista llega ordenada de más reciente a más antiguo y siempre incluye el
/// mes que está seleccionado.
class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.meses,
    required this.seleccionado,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final List<MesAnio> meses;
  final MesAnio seleccionado;
  final ValueChanged<MesAnio> onChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final List<MesAnio> opciones = meses.contains(seleccionado)
        ? meses
        : <MesAnio>[seleccionado, ...meses];

    return Padding(
      padding: padding,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 20,
              color: AppColors.utsGreen,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MesAnio>(
                  value: seleccionado,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  dropdownColor: AppColors.background,
                  items: <DropdownMenuItem<MesAnio>>[
                    for (final MesAnio mes in opciones)
                      DropdownMenuItem<MesAnio>(
                        value: mes,
                        child: Text(
                          mes.esActual
                              ? '${mes.etiqueta} (mes actual)'
                              : mes.etiqueta,
                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (MesAnio? mes) {
                    if (mes != null) onChanged(mes);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
