import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/image_preview.dart';
import '../../../shared/widgets/uts_header.dart';
import '../../../shared/widgets/status_badge.dart';
import '../domain/historial_entry.dart';
import '../domain/reporte.dart';
import '../domain/servicio_almacenamiento_imagen.dart';
import '../data/providers/reporte_providers.dart';

/// Pantalla 9: Detalle de Reporte Estudiante (con stream real desde Firestore).
class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Extraer reportId de la ruta: /detalle-reporte/{reportId}
    final String? reportId = GoRouterState.of(context)
        .pathParameters['reportId'];

    if (reportId == null || reportId.isEmpty) {
      return const _ErrorDetalle(mensaje: 'ID de reporte no válido');
    }

    final AsyncValue<Reporte?> asyncReporte = ref.watch(
      reporteByIdProvider(reportId),
    );
    final AsyncValue<List<HistorialEntry>> asyncHistorial = ref.watch(
      historialProvider(reportId),
    );

    return Scaffold(
      body: SafeArea(
        child: asyncReporte.when(
          loading: () => const _CargandoDetalle(),
          error: (error, _) => _ErrorDetalle(mensaje: error.toString()),
          data: (reporte) {
            if (reporte == null) {
              return const _NoExisteReporte();
            }
            return _DetalleReporte(
              reporte: reporte,
              asyncHistorial: asyncHistorial,
            );
          },
        ),
      ),
    );
  }
}

class _CargandoDetalle extends StatelessWidget {
  const _CargandoDetalle();

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

class _ErrorDetalle extends StatelessWidget {
  const _ErrorDetalle({required this.mensaje});

  final String mensaje;

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
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    'No se pudo cargar el detalle',
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
          ),
        ),
      ],
    );
  }
}

class _NoExisteReporte extends StatelessWidget {
  const _NoExisteReporte();

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
                    'El reporte no existe',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Es posible que haya sido eliminado o el ID sea incorrecto.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Volver a mis reportes'),
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

class _DetalleReporte extends StatelessWidget {
  const _DetalleReporte({required this.reporte, required this.asyncHistorial});

