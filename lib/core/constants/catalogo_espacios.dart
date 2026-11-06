import 'catalogo_edificios.dart';

/// Tipos de espacio donde puede ocurrir un reporte (RF-11).
///
/// El valor [slug] es el que se persiste en Firestore (sin tildes); [etiqueta]
/// es el texto que ve el usuario. El formulario de reportes cambia sus campos
/// según el tipo seleccionado.
enum TipoEspacio {
  aula('aula', 'Aula / salón'),
  laboratorio('laboratorio', 'Laboratorio'),
  salaComputo('sala_computo', 'Sala de cómputo'),
  bano('bano', 'Baño'),
  pasillo('pasillo', 'Pasillo / corredor'),
  oficina('oficina', 'Oficina / dependencia'),
  auditorio('auditorio', 'Auditorio / sala'),
  biblioteca('biblioteca', 'Biblioteca'),
  cafeteria('cafeteria', 'Cafetería / zona de comidas'),
  escaleras('escaleras', 'Escaleras'),
  ascensor('ascensor', 'Ascensor'),
  zonaExterior('zona_exterior', 'Zona exterior / campus abierto'),
  parqueadero('parqueadero', 'Parqueadero CAR'),
  // Se conserva para interpretar reportes antiguos, pero ya no se ofrece en
  // el formulario (ver [seleccionable]).
  acceso('acceso', 'Acceso / portería'),
  otro('otro', 'Otro espacio');

  const TipoEspacio(this.slug, this.etiqueta);

  /// Identificador estable en Firestore (`reports/{id}.tipoUbicacion`).
  final String slug;

  /// Texto visible en el formulario y en el detalle.
  final String etiqueta;

  /// Opciones que se muestran al crear un reporte nuevo.
  bool get seleccionable => this != TipoEspacio.acceso;

  /// Tipos que están dentro de un edificio y por tanto piden edificio.
  bool get requiereEdificio =>
      this == TipoEspacio.aula ||
      this == TipoEspacio.laboratorio ||
      this == TipoEspacio.salaComputo ||
      this == TipoEspacio.bano ||
      this == TipoEspacio.pasillo ||
      this == TipoEspacio.oficina ||
      this == TipoEspacio.cafeteria ||
      this == TipoEspacio.escaleras ||
      this == TipoEspacio.ascensor;

  /// Tipos que piden un piso "normal". Escaleras y ascensor usan su propio
  /// selector (tramo / piso-cabina).
  bool get requierePiso =>
      this == TipoEspacio.aula ||
      this == TipoEspacio.laboratorio ||
      this == TipoEspacio.salaComputo ||
      this == TipoEspacio.bano ||
      this == TipoEspacio.pasillo ||
      this == TipoEspacio.oficina;

  /// El formulario oculta la referencia donde no aporta a la ubicación.
  bool get muestraReferencia => this != TipoEspacio.cafeteria;

  /// En zonas exteriores la referencia es obligatoria para poder ubicar el
  /// daño; en el resto es opcional.
  bool get referenciaObligatoria => this == TipoEspacio.zonaExterior;

  /// Recupera un tipo desde el slug persistido. Devuelve `null` si el valor no
  /// existe (por ejemplo, un documento antiguo sin `tipoUbicacion`).
  static TipoEspacio? desdeSlug(String? slug) {
    for (final tipo in values) {
      if (tipo.slug == slug) return tipo;
    }
    return null;
  }
}

/// Catálogos dependientes del tipo de espacio (RF-11).
abstract final class CatalogoEspacios {
  /// Pisos de los edificios A y B (6 niveles).
  static const List<String> _pisosSeisNiveles = [
    'Piso 1',
    'Piso 2',
    'Piso 3',
    'Piso 4',
    'Piso 5',
    'Piso 6',
  ];

  /// Pisos de los edificios C, D, E y CAR (4 niveles).
  static const List<String> _pisosCuatroNiveles = [
    'Piso 1',
    'Piso 2',
    'Piso 3',
    'Piso 4',
  ];

  /// Pisos disponibles según el edificio elegido.
  static List<String> pisosPara(String? edificio) {
    if (edificio == CatalogoEdificios.a || edificio == CatalogoEdificios.b) {
      return _pisosSeisNiveles;
    }
    if (edificio == CatalogoEdificios.c ||
        edificio == CatalogoEdificios.d ||
        edificio == CatalogoEdificios.e ||
        edificio == CatalogoEdificios.car) {
      return _pisosCuatroNiveles;
    }
    return const [];
  }

  /// Las salas de cómputo solo existen en el piso 3 de los edificios A y B.
  static const List<String> pisosSalaComputo = ['Piso 3'];

  static const List<String> ascensores = ['Ascensor 1', 'Ascensor 2', 'Único'];

  static const List<String> generosBano = ['Hombre', 'Mujer'];

  /// Tramos según los pisos del edificio elegido.
  static List<String> tramosEscalerasPara(String? edificio) {
    final totalPisos = pisosPara(edificio).length;
    return [
      for (var piso = 1; piso < totalPisos; piso++) 'Piso $piso a ${piso + 1}',
    ];
  }

  /// Pisos del ascensor según el edificio elegido.
  static List<String> pisosAscensorPara(String? edificio) {
    return [...pisosPara(edificio), 'Cabina', 'No aplica'];
  }

  static const List<String> zonasExteriores = [
    'Jardines',
    'Sendero peatonal',
    'Otra',
  ];
}
