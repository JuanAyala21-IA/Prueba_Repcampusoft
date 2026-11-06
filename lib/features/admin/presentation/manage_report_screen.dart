import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/estado_reporte_style.dart';
import '../../../core/utils/results.dart';
import '../../../core/routes/session_provider.dart';
import '../../../shared/widgets/curved_green_background.dart';
import '../../../shared/widgets/image_preview.dart';
import '../../../shared/widgets/image_source_sheet.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../reportes/data/comprimir_imagen.dart';
import '../../reportes/domain/servicio_almacenamiento_imagen.dart';
import '../../../shared/widgets/uts_header.dart';
import '../../auth/domain/rol_enum.dart';
import '../../reportes/data/providers/reporte_providers.dart';
import '../../reportes/domain/historial_entry.dart';
import '../../reportes/domain/reporte.dart';
import '../../reportes/domain/reporte_repository.dart';

/// Pantalla de gestión de un reporte por el administrativo (RF-15).
/// Recibe [reportId] por parámetro de ruta: /gestion-reporte?reportId=...
class ManageReportScreen extends ConsumerWidget {
  const ManageReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? reportId = GoRouterState.of(context)
        .uri
        .queryParameters['reportId'];

    if (reportId == null || reportId.isEmpty) {
      return const _ErrorGestion(mensaje: 'ID de reporte no válido');
    }

    final AsyncValue<Reporte?> asyncReporte = ref.watch(
      reporteByIdProvider(reportId),
    );
    final AsyncValue<List<HistorialEntry>> asyncHistorial = ref.watch(
      historialProvider(reportId),
    );

