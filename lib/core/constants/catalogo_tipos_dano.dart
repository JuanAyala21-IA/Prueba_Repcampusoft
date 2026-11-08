import 'catalogo_espacios.dart';

/// Catálogo local de tipos de daño (pantalla 8.png), filtrado por el tipo de
/// espacio seleccionado. El dominio usa español.
abstract final class CatalogoTiposDano {
  /// Lista genérica para espacios sin catálogo propio.
  static const List<String> _genericos = [
    'Silla dañada',
    'Lámpara averiada',
    'Puerta dañada',
    'Ventana rota',
    'Aire acondicionado',
    'Techo / pared / piso',
    'Otro daño',
  ];

  static const Map<TipoEspacio, List<String>> _porEspacio = {
    TipoEspacio.aula: [
      'Silla dañada',
      'Mesa / pupitre dañado',
      'Tablero en mal estado',
      'Lámpara averiada',
      'Toma corriente dañada',
      'Puerta dañada',
      'Ventana rota',
      'Aire acondicionado / ventilador',
      'Techo / pared / piso',
      'Otro daño',
    ],
    TipoEspacio.laboratorio: [
      'Equipo de laboratorio dañado',
      'Mesón de trabajo dañado',
      'Silla dañada',
      'Toma corriente / red dañada',
      'Lámpara averiada',
      'Puerta / ventana dañada',
      'Ventilación / extractor',
      'Lavamanos / ducha de emergencia',
      'Techo / pared / piso',
      'Otro daño',
    ],
    TipoEspacio.salaComputo: [
      'Equipo de cómputo dañado',
      'Silla dañada',
      'Mesa / escritorio dañado',
      'Toma corriente / red dañada',
      'Lámpara averiada',
      'Puerta / ventana dañada',
      'Aire acondicionado',
      'Techo / pared / piso',
      'Otro daño',
    ],
    TipoEspacio.bano: [
      'Sanitario dañado',
      'Lavamanos dañado',
      'Grifo / fuga de agua',
      'Dispensador de jabón',
      'Dispensador de papel',
      'Secador de manos',
      'Espejo roto',
      'Puerta / cerradura',
      'División / panel',
      'Lámpara averiada',
      'Techo / pared / piso',
      'Drenaje tapado',
      'Otro daño',
    ],
    TipoEspacio.pasillo: [
      'Lámpara averiada',
      'Techo / pared en mal estado',
      'Piso en mal estado',
      'Puerta dañada',
      'Ventana rota',
      'Toma corriente dañada',
      'Señalización faltante / dañada',
      'Extintor',
      'Otro daño',
    ],
    TipoEspacio.oficina: [
      'Silla dañada',
      'Escritorio dañado',
      'Lámpara averiada',
      'Toma corriente dañada',
      'Puerta / cerradura',
      'Ventana rota',
      'Aire acondicionado',
      'Techo / pared / piso',
      'Otro daño',
    ],
    TipoEspacio.auditorio: [
      'Silla dañada',
      'Tarima / escenario',
      'Lámpara averiada',
      'Equipo de sonido',
      'Proyector',
      'Puerta dañada',
      'Techo / pared / piso',
      'Otro daño',
    ],
    TipoEspacio.biblioteca: [
      'Silla dañada',
      'Mesa dañada',
      'Estantería dañada',
      'Lámpara averiada',
      'Toma corriente dañada',
      'Puerta dañada',
      'Techo / pared / piso',
      'Otro daño',
    ],
    TipoEspacio.cafeteria: [
      'Mesa dañada',
      'Silla dañada',
      'Lámpara averiada',
      'Toma corriente dañada',
      'Techo / pared / piso',
      'Lavamanos / fregadero',
      'Otro daño',
    ],
    TipoEspacio.escaleras: [
      'Pasamanos suelto / dañado',
      'Escalón en mal estado',
      'Lámpara averiada',
      'Techo / pared',
      'Señalización faltante / dañada',
      'Otro daño',
    ],
    TipoEspacio.ascensor: [
      'Puerta del ascensor',
      'Botonera',
      'Iluminación de cabina',
      'Cabina / panel',
      'Señalización',
      'Otro daño',
    ],
    TipoEspacio.zonaExterior: [
      'Banca dañada',
      'Luminaria averiada',
      'Basurero dañado',
      'Zona verde / jardín',
      'Sendero en mal estado',
      'Estructura / techo',
      'Otro daño',
    ],
    TipoEspacio.parqueadero: [
      'Señalización',
      'Luminaria averiada',
      'Superficie en mal estado',
      'Otro daño',
    ],
    TipoEspacio.acceso: [
      'Puerta / portón',
      'Lector / torniquete',
      'Luminaria averiada',
      'Techo / estructura',
      'Señalización',
      'Otro daño',
    ],
    TipoEspacio.otro: _genericos,
  };

  /// Tipos de daño disponibles para [tipo]. Si todavía no se eligió el espacio,
  /// devuelve la lista genérica.
  static List<String> para(TipoEspacio? tipo) {
    if (tipo == null) return _genericos;
    return _porEspacio[tipo] ?? _genericos;
  }

  /// Lista única de todos los tipos de daño del catálogo local.
  ///
  /// Se usa para sembrar el catálogo dinámico en Firestore, donde los tipos
  /// quedan disponibles para todos los sitios.
  static List<String> todos() {
    final List<String> valores = <String>[..._genericos];
    for (final List<String> lista in _porEspacio.values) {
      for (final String valor in lista) {
        if (!valores.contains(valor)) valores.add(valor);
      }
    }
    return valores;
  }
}
