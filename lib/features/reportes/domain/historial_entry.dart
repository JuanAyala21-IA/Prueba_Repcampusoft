import '../../../core/theme/estado_reporte_style.dart';

/// Entrada del historial de cambios de estado de un reporte.
class HistorialEntry {
  const HistorialEntry({
    required this.historialId,
    required this.estadoAnterior,
    required this.estadoNuevo,
    this.observacion,
    required this.fecha,
    this.adminUid,
    this.adminNombre,
  });

  final String historialId;
  final EstadoReporte estadoAnterior;
  final EstadoReporte estadoNuevo;
  final String? observacion;
  final DateTime fecha;

  /// Funcionario que realizó el cambio de estado.
  final String? adminUid;
  final String? adminNombre;
}
