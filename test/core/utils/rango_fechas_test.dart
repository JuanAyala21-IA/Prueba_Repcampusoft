import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/core/theme/estado_reporte_style.dart';
import 'package:repcampusoft/core/utils/rango_fechas.dart';

void main() {
  final DateTime ahora = DateTime(2026, 11, 8, 15, 30);

  group('RangoFechas', () {
    test('todo contiene cualquier fecha', () {
      const RangoFechas rango = RangoFechas.todo();
      expect(rango.esTodo, isTrue);
      expect(rango.contiene(DateTime(2020, 1, 1)), isTrue);
      expect(rango.contiene(DateTime(2030, 12, 31)), isTrue);
      expect(rango.etiqueta, 'Todo el tiempo');
    });

    test('hoy solo contiene el día actual', () {
      final RangoFechas rango = RangoFechas.hoy(ahora);
      expect(rango.contiene(DateTime(2026, 11, 8, 0, 1)), isTrue);
      expect(rango.contiene(DateTime(2026, 11, 8, 23, 59)), isTrue);
      expect(rango.contiene(DateTime(2026, 11, 7, 23, 59)), isFalse);
      expect(rango.contiene(DateTime(2026, 11, 9)), isFalse);
    });

    test('últimos 7 días incluye hoy y los seis anteriores', () {
      final RangoFechas rango = RangoFechas.ultimos7Dias(ahora);
      expect(rango.contiene(DateTime(2026, 11, 2)), isTrue);
      expect(rango.contiene(DateTime(2026, 11, 1)), isFalse);
      expect(rango.contiene(DateTime(2026, 11, 8)), isTrue);
    });

    test('este mes y este año respetan sus límites', () {
      final RangoFechas mes = RangoFechas.esteMes(ahora);
      expect(mes.contiene(DateTime(2026, 11, 1)), isTrue);
      expect(mes.contiene(DateTime(2026, 10, 31)), isFalse);

      final RangoFechas anio = RangoFechas.esteAnio(ahora);
      expect(anio.contiene(DateTime(2026, 1, 1)), isTrue);
      expect(anio.contiene(DateTime(2025, 12, 31)), isFalse);
    });

    test('personalizado ordena fechas y el límite final es inclusivo', () {
      final RangoFechas rango = RangoFechas.personalizado(
        DateTime(2026, 11, 8),
        DateTime(2026, 11, 1),
      );
      expect(rango.desde, DateTime(2026, 11, 1));
      expect(rango.hasta, DateTime(2026, 11, 8));
      expect(rango.contiene(DateTime(2026, 11, 1, 23, 59)), isTrue);
      expect(rango.contiene(DateTime(2026, 11, 8, 23, 59)), isTrue);
      expect(rango.contiene(DateTime(2026, 10, 31)), isFalse);
      expect(rango.contiene(DateTime(2026, 11, 9)), isFalse);
    });

    test('serializa y reconstruye el rango desde parámetros', () {
      final RangoFechas original = RangoFechas.personalizado(
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 8),
      );
      final RangoFechas reconstruido = RangoFechas.desdeParametros(
        original.parametros,
      );
      expect(reconstruido, original);
      expect(
        RangoFechas.desdeParametros(const <String, String>{}).esTodo,
        isTrue,
      );
    });
  });

  test('EstadoReporte sigue exponiendo los cinco estados del CSV', () {
    expect(EstadoReporte.values.length, 5);
  });
}
