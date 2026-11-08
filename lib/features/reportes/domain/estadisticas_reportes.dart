import '../../../core/theme/estado_reporte_style.dart';
import '../../../core/utils/rango_fechas.dart';
import 'reporte.dart';

/// Conteo de reportes en un día o mes concreto.
class EstadisticaPorFecha {
  EstadisticaPorFecha({
    required this.fecha,
    required this.esMes,
    required this.total,
    required this.porEstado,
  });

  final DateTime fecha;
  final bool esMes;
  final int total;
  final Map<EstadoReporte, int> porEstado;

  int cantidad(EstadoReporte estado) => porEstado[estado] ?? 0;

  String get etiqueta {
    String dos(int valor) => valor.toString().padLeft(2, '0');
    if (esMes) return '${dos(fecha.month)}/${fecha.year}';
    return '${dos(fecha.day)}/${dos(fecha.month)}';
  }

  String get etiquetaCompleta {
    String dos(int valor) => valor.toString().padLeft(2, '0');
    if (esMes) return '${dos(fecha.month)}/${fecha.year}';
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
  }
}

/// Estadísticas de reportes para el dashboard del superadministrador.
///
/// Todos los cálculos se hacen sobre reportes **creados** dentro del rango de
/// fechas seleccionado. El estado que se cuenta es el estado actual del
/// reporte.
class EstadisticasReportes {
  EstadisticasReportes._({
    required this.total,
    required this.porEstado,
    required this.porFecha,
    required this.agrupadoPorMes,
    required this.promedioDiasSolucion,
  });

  final int total;
  final Map<EstadoReporte, int> porEstado;
  final List<EstadisticaPorFecha> porFecha;
  final bool agrupadoPorMes;

  /// Promedio de días entre la creación y la solución de los reportes
  /// solucionados del periodo. Es `0` si no hay datos.
  final double promedioDiasSolucion;

  int get solucionados => porEstado[EstadoReporte.solucionado] ?? 0;
  int get rechazados => porEstado[EstadoReporte.rechazado] ?? 0;
  int get pendientes => porEstado[EstadoReporte.pendiente] ?? 0;
  int get enRevision => porEstado[EstadoReporte.enRevision] ?? 0;
  int get enProceso => porEstado[EstadoReporte.enProceso] ?? 0;

  /// Reportes que todavía no están cerrados (ni solucionados ni rechazados).
  int get sinCerrar => pendientes + enRevision + enProceso;

  double get porcentajeSolucionados =>
      total == 0 ? 0 : (solucionados / total) * 100;

  double get porcentajeRechazados =>
      total == 0 ? 0 : (rechazados / total) * 100;

  factory EstadisticasReportes.calcular(
    List<Reporte> reportes, {
    required RangoFechas rango,
    DateTime? ahora,
  }) {
    final List<Reporte> filtrados = reportes
        .where((Reporte reporte) => rango.contiene(reporte.creadoEn))
        .toList();

    final Map<EstadoReporte, int> porEstado = <EstadoReporte, int>{
      for (final EstadoReporte estado in EstadoReporte.values) estado: 0,
    };
    for (final Reporte reporte in filtrados) {
      porEstado[reporte.estado] = (porEstado[reporte.estado] ?? 0) + 1;
    }

    final DateTime? inicio = rango.desde ?? _fechaMinima(filtrados);
    final DateTime? fin = rango.hasta ?? _fechaMaxima(filtrados);
    final bool agrupadoPorMes =
        inicio != null && fin != null && fin.difference(inicio).inDays > 90;

    final List<EstadisticaPorFecha> porFecha = <EstadisticaPorFecha>[];
    if (inicio != null && fin != null) {
      final Map<DateTime, EstadisticaPorFecha> indices =
          <DateTime, EstadisticaPorFecha>{};
      DateTime cursor = agrupadoPorMes
          ? DateTime(inicio.year, inicio.month)
          : DateTime(inicio.year, inicio.month, inicio.day);
      final DateTime limite = agrupadoPorMes
          ? DateTime(fin.year, fin.month)
          : DateTime(fin.year, fin.month, fin.day);

      while (!cursor.isAfter(limite)) {
        final EstadisticaPorFecha estadistica = EstadisticaPorFecha(
          fecha: cursor,
          esMes: agrupadoPorMes,
          total: 0,
          porEstado: <EstadoReporte, int>{
            for (final EstadoReporte estado in EstadoReporte.values) estado: 0,
          },
        );
        indices[cursor] = estadistica;
        porFecha.add(estadistica);
        cursor = agrupadoPorMes
            ? DateTime(cursor.year, cursor.month + 1)
            : cursor.add(const Duration(days: 1));
      }

      for (final Reporte reporte in filtrados) {
        final DateTime fecha = reporte.creadoEn;
        final DateTime clave = agrupadoPorMes
            ? DateTime(fecha.year, fecha.month)
            : DateTime(fecha.year, fecha.month, fecha.day);
        final EstadisticaPorFecha? estadistica = indices[clave];
        if (estadistica == null) continue;
        estadistica.porEstado[reporte.estado] =
            (estadistica.porEstado[reporte.estado] ?? 0) + 1;
        indices[clave] = EstadisticaPorFecha(
          fecha: estadistica.fecha,
          esMes: estadistica.esMes,
          total: estadistica.total + 1,
          porEstado: estadistica.porEstado,
        );
      }
      // Reemplaza los objetos inmutables por los totales actualizados.
      for (int i = 0; i < porFecha.length; i++) {
        porFecha[i] = indices[porFecha[i].fecha] ?? porFecha[i];
      }
    }

    final List<int> diasSolucion = <int>[];
    for (final Reporte reporte in filtrados) {
      if (reporte.estado != EstadoReporte.solucionado) continue;
      final DateTime? actualizado = reporte.actualizadoEn;
      if (actualizado == null) continue;
      final int dias = actualizado.difference(reporte.creadoEn).inDays;
      diasSolucion.add(dias < 0 ? 0 : dias);
    }
    final double promedio = diasSolucion.isEmpty
        ? 0
        : diasSolucion.reduce((int a, int b) => a + b) / diasSolucion.length;

    return EstadisticasReportes._(
      total: filtrados.length,
      porEstado: porEstado,
      porFecha: porFecha,
      agrupadoPorMes: agrupadoPorMes,
      promedioDiasSolucion: promedio,
    );
  }

  static DateTime? _fechaMinima(List<Reporte> reportes) {
    if (reportes.isEmpty) return null;
    DateTime minima = reportes.first.creadoEn;
    for (final Reporte reporte in reportes) {
      if (reporte.creadoEn.isBefore(minima)) minima = reporte.creadoEn;
    }
    return DateTime(minima.year, minima.month, minima.day);
  }

  static DateTime? _fechaMaxima(List<Reporte> reportes) {
    if (reportes.isEmpty) return null;
    DateTime maxima = reportes.first.creadoEn;
    for (final Reporte reporte in reportes) {
      if (reporte.creadoEn.isAfter(maxima)) maxima = reporte.creadoEn;
    }
    return DateTime(maxima.year, maxima.month, maxima.day);
  }
}
