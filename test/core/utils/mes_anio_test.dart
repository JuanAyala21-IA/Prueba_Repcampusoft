import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/core/utils/mes_anio.dart';

void main() {
  group('MesAnio', () {
    test('deriva mes y año de una fecha', () {
      expect(MesAnio.desde(DateTime(2026, 11, 23)), const MesAnio(2026, 11));
      expect(MesAnio.desde(DateTime(2026, 1, 1)), const MesAnio(2026, 1));
    });

    test('mes actual corresponde al mes corriente', () {
      final MesAnio actual = MesAnio.actual();
      final DateTime hoy = DateTime.now();
      expect(actual.anio, hoy.year);
      expect(actual.mes, hoy.month);
      expect(actual.esActual, isTrue);
    });

    test('contiene solo fechas del mismo mes y año', () {
      const MesAnio octubre = MesAnio(2026, 10);
      expect(octubre.contiene(DateTime(2026, 10, 1)), isTrue);
      expect(octubre.contiene(DateTime(2026, 10, 31)), isTrue);
      expect(octubre.contiene(DateTime(2026, 9, 30)), isFalse);
      expect(octubre.contiene(DateTime(2026, 11, 1)), isFalse);
      expect(octubre.contiene(DateTime(2025, 10, 1)), isFalse);
    });

    test('mes anterior cambia de mes o de año', () {
      expect(const MesAnio(2026, 3).anterior, const MesAnio(2026, 2));
      expect(const MesAnio(2026, 1).anterior, const MesAnio(2025, 12));
    });

    test('etiqueta legible con nombre en español', () {
      expect(const MesAnio(2026, 11).etiqueta, 'Noviembre 2026');
      expect(const MesAnio(2026, 1).etiqueta, 'Enero 2026');
    });

    test('equals y hashCode por mes y año', () {
      const MesAnio a = MesAnio(2026, 5);
      const MesAnio b = MesAnio(2026, 5);
      const MesAnio c = MesAnio(2026, 6);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('ordena de más reciente a más antiguo con compareTo', () {
      const List<MesAnio> desordenada = [
        MesAnio(2026, 6),
        MesAnio(2025, 12),
        MesAnio(2026, 5),
        MesAnio(2026, 1),
      ];
      final List<MesAnio> ordenada = desordenada.toList()
        ..sort((a, b) => b.compareTo(a));
      expect(ordenada, const <MesAnio>[
        MesAnio(2026, 6),
        MesAnio(2026, 5),
        MesAnio(2026, 1),
        MesAnio(2025, 12),
      ]);
    });
  });
}
