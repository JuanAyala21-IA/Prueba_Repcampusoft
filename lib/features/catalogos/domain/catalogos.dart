import '../../../core/constants/catalogo_edificios.dart';
import '../../../core/constants/catalogo_espacios.dart';
import '../../../core/constants/catalogo_tipos_dano.dart';

/// Convierte un nombre en un identificador estable sin tildes ni espacios.
String slugCatalogo(String texto) {
  const Map<String, String> reemplazos = <String, String>{
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'Á': 'a',
    'É': 'e',
    'Í': 'i',
    'Ó': 'o',
    'Ú': 'u',
    'Ü': 'u',
    'ñ': 'n',
    'Ñ': 'n',
  };
  String resultado = texto.trim().toLowerCase();
  reemplazos.forEach((String con, String sin) {
    resultado = resultado.replaceAll(con, sin);
  });
  resultado = resultado.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return resultado.replaceAll(RegExp(r'^_+|_+$'), '');
}

class EdificioCatalogo {
  const EdificioCatalogo({
    required this.id,
    required this.nombre,
    required this.pisos,
    this.activo = true,
    this.orden = 0,
  });

  final String id;
  final String nombre;
  final List<String> pisos;
  final bool activo;
  final int orden;

  EdificioCatalogo copyWith({
    String? nombre,
    List<String>? pisos,
    bool? activo,
    int? orden,
  }) {
    return EdificioCatalogo(
      id: id,
      nombre: nombre ?? this.nombre,
      pisos: pisos ?? this.pisos,
      activo: activo ?? this.activo,
      orden: orden ?? this.orden,
    );
  }
}

class SitioReporteCatalogo {
  const SitioReporteCatalogo({
    required this.id,
    required this.nombre,
    required this.slug,
    required this.requiereEdificio,
    required this.requierePiso,
    required this.muestraReferencia,
    required this.referenciaObligatoria,
    this.tipoEspecial,
    this.activo = true,
    this.orden = 0,
  });

  final String id;
  final String nombre;
  final String slug;
  final bool requiereEdificio;
  final bool requierePiso;
  final bool muestraReferencia;
  final bool referenciaObligatoria;

  /// Comportamiento especial del formulario: `bano`, `escaleras`, `ascensor`
  /// o `zona_exterior`. `null` para un sitio genérico.
  final String? tipoEspecial;
  final bool activo;
  final int orden;

  /// Tipo base del dominio. Los sitios nuevos usan `otro` para no romper las
  /// reglas de Firestore, que validan los slugs históricos.
  TipoEspacio get tipoBase => TipoEspacio.desdeSlug(slug) ?? TipoEspacio.otro;

  bool get esPersonalizado => TipoEspacio.desdeSlug(slug) == null;

  SitioReporteCatalogo copyWith({
    String? nombre,
    bool? requiereEdificio,
    bool? requierePiso,
    bool? muestraReferencia,
    bool? referenciaObligatoria,
    String? tipoEspecial,
    bool? activo,
    int? orden,
  }) {
    return SitioReporteCatalogo(
      id: id,
      nombre: nombre ?? this.nombre,
      slug: slug,
      requiereEdificio: requiereEdificio ?? this.requiereEdificio,
      requierePiso: requierePiso ?? this.requierePiso,
      muestraReferencia: muestraReferencia ?? this.muestraReferencia,
      referenciaObligatoria:
          referenciaObligatoria ?? this.referenciaObligatoria,
      tipoEspecial: tipoEspecial ?? this.tipoEspecial,
      activo: activo ?? this.activo,
      orden: orden ?? this.orden,
    );
  }
}

class TipoDanoCatalogo {
  const TipoDanoCatalogo({
    required this.id,
    required this.nombre,
    this.activo = true,
    this.orden = 0,
  });

  final String id;
  final String nombre;
  final bool activo;
  final int orden;

  TipoDanoCatalogo copyWith({String? nombre, bool? activo, int? orden}) {
    return TipoDanoCatalogo(
      id: id,
      nombre: nombre ?? this.nombre,
      activo: activo ?? this.activo,
      orden: orden ?? this.orden,
    );
  }
}

class ZonaExteriorCatalogo {
  const ZonaExteriorCatalogo({
    required this.id,
    required this.nombre,
    this.activo = true,
    this.orden = 0,
  });

  final String id;
  final String nombre;
  final bool activo;
  final int orden;

  ZonaExteriorCatalogo copyWith({String? nombre, bool? activo, int? orden}) {
    return ZonaExteriorCatalogo(
      id: id,
      nombre: nombre ?? this.nombre,
      activo: activo ?? this.activo,
      orden: orden ?? this.orden,
    );
  }
}

List<String> _pisos(int cantidad) => <String>[
  for (int i = 1; i <= cantidad; i++) 'Piso $i',
];

List<EdificioCatalogo> edificiosPorDefecto() {
  const Map<String, int> pisosPorEdificio = <String, int>{
    CatalogoEdificios.a: 6,
    CatalogoEdificios.b: 6,
    CatalogoEdificios.c: 4,
    CatalogoEdificios.d: 4,
    CatalogoEdificios.e: 4,
    CatalogoEdificios.car: 4,
  };
  int orden = 0;
  return pisosPorEdificio.entries.map((MapEntry<String, int> item) {
    return EdificioCatalogo(
      id: 'edificio_${slugCatalogo(item.key)}',
      nombre: item.key,
      pisos: _pisos(item.value),
      orden: orden++,
    );
  }).toList();
}

String? _tipoEspecialDe(TipoEspacio tipo) {
  return switch (tipo) {
    TipoEspacio.bano => 'bano',
    TipoEspacio.escaleras => 'escaleras',
    TipoEspacio.ascensor => 'ascensor',
    TipoEspacio.zonaExterior => 'zona_exterior',
    _ => null,
  };
}

List<SitioReporteCatalogo> sitiosPorDefecto() {
  int orden = 0;
  return TipoEspacio.values.where((TipoEspacio tipo) => tipo.seleccionable).map(
    (TipoEspacio tipo) {
      return SitioReporteCatalogo(
        id: tipo.slug,
        nombre: tipo.etiqueta,
        slug: tipo.slug,
        requiereEdificio: tipo.requiereEdificio,
        requierePiso: tipo.requierePiso,
        muestraReferencia: tipo.muestraReferencia,
        referenciaObligatoria: tipo.referenciaObligatoria,
        tipoEspecial: _tipoEspecialDe(tipo),
        orden: orden++,
      );
    },
  ).toList();
}

List<TipoDanoCatalogo> tiposDanoPorDefecto() {
  int orden = 0;
  return CatalogoTiposDano.todos()
      .map(
        (String nombre) => TipoDanoCatalogo(
          id: slugCatalogo(nombre),
          nombre: nombre,
          orden: orden++,
        ),
      )
      .toList();
}

List<ZonaExteriorCatalogo> zonasPorDefecto() {
  int orden = 0;
  return CatalogoEspacios.zonasExteriores
      .map(
        (String nombre) => ZonaExteriorCatalogo(
          id: slugCatalogo(nombre),
          nombre: nombre,
          orden: orden++,
        ),
      )
      .toList();
}
