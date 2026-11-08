import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/core/utils/validators.dart';

void main() {
  group('Validators.correo', () {
    test('descarta vacío', () {
      expect(Validators.correo(null), 'Ingresa tu correo institucional');
      expect(Validators.correo('   '), 'Ingresa tu correo institucional');
    });

    test('descarta mal formato', () {
      expect(Validators.correo('vacio'), 'Correo no válido');
      expect(Validators.correo('a@b'), 'Correo no válido');
      expect(Validators.correo('a b@c.co'), 'Correo no válido');
    });

    test('acepta correo válido', () {
      expect(Validators.correo('csblanco@uts.edu.co'), isNull);
      expect(Validators.correo('juan@correo.uts.edu.co'), isNull);
    });
  });

  group('Validators.requerido', () {
    test('descarta vacío y acepta valor', () {
      expect(Validators.requerido(null), 'Este campo es obligatorio');
      expect(Validators.requerido('  '), 'Este campo es obligatorio');
      expect(Validators.requerido('Ana'), isNull);
    });
  });

  group('Validators.contrasena', () {
    test('descarta vacía y corta', () {
      expect(Validators.contrasena(''), 'Ingresa tu contraseña');
      expect(Validators.contrasena('12345'), 'Mínimo 6 caracteres');
    });

    test('acepta 6+ caracteres', () {
      expect(Validators.contrasena('123456'), isNull);
    });
  });

  group('Validators.confirmarContrasena', () {
    test('valida coincidencia', () {
      expect(
        Validators.confirmarContrasena(campo: 'abc123', valor: ''),
        'Confirma tu contraseña',
      );
      expect(
        Validators.confirmarContrasena(campo: 'abc123', valor: 'xyz789'),
        'Las contraseñas no coinciden',
      );
      expect(
        Validators.confirmarContrasena(campo: 'abc123', valor: 'abc123'),
        isNull,
      );
    });
  });
}
