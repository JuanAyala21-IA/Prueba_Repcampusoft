import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/routes/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/estado_reporte_style.dart';
import '../../../core/utils/rango_fechas.dart';
import '../../../shared/widgets/curved_green_background.dart';
import '../../../shared/widgets/date_range_filter.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/report_card.dart';
import '../../../shared/widgets/uts_header.dart';
import '../../reportes/data/providers/reporte_providers.dart';
import '../../reportes/domain/reporte.dart';

/// Sección exclusiva del personal de mantenimiento: reportes que tomó y que
/// todavía debe resolver. Evita que se pierdan entre todos los daños
/// reportados.
class AssignedReportsScreen extends ConsumerStatefulWidget {
  const AssignedReportsScreen({super.key});

  @override
  ConsumerState<AssignedReportsScreen> createState() =>
      _AssignedReportsScreenState();
}

class _AssignedReportsScreenState extends ConsumerState<AssignedReportsScreen> {
  RangoFechas _rango = const RangoFechas.todo();

  @override
  Widget build(BuildContext context) {
    final Sesion sesion = ref.watch(sesionProvider);
    final asyncReportes = ref.watch(
      todosLosReportesProvider((
        filtroEstado: 'Todos',
        filtroEdificio: 'Todos',
      )),
    );

    return Scaffold(
      body: CurvedGreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              const UtsHeader(
                titulo: 'Mis reportes asignados',
                subtitulo: 'Daños que tomaste para resolver',
                mostrarLogo: false,
              ),
              const SizedBox(height: 4),
              DateRangeFilter(
                valor: _rango,
                onChanged: (RangoFechas rango) {
                  setState(() => _rango = rango);
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: asyncReportes.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      _ErrorAsignados(mensaje: error.toString()),
                  data: (reportes) {
                    final asignados =
                        reportes.where((reporte) {
                          if (!reporte.asignadoAUsuario(sesion.uid)) {
                            return false;
                          }
                          if (!_rango.contiene(reporte.creadoEn)) {
                            return false;
                          }
                          return reporte.estado != EstadoReporte.solucionado &&
                              reporte.estado != EstadoReporte.rechazado;
                        }).toList()..sort((a, b) {
                          final DateTime fechaA = a.asignadoEn ?? a.creadoEn;
                          final DateTime fechaB = b.asignadoEn ?? b.creadoEn;
                          return fechaA.compareTo(fechaB);
                        });

                    if (asignados.isEmpty) {
                      return _SinAsignados(
                        rango: _rango,
                        onVerTodo: () =>
                            setState(() => _rango = const RangoFechas.todo()),
                      );
                    }
                    return _ListaAsignados(reportes: asignados);
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

class _ListaAsignados extends StatelessWidget {
  const _ListaAsignados({required this.reportes});

  final List<Reporte> reportes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: reportes.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              reportes.length == 1
                  ? '1 reporte por resolver'
                  : '${reportes.length} reportes por resolver',
              style: AppTypography.textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        final reporte = reportes[index - 1];
        return ReportCard(
          titulo: reporte.tipoDano,
          ubicacion: reporte.ubicacionTexto,
          estado: reporte.estado,
          fecha: _formatFecha(reporte.asignadoEn ?? reporte.creadoEn),
          icono: _iconoPorTipo(reporte.tipoDano),
          onTap: () => context.push(
            '${AppRoutes.gestionReporte}?reportId=${reporte.reporteId}',
          ),
        );
      },
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

class _SinAsignados extends StatelessWidget {
  const _SinAsignados({required this.rango, required this.onVerTodo});

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
            const Icon(
              Icons.assignment_turned_in_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              rango.esTodo
                  ? 'No tienes reportes asignados'
                  : 'No hay reportes asignados en este rango',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              rango.esTodo
                  ? 'Toma un reporte en "Daños Reportados" y aparecerá aquí para que no se pierda entre los demás.'
                  : rango.descripcion,
              style: AppTypography.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!rango.esTodo)
              PrimaryButton(
                texto: 'Ver todo el tiempo',
                onPressed: onVerTodo,
                variante: Variante.secundario,
              )
            else
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.danosReportados),
                icon: const Icon(Icons.campaign_outlined),
                label: const Text('Ver daños reportados'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorAsignados extends StatelessWidget {
  const _ErrorAsignados({required this.mensaje});

  final String mensaje;

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
              style: AppTypography.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