    return Scaffold(
      body: CurvedGreenBackground(
        child: SafeArea(
          child: asyncReporte.when(
            loading: () => const _CargandoGestion(),
            error: (error, _) => _ErrorGestion(mensaje: error.toString()),
            data: (reporte) {
              if (reporte == null) {
                return const _NoExisteReporteGestion();
              }
              return _GestionReporte(
                reporte: reporte,
                asyncHistorial: asyncHistorial,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CargandoGestion extends StatelessWidget {
  const _CargandoGestion();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const UtsHeader(titulo: 'Gestionar Reporte', mostrarLogo: false),
        const Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}

class _ErrorGestion extends StatelessWidget {
  const _ErrorGestion({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const UtsHeader(titulo: 'Gestionar Reporte', mostrarLogo: false),
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
                    'No se pudo cargar el reporte',
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
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Volver'),
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

class _NoExisteReporteGestion extends StatelessWidget {
  const _NoExisteReporteGestion();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const UtsHeader(titulo: 'Gestionar Reporte', mostrarLogo: false),
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
                    child: const Text('Volver a daños reportados'),
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

class _GestionReporte extends ConsumerStatefulWidget {
  const _GestionReporte({required this.reporte, required this.asyncHistorial});

  final Reporte reporte;
  final AsyncValue<List<HistorialEntry>> asyncHistorial;

  @override
  ConsumerState<_GestionReporte> createState() => _GestionReporteState();
}

class _GestionReporteState extends ConsumerState<_GestionReporte> {
  String? _estadoSeleccionado;
  final _observacionController = TextEditingController();
  bool _guardando = false;
  bool _tomando = false;
  bool _procesandoEvidencia = false;

  /// Foto opcional que prueba que el daño quedó solucionado (solo al pasar a
  /// `Solucionado`).
  String? _evidenciaBase64;

  @override
  void initState() {
    super.initState();
    _estadoSeleccionado = widget.reporte.estado.valorFirestore;
    _observacionController.addListener(_actualizarEstadoBoton);
  }

  @override
  void dispose() {
    _observacionController.removeListener(_actualizarEstadoBoton);
    _observacionController.dispose();
    super.dispose();
  }

  void _actualizarEstadoBoton() {
    if (mounted) setState(() {});
  }

  bool get _requiereObservacion =>
      _estadoSeleccionado == 'Rechazado' &&
      (_observacionController.text.trim().isEmpty);

  /// La foto de evidencia es obligatoria al marcar el reporte como solucionado.
  bool get _requiereEvidencia =>
      _estadoSeleccionado == 'Solucionado' && _evidenciaBase64 == null;

  bool get _puedeGuardar =>
      _estadoSeleccionado != null &&
      _estadoSeleccionado != widget.reporte.estado.valorFirestore &&
      !_requiereObservacion &&
      !_requiereEvidencia &&
      !_guardando;

  Set<String> _transicionesPermitidas(String estadoActual) =>
      transicionesPermitidas[estadoActual] ?? const <String>{};

  Future<void> _tomarReporte() async {
    setState(() => _tomando = true);
    final Result<void> resultado = await ref
        .read(reporteRepositoryProvider)
        .tomarReporte(reportId: widget.reporte.reporteId);
    if (!mounted) return;
    setState(() => _tomando = false);
    switch (resultado) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte asignado a ti. Ya puedes atenderlo.'),
            backgroundColor: Colors.green,
          ),
        );
      case Failure():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.message),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Future<void> _seleccionarEvidencia() async {
    final ImageSource? fuente = await mostrarSelectorFuenteImagen(context);
    if (fuente == null) return;
    if (!mounted) return;
    setState(() => _procesandoEvidencia = true);
    final XFile? archivo = await ImagePicker().pickImage(
      source: fuente,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (archivo == null) {
      if (mounted) setState(() => _procesandoEvidencia = false);
      return;
    }
    // Mismo criterio que la foto del reporte: compresión equilibrada
    // (máx. 1280 px, ~150–250 KB).
    Uint8List comprimida;
    try {
      comprimida = await comprimirImagenReporte(archivo);
    } catch (_) {
      if (!mounted) return;
      setState(() => _procesandoEvidencia = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo comprimir la imagen.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _procesandoEvidencia = false;
      _evidenciaBase64 = base64Encode(comprimida);
    });
  }

  Future<void> _guardarCambios() async {
    if (!_puedeGuardar) return;

    setState(() => _guardando = true);

    final resultado = await ref
        .read(reporteRepositoryProvider)
        .cambiarEstado(
          reportId: widget.reporte.reporteId,
          estadoNuevo: _estadoSeleccionado!,
          observacion: _observacionController.text.trim().isEmpty
              ? null
              : _observacionController.text.trim(),
          evidenciaBase64: _estadoSeleccionado == 'Solucionado'
              ? _evidenciaBase64
              : null,
        );

    if (!mounted) {
      setState(() => _guardando = false);
      return;
    }

    setState(() => _guardando = false);

    switch (resultado) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estado actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // true = recargar lista
      case Failure():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.message),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reporte = widget.reporte;
    final estadoActual = reporte.estado.valorFirestore;
    final Sesion sesion = ref.watch(sesionProvider);
    final bool esAdministrativo = sesion.rol == RolEnum.administrativo;
    final bool esMantenimiento = sesion.rol == RolEnum.mantenimiento;
    final Set<String> destinosPermitidos = _transicionesPermitidas(
      estadoActual,
    );
    // Mantenimiento atiende y soluciona; rechazar es una decisión
    // administrativa, así que esa opción no se le ofrece.
    final List<String> destinosVisibles = esMantenimiento
        ? destinosPermitidos.where((e) => e != 'Rechazado').toList()
        : destinosPermitidos.toList();
    final bool asignadoAMi = reporte.asignadoAUsuario(sesion.uid);
    final bool asignadoAOtro = !reporte.sinAsignar && !asignadoAMi;
    final bool esFinal =
        reporte.estado == EstadoReporte.solucionado ||
        reporte.estado == EstadoReporte.rechazado;
    // El encargado de mantenimiento debe tomar el reporte antes de atenderlo;
    // una vez asignado, solo él puede cambiar su estado.
    final bool puedeTomar = esMantenimiento && reporte.sinAsignar && !esFinal;
    final bool puedeGestionar =
        esAdministrativo || (esMantenimiento && asignadoAMi);

    return Scaffold(
      body: CurvedGreenBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                UtsHeader(titulo: 'Gestionar Reporte', mostrarLogo: false),
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
                      // Tipo de daño + estado actual
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              reporte.tipoDano,
                              style: AppTypography.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          StatusBadge(estado: reporte.estado),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Datos de ubicación
                      _DatoFila(
                        etiqueta: 'Tipo de espacio:',
                        valor: reporte.tipoUbicacion.etiqueta,
                      ),
                      if (reporte.edificio != null)
                        _DatoFila(
                          etiqueta: 'Edificio:',
                          valor: reporte.edificio!,
                        ),
                      if (reporte.piso != null)
                        _DatoFila(etiqueta: 'Piso:', valor: reporte.piso!),
                      _DatoFila(etiqueta: 'Espacio:', valor: reporte.espacio),
                      if (reporte.referencia != null)
                        _DatoFila(
                          etiqueta: 'Referencia:',
                          valor: reporte.referencia!,
                        ),
                      const SizedBox(height: 8),
                      // Descripción
                      _DatoFila(
                        etiqueta: 'Descripción:',
                        valor: reporte.descripcion,
                        esMultilinea: true,
                      ),
                      const SizedBox(height: 8),
                      // Autor
                      _DatoFila(
                        etiqueta: 'Reportado por:',
                        valor: reporte.correoAutor,
                      ),
                      _DatoFila(
                        etiqueta: 'Asignado a:',
                        valor: reporte.sinAsignar
                            ? 'Sin asignar'
                            : (reporte.asignadoNombre ??
                                  'Encargado de mantenimiento'),
                      ),
                      if (reporte.encargadoNombre != null &&
                          reporte.encargadoNombre!.isNotEmpty)
                        _DatoFila(
                          etiqueta: 'Encargado:',
                          valor: reporte.encargadoNombre!,
                        ),
                      const SizedBox(height: 12),
                      // Foto si existe
                      if (reporte.tieneFoto) ...[
                        Text(
                          'Evidencia:',
                          style: AppTypography.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 10),
                        _FotoEvidencia(
                          reporteId: reporte.reporteId,
                          ubicacion: reporte.ubicacionTexto,
                        ),
                      ],
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
                          mediaId: 'solucion',
                          descripcion:
                              'Evidencia de que el daño fue solucionado',
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Divider antes de sección gestión
                      Divider(color: AppColors.divider),
                      const SizedBox(height: 16),
                      // Sección de gestión (solo administrativo/mantenimiento)
                      Text(
                        puedeGestionar
                            ? 'Cambiar estado'
                            : 'Gestión del reporte',
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estado actual: ${reporte.estado.nombre}',
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Botones de transición permitida
                      if (puedeTomar) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
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
                                  const Icon(
                                    Icons.build_circle_outlined,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Este reporte no tiene encargado. Tómalo para '
                                      'atenderlo: desde ese momento solo tú podrás '
                                      'cambiar su estado.',
                                      style: AppTypography.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: PrimaryButton(
                                  texto: _tomando
                                      ? 'Tomando reporte...'
                                      : 'Tomar reporte',
                                  onPressed: _tomando ? null : _tomarReporte,
                                  cargando: _tomando,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (asignadoAOtro && esMantenimiento) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Este reporte ya fue tomado por '
                                  '${reporte.asignadoNombre ?? 'otro encargado'}. '
                                  'Solo esa persona puede atenderlo.',
                                  style: AppTypography.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (!puedeGestionar) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Vista de solo lectura. Los administrativos y el '
                                  'personal de mantenimiento son quienes actualizan '
                                  'el estado de los reportes.',
                                  style: AppTypography.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (destinosVisibles.isEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.estadoSolucionado,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Este reporte ya está en un estado final (${reporte.estado.nombre}). '
                                  'No se pueden realizar más cambios.',
                                  style: AppTypography.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: destinosVisibles.map((estado) {
                            final estadoEnum = EstadoReporte.fromValor(estado);
                            final seleccionado = _estadoSeleccionado == estado;
                            return ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    estadoEnum.icono,
                                    size: 16,
                                    color: estadoEnum.colorTexto,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(estadoEnum.nombre),
                                ],
                              ),
                              selected: seleccionado,
                              onSelected: (_) =>
                                  setState(() => _estadoSeleccionado = estado),
                              selectedColor: estadoEnum.color.withValues(
                                alpha: 0.2,
                              ),
                              checkmarkColor: estadoEnum.color,
                              labelStyle: TextStyle(
                                color: seleccionado
                                    ? estadoEnum.color
                                    : AppColors.textPrimary,
                                fontWeight: seleccionado
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: seleccionado
                                    ? estadoEnum.color
                                    : AppColors.divider,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                        // Campo observación
                        Text(
                          'Observación',
                          style: AppTypography.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _observacionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: _estadoSeleccionado == 'Rechazado'
                                ? 'Motivo del rechazo (obligatorio)'
                                : 'Observación opcional...',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.divider),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.divider),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.utsGreen,
                                width: 2,
                              ),
                            ),
                            errorText: _requiereObservacion
                                ? 'La observación es obligatoria al rechazar'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (_estadoSeleccionado == 'Solucionado') ...[
                          Text(
                            'Evidencia de la solución',
                            style: AppTypography.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Obligatoria: adjunta una foto que demuestre que el '
                            'daño quedó solucionado.',
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_procesandoEvidencia) ...[
                            Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text('Procesando imagen...'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ] else if (_evidenciaBase64 != null) ...[
                            GestureDetector(
                              onTap: () => mostrarImagenAmpliada(
                                context,
                                base64Decode(_evidenciaBase64!),
                                descripcion: 'Evidencia de la solución',
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.memory(
                                      base64Decode(_evidenciaBase64!),
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
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
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _procesandoEvidencia
                                    ? null
                                    : _seleccionarEvidencia,
                                icon: Icon(
                                  _evidenciaBase64 == null
                                      ? Icons.add_a_photo_outlined
                                      : Icons.change_circle_outlined,
                                ),
                                label: Text(
                                  _evidenciaBase64 == null
                                      ? 'Adjuntar imagen'
                                      : 'Cambiar imagen',
                                ),
                              ),
                              if (_evidenciaBase64 != null) ...[
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _evidenciaBase64 = null),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Quitar'),
                                ),
                              ],
                            ],
                          ),
                          if (_requiereEvidencia) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Debes adjuntar la foto de evidencia para marcar '
                              'el reporte como solucionado.',
                              style: AppTypography.textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.estadoPendiente,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 22),
                        ],
                        // Botón guardar
                        PrimaryButton(
                          texto: _guardando
                              ? 'Guardando...'
                              : 'Guardar cambios',
                          onPressed: _puedeGuardar ? _guardarCambios : null,
                          cargando: _guardando,
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Línea de tiempo / Historial
                _HistorialSection(asyncHistorial: widget.asyncHistorial),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
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
    this.mediaId = 'foto',
    this.descripcion = 'Evidencia fotográfica del daño',
  });

  final String reporteId;
  final String ubicacion;
  final String mediaId;
  final String descripcion;

  @override
  ConsumerState<_FotoEvidencia> createState() => _FotoEvidenciaState();
}

class _FotoEvidenciaState extends ConsumerState<_FotoEvidencia> {
  late Future<Uint8List?> _media;

  @override
  void initState() {
    super.initState();
    _media = _cargarMedia();
  }

  @override
  void didUpdateWidget(covariant _FotoEvidencia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reporteId != widget.reporteId ||
        oldWidget.mediaId != widget.mediaId) {
      _media = _cargarMedia();
    }
  }

  /// Se guarda el Future para no volver a leer Firestore/Storage en cada
  /// rebuild (eso hacía que la imagen parpadeara). Soporta las imágenes nuevas
  /// en Storage y las antiguas guardadas como Base64.
  Future<Uint8List?> _cargarMedia() async {
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
      future: _media,
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
          label:
              '${widget.descripcion} en ${widget.ubicacion}. Toca para ampliar',
          child: GestureDetector(
            onTap: () => mostrarImagenAmpliada(
              context,
              bytes,
              descripcion: '${widget.descripcion} en ${widget.ubicacion}',
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
