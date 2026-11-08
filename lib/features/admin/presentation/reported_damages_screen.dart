import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/catalogo_edificios.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/routes/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/estado_reporte_style.dart';
import '../../../core/utils/rango_fechas.dart';
import '../../../shared/widgets/curved_green_background.dart';
import '../../../shared/widgets/date_range_filter.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/report_card.dart';
import '../../../shared/widgets/reportes_agrupados_por_fecha.dart';
import '../../../shared/widgets/uts_header.dart';
import '../../auth/domain/rol_enum.dart';
import '../../reportes/data/providers/reporte_providers.dart';
import '../../reportes/domain/estadisticas_reportes.dart';
import '../../reportes/domain/reporte.dart';
import '../../reportes/presentation/widgets/reportes_estadisticas_panel.dart';

/// Pantalla 12: Daños Reportados / Gestión de Reportes (Administrador).
class ReportedDamagesScreen extends ConsumerStatefulWidget {
  const ReportedDamagesScreen({super.key});

  @override
  ConsumerState<ReportedDamagesScreen> createState() =>
      _ReportedDamagesScreenState();
}

enum _VistaReportes { listado, estadisticas }

class _ReportedDamagesScreenState extends ConsumerState<ReportedDamagesScreen> {
  String _filtroEstado = 'Todos';
  String _filtroEdificio = 'Todos';
  RangoFechas _rango = const RangoFechas.todo();
  _VistaReportes _vista = _VistaReportes.listado;
  final _buscadorController = TextEditingController();

  // Map: valor filtro (Firestore) -> label visible (UI)
  static const _estadoLabels = {
    'Todos': 'Todos',
    'Pendiente': 'Pendientes',
    'En revision': 'En revisión',
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

  void _abrirExportacion() {
    final Map<String, String> parametros = <String, String>{
      ..._rango.parametros,
      if (_vista == _VistaReportes.listado && _filtroEstado != 'Todos')
        'estado': _filtroEstado,
    };
    final Uri uri = Uri(
      path: AppRoutes.exportarReportes,
      queryParameters: parametros.isEmpty ? null : parametros,
    );
    context.push(uri.toString());
  }

  /// Aplica búsqueda, estado, edificio y la visibilidad por rol.
  List<Reporte> _filtrar(
    List<Reporte> reportes, {
    required Sesion sesion,
    required bool esMantenimiento,
  }) {
    final String consulta = _buscadorController.text.trim().toLowerCase();
    return reportes.where((Reporte reporte) {
      if (_filtroEstado != 'Todos' &&
          reporte.estado.valorFirestore != _filtroEstado) {
        return false;
      }
      if (_filtroEdificio != 'Todos' && reporte.edificio != _filtroEdificio) {
        return false;
      }
      if (consulta.isNotEmpty) {
        final String texto = <String>[
          reporte.tipoDano,
          reporte.descripcion,
          reporte.correoAutor,
          reporte.ubicacionTexto,
        ].join(' ').toLowerCase();
        if (!texto.contains(consulta)) return false;
      }
      if (esMantenimiento) {
        if (reporte.asignadoAUsuario(sesion.uid)) return true;
        if (!reporte.sinAsignar) return false;
        return reporte.estado != EstadoReporte.solucionado &&
            reporte.estado != EstadoReporte.rechazado;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final asyncReportes = ref.watch(
      todosLosReportesProvider((
        filtroEstado: 'Todos',
        filtroEdificio: 'Todos',
      )),
    );
    final Sesion sesion = ref.watch(sesionProvider);
    final bool esMantenimiento = sesion.rol == RolEnum.mantenimiento;
    final bool esSuperadministrador = sesion.esSuperadministrador;

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
                accion: esSuperadministrador
                    ? IconButton(
                        tooltip: 'Descargar reportes (CSV)',
                        onPressed: _abrirExportacion,
                        icon: const Icon(Icons.file_download_outlined),
                      )
                    : null,
              ),
              const SizedBox(height: 2),
              DateRangeFilter(
                valor: _rango,
                onChanged: (RangoFechas rango) {
                  setState(() => _rango = rango);
                },
              ),
              if (esSuperadministrador) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<_VistaReportes>(
                      segments: const [
                        ButtonSegment<_VistaReportes>(
                          value: _VistaReportes.listado,
                          icon: Icon(Icons.list_alt_outlined, size: 18),
                          label: Text('Reportes'),
                        ),
                        ButtonSegment<_VistaReportes>(
                          value: _VistaReportes.estadisticas,
                          icon: Icon(Icons.insights_outlined, size: 18),
                          label: Text('Estadísticas'),
                        ),
                      ],
                      selected: <_VistaReportes>{_vista},
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                      onSelectionChanged: (Set<_VistaReportes> seleccion) {
                        setState(() => _vista = seleccion.first);
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Expanded(
                child: asyncReportes.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ErrorLista(mensaje: error.toString()),
                  data: (reportes) {
                    if (esSuperadministrador &&
                        _vista == _VistaReportes.estadisticas) {
                      final EstadisticasReportes periodo =
                          EstadisticasReportes.calcular(
                            reportes,
                            rango: _rango,
                          );
                      final EstadisticasReportes general =
                          EstadisticasReportes.calcular(
                            reportes,
                            rango: const RangoFechas.todo(),
                          );
                      return ReportesEstadisticasPanel(
                        periodo: periodo,
                        general: general,
                        rango: _rango,
                      );
                    }

                    final List<Reporte> porFecha = reportes
                        .where(
                          (Reporte reporte) =>
                              _rango.contiene(reporte.creadoEn),
                        )
                        .toList();
                    final List<Reporte> visibles = _filtrar(
                      porFecha,
                      sesion: sesion,
                      esMantenimiento: esMantenimiento,
                    );

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: PillField(
                            hint: 'Buscar daño...',
                            icono: Icons.search,
                            borde: true,
                            controlador: _buscadorController,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              _chip('Todos'),
                              _chip('Pendiente'),
                              _chip('En revision'),
                              _chip('En proceso'),
                              _chip('Solucionado'),
                              if (!esMantenimiento) _chip('Rechazado'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Text(
                                'Ubicación:',
                                style: AppTypography.textTheme.titleSmall,
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: _edificioDropdown()),
                              const SizedBox(width: 10),
                              Text(
                                visibles.length == 1
                                    ? '1 reporte'
                                    : '${visibles.length} reportes',
                                style: AppTypography.textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: visibles.isEmpty
                              ? const _ListaVaciaAdmin()
                              : _ListaReportesAdmin(reportes: visibles),
                        ),
                      ],
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

  Widget _chip(String valorFiltro) {
    final bool activo = _filtroEstado == valorFiltro;
    final String label = _estadoLabels[valorFiltro] ?? valorFiltro;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: activo,
        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
        onSelected: (_) => setState(() => _filtroEstado = valorFiltro),
      ),
    );
  }

  Widget _edificioDropdown() {
    final edificios = ['Todos', ...CatalogoEdificios.valores];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filtroEdificio,
          isDense: true,
          isExpanded: true,
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
              'Intenta cambiar el rango de fechas, el estado, el edificio o la búsqueda.',
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
    return ReportesAgrupadosPorFecha(
      reportes: reportes,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemBuilder: (BuildContext context, Reporte reporte) {
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
