import 'reporte.dart';

/// Grupo de reportes que comparten el mismo día.
class GrupoReportesFecha {
  const GrupoReportesFecha({required this.fecha, required this.reportes});

  final DateTime fecha;
  final List<Reporte> reportes;
}

/// Agrupa reportes por día para mostrarlos con encabezados de fecha.
///
/// Por defecto usa `creadoEn` y ordena del más reciente al más antiguo.
/// [fechaDe] permite agrupar por otra fecha (por ejemplo, la asignación).
List<GrupoReportesFecha> agruparReportesPorFecha(
  List<Reporte> reportes, {
  DateTime Function(Reporte)? fechaDe,
  bool descendente = true,
}) {
  final DateTime Function(Reporte) obtenerFecha =
      fechaDe ?? (Reporte reporte) => reporte.creadoEn;
  final List<Reporte> ordenados = List<Reporte>.of(reportes)
    ..sort((Reporte a, Reporte b) {
      final int comparacion = obtenerFecha(a).compareTo(obtenerFecha(b));
      return descendente ? -comparacion : comparacion;
    });

  final List<GrupoReportesFecha> grupos = <GrupoReportesFecha>[];
  for (final Reporte reporte in ordenados) {
    final DateTime fecha = obtenerFecha(reporte);
    final DateTime dia = DateTime(fecha.year, fecha.month, fecha.day);
    if (grupos.isEmpty || grupos.last.fecha != dia) {
      grupos.add(GrupoReportesFecha(fecha: dia, reportes: <Reporte>[reporte]));
    } else {
      grupos.last.reportes.add(reporte);
    }
  }
  return grupos;
}

/// Etiqueta legible para el encabezado de un grupo: Hoy, Ayer o la fecha.
String etiquetaFechaGrupo(DateTime fecha, {DateTime? ahora}) {
  final DateTime referencia = ahora ?? DateTime.now();
  final DateTime hoy = DateTime(
    referencia.year,
    referencia.month,
    referencia.day,
  );
  final DateTime dia = DateTime(fecha.year, fecha.month, fecha.day);
  final int diferencia = hoy.difference(dia).inDays;
  if (diferencia == 0) return 'Hoy';
  if (diferencia == 1) return 'Ayer';
  String dos(int valor) => valor.toString().padLeft(2, '0');
  return '${dos(dia.day)}/${dos(dia.month)}/${dia.year}';
}