  final Reporte reporte;
  final AsyncValue<List<HistorialEntry>> asyncHistorial;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          UtsHeader(titulo: 'Tus Reportes', mostrarLogo: false),
          const SizedBox(height: 12),
          // Tarjeta principal del reporte
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estado actual con StatusBadge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reporte.tipoDano,
                        style: AppTypography.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StatusBadge(estado: reporte.estado),
                  ],
                ),
                const SizedBox(height: 16),
                _DatoFila(
                  etiqueta: 'Tipo de espacio:',
                  valor: reporte.tipoUbicacion.etiqueta,
                ),
                if (reporte.edificio != null)
                  _DatoFila(etiqueta: 'Edificio:', valor: reporte.edificio!),
                if (reporte.piso != null)
                  _DatoFila(etiqueta: 'Piso:', valor: reporte.piso!),
                _DatoFila(etiqueta: 'Espacio:', valor: reporte.espacio),
                if (reporte.referencia != null)
                  _DatoFila(
                    etiqueta: 'Referencia:',
                    valor: reporte.referencia!,
                  ),
                const SizedBox(height: 8),
                _DatoFila(
                  etiqueta: 'Descripción:',
                  valor: reporte.descripcion,
                  esMultilinea: true,
                ),
                const SizedBox(height: 12),
                // Foto si existe
                if (reporte.tieneFoto) ...[
                  Text('Evidencia:', style: AppTypography.textTheme.titleSmall),
                  const SizedBox(height: 10),
                  _FotoEvidencia(
                    reporteId: reporte.reporteId,
                    ubicacion: reporte.ubicacionTexto,
                  ),
                ],
                // Evidencia de la solución: visible también para el autor.
                if (reporte.tieneEvidenciaSolucion) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Evidencia de la solución:',
                    style: AppTypography.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 10),
                  _FotoEvidencia(
                    reporteId: reporte.reporteId,
                    ubicacion: reporte.ubicacionTexto,
                    esSolucion: true,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Línea de tiempo / Historial
          _HistorialSection(asyncHistorial: asyncHistorial),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DatoFila extends StatelessWidget {
  const _DatoFila({
    required this.etiqueta,
    required this.valor,
    this.esMultilinea = false,
  });

  final String etiqueta;
  final String valor;
  final bool esMultilinea;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: esMultilinea
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              etiqueta,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(valor, style: AppTypography.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _FotoEvidencia extends ConsumerStatefulWidget {
  const _FotoEvidencia({
    required this.reporteId,
    required this.ubicacion,
    this.esSolucion = false,
  });

  final String reporteId;
  final String ubicacion;

  /// `true` para mostrar `media/solucion` (evidencia de la reparación).
  final bool esSolucion;

  String get mediaId => esSolucion ? 'solucion' : 'foto';

  String get descripcion => esSolucion
      ? 'Evidencia de la solución en $ubicacion'
      : 'Evidencia del daño en $ubicacion';

  @override
  ConsumerState<_FotoEvidencia> createState() => _FotoEvidenciaState();
}

class _FotoEvidenciaState extends ConsumerState<_FotoEvidencia> {
  late Future<Uint8List?> _foto;

  @override
  void initState() {
    super.initState();
    _foto = _cargarFoto();
  }

  @override
  void didUpdateWidget(covariant _FotoEvidencia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reporteId != widget.reporteId ||
        oldWidget.mediaId != widget.mediaId) {
      _foto = _cargarFoto();
    }
  }

  /// Se guarda el Future para no volver a leer Firestore/Storage en cada
  /// rebuild (eso hacía que la imagen parpadeara). Soporta las imágenes nuevas
  /// en Storage y las antiguas guardadas como Base64.
  Future<Uint8List?> _cargarFoto() async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
        .instance
        .collection('reports')
        .doc(widget.reporteId)
        .collection('media')
        .doc(widget.mediaId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    final Map<String, dynamic> data = doc.data()!;

    final String? base64 = data['base64'] as String?;
    if (base64 != null && base64.isNotEmpty) {
      return base64Decode(base64);
    }

    final String? storagePath = data['storagePath'] as String?;
    if (storagePath != null && storagePath.isNotEmpty) {
      return ref
          .read(servicioAlmacenamientoImagenProvider)
          .descargar(storagePath);
    }

    final String? downloadUrl = data['downloadUrl'] as String?;
    if (downloadUrl != null && downloadUrl.isNotEmpty) {
      return FirebaseStorage.instance
          .refFromURL(downloadUrl)
          .getData(5 * 1024 * 1024);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _foto,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final Uint8List? bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: Icon(
                Icons.image_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return Semantics(
          image: true,
          button: true,
          label: '${widget.descripcion}. Toca para ampliar',
          child: GestureDetector(
            onTap: () => mostrarImagenAmpliada(
              context,
              bytes,
              descripcion: widget.descripcion,
            ),
            child: Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.divider),
                    image: DecorationImage(
                      image: MemoryImage(bytes),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Positioned(
                  right: 8,
                  bottom: 8,
                  child: IndicadorAmpliarImagen(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HistorialSection extends StatelessWidget {
  const _HistorialSection({required this.asyncHistorial});

  final AsyncValue<List<HistorialEntry>> asyncHistorial;

  @override
  Widget build(BuildContext context) {
    return asyncHistorial.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (historial) {
        if (historial.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historial de estados',
              style: AppTypography.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...historial.map((entry) => _HistorialItem(entry: entry)),
          ],
        );
      },
    );
  }
}

class _HistorialItem extends StatelessWidget {
  const _HistorialItem({required this.entry});

  final HistorialEntry entry;

  @override
  Widget build(BuildContext context) {
    final String fecha =
        '${entry.fecha.day.toString().padLeft(2, '0')}/${entry.fecha.month.toString().padLeft(2, '0')}/${entry.fecha.year} '
        '${entry.fecha.hour.toString().padLeft(2, '0')}:${entry.fecha.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(estado: entry.estadoNuevo, compacto: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fecha,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${entry.estadoAnterior.nombre} → ${entry.estadoNuevo.nombre}',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (entry.observacion != null && entry.observacion!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Observación: ${entry.observacion}',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (entry.adminNombre != null && entry.adminNombre!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Atendido por: ${entry.adminNombre}',
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
