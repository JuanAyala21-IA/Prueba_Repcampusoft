import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/core/constants/catalogo_edificios.dart';
import 'package:repcampusoft/core/constants/catalogo_espacios.dart';
import 'package:repcampusoft/core/constants/catalogo_tipos_dano.dart';

void main() {
  group('CatalogoEdificios', () {
    test('incluye los edificios A–E y CAR', () {
      expect(CatalogoEdificios.valores, [
        'Edificio A',
        'Edificio B',
        'Edificio C',
        'Edificio D',
        'Edificio E',
        'CAR',
      ]);
    });

    test('salas de cómputo y cafeterías usan sus edificios permitidos', () {
      expect(CatalogoEdificios.salasComputo, ['Edificio A', 'Edificio B']);
      expect(CatalogoEdificios.cafeterias, [
        'Edificio A',
        'Edificio C',
        'Edificio E',
      ]);
    });
  });

  group('CatalogoEspacios.pisosPara', () {
    test('los edificios A y B tienen 6 pisos y no ofrecen sótano', () {
      for (final edificio in [CatalogoEdificios.a, CatalogoEdificios.b]) {
        final pisos = CatalogoEspacios.pisosPara(edificio);
        expect(pisos, hasLength(6));
        expect(pisos.first, 'Piso 1');
        expect(pisos.last, 'Piso 6');
        expect(pisos, isNot(contains('Sótano')));
      }
    });

    test('los edificios C, D, E y CAR tienen 4 pisos', () {
      for (final edificio in [
        CatalogoEdificios.c,
        CatalogoEdificios.d,
        CatalogoEdificios.e,
        CatalogoEdificios.car,
      ]) {
        final pisos = CatalogoEspacios.pisosPara(edificio);
        expect(pisos, hasLength(4));
        expect(pisos.last, 'Piso 4');
        expect(pisos, isNot(contains('Sótano')));
      }
    });

    test('sin edificio no se ofrecen pisos', () {
      expect(CatalogoEspacios.pisosPara(null), isEmpty);
    });
  });

  test('baños solo ofrecen Hombre y Mujer', () {
    expect(CatalogoEspacios.generosBano, ['Hombre', 'Mujer']);
  });

  test('zonas exteriores solo ofrecen jardines, sendero y otra', () {
    expect(CatalogoEspacios.zonasExteriores, [
      'Jardines',
      'Sendero peatonal',
      'Otra',
    ]);
  });

  test('sala de cómputo solo existe en el piso 3', () {
    expect(CatalogoEspacios.pisosSalaComputo, ['Piso 3']);
  });

  test('los tramos de escaleras dependen de los pisos del edificio', () {
    expect(CatalogoEspacios.tramosEscalerasPara(CatalogoEdificios.a), [
      'Piso 1 a 2',
      'Piso 2 a 3',
      'Piso 3 a 4',
      'Piso 4 a 5',
      'Piso 5 a 6',
    ]);
    expect(CatalogoEspacios.tramosEscalerasPara(CatalogoEdificios.c), [
      'Piso 1 a 2',
      'Piso 2 a 3',
      'Piso 3 a 4',
    ]);
    expect(CatalogoEspacios.tramosEscalerasPara(null), isEmpty);
  });

  test('el acceso / portería no se ofrece como opción nueva', () {
    expect(TipoEspacio.acceso.seleccionable, isFalse);
    expect(
      TipoEspacio.values.where((tipo) => tipo.seleccionable),
      isNot(contains(TipoEspacio.acceso)),
    );
  });

  test('laboratorio y sala de cómputo son tipos distintos', () {
    expect(TipoEspacio.laboratorio, isNot(TipoEspacio.salaComputo));
    expect(TipoEspacio.salaComputo.etiqueta, 'Sala de cómputo');
    expect(TipoEspacio.laboratorio.etiqueta, 'Laboratorio');
  });

  test('zona exterior ya no ofrece cancha deportiva como daño', () {
    expect(
      CatalogoTiposDano.para(TipoEspacio.zonaExterior),
      isNot(contains('Cancha deportiva')),
    );
  });

  test('parqueadero ya no ofrece barrera / portón como daño', () {
    expect(
      CatalogoTiposDano.para(TipoEspacio.parqueadero),
      isNot(contains('Barrera / portón')),
    );
  });
}
