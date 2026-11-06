import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/catalogo_edificios.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/routes/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/estado_reporte_style.dart';
import '../../../shared/widgets/curved_green_background.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/report_card.dart';
import '../../../shared/widgets/uts_header.dart';
import '../../auth/domain/rol_enum.dart';
import '../../reportes/data/providers/reporte_providers.dart';
import '../../reportes/domain/reporte.dart';

/// Pantalla 12: Daños Reportados / Gestión de Reportes (Administrador).
class ReportedDamagesScreen extends ConsumerStatefulWidget {
  const ReportedDamagesScreen({super.key});

  @override
  ConsumerState<ReportedDamagesScreen> createState() =>
      _ReportedDamagesScreenState();
}

class _ReportedDamagesScreenState extends ConsumerState<ReportedDamagesScreen> {
  String _filtroEstado = 'Todos';
  String _filtroEdificio = 'Todos';
  final _buscadorController = TextEditingController();

  // Map: valor filtro (Firestore) -> label visible (UI)
  static const _estadoLabels = {
    'Todos': 'Todos',
    'Pendiente': 'Pendientes',
    'En revision': 'En revisi\u00f3n',
    'En proceso': 'En proceso',
    'Solucionado': 'Solucionados',
    'Rechazado': 'Rechazados',
  };

  @override
  void initState() {
    super.initState();
    _buscadorController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncReportes = ref.watch(
      todosLosReportesProvider((
        filtroEstado: _filtroEstado,
        filtroEdificio: _filtroEdificio,
      )),
    );
    final Sesion sesion = ref.watch(sesionProvider);
    final bool esMantenimiento = sesion.rol == RolEnum.mantenimiento;

    return Scaffold(
      body: CurvedGreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              UtsHeader(
                titulo: 'Daños Reportados',
                mostrarLogo: false,
                subtitulo: esMantenimiento
                    ? 'Toma un reporte para atenderlo'
                    : null,
              ),
              const SizedBox(height: 8),
              // Buscador (filtrado en memoria)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: PillField(
                  hint: 'Buscar daño...',
                  icono: Icons.search,
                  borde: true,
                  controlador: _buscadorController,
                ),
              ),
              const SizedBox(height: 14),
              // Chips de filtro por estado
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _chip('Todos'),
                    _chip('Pendiente'),
                    _chip('En revision'),
                    _chip('Solucionado'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Selector de edificio
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Ubicacion:',
                      style: AppTypography.textTheme.titleSmall,
                    ),
                    const SizedBox(width: 10),
                    _edificioDropdown(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Lista de reportes (stream)
              Expanded(
                child: asyncReportes.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ErrorLista(mensaje: error.toString()),
                  data: (reportes) {
                    // Filtrado en memoria por búsqueda (tipoDano, descripcion, correoAutor)
                    final query = _buscadorController.text.trim().toLowerCase();
                    final filtrados = query.isEmpty
                        ? reportes
                        : reportes.where((r) {
                            final hayTipo = r.tipoDano.toLowerCase().contains(
                              query,
                            );
                            final hayDesc = r.descripcion
                                .toLowerCase()
                                .contains(query);
                            final hayCorreo = r.correoAutor
                                .toLowerCase()
                                .contains(query);
                            final hayUbicacion = r.ubicacionTexto
                                .toLowerCase()
                                .contains(query);
                            return hayTipo ||
                                hayDesc ||
                                hayCorreo ||
                                hayUbicacion;
                          }).toList();

                    if (filtrados.isEmpty) {
                      return const _ListaVaciaAdmin();
                    }
                    // El encargado de mantenimiento solo ve lo que puede tomar
                    // (sin asignar) y lo que ya tomó él. Los reportes tomados por
                    // otros compañeros no aparecen en su lista.
                    final visibles = esMantenimiento
                        ? filtrados.where((r) {
                            if (r.asignadoAUsuario(sesion.uid)) return true;
                            if (!r.sinAsignar) return false;
                            return r.estado != EstadoReporte.solucionado &&
                                r.estado != EstadoReporte.rechazado;
                          }).toList()
                        : filtrados;

                    if (visibles.isEmpty) {
                      return const _ListaVaciaAdmin();
                    }
                    return _ListaReportesAdmin(reportes: visibles);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String valorFiltro) {
    final bool activo = _filtroEstado == valorFiltro;
    final String label = _estadoLabels[valorFiltro] ?? valorFiltro;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: activo,
        onSelected: (_) => setState(() => _filtroEstado = valorFiltro),
      ),
    );
  }

  Widget _edificioDropdown() {
    final edificios = ['Todos', ...CatalogoEdificios.valores];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filtroEdificio,
          isDense: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          dropdownColor: AppColors.background,
          items: edificios
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _filtroEdificio = value);
          },
        ),
      ),
    );
  }
}

class _ErrorLista extends StatelessWidget {
  const _ErrorLista({required this.mensaje});

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
              'No se pudieron cargar los reportes',
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
          ],
        ),
      ),
    );
  }
}

class _ListaVaciaAdmin extends StatelessWidget {
  const _ListaVaciaAdmin();

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
              'No hay reportes con esos filtros',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta cambiar los filtros de estado, edificio o búsqueda.',
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

class _ListaReportesAdmin extends StatelessWidget {
  const _ListaReportesAdmin({required this.reportes});

  final List<Reporte> reportes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
          asignadoNombre: reporte.asignadoNombre,
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
