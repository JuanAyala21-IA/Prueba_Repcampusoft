/// Rangos de fecha usados por los filtros de reportes y las estadísticas.
///
/// Las fechas se normalizan al inicio del día (00:00) y el límite superior es
/// inclusivo, de modo que un reporte del mismo día del rango siempre entra.
enum PresetRangoFecha {
  todo,
  hoy,
  ultimos7Dias,
  esteMes,
  esteAnio,
  personalizado,
}

class RangoFechas {
  const RangoFechas._({
    required this.desde,
    required this.hasta,
    required this.preset,
  });

  /// Primer día incluido (00:00) o `null` si no hay límite.
  final DateTime? desde;

  /// Último día incluido (00:00) o `null` si no hay límite.
  final DateTime? hasta;

  final PresetRangoFecha preset;

  const RangoFechas.todo()
    : desde = null,
      hasta = null,
      preset = PresetRangoFecha.todo;

  factory RangoFechas.hoy([DateTime? ahora]) {
    final DateTime hoy = _soloFecha(ahora ?? DateTime.now());
    return RangoFechas._(desde: hoy, hasta: hoy, preset: PresetRangoFecha.hoy);
  }

  /// Hoy y los seis días anteriores (7 días en total).
  factory RangoFechas.ultimos7Dias([DateTime? ahora]) {
    final DateTime hoy = _soloFecha(ahora ?? DateTime.now());
    return RangoFechas._(
      desde: hoy.subtract(const Duration(days: 6)),
      hasta: hoy,
      preset: PresetRangoFecha.ultimos7Dias,
    );
  }

  factory RangoFechas.esteMes([DateTime? ahora]) {
    final DateTime hoy = _soloFecha(ahora ?? DateTime.now());
    return RangoFechas._(
      desde: DateTime(hoy.year, hoy.month),
      hasta: hoy,
      preset: PresetRangoFecha.esteMes,
    );
  }

  factory RangoFechas.esteAnio([DateTime? ahora]) {
    final DateTime hoy = _soloFecha(ahora ?? DateTime.now());
    return RangoFechas._(
      desde: DateTime(hoy.year),
      hasta: hoy,
      preset: PresetRangoFecha.esteAnio,
    );
  }

  /// Rango elegido en el calendario. Si vienen invertidas, se ordenan.
  factory RangoFechas.personalizado(DateTime desde, DateTime hasta) {
    DateTime inicio = _soloFecha(desde);
    DateTime fin = _soloFecha(hasta);
    if (fin.isBefore(inicio)) {
      final DateTime temporal = inicio;
      inicio = fin;
      fin = temporal;
    }
    return RangoFechas._(
      desde: inicio,
      hasta: fin,
      preset: PresetRangoFecha.personalizado,
    );
  }

  bool get esTodo => desde == null && hasta == null;

  /// Indica si [fecha] cae dentro del rango (comparando solo el día).
  bool contiene(DateTime fecha) {
    final DateTime dia = _soloFecha(fecha);
    if (desde != null && dia.isBefore(desde!)) return false;
    if (hasta != null && dia.isAfter(hasta!)) return false;
    return true;
  }

  /// Texto corto para chips: "Hoy", "Este mes", "01/11 - 08/11", etc.
  String get etiqueta {
    return switch (preset) {
      PresetRangoFecha.todo => 'Todo el tiempo',
      PresetRangoFecha.hoy => 'Hoy',
      PresetRangoFecha.ultimos7Dias => 'Últimos 7 días',
      PresetRangoFecha.esteMes => 'Este mes',
      PresetRangoFecha.esteAnio => 'Este año',
      PresetRangoFecha.personalizado =>
        '${_fechaCorta(desde!)} - ${_fechaCorta(hasta!)}',
    };
  }

  /// Descripción más explícita para encabezados y exportación.
  String get descripcion {
    if (esTodo) return 'Todo el tiempo';
    return '${_fechaCompleta(desde!)} al ${_fechaCompleta(hasta!)}';
  }

  /// Parámetros de URL para conservar el rango al abrir la exportación.
  Map<String, String> get parametros {
    if (esTodo) return const <String, String>{};
    return <String, String>{
      'desde': desde!.toIso8601String(),
      'hasta': hasta!.toIso8601String(),
    };
  }

  /// Reconstruye un rango desde los parámetros de la ruta. Si faltan o son
  /// inválidos, devuelve [RangoFechas.todo].
  static RangoFechas desdeParametros(Map<String, String> parametros) {
    final DateTime? desde = DateTime.tryParse(parametros['desde'] ?? '');
    final DateTime? hasta = DateTime.tryParse(parametros['hasta'] ?? '');
    if (desde == null || hasta == null) return const RangoFechas.todo();
    return RangoFechas.personalizado(desde, hasta);
  }

  @override
  bool operator ==(Object other) {
    return other is RangoFechas &&
        other.preset == preset &&
        other.desde == desde &&
        other.hasta == hasta;
  }

  @override
  int get hashCode => Object.hash(preset, desde, hasta);
}

DateTime _soloFecha(DateTime fecha) =>
    DateTime(fecha.year, fecha.month, fecha.day);

String _fechaCorta(DateTime fecha) {
  String dos(int valor) => valor.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)}';
}

String _fechaCompleta(DateTime fecha) {
  String dos(int valor) => valor.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
}
