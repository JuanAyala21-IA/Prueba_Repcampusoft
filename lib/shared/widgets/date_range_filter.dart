import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/rango_fechas.dart';

/// Fila horizontal de filtros rápidos por fecha + calendario personalizado.
class DateRangeFilter extends StatelessWidget {
  const DateRangeFilter({
    super.key,
    required this.valor,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final RangoFechas valor;
  final ValueChanged<RangoFechas> onChanged;
  final EdgeInsetsGeometry padding;

  static const List<PresetRangoFecha> _presets = [
    PresetRangoFecha.todo,
    PresetRangoFecha.hoy,
    PresetRangoFecha.ultimos7Dias,
    PresetRangoFecha.esteMes,
    PresetRangoFecha.esteAnio,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final PresetRangoFecha preset in _presets)
                  _chip(
                    etiqueta: _etiquetaPreset(preset),
                    activo: valor.preset == preset,
                    onTap: () => onChanged(_crearPreset(preset)),
                  ),
                _chip(
                  etiqueta: valor.preset == PresetRangoFecha.personalizado
                      ? valor.etiqueta
                      : 'Personalizado',
                  activo: valor.preset == PresetRangoFecha.personalizado,
                  icono: Icons.calendar_month_outlined,
                  onTap: () => _elegirRango(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String etiqueta,
    required bool activo,
    required VoidCallback onTap,
    IconData? icono,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: activo,
        onSelected: (_) => onTap(),
        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.utsGreen.withValues(alpha: 0.35),
        side: BorderSide(
          color: activo ? AppColors.utsGreen : AppColors.divider,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono != null) ...[
              Icon(icono, size: 15, color: AppColors.textPrimary),
              const SizedBox(width: 5),
            ],
            Text(
              etiqueta,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _elegirRango(BuildContext context) async {
    final DateTime hoy = DateTime.now();
    final DateTime inicioSugerido =
        valor.desde ?? hoy.subtract(const Duration(days: 29));
    final DateTime finSugerido = valor.hasta ?? hoy;
    final DateTimeRange? seleccionado = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(hoy.year, hoy.month, hoy.day),
      initialDateRange: DateTimeRange(start: inicioSugerido, end: finSugerido),
      locale: const Locale('es'),
      helpText: 'Seleccionar rango de fechas',
      saveText: 'Aplicar',
      cancelText: 'Cancelar',
      fieldStartLabelText: 'Desde',
      fieldEndLabelText: 'Hasta',
    );
    if (seleccionado == null) return;
    onChanged(RangoFechas.personalizado(seleccionado.start, seleccionado.end));
  }

  String _etiquetaPreset(PresetRangoFecha preset) {
    return switch (preset) {
      PresetRangoFecha.todo => 'Todo el tiempo',
      PresetRangoFecha.hoy => 'Hoy',
      PresetRangoFecha.ultimos7Dias => 'Últimos 7 días',
      PresetRangoFecha.esteMes => 'Este mes',
      PresetRangoFecha.esteAnio => 'Este año',
      PresetRangoFecha.personalizado => 'Personalizado',
    };
  }

  RangoFechas _crearPreset(PresetRangoFecha preset) {
    return switch (preset) {
      PresetRangoFecha.todo => const RangoFechas.todo(),
      PresetRangoFecha.hoy => RangoFechas.hoy(),
      PresetRangoFecha.ultimos7Dias => RangoFechas.ultimos7Dias(),
      PresetRangoFecha.esteMes => RangoFechas.esteMes(),
      PresetRangoFecha.esteAnio => RangoFechas.esteAnio(),
      PresetRangoFecha.personalizado => valor,
    };
  }
}
