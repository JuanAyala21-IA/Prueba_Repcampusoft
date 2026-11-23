import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/features/notificaciones/domain/notificacion.dart';

void main() {
  group('Notificacion.corregirTexto', () {
    test('corrige «dano» y «danos» sin tilde', () {
      expect(
        Notificacion.corregirTexto('Nuevo reporte de dano'),
        'Nuevo reporte de daño',
      );
      expect(
        Notificacion.corregirTexto('Reportes de danos'),
        'Reportes de daños',
      );
      expect(Notificacion.corregirTexto('Dano en el aula'), 'Daño en el aula');
    });

    test('no altera palabras correctas como «dañado» o «dañar»', () {
      expect(
        Notificacion.corregirTexto('El equipo dañado sigue igual'),
        'El equipo dañado sigue igual',
      );
      expect(
        Notificacion.corregirTexto('Se debe dañar el muro'),
        'Se debe dañar el muro',
      );
    });

    test('deja intacto el texto que ya está correcto', () {
      expect(
        Notificacion.corregirTexto('Nuevo reporte de daño'),
        'Nuevo reporte de daño',
      );
      expect(
        Notificacion.corregirTexto('Reporte solucionado'),
        'Reporte solucionado',
      );
    });
  });
}
