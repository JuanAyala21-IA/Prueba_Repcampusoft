import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../../core/routes/session_provider.dart';
import '../../domain/historial_entry.dart';
import '../../domain/reporte.dart';
import '../../domain/reporte_repository.dart';
import '../../domain/servicio_almacenamiento_imagen.dart';
import '../firebase_almacenamiento_imagen.dart';
import '../firebase_reporte_repository.dart';
import '../sonda_conectividad_connectivity.dart';

/// StreamProvider que expone los reportes del usuario actual en tiempo real.
///
/// No es `autoDispose`: al volver a "Tus reportes" se muestra de inmediato la
/// última lista conocida en lugar de reiniciar la carga (lo que se percibía
/// como que la pantalla se recargaba sola). El stream se reconstruye cuando
/// cambia el usuario de la sesión.
final misReportesProvider = StreamProvider<List<Reporte>>((ref) {
  final String? uid = ref.watch(sesionProvider.select((sesion) => sesion.uid));
  if (uid == null) {
    return const Stream<List<Reporte>>.empty();
  }
  final repository = ref.watch(reporteRepositoryProvider);
  return repository.watchMisReportes();
});

/// StreamProvider.family para un reporte por ID en tiempo real.
final reporteByIdProvider = StreamProvider.autoDispose.family<Reporte?, String>(
  (ref, reportId) {
    final repository = ref.watch(reporteRepositoryProvider);
    return repository.watchReporteById(reportId);
  },
);

/// StreamProvider.family para el historial de un reporte.
final historialProvider = StreamProvider.autoDispose
    .family<List<HistorialEntry>, String>((ref, reportId) {
      final repository = ref.watch(reporteRepositoryProvider);
      return repository.watchHistorial(reportId);
    });

/// StreamProvider.family para TODOS los reportes (admin) con filtros opcionales.
/// Filtros: [filtroEstado] (ej. 'Pendiente', 'En revision', 'En proceso',
/// 'Solucionado', 'Todos') y [filtroEdificio] (ej. 'Edificio A', 'Todos').
final todosLosReportesProvider = StreamProvider.autoDispose
    .family<List<Reporte>, ({String? filtroEstado, String? filtroEdificio})>((
      ref,
      filtros,
    ) {
      final repository = ref.watch(reporteRepositoryProvider);
      return repository.watchTodosLosReportes(
        filtroEstado: filtros.filtroEstado == 'Todos'
            ? null
            : filtros.filtroEstado,
        filtroEdificio: filtros.filtroEdificio == 'Todos'
            ? null
            : filtros.filtroEdificio,
      );
    });

/// Overrides de Fase 5 (T4/T5): inyecta el repositorio Firestore activo y la
/// sonda de conectividad real en el [ProviderScope] de la raiz (main.dart).
///
/// El ProviderScope de raiz usa `overrides: reportesOverrides` (ver main.dart).
final List<Override> reportesOverrides = <Override>[
  servicioAlmacenamientoImagenProvider.overrideWith(
    (ref) => FirebaseAlmacenamientoImagen(),
  ),
  reporteRepositoryProvider.overrideWith(
    (ref) => FirebaseReporteRepository(
      almacenamiento: ref.watch(servicioAlmacenamientoImagenProvider),
    ),
  ),
  sondaConectividadProvider.overrideWith(
    (ref) => SondaConectividadConnectivity(),
  ),
];
