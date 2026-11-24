import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/core/utils/validators.dart';

void main() {
  group('Validators.nombre', () {
    test('acepta letras, tildes, ñ, espacios, guion y apóstrofo', () {
      expect(Validators.nombre('Juan José Ayala'), isNull);
      expect(Validators.nombre('María-José O\'Connor'), isNull);
      expect(Validators.nombre('Ñandú Pérez'), isNull);
    });

    test('rechaza números, símbolos y vacío', () {
      expect(Validators.nombre('Juan 123'), isNotNull);
      expect(Validators.nombre('Ana2'), isNotNull);
      expect(Validators.nombre('correo@uts.edu.co'), isNotNull);
      expect(Validators.nombre(''), 'Este campo es obligatorio');
      expect(Validators.nombre(null), 'Este campo es obligatorio');
    });
  });

  group('Validators.telefono', () {
    test('acepta vacío (opcional) y exactamente 10 dígitos', () {
      expect(Validators.telefono(''), isNull);
      expect(Validators.telefono(null), isNull);
      expect(Validators.telefono('3001234567'), isNull);
    });

    test('rechaza menos de 10, más de 10 o con símbolos', () {
      expect(Validators.telefono('300123456'), isNotNull);
      expect(Validators.telefono('30012345678'), isNotNull);
      expect(Validators.telefono('+57 300 123 4567'), isNotNull);
      expect(Validators.telefono('300-123-4567'), isNotNull);
    });
  });

  group('Validators.textoReporte', () {
    test('acepta letras, tildes y puntuación básica', () {
      expect(Validators.textoReporte('Grieta en la pared.'), isNull);
      expect(Validators.textoReporte('¿Dónde está la banca?'), isNull);
      expect(
        Validators.textoReporte('Frente al edificio (lado norte)'),
        isNull,
      );
      expect(Validators.textoReporte('María\'s office'), isNull);
    });

    test('rechaza números', () {
      expect(Validators.textoReporte('Salón 305'), 'No se permiten números');
      expect(Validators.textoReporte('abc123'), 'No se permiten números');
    });

    test('rechaza símbolos no permitidos', () {
      expect(Validators.textoReporte('Mesa @ rota'), isNotNull);
      expect(Validators.textoReporte('Daño # grande'), isNotNull);
    });

    test('respeta si el campo es obligatorio u opcional', () {
      expect(Validators.textoReporte(''), isNull);
      expect(
        Validators.textoReporte('', obligatorio: true),
        'Campo obligatorio',
      );
    });
  });
}
