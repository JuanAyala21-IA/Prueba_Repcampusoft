/// Mes y año usados por la bandeja de notificaciones.
///
/// La bandeja muestra únicamente el mes en curso y permite consultar los meses
/// anteriores. Nada se borra de Firestore: este tipo solo describe el periodo
/// que se está visualizando.
class MesAnio implements Comparable<MesAnio> {
  const MesAnio(this.anio, this.mes)
    : assert(mes >= 1 && mes <= 12, 'El mes debe estar entre 1 y 12');

  /// Mes en curso (o el de [ahora] cuando se indica, útil en pruebas).
  factory MesAnio.actual([DateTime? ahora]) {
    final DateTime fecha = ahora ?? DateTime.now();
    return MesAnio(fecha.year, fecha.month);
  }

  factory MesAnio.desde(DateTime fecha) => MesAnio(fecha.year, fecha.month);

  final int anio;
  final int mes;

  static const List<String> _nombresMeses = <String>[
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  /// Etiqueta legible, por ejemplo `Noviembre 2026`.
  String get etiqueta => '${_nombresMeses[mes - 1]} $anio';

  DateTime get inicio => DateTime(anio, mes);

  /// Inicio del mes siguiente (límite exclusivo para consultas por rango).
  DateTime get siguienteInicio =>
      mes == 12 ? DateTime(anio + 1) : DateTime(anio, mes + 1);

  bool get esActual => this == MesAnio.actual();

  /// `true` si [fecha] cae dentro de este mes y año.
  bool contiene(DateTime fecha) => fecha.year == anio && fecha.month == mes;

  /// Mes anterior (diciembre del año previo cuando corresponde).
  MesAnio get anterior =>
      mes == 1 ? MesAnio(anio - 1, 12) : MesAnio(anio, mes - 1);

  @override
  int compareTo(MesAnio other) {
    final int porAnio = anio.compareTo(other.anio);
    return porAnio != 0 ? porAnio : mes.compareTo(other.mes);
  }

  @override
  bool operator ==(Object other) =>
      other is MesAnio && other.anio == anio && other.mes == mes;

  @override
  int get hashCode => Object.hash(anio, mes);

  @override
  String toString() => etiqueta;
}
