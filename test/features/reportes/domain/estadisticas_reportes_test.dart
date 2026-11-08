import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/core/constants/catalogo_espacios.dart';
import 'package:repcampusoft/core/theme/estado_reporte_style.dart';
import 'package:repcampusoft/core/utils/rango_fechas.dart';
import 'package:repcampusoft/features/reportes/domain/estadisticas_reportes.dart';
import 'package:repcampusoft/features/reportes/domain/reporte.dart';

void main() {
  Reporte crear({
    required String id,
    required EstadoReporte estado,
    required DateTime creadoEn,
    DateTime? actualizadoEn,
  }) {
    return Reporte(
      reporteId: id,
      uid: 'uid-$id',
      correoAutor: '$id@uts.edu.co',
      tipoDano: 'Silla dañada',
      tipoUbicacion: TipoEspacio.aula,
      edificio: 'Edificio A',
      piso: 'Piso 2',
      espacio: 'Salón 203',
      descripcion: 'Descripción',
      estado: estado,
      tieneFoto: false,
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn,
    );
  }

  final List<Reporte> reportes = [
    crear(
      id: 'pendiente',
      estado: EstadoReporte.pendiente,
      creadoEn: DateTime(2026, 11, 1, 9),
    ),
    crear(
      id: 'revision',
      estado: EstadoReporte.enRevision,
      creadoEn: DateTime(2026, 11, 2, 9),
    ),
    crear(
      id: 'proceso',
      estado: EstadoReporte.enProceso,
      creadoEn: DateTime(2026, 11, 3, 9),
    ),
    crear(
      id: 'solucionado',
      estado: EstadoReporte.solucionado,
      creadoEn: DateTime(2026, 11, 4, 9),
      actualizadoEn: DateTime(2026, 11, 6, 9),
    ),
    crear(
      id: 'fuera',
      estado: EstadoReporte.pendiente,
      creadoEn: DateTime(2026, 10, 20, 9),
    ),
  ];

  test('calcula totales por estado y solo cuenta el rango', () {
    final EstadisticasReportes stats = EstadisticasReportes.calcular(
      reportes,
      rango: RangoFechas.personalizado(
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 8),
      ),
    );

    expect(stats.total, 4);
    expect(stats.pendientes, 1);
    expect(stats.enRevision, 1);
    expect(stats.enProceso, 1);
    expect(stats.solucionados, 1);
    expect(stats.sinCerrar, 3);
    expect(stats.porcentajeSolucionados, 25);
  });

  test('agrupa por día y rellena los días sin reportes', () {
    final EstadisticasReportes stats = EstadisticasReportes.calcular(
      reportes,
      rango: RangoFechas.personalizado(
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 8),
      ),
    );

    expect(stats.agrupadoPorMes, isFalse);
    expect(stats.porFecha.length, 8);
    expect(stats.porFecha.first.total, 1);
    expect(stats.porFecha[5].total, 0);
    expect(stats.porFecha[7].total, 0);
  });

  test('agrupa por mes cuando el rango supera 90 días', () {
    final EstadisticasReportes stats = EstadisticasReportes.calcular(
      reportes,
      rango: RangoFechas.personalizado(
        DateTime(2026, 1, 1),
        DateTime(2026, 12, 31),
      ),
    );

    expect(stats.agrupadoPorMes, isTrue);
    expect(stats.porFecha.length, 12);
    expect(stats.porFecha.first.etiqueta, '01/2026');
  });

  test('promedia los días hasta la solución', () {
    final EstadisticasReportes stats = EstadisticasReportes.calcular(
      reportes,
      rango: const RangoFechas.todo(),
    );
    expect(stats.promedioDiasSolucion, 2);
  });

  test('con lista vacía devuelve ceros', () {
    final EstadisticasReportes stats = EstadisticasReportes.calcular(
      const <Reporte>[],
      rango: const RangoFechas.todo(),
    );
    expect(stats.total, 0);
    expect(stats.porFecha, isEmpty);
    expect(stats.porcentajeSolucionados, 0);
  });
}
