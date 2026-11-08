import 'reporte.dart';

/// Separador usado en el CSV. Se usa `;` para que Excel en español (Colombia)
/// abra el archivo directamente en columnas al hacer doble clic.
const String separadorCsvReportes = ';';

/// Encabezados del CSV de reportes, en el mismo orden en que se escriben las
/// columnas. Se exponen para documentación y pruebas.
const List<String> encabezadosCsvReportes = <String>[
  'ID del reporte',
  'Fecha de creación',
  'Última actualización',
  'Estado',
  'Tipo de daño',
  'Tipo de ubicación',
  'Edificio',
  'Piso',
  'Espacio',
  'Referencia',
  'Ubicación completa',
  'Descripción',
  'Correo del autor',
  'UID del autor',
  'Tiene foto del daño',
  'Asignado a',
  'UID del asignado',
  'Fecha de asignación',
  'Solucionado por',
  'UID de quien solucionó',
  'Tiene evidencia de solución',
  'Observación de gestión',
  'Días desde la creación',
  'Días hasta la solución',
];

/// Genera el contenido CSV (UTF-8 con BOM) con **todos** los reportes.
///
/// - Incluye todos los estados: Pendiente, En revisión, En proceso y
///   Solucionado.
/// - Ordena del más reciente al más antiguo por fecha de creación.
/// - Escapa comillas, separadores y saltos de línea según RFC 4180.
/// - Usa fechas locales en formato `dd/MM/yyyy HH:mm`.
///
/// [ahora] permite fijar el instante de cálculo de los días transcurridos en
/// las pruebas; en producción se usa la fecha actual.
String generarCsvReportes(List<Reporte> reportes, {DateTime? ahora}) {
  final DateTime referencia = ahora ?? DateTime.now();
  final List<Reporte> ordenados = List<Reporte>.of(reportes)
    ..sort((Reporte a, Reporte b) => b.creadoEn.compareTo(a.creadoEn));

  final StringBuffer buffer = StringBuffer()
    ..write('\uFEFF')
    ..write(encabezadosCsvReportes.map(_campoCsv).join(separadorCsvReportes))
    ..write('\r\n');

  for (final Reporte reporte in ordenados) {
    final String? fechaSolucion = reporte.estado.valorFirestore == 'Solucionado'
        ? _fecha(reporte.actualizadoEn)
        : null;
    final List<String> campos = <String>[
      reporte.reporteId,
      _fecha(reporte.creadoEn),
      _fecha(reporte.actualizadoEn),
      reporte.estado.nombre,
      reporte.tipoDano,
      reporte.tipoUbicacion.etiqueta,
      reporte.edificio ?? '',
      reporte.piso ?? '',
      reporte.espacio,
      reporte.referencia ?? '',
      reporte.ubicacionTexto,
      reporte.descripcion,
      reporte.correoAutor,
      reporte.uid,
      _siNo(reporte.tieneFoto),
      reporte.asignadoNombre ?? '',
      reporte.asignadoA ?? '',
      _fecha(reporte.asignadoEn),
      reporte.encargadoNombre ?? '',
      reporte.encargadoUid ?? '',
      _siNo(reporte.tieneEvidenciaSolucion),
      reporte.observacionAdmin ?? '',
      _diasEntre(reporte.creadoEn, referencia).toString(),
      fechaSolucion == null
          ? ''
          : _diasEntre(reporte.creadoEn, reporte.actualizadoEn!).toString(),
    ];

    buffer
      ..write(campos.map(_campoCsv).join(separadorCsvReportes))
      ..write('\r\n');
  }

  return buffer.toString();
}

/// Nombre sugerido del archivo, sin extensión (el guardador agrega `.csv`).
/// Ejemplo: `reportes_repcampusoft_2026-11-07_1430`.
String nombreArchivoCsvReportes(DateTime fecha) {
  String dosDigitos(int valor) => valor.toString().padLeft(2, '0');
  return 'reportes_repcampusoft_'
      '${fecha.year}-${dosDigitos(fecha.month)}-${dosDigitos(fecha.day)}_'
      '${dosDigitos(fecha.hour)}${dosDigitos(fecha.minute)}';
}

/// Fecha local `dd/MM/yyyy HH:mm`; vacía si el valor es `null`.
String _fecha(DateTime? fecha) {
  if (fecha == null) return '';
  final DateTime local = fecha.toLocal();
  String dosDigitos(int valor) => valor.toString().padLeft(2, '0');
  return '${dosDigitos(local.day)}/${dosDigitos(local.month)}/${local.year} '
      '${dosDigitos(local.hour)}:${dosDigitos(local.minute)}';
}

/// Días completos entre dos fechas (sin contar la hora).
int _diasEntre(DateTime desde, DateTime hasta) {
  final DateTime inicio = DateTime(desde.year, desde.month, desde.day);
  final DateTime fin = DateTime(hasta.year, hasta.month, hasta.day);
  final int dias = fin.difference(inicio).inDays;
  return dias < 0 ? 0 : dias;
}

String _siNo(bool valor) => valor ? 'Sí' : 'No';

/// Aplica las reglas de escape de RFC 4180 solo cuando el campo lo necesita.
///
/// Además neutraliza la inyección de fórmulas en Excel: si un texto generado
/// por el usuario empieza por `=`, `+`, `-`, `@`, tabulador o retorno de carro,
/// se antepone un apóstrofo para que Excel lo trate como texto.
String _campoCsv(String valor) {
  String texto = valor;
  if (texto.isNotEmpty && '=+-@\t\r'.contains(texto[0])) {
    texto = "'$texto";
  }
  final bool necesitaComillas =
      texto.contains(separadorCsvReportes) ||
      texto.contains('"') ||
      texto.contains('\n') ||
      texto.contains('\r') ||
      texto != texto.trim();
  if (!necesitaComillas) return texto;
  return '"${texto.replaceAll('"', '""')}"';
}
