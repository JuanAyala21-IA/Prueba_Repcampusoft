import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/estado_reporte_style.dart';
import '../../../core/utils/rango_fechas.dart';
import '../../../shared/widgets/curved_green_background.dart';
import '../../../shared/widgets/date_range_filter.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/uts_header.dart';
import '../data/providers/reporte_providers.dart';
import '../data/reporte_csv_saver.dart';
import '../domain/reporte.dart';
import '../domain/reporte_csv.dart';

/// Exportación de reportes a CSV (solo superadministrador).
///
/// Puede recibir por URL `desde` y `hasta` (ISO 8601) y `estado` para exportar
/// exactamente el filtro que estaba activo en "Daños Reportados".
class ExportReportsScreen extends ConsumerStatefulWidget {
  const ExportReportsScreen({super.key});

  @override
  ConsumerState<ExportReportsScreen> createState() =>
      _ExportReportsScreenState();
}

class _ExportReportsScreenState extends ConsumerState<ExportReportsScreen> {
  bool _guardando = false;
  bool _filtrosInicializados = false;
  RangoFechas _rango = const RangoFechas.todo();
  String _estado = 'Todos';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filtrosInicializados) return;
    _filtrosInicializados = true;
    final Map<String, String> parametros = GoRouterState.of(context)
        .uri
        .queryParameters;
    _rango = RangoFechas.desdeParametros(parametros);
    final String? estado = parametros['estado'];
    if (estado != null &&
        EstadoReporte.values.any(
          (EstadoReporte valor) => valor.valorFirestore == estado,
        )) {
      _estado = estado;
    }
  }

  List<Reporte> _filtrar(List<Reporte> reportes) {
    return reportes.where((Reporte reporte) {
      if (!_rango.contiene(reporte.creadoEn)) return false;
      if (_estado != 'Todos' && reporte.estado.valorFirestore != _estado) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _descargarCsv(List<Reporte> reportes) async {
    setState(() => _guardando = true);
    try {
      final DateTime ahora = DateTime.now();
      final String contenido = generarCsvReportes(reportes, ahora: ahora);
      final String nombre = nombreArchivoCsvReportes(ahora);
      final String? ruta = await ref
          .read(reporteCsvSaverProvider)
          .guardar(nombreArchivo: nombre, contenido: contenido);
      if (!mounted) return;
      _mostrarMensaje(
        ruta == null
            ? 'No se guardó el archivo.'
            : 'CSV guardado con ${reportes.length} reportes.',
      );
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje('No se pudo guardar el CSV: $error');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Reporte>> reportesAsync = ref.watch(
      todosLosReportesProvider((filtroEstado: null, filtroEdificio: null)),
    );

    return Scaffold(
      body: CurvedGreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              const UtsHeader(
                titulo: 'Descargar reportes',
                subtitulo: 'Exportación completa en CSV',
                mostrarLogo: false,
              ),
              Expanded(
                child: reportesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ErrorExportacion(
                    mensaje: error.toString(),
                    onReintentar: () => ref.invalidate(
                      todosLosReportesProvider((
                        filtroEstado: null,
                        filtroEdificio: null,
                      )),
                    ),
                  ),
                  data: (reportes) {
                    final List<Reporte> filtrados = _filtrar(reportes);
                    return _ContenidoExportacion(
                      reportes: filtrados,
                      totalGeneral: reportes.length,
                      rango: _rango,
                      estado: _estado,
                      guardando: _guardando,
                      onRango: (RangoFechas rango) {
                        setState(() => _rango = rango);
                      },
                      onEstado: (String estado) {
                        setState(() => _estado = estado);
                      },
                      onLimpiar: () {
                        setState(() {
                          _rango = const RangoFechas.todo();
                          _estado = 'Todos';
                        });
                      },
                      onDescargar: () => _descargarCsv(filtrados),
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

class _ContenidoExportacion extends StatelessWidget {
  const _ContenidoExportacion({
    required this.reportes,
    required this.totalGeneral,
    required this.rango,
    required this.estado,
    required this.guardando,
    required this.onRango,
    required this.onEstado,
    required this.onLimpiar,
    required this.onDescargar,
  });

  final List<Reporte> reportes;
  final int totalGeneral;
  final RangoFechas rango;
  final String estado;
  final bool guardando;
  final ValueChanged<RangoFechas> onRango;
  final ValueChanged<String> onEstado;
  final VoidCallback onLimpiar;
  final VoidCallback onDescargar;

  @override
  Widget build(BuildContext context) {
    final bool sinReportes = reportes.isEmpty;
    final bool conFiltros = !rango.esTodo || estado != 'Todos';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.sombraTarjeta(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.file_download_outlined,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Reportes en CSV',
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  conFiltros
                      ? 'El archivo incluye solamente los reportes que cumplen '
                            'el filtro seleccionado. Puedes ajustarlo aquí.'
                      : 'El archivo incluye todos los reportes registrados, sin '
                            'importar su estado: pendientes, en revisión, en '
                            'proceso y solucionados.',
                  style: AppTypography.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 10),
                Text(
                  'Filtro de fechas',
                  style: AppTypography.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                DateRangeFilter(
                  valor: rango,
                  onChanged: onRango,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Estado:', style: AppTypography.textTheme.titleSmall),
                    const SizedBox(width: 10),
                    Expanded(child: _selectorEstado()),
                    if (conFiltros)
                      TextButton(
                        onPressed: onLimpiar,
                        child: const Text('Limpiar'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 12),
                Text(
                  'Resumen del filtro',
                  style: AppTypography.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  conFiltros
                      ? '${reportes.length} de $totalGeneral reportes · '
                            '${rango.descripcion}'
                      : '${reportes.length} reportes · todo el tiempo',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                _ResumenEstados(reportes: reportes),
                const SizedBox(height: 18),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 12),
                Text(
                  'Cada fila incluye:',
                  style: AppTypography.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                const _DetalleIncluido(
                  texto:
                      'ID, fechas de creación, actualización y solución, '
                      'estado y tipo de daño.',
                ),
                const _DetalleIncluido(
                  texto:
                      'Ubicación completa (edificio, piso, espacio y '
                      'referencia) y descripción del daño.',
                ),
                const _DetalleIncluido(
                  texto:
                      'Correo y UID del autor, foto del daño, encargado de '
                      'mantenimiento y evidencia de solución.',
                ),
                const _DetalleIncluido(
                  texto:
                      'Observación de gestión, días desde la creación y días '
                      'hasta la solución.',
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  texto: 'Descargar CSV',
                  cargando: guardando,
                  onPressed: sinReportes ? null : onDescargar,
                ),
                if (sinReportes) ...[
                  const SizedBox(height: 10),
                  Text(
                    'No hay reportes con los filtros seleccionados.',
                    textAlign: TextAlign.center,
                    style: AppTypography.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'El archivo se guarda donde tú elijas desde el diálogo del '
            'sistema. En Excel se abre directamente en columnas.',
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectorEstado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: estado,
          isDense: true,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          dropdownColor: AppColors.background,
          items: [
            const DropdownMenuItem(value: 'Todos', child: Text('Todos')),
            for (final EstadoReporte valor in EstadoReporte.values)
              DropdownMenuItem(
                value: valor.valorFirestore,
                child: Text(valor.nombre),
              ),
          ],
          onChanged: (String? valor) {
            if (valor != null) onEstado(valor);
          },
        ),
      ),
    );
  }
}

class _ResumenEstados extends StatelessWidget {
  const _ResumenEstados({required this.reportes});

  final List<Reporte> reportes;

  @override
  Widget build(BuildContext context) {
    final Map<EstadoReporte, int> conteos = <EstadoReporte, int>{
      for (final EstadoReporte estado in EstadoReporte.values)
        estado: reportes
            .where((Reporte reporte) => reporte.estado == estado)
            .length,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ContadorEstado(
          etiqueta: 'Total',
          cantidad: reportes.length,
          color: AppColors.utsGreen,
        ),
        for (final EstadoReporte estado in EstadoReporte.values)
          _ContadorEstado(
            etiqueta: estado.nombre,
            cantidad: conteos[estado] ?? 0,
            color: estado.color,
          ),
      ],
    );
  }
}

class _ContadorEstado extends StatelessWidget {
  const _ContadorEstado({
    required this.etiqueta,
    required this.cantidad,
    required this.color,
  });

  final String etiqueta;
  final int cantidad;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            '$etiqueta: $cantidad',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetalleIncluido extends StatelessWidget {
  const _DetalleIncluido({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: AppColors.utsGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto, style: AppTypography.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _ErrorExportacion extends StatelessWidget {
  const _ErrorExportacion({required this.mensaje, required this.onReintentar});

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
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.estadoPendiente,
            ),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar los reportes.',
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
