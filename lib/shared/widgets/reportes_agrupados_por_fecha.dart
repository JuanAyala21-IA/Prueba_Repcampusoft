import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/reportes/domain/reporte.dart';
import '../../features/reportes/domain/reporte_agrupacion.dart';

/// Lista de reportes con encabezados por día.
///
/// Evita repetir en cada pantalla la lógica de agrupar y separar las tarjetas.
/// [itemBuilder] construye la tarjeta de cada reporte.
class ReportesAgrupadosPorFecha extends StatelessWidget {
  const ReportesAgrupadosPorFecha({
    super.key,
    required this.reportes,
    required this.itemBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.fechaDe,
    this.descendente = true,
    this.ahora,
  });

  final List<Reporte> reportes;
  final Widget Function(BuildContext context, Reporte reporte) itemBuilder;
  final EdgeInsetsGeometry padding;
  final DateTime Function(Reporte)? fechaDe;
  final bool descendente;
  final DateTime? ahora;

  @override
  Widget build(BuildContext context) {
    final List<GrupoReportesFecha> grupos = agruparReportesPorFecha(
      reportes,
      fechaDe: fechaDe,
      descendente: descendente,
    );
    final List<Object> entradas = <Object>[];
    for (final GrupoReportesFecha grupo in grupos) {
      entradas.add(grupo);
      entradas.addAll(grupo.reportes);
    }

    return ListView.builder(
      padding: padding,
      itemCount: entradas.length,
      itemBuilder: (context, index) {
        final Object entrada = entradas[index];
        if (entrada is GrupoReportesFecha) {
          return _EncabezadoFecha(
            grupo: entrada,
            esPrimero: index == 0,
            ahora: ahora,
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: itemBuilder(context, entrada as Reporte),
        );
      },
    );
  }
}

class _EncabezadoFecha extends StatelessWidget {
  const _EncabezadoFecha({
    required this.grupo,
    required this.esPrimero,
    this.ahora,
  });

  final GrupoReportesFecha grupo;
  final bool esPrimero;
  final DateTime? ahora;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: esPrimero ? 0 : 8, bottom: 10),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 7),
          Text(
            etiquetaFechaGrupo(grupo.fecha, ahora: ahora),
            style: AppTypography.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${grupo.reportes.length}',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
