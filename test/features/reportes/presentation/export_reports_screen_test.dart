import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:repcampusoft/core/constants/catalogo_espacios.dart';
import 'package:repcampusoft/core/routes/app_router.dart';
import 'package:repcampusoft/core/theme/estado_reporte_style.dart';
import 'package:repcampusoft/features/reportes/data/providers/reporte_providers.dart';
import 'package:repcampusoft/features/reportes/data/reporte_csv_saver.dart';
import 'package:repcampusoft/features/reportes/domain/reporte.dart';
import 'package:repcampusoft/features/reportes/domain/reporte_csv.dart';
import 'package:repcampusoft/features/reportes/presentation/export_reports_screen.dart';
import 'package:repcampusoft/shared/widgets/primary_button.dart';

class _FakeReporteCsvSaver implements ReporteCsvSaver {
  _FakeReporteCsvSaver({this.ruta = '/descargas/reportes.csv'});

  final String? ruta;
  String? nombreRecibido;
  String? contenidoRecibido;
  int llamadas = 0;

  @override
  Future<String?> guardar({
    required String nombreArchivo,
    required String contenido,
  }) async {
    llamadas++;
    nombreRecibido = nombreArchivo;
    contenidoRecibido = contenido;
    return ruta;
  }
}

List<Reporte> _crearReportes() {
  final DateTime ahora = DateTime(2026, 11, 7, 10, 30);
  Reporte crear(String id, EstadoReporte estado, int dias) {
    return Reporte(
      reporteId: id,
      uid: 'uid-$id',
      correoAutor: '$id@uts.edu.co',
      tipoDano: 'Silla dañada',
      tipoUbicacion: TipoEspacio.aula,
      edificio: 'Edificio A',
      piso: 'Piso 2',
      espacio: 'Salón 203',
      descripcion: 'Descripción de $id',
      estado: estado,
      tieneFoto: true,
      creadoEn: ahora.subtract(Duration(days: dias)),
      actualizadoEn: estado == EstadoReporte.solucionado
          ? ahora.subtract(const Duration(days: 1))
          : null,
      encargadoNombre: estado == EstadoReporte.solucionado
          ? 'Carlos Mantenimiento'
          : null,
      tieneEvidenciaSolucion: estado == EstadoReporte.solucionado,
    );
  }

  return [
    crear('r-pendiente', EstadoReporte.pendiente, 5),
    crear('r-revision', EstadoReporte.enRevision, 4),
    crear('r-proceso', EstadoReporte.enProceso, 3),
    crear('r-solucionado', EstadoReporte.solucionado, 2),
  ];
}

Widget _crearPantalla({
  required List<Reporte> reportes,
  required _FakeReporteCsvSaver saver,
  String location = AppRoutes.exportarReportes,
}) {
  return ProviderScope(
    overrides: [
      todosLosReportesProvider.overrideWith(
        (ref, filtros) => Stream.value(reportes),
      ),
      reporteCsvSaverProvider.overrideWithValue(saver),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(
            path: AppRoutes.exportarReportes,
            builder: (_, _) => const ExportReportsScreen(),
          ),
        ],
      ),
    ),
  );
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ExportReportsScreen', () {
    testWidgets('muestra el resumen por estado y el total de reportes', (
      tester,
    ) async {
      await tester.pumpWidget(
        _crearPantalla(
          reportes: _crearReportes(),
          saver: _FakeReporteCsvSaver(),
        ),
      );
      await tester.pump();

      expect(find.text('Reportes en CSV'), findsOneWidget);
      expect(find.text('Total: 4'), findsOneWidget);
      expect(find.text('Pendiente: 1'), findsOneWidget);
      expect(find.text('En revisión: 1'), findsOneWidget);
      expect(find.text('En proceso: 1'), findsOneWidget);
      expect(find.text('Solucionado: 1'), findsOneWidget);
    });

    testWidgets('descarga el CSV con todos los reportes y estados', (
      tester,
    ) async {
      final saver = _FakeReporteCsvSaver();
      await tester.pumpWidget(
        _crearPantalla(reportes: _crearReportes(), saver: saver),
      );
      await tester.pump();

      final boton = find.widgetWithText(PrimaryButton, 'Descargar CSV');
      await tester.ensureVisible(boton);
      await tester.pump();
      await tester.tap(boton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(saver.llamadas, 1);
      expect(saver.contenidoRecibido, isNotNull);
      final contenido = saver.contenidoRecibido!;
      expect(contenido.startsWith('\uFEFF'), isTrue);
      expect(
        contenido.contains(encabezadosCsvReportes.join(separadorCsvReportes)),
        isTrue,
      );
      for (final estado in EstadoReporte.values) {
        expect(contenido.contains(estado.nombre), isTrue);
      }
      expect(
        saver.nombreRecibido,
        matches(r'^reportes_repcampusoft_\d{4}-\d{2}-\d{2}_\d{4}$'),
      );
      expect(find.text('CSV guardado con 4 reportes.'), findsOneWidget);
    });

    testWidgets('avisa cuando el usuario cancela el guardado', (tester) async {
      final saver = _FakeReporteCsvSaver(ruta: null);
      await tester.pumpWidget(
        _crearPantalla(reportes: _crearReportes(), saver: saver),
      );
      await tester.pump();

      final boton = find.widgetWithText(PrimaryButton, 'Descargar CSV');
      await tester.ensureVisible(boton);
      await tester.pump();
      await tester.tap(boton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No se guardó el archivo.'), findsOneWidget);
    });

    testWidgets('respeta los filtros de fecha y estado recibidos por URL', (
      tester,
    ) async {
      final saver = _FakeReporteCsvSaver();
      final String location = Uri(
        path: AppRoutes.exportarReportes,
        queryParameters: const <String, String>{
          'desde': '2026-11-01T00:00:00.000',
          'hasta': '2026-11-06T00:00:00.000',
          'estado': 'Solucionado',
        },
      ).toString();

      await tester.pumpWidget(
        _crearPantalla(
          reportes: _crearReportes(),
          saver: saver,
          location: location,
        ),
      );
      await tester.pump();

      expect(find.text('Total: 1'), findsOneWidget);
      expect(find.text('Solucionado: 1'), findsOneWidget);
      expect(find.textContaining('1 de 4 reportes'), findsOneWidget);

      final boton = find.widgetWithText(PrimaryButton, 'Descargar CSV');
      await tester.ensureVisible(boton);
      await tester.pump();
      await tester.tap(boton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(saver.llamadas, 1);
      final contenido = saver.contenidoRecibido!;
      expect(contenido.contains('r-solucionado'), isTrue);
      expect(contenido.contains('r-pendiente'), isFalse);
    });

    testWidgets('deshabilita la descarga cuando no hay reportes', (
      tester,
    ) async {
      await tester.pumpWidget(
        _crearPantalla(reportes: const [], saver: _FakeReporteCsvSaver()),
      );
      await tester.pump();

      expect(find.text('Total: 0'), findsOneWidget);
      expect(
        find.text('No hay reportes con los filtros seleccionados.'),
        findsOneWidget,
      );
      final boton = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'Descargar CSV'),
      );
      expect(boton.onPressed, isNull);
    });
  });
}
