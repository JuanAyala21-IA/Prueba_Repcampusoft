import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/curved_green_background.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/report_card.dart';
import '../../../shared/widgets/uts_header.dart';
import '../domain/reporte.dart';
import '../data/providers/reporte_providers.dart';

/// Pantalla 10: Lista de Reportes Estudiante (con stream real desde Firestore).
class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Reporte>> asyncReportes = ref.watch(
      misReportesProvider,
    );

    return Scaffold(
      body: CurvedGreenBackground(
        child: SafeArea(
          child: asyncReportes.when(
            // Muestra el error aunque Riverpod esté reintentando la consulta:
            // sin esto, un PERMISSION_DENIED dejaba el spinner indefinidamente.
            skipLoadingOnReload: true,
            loading: () => const _CargandoReportes(),
            error: (error, _) => _ErrorCarga(mensaje: error.toString()),
            data: (reportes) {
              if (reportes.isEmpty) {
                return const _ListaVacia();
              }
              return _ListaReportes(reportes: reportes);
            },
          ),
        ),
      ),
    );
  }
}

class _CargandoReportes extends StatelessWidget {
  const _CargandoReportes();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const UtsHeader(titulo: 'Tus Reportes', mostrarLogo: false),
        const Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}

class _ErrorCarga extends ConsumerWidget {
  const _ErrorCarga({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const UtsHeader(titulo: 'Tus Reportes', mostrarLogo: false),
        Expanded(
          child: Center(
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
                  // El stream queda en error hasta que se recrea el proveedor;
                  // este botón permite reintentar sin reiniciar la app.
                  PrimaryButton(
                    texto: 'Reintentar',
                    onPressed: () => ref.invalidate(misReportesProvider),
                    variante: Variante.verdeOscuro,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListaVacia extends StatelessWidget {
  const _ListaVacia();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const UtsHeader(titulo: 'Tus Reportes', mostrarLogo: false),
        Expanded(
          child: Center(
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
          ),
        ),
      ],
    );
  }
}

class _ListaReportes extends StatelessWidget {
  const _ListaReportes({required this.reportes});

  final List<Reporte> reportes;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const UtsHeader(titulo: 'Tus Reportes', mostrarLogo: false),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reportes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final reporte = reportes[index];
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
        ],
      ),
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
