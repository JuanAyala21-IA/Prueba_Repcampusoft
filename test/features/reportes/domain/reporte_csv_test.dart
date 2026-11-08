import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/core/constants/catalogo_espacios.dart';
import 'package:repcampusoft/core/theme/estado_reporte_style.dart';
import 'package:repcampusoft/features/reportes/domain/reporte.dart';
import 'package:repcampusoft/features/reportes/domain/reporte_csv.dart';

void main() {
  Reporte reporte({
    required String id,
    required EstadoReporte estado,
    required DateTime creadoEn,
    DateTime? actualizadoEn,
    String descripcion = 'Descripción normal',
    String? observacionAdmin,
    String? encargadoNombre,
    String? asignadoNombre,
    bool tieneFoto = false,
    bool tieneEvidencia = false,
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
      descripcion: descripcion,
      estado: estado,
      tieneFoto: tieneFoto,
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn,
      observacionAdmin: observacionAdmin,
      encargadoNombre: encargadoNombre,
      asignadoNombre: asignadoNombre,
      tieneEvidenciaSolucion: tieneEvidencia,
    );
  }

  group('generarCsvReportes', () {
    test('incluye BOM, encabezados y todos los estados', () {
      final ahora = DateTime(2026, 11, 7, 10, 30);
      final reportes = [
        reporte(
          id: 'r-pendiente',
          estado: EstadoReporte.pendiente,
          creadoEn: ahora.subtract(const Duration(days: 2)),
        ),
        reporte(
          id: 'r-revision',
          estado: EstadoReporte.enRevision,
          creadoEn: ahora.subtract(const Duration(days: 3)),
        ),
        reporte(
          id: 'r-proceso',
          estado: EstadoReporte.enProceso,
          creadoEn: ahora.subtract(const Duration(days: 4)),
        ),
        reporte(
          id: 'r-solucionado',
          estado: EstadoReporte.solucionado,
          creadoEn: ahora.subtract(const Duration(days: 5)),
          actualizadoEn: ahora.subtract(const Duration(days: 1)),
          encargadoNombre: 'Carlos Mantenimiento',
          tieneEvidencia: true,
        ),
      ];

      final csv = generarCsvReportes(reportes, ahora: ahora);

      expect(csv.startsWith('\uFEFF'), isTrue);
      final lineas = csv.substring(1).split('\r\n');
      expect(lineas.first, encabezadosCsvReportes.join(separadorCsvReportes));
      // 4 reportes + encabezado + salto final vacío.
      expect(lineas.length, 6);

      for (final estado in EstadoReporte.values) {
        expect(csv.contains(estado.nombre), isTrue, reason: estado.nombre);
      }
      expect(csv.contains('r-pendiente'), isTrue);
      expect(csv.contains('r-solucionado'), isTrue);
      expect(csv.contains('Carlos Mantenimiento'), isTrue);
      expect(csv.contains('Sí'), isTrue);
    });

    test('ordena del más reciente al más antiguo', () {
      final ahora = DateTime(2026, 11, 7, 10, 30);
      final csv = generarCsvReportes([
        reporte(
          id: 'antiguo',
          estado: EstadoReporte.pendiente,
          creadoEn: ahora.subtract(const Duration(days: 10)),
        ),
        reporte(
          id: 'reciente',
          estado: EstadoReporte.pendiente,
          creadoEn: ahora.subtract(const Duration(days: 1)),
        ),
      ], ahora: ahora);

      final lineas = csv.substring(1).split('\r\n');
      expect(lineas[1].contains('reciente'), isTrue);
      expect(lineas[2].contains('antiguo'), isTrue);
    });

    test('formatea fechas y calcula días de creación y solución', () {
      final ahora = DateTime(2026, 11, 7, 10, 30);
      final csv = generarCsvReportes([
        reporte(
          id: 'r1',
          estado: EstadoReporte.solucionado,
          creadoEn: DateTime(2026, 11, 1, 8, 15),
          actualizadoEn: DateTime(2026, 11, 4, 16, 45),
        ),
      ], ahora: ahora);

      final fila = csv
          .substring(1)
          .split('\r\n')[1]
          .split(separadorCsvReportes);
      // Índices según encabezadosCsvReportes.
      expect(fila[1], '01/11/2026 08:15');
      expect(fila[2], '04/11/2026 16:45');
      expect(fila[22], '6'); // Días desde la creación.
      expect(fila[23], '3'); // Días hasta la solución.
    });

    test('escapa comillas, separador y saltos de línea', () {
      final csv = generarCsvReportes([
        reporte(
          id: 'r-escape',
          estado: EstadoReporte.pendiente,
          creadoEn: DateTime(2026, 11, 7, 9),
          descripcion: 'Daño; "grave"\nrequiere revisión',
        ),
      ], ahora: DateTime(2026, 11, 7, 10));

      expect(csv.contains('"Daño; ""grave""\nrequiere revisión"'), isTrue);
    });

    test('neutraliza fórmulas de Excel en textos del usuario', () {
      final csv = generarCsvReportes([
        reporte(
          id: 'r-formula',
          estado: EstadoReporte.pendiente,
          creadoEn: DateTime(2026, 11, 7, 9),
          descripcion: '=HYPERLINK("http://sitio")',
        ),
      ], ahora: DateTime(2026, 11, 7, 10));

      expect(csv.contains("'=HYPERLINK"), isTrue);
    });

    test('sin reportes devuelve solo el encabezado', () {
      final csv = generarCsvReportes([], ahora: DateTime(2026, 11, 7));
      final lineas = csv.substring(1).split('\r\n');
      expect(lineas.length, 2);
      expect(lineas.first, encabezadosCsvReportes.join(separadorCsvReportes));
      expect(lineas.last, isEmpty);
    });
  });

  test('nombreArchivoCsvReportes usa fecha y hora con dos dígitos', () {
    expect(
      nombreArchivoCsvReportes(DateTime(2026, 1, 5, 7, 3)),
      'reportes_repcampusoft_2026-01-05_0703',
    );
  });
}
