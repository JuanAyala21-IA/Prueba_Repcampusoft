import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/core/theme/estado_reporte_style.dart';

void main() {
  group('EstadoReporte etiquetas', () {
    test('la etiqueta de revisión usa tilde y no caracteres corruptos', () {
      expect(EstadoReporte.enRevision.nombre, 'En revisión');
      for (final EstadoReporte estado in EstadoReporte.values) {
        expect(
          estado.nombre.contains('\uFFFD'),
          isFalse,
          reason: '${estado.name} tiene un carácter de reemplazo',
        );
      }
    });

    test('fromValor acepta el valor ASCII de Firestore', () {
      for (final EstadoReporte estado in EstadoReporte.values) {
        expect(EstadoReporte.fromValor(estado.valorFirestore), estado);
      }
    });

    test('fromValor acepta la etiqueta de UI con tilde', () {
      expect(EstadoReporte.fromValor('En revisión'), EstadoReporte.enRevision);
      expect(EstadoReporte.fromValor('EN REVISIÓN'), EstadoReporte.enRevision);
      expect(
        EstadoReporte.fromValor(' En revision '),
        EstadoReporte.enRevision,
      );
    });

    test('fromValor cae en pendiente para valores desconocidos', () {
      expect(EstadoReporte.fromValor('Desconocido'), EstadoReporte.pendiente);
      expect(EstadoReporte.fromValor(''), EstadoReporte.pendiente);
    });
  });
}
