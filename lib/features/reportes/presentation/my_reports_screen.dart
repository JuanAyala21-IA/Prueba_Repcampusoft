import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/rango_fechas.dart';
import '../../../shared/widgets/curved_green_background.dart';
import '../../../shared/widgets/date_range_filter.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/report_card.dart';
import '../../../shared/widgets/reportes_agrupados_por_fecha.dart';
import '../../../shared/widgets/uts_header.dart';
import '../data/providers/reporte_providers.dart';
import '../domain/reporte.dart';

/// Pantalla 10: Lista de Reportes Estudiante (con stream real desde Firestore).
class MyReportsScreen extends ConsumerStatefulWidget {
  const MyReportsScreen({super.key});

  @override
  ConsumerState<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends ConsumerState<MyReportsScreen> {
  RangoFechas _rango = const RangoFechas.todo();

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Reporte>> asyncReportes = ref.watch(
      misReportesProvider,
    );

    return Scaffold(
      body: CurvedGreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              const UtsHeader(titulo: 'Tus Reportes', mostrarLogo: false),
              const SizedBox(height: 4),
              DateRangeFilter(
                valor: _rango,
                onChanged: (RangoFechas rango) {
                  setState(() => _rango = rango);
                },
              ),
              const SizedBox(height: 10),
              Expanded(
                child: asyncReportes.when(
                  // Muestra el error aunque Riverpod esté reintentando la
                  // consulta: sin esto, un PERMISSION_DENIED dejaba el spinner
                  // indefinidamente.
                  skipLoadingOnReload: true,
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ErrorCarga(
                    mensaje: error.toString(),
                    onReintentar: () => ref.invalidate(misReportesProvider),
                  ),
                  data: (reportes) {
                    if (reportes.isEmpty) {
                      return const _ListaVacia();
                    }
                    final List<Reporte> filtrados = reportes
                        .where(
                          (Reporte reporte) =>
                              _rango.contiene(reporte.creadoEn),
                        )
                        .toList();
                    if (filtrados.isEmpty) {
                      return _SinResultadosRango(
                        rango: _rango,
                        onVerTodo: () =>
                            setState(() => _rango = const RangoFechas.todo()),
                      );
                    }
                    return _ListaReportes(
                      reportes: filtrados,
                      rango: _rango,
                      total: reportes.length,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCarga extends StatelessWidget {
  const _ErrorCarga({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar tus reportes',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              texto: 'Reintentar',
              onPressed: onReintentar,
              variante: Variante.verdeOscuro,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaVacia extends StatelessWidget {
  const _ListaVacia();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.report_problem_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes reportes aún',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando crees un reporte desde "Reportar daños",\naparecerá aquí para que puedas hacerle seguimiento.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SinResultadosRango extends StatelessWidget {
  const _SinResultadosRango({required this.rango, required this.onVerTodo});

  final RangoFechas rango;
  final VoidCallback onVerTodo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No hay reportes en este rango de fechas',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              rango.descripcion,
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              texto: 'Ver todo el tiempo',
              onPressed: onVerTodo,
              variante: Variante.secundario,
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaReportes extends StatelessWidget {
  const _ListaReportes({
    required this.reportes,
    required this.rango,
    required this.total,
  });

  final List<Reporte> reportes;
  final RangoFechas rango;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  reportes.length == 1
                      ? '1 reporte'
                      : '${reportes.length} de $total reportes',
                  style: AppTypography.textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!rango.esTodo)
                Text(
                  rango.etiqueta,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ReportesAgrupadosPorFecha(
            reportes: reportes,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemBuilder: (BuildContext context, Reporte reporte) {
              return ReportCard(
                titulo: reporte.tipoDano,
                ubicacion: reporte.ubicacionTexto,
                estado: reporte.estado,
                fecha: _formatFecha(reporte.creadoEn),
                icono: _iconoPorTipo(reporte.tipoDano),
                onTap: () => context.push(
                  '${AppRoutes.detalleReporte}/${reporte.reporteId}',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  IconData _iconoPorTipo(String tipoDano) {
    switch (tipoDano.toLowerCase()) {
      case 'silla':
      case 'mobiliario':
        return Icons.chair_outlined;
      case 'lámpara':
      case 'lampara':
      case 'iluminación':
      case 'iluminacion':
        return Icons.lightbulb_outline;
      case 'puerta':
        return Icons.door_front_door_outlined;
      case 'ventana':
        return Icons.window_outlined;
      case 'aire acondicionado':
      case 'aire':
        return Icons.ac_unit_outlined;
      case 'baño':
      case 'bano':
      case 'sanitario':
        return Icons.wc_outlined;
      case 'pizarra':
        return Icons.format_paint_outlined;
      case 'proyector':
        return Icons.tv_outlined;
      case 'tomacorriente':
      case 'enchufe':
        return Icons.electrical_services_outlined;
      default:
        return Icons.report_problem_outlined;
    }
  }
}
