import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:repcampusoft/core/constants/catalogo_espacios.dart';
import 'package:repcampusoft/core/utils/results.dart';
import 'package:repcampusoft/features/reportes/domain/historial_entry.dart';
import 'package:repcampusoft/features/reportes/domain/reporte.dart';
import 'package:repcampusoft/features/reportes/domain/reporte_repository.dart';
import 'package:repcampusoft/features/reportes/domain/servicio_adjuntar_foto.dart';
import 'package:repcampusoft/features/reportes/presentation/report_damage_screen.dart';
import 'package:repcampusoft/shared/widgets/fields.dart';
import 'package:repcampusoft/shared/widgets/primary_button.dart';

class FakeRepo implements ReporteRepository {
  final Result<String> Function(BorradorReporte)? onCrear;
  final List<BorradorReporte> calledWith = [];

  FakeRepo({this.onCrear});

  @override
  Future<Result<String>> crear(BorradorReporte borrador) async {
    calledWith.add(borrador);
    if (onCrear != null) return onCrear!(borrador);
    return const Success('test-report-id');
  }

  @override
  Stream<List<Reporte>> watchMisReportes() => Stream.value(<Reporte>[]);

  @override
  Stream<Reporte?> watchReporteById(String reportId) => Stream.value(null);

  @override
  Stream<List<HistorialEntry>> watchHistorial(String reportId) =>
      Stream.value(<HistorialEntry>[]);

  @override
  Stream<List<Reporte>> watchTodosLosReportes({
    String? filtroEstado,
    String? filtroEdificio,
  }) => Stream.value(<Reporte>[]);

  @override
  Future<Result<void>> cambiarEstado({
    required String reportId,
    required String estadoNuevo,
    String? observacion,
    String? evidenciaBase64,
  }) async => const Success(null);

  @override
  Future<Result<void>> tomarReporte({required String reportId}) async =>
      const Success(null);
}

class FakeSonda implements SondaConectividad {
  final bool Function()? onHayConexion;

  FakeSonda({this.onHayConexion});

  @override
  Future<bool> hayConexion() async {
    if (onHayConexion != null) return onHayConexion!();
    return true;
  }
}

Widget createTestWidget({
  required ReporteRepository repo,
  required SondaConectividad sonda,
}) {
  return ProviderScope(
    overrides: [
      reporteRepositoryProvider.overrideWith((_) => repo),
      sondaConectividadProvider.overrideWith((_) => sonda),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const ReportDamageScreen()),
          GoRoute(
            path: '/mis-reportes',
            builder: (_, _) => const Scaffold(body: Text('Mis Reportes')),
          ),
        ],
      ),
    ),
  );
}

/// Abre el dropdown en [index] y elige la opción visible [valor].
Future<void> _seleccionar(WidgetTester tester, int index, String valor) async {
  final dropdowns = find.byType(DropdownButtonFormField<String>);
  await tester.ensureVisible(dropdowns.at(index));
  await tester.pumpAndSettle();
  await tester.tap(dropdowns.at(index), warnIfMissed: false);
  await tester.pumpAndSettle();

  // La lista del dropdown se construye de forma perezosa: si la opción no
  // está en pantalla, se desplaza el menú hasta encontrarla.
  if (find.text(valor).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(valor),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }

  final opcion = find.text(valor).last;
  await tester.ensureVisible(opcion);
  await tester.pumpAndSettle();
  await tester.tap(opcion, warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// Escribe en el campo de texto cuya etiqueta es [etiqueta].
Future<void> _escribir(
  WidgetTester tester,
  String etiqueta,
  String texto,
) async {
  final campo = find.descendant(
    of: find.widgetWithText(LabelledField, etiqueta),
    matching: find.byType(TextFormField),
  );
  await tester.ensureVisible(campo);
  await tester.pumpAndSettle();
  await tester.enterText(campo, texto);
  await tester.pumpAndSettle();
}

Future<void> _enviar(WidgetTester tester) async {
  final boton = find.byType(PrimaryButton);
  await tester.ensureVisible(boton);
  await tester.pumpAndSettle();
  await tester.tap(boton, warnIfMissed: false);
  await tester.pumpAndSettle();
}

void main() {
  group('ReportDamageScreen widget tests', () {
    testWidgets('1. Sin ubicación muestra errores y no llama al repo', (
      tester,
    ) async {
      final repo = FakeRepo();
      final sonda = FakeSonda();

      await tester.pumpWidget(createTestWidget(repo: repo, sonda: sonda));
      await tester.pumpAndSettle();

      await _enviar(tester);

      expect(find.text('Campo obligatorio'), findsNWidgets(2));
      expect(repo.calledWith, isEmpty);
    });

    testWidgets('2. Solo con tipo de espacio no llama al repo', (tester) async {
      final repo = FakeRepo();

      await tester.pumpWidget(createTestWidget(repo: repo, sonda: FakeSonda()));
      await tester.pumpAndSettle();

      await _seleccionar(tester, 0, 'Aula / salón');
      await _enviar(tester);

      expect(repo.calledWith, isEmpty);
    });

    testWidgets('3. Inicialmente solo se muestra el selector de espacio', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(repo: FakeRepo(), sonda: FakeSonda()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reportar daños'), findsOneWidget);
      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.text('¿Dónde ocurrió?'), findsOneWidget);
      // Solo el dropdown de tipo de espacio y el campo de descripción.
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('4. Aula: guarda edificio, piso y Salón con prefijo', (
      tester,
    ) async {
      final repo = FakeRepo(onCrear: (_) => const Success('report-123'));

      await tester.pumpWidget(createTestWidget(repo: repo, sonda: FakeSonda()));
      await tester.pumpAndSettle();

      await _seleccionar(tester, 0, 'Aula / salón');
      await _seleccionar(tester, 1, 'Edificio A');
      await _seleccionar(tester, 2, 'Piso 1');
      await _escribir(tester, 'Salón', '101');
      await _escribir(tester, 'Descripción', 'Grieta en pared');
      await _seleccionar(tester, 3, 'Silla dañada');
      await _enviar(tester);

      expect(repo.calledWith.length, 1);
      final borrador = repo.calledWith.first;
      expect(borrador.tipoUbicacion, TipoEspacio.aula);
      expect(borrador.tipoDano, 'Silla dañada');
      expect(borrador.edificio, 'Edificio A');
      expect(borrador.piso, 'Piso 1');
      expect(borrador.espacio, 'Salón 101');
      expect(borrador.referencia, isNull);
      expect(borrador.descripcion, 'Grieta en pared');
      expect(borrador.ubicacionTexto, 'Edificio A · Piso 1 · Salón 101');
      expect(borrador.fotoBase64, isNull);

      // Tras enviar, la app lleva directo a "Tus reportes" en lugar de dejar
      // al usuario en el formulario.
      expect(find.text('Mis Reportes'), findsOneWidget);
      expect(
        find.text('Reporte enviado. Ya aparece en Tus reportes.'),
        findsOneWidget,
      );
      expect(find.byType(ReportDamageScreen), findsNothing);
    });

    testWidgets('5. Baño: no pide salón y guarda el género como espacio', (
      tester,
    ) async {
      final repo = FakeRepo();

      await tester.pumpWidget(createTestWidget(repo: repo, sonda: FakeSonda()));
      await tester.pumpAndSettle();

      await _seleccionar(tester, 0, 'Baño');
      // El formulario de baño no muestra el campo Salón.
      expect(find.text('Salón'), findsNothing);

      await _seleccionar(tester, 0 + 1, 'Edificio A');
      await _seleccionar(tester, 0 + 2, 'Piso 2');
      await _seleccionar(tester, 0 + 3, 'Mujer');
      await _seleccionar(tester, 0 + 4, 'Sanitario dañado');
      await _escribir(tester, 'Descripción', 'Sanitario tapado');
      await _enviar(tester);

      expect(repo.calledWith.length, 1);
      final borrador = repo.calledWith.first;
      expect(borrador.tipoUbicacion, TipoEspacio.bano);
      expect(borrador.espacio, 'Baño de mujeres');
      expect(borrador.edificio, 'Edificio A');
      expect(borrador.piso, 'Piso 2');
      expect(borrador.tipoDano, 'Sanitario dañado');
      expect(borrador.ubicacionTexto, 'Edificio A · Piso 2 · Baño de mujeres');
    });

    testWidgets(
      '6. Zona exterior: sin edificio/piso, con zona y referencia obligatoria',
      (tester) async {
        final repo = FakeRepo();

        await tester.pumpWidget(
          createTestWidget(repo: repo, sonda: FakeSonda()),
        );
        await tester.pumpAndSettle();

        await _seleccionar(tester, 0, 'Zona exterior / campus abierto');
        // No se piden edificio ni piso.
        expect(find.text('Edificio'), findsNothing);
        expect(find.text('Piso'), findsNothing);

        await _seleccionar(tester, 1, 'Jardines');
        await _seleccionar(tester, 2, 'Banca dañada');
        await _escribir(tester, 'Referencia', 'Frente al Edificio B');
        await _escribir(tester, 'Descripción', 'Banca rota');
        await _enviar(tester);

        expect(repo.calledWith.length, 1);
        final borrador = repo.calledWith.first;
        expect(borrador.tipoUbicacion, TipoEspacio.zonaExterior);
        expect(borrador.edificio, isNull);
        expect(borrador.piso, isNull);
        expect(borrador.espacio, 'Jardines');
        expect(borrador.referencia, 'Frente al Edificio B');
        expect(
          borrador.ubicacionTexto,
          'Zona exterior · Jardines · Frente al Edificio B',
        );
      },
    );

    testWidgets('7. Zona exterior sin referencia no envía', (tester) async {
      final repo = FakeRepo();

      await tester.pumpWidget(createTestWidget(repo: repo, sonda: FakeSonda()));
      await tester.pumpAndSettle();

      await _seleccionar(tester, 0, 'Zona exterior / campus abierto');
      await _seleccionar(tester, 1, 'Jardines');
      await _seleccionar(tester, 2, 'Banca dañada');
      await _escribir(tester, 'Descripción', 'Banca rota');
      await _enviar(tester);

      expect(repo.calledWith, isEmpty);
      expect(find.text('Campo obligatorio'), findsOneWidget);
    });

    testWidgets('8a. Baño muestra daños de baño y no de aula', (tester) async {
      await tester.pumpWidget(
        createTestWidget(repo: FakeRepo(), sonda: FakeSonda()),
      );
      await tester.pumpAndSettle();

      await _seleccionar(tester, 0, 'Baño');
      await tester.ensureVisible(
        find.byType(DropdownButtonFormField<String>).at(3),
      );
      await tester.tap(
        find.byType(DropdownButtonFormField<String>).at(3),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('Sanitario dañado'), findsWidgets);
      expect(find.text('Silla dañada'), findsNothing);
    });

    testWidgets('8b. Aula muestra daños de aula y no de baño', (tester) async {
      await tester.pumpWidget(
        createTestWidget(repo: FakeRepo(), sonda: FakeSonda()),
      );
      await tester.pumpAndSettle();

      await _seleccionar(tester, 0, 'Aula / salón');
      await tester.ensureVisible(
        find.byType(DropdownButtonFormField<String>).at(2),
      );
      await tester.tap(
        find.byType(DropdownButtonFormField<String>).at(2),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('Silla dañada'), findsWidgets);
      expect(find.text('Sanitario dañado'), findsNothing);
    });

    testWidgets('9. Repo devuelve Failure: muestra SnackBar y apaga cargando', (
      tester,
    ) async {
      final repo = FakeRepo(onCrear: (_) => const Failure('mensaje de prueba'));

      await tester.pumpWidget(createTestWidget(repo: repo, sonda: FakeSonda()));
      await tester.pumpAndSettle();

      await _seleccionar(tester, 0, 'Aula / salón');
      await _seleccionar(tester, 1, 'Edificio A');
      await _seleccionar(tester, 2, 'Piso 1');
      await _escribir(tester, 'Salón', '101');
      await _escribir(tester, 'Descripción', 'Test failure');
      await _seleccionar(tester, 3, 'Silla dañada');
      await _enviar(tester);

      expect(repo.calledWith.length, 1);
      expect(find.text('mensaje de prueba'), findsOneWidget);

      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.cargando, isFalse);
    });

    testWidgets('10. Sin foto y sin conexión permite enviar', (tester) async {
      final repo = FakeRepo();

      await tester.pumpWidget(
        createTestWidget(
          repo: repo,
          sonda: FakeSonda(onHayConexion: () => false),
        ),
      );
      await tester.pumpAndSettle();

      await _seleccionar(tester, 0, 'Aula / salón');
      await _seleccionar(tester, 1, 'Edificio A');
      await _seleccionar(tester, 2, 'Piso 1');
      await _escribir(tester, 'Salón', '101');
      await _escribir(tester, 'Descripción', 'Test sin conexión');
      await _seleccionar(tester, 3, 'Silla dañada');
      await _enviar(tester);

      expect(repo.calledWith.length, 1);
    });

    testWidgets('11. Baño solo ofrece Hombre y Mujer', (tester) async {
      await tester.pumpWidget(
        createTestWidget(repo: FakeRepo(), sonda: FakeSonda()),
      );
      await tester.pumpAndSettle();

      await _seleccionar(tester, 0, 'Baño');
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdowns.at(2));
      await tester.tap(dropdowns.at(2), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Hombre'), findsWidgets);
      expect(find.text('Mujer'), findsWidgets);
      expect(find.text('Mixto'), findsNothing);
      expect(find.text('Accesible / Familiar'), findsNothing);
    });

    testWidgets(
      '12. Auditorio: sin edificio ni piso, con nombre y referencia',
      (tester) async {
        final repo = FakeRepo();
        await tester.pumpWidget(
          createTestWidget(repo: repo, sonda: FakeSonda()),
        );
        await tester.pumpAndSettle();

        await _seleccionar(tester, 0, 'Auditorio / sala');
        expect(find.text('Edificio'), findsNothing);
        expect(find.text('Piso'), findsNothing);
        expect(find.text('Nombre del auditorio'), findsOneWidget);

        await _escribir(tester, 'Nombre del auditorio', 'Auditorio principal');
        await _escribir(tester, 'Referencia (opcional)', 'Ala norte');
        await _escribir(tester, 'Descripción', 'Silla rota');
        await _seleccionar(tester, 1, 'Silla dañada');
        await _enviar(tester);

        final borrador = repo.calledWith.first;
        expect(borrador.tipoUbicacion, TipoEspacio.auditorio);
        expect(borrador.edificio, isNull);
        expect(borrador.piso, isNull);
        expect(borrador.espacio, 'Auditorio principal');
        expect(borrador.referencia, 'Ala norte');
        expect(borrador.ubicacionTexto, 'Auditorio principal');
      },
    );

    testWidgets('13. Biblioteca: sin edificio ni piso, con zona y referencia', (
      tester,
    ) async {
      final repo = FakeRepo();
      await tester.pumpWidget(createTestWidget(repo: repo, sonda: FakeSonda()));
      await tester.pumpAndSettle();

      await _seleccionar(tester, 0, 'Biblioteca');
      expect(find.text('Edificio'), findsNothing);
      expect(find.text('Piso'), findsNothing);
      expect(find.text('Zona de la biblioteca'), findsOneWidget);

      await _escribir(tester, 'Zona de la biblioteca', 'Sala de lectura');
      await _escribir(tester, 'Referencia (opcional)', 'Segundo piso');
      await _escribir(tester, 'Descripción', 'Mesa rota');
      await _seleccionar(tester, 1, 'Mesa dañada');
      await _enviar(tester);

      final borrador = repo.calledWith.first;
      expect(borrador.tipoUbicacion, TipoEspacio.biblioteca);
      expect(borrador.edificio, isNull);
      expect(borrador.piso, isNull);
      expect(borrador.espacio, 'Sala de lectura');
      expect(borrador.referencia, 'Segundo piso');
    });

    testWidgets(
      '14. Cafetería: solo A, C y E; sin piso, módulo ni referencia',
      (tester) async {
        final repo = FakeRepo();
        await tester.pumpWidget(
          createTestWidget(repo: repo, sonda: FakeSonda()),
        );
        await tester.pumpAndSettle();

        await _seleccionar(tester, 0, 'Cafetería / zona de comidas');
        expect(find.text('Piso'), findsNothing);
        expect(find.text('Módulo o punto'), findsNothing);
        expect(find.text('Referencia (opcional)'), findsNothing);

        final dropdowns = find.byType(DropdownButtonFormField<String>);
        await tester.ensureVisible(dropdowns.at(1));
        await tester.pumpAndSettle();
        await tester.tap(dropdowns.at(1), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Edificio A'), findsWidgets);
        expect(find.text('Edificio C'), findsWidgets);
        expect(find.text('Edificio E'), findsWidgets);
        expect(find.text('Edificio B'), findsNothing);
        expect(find.text('Edificio D'), findsNothing);
        expect(find.text('CAR'), findsNothing);

        await tester.tap(find.text('Edificio A').last, warnIfMissed: false);
        await tester.pumpAndSettle();
        await _escribir(tester, 'Descripción', 'Mesa rota');
        await _seleccionar(tester, 2, 'Mesa dañada');
        await _enviar(tester);

        final borrador = repo.calledWith.first;
        expect(borrador.tipoUbicacion, TipoEspacio.cafeteria);
        expect(borrador.edificio, 'Edificio A');
        expect(borrador.piso, isNull);
        expect(borrador.espacio, 'Cafetería');
        expect(borrador.referencia, isNull);
        expect(borrador.ubicacionTexto, 'Edificio A · Cafetería');
      },
    );

    testWidgets('15. Parqueadero: sin zona, se guarda como Parqueadero CAR', (
      tester,
    ) async {
      final repo = FakeRepo();
      await tester.pumpWidget(createTestWidget(repo: repo, sonda: FakeSonda()));
      await tester.pumpAndSettle();

      await _seleccionar(tester, 0, 'Parqueadero CAR');
      expect(find.text('Zona'), findsNothing);
      expect(find.text('Referencia (opcional)'), findsOneWidget);

      final dropdowns = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(dropdowns.at(1));
      await tester.pumpAndSettle();
      await tester.tap(dropdowns.at(1), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Señalización'), findsWidgets);
      expect(find.text('Barrera / portón'), findsNothing);

      await tester.tap(find.text('Señalización').last, warnIfMissed: false);
      await tester.pumpAndSettle();
      await _escribir(tester, 'Referencia (opcional)', 'Cerca de la entrada');
      await _escribir(tester, 'Descripción', 'Señal caída');
      await _enviar(tester);

      final borrador = repo.calledWith.first;
      expect(borrador.tipoUbicacion, TipoEspacio.parqueadero);
      expect(borrador.espacio, 'Parqueadero CAR');
      expect(borrador.referencia, 'Cerca de la entrada');
      expect(borrador.ubicacionTexto, 'Parqueadero CAR · Cerca de la entrada');
    });

    testWidgets('16. Sala de cómputo: solo A/B y únicamente Piso 3', (
      tester,
    ) async {
      final repo = FakeRepo();
      await tester.pumpWidget(createTestWidget(repo: repo, sonda: FakeSonda()));
      await tester.pumpAndSettle();

      await _seleccionar(tester, 0, 'Sala de cómputo');
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdowns.at(1), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Edificio A'), findsWidgets);
      expect(find.text('Edificio B'), findsWidgets);
      expect(find.text('Edificio C'), findsNothing);

      await tester.tap(find.text('Edificio A').last, warnIfMissed: false);
      await tester.pumpAndSettle();
      final pisoDropdown = find.byType(DropdownButtonFormField<String>).at(2);
      await tester.ensureVisible(pisoDropdown);
      await tester.pumpAndSettle();
      await tester.tap(pisoDropdown, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Piso 3'), findsWidgets);
      expect(find.text('Piso 1'), findsNothing);
      expect(find.text('Piso 4'), findsNothing);
      expect(find.text('Piso 6'), findsNothing);

      await tester.tap(find.text('Piso 3').last, warnIfMissed: false);
      await tester.pumpAndSettle();
      await _escribir(tester, 'Sala de cómputo', 'Sala de cómputo 305');
      await _escribir(tester, 'Descripción', 'Equipo sin encender');
      await _seleccionar(tester, 3, 'Equipo de cómputo dañado');
      await _enviar(tester);

      final borrador = repo.calledWith.first;
      expect(borrador.tipoUbicacion, TipoEspacio.salaComputo);
      expect(borrador.edificio, 'Edificio A');
      expect(borrador.piso, 'Piso 3');
      expect(borrador.espacio, 'Sala de cómputo 305');
      expect(
        borrador.ubicacionTexto,
        'Edificio A · Piso 3 · Sala de cómputo 305',
      );
    });

    testWidgets('17. Acceso / portería ya no se ofrece', (tester) async {
      await tester.pumpWidget(
        createTestWidget(repo: FakeRepo(), sonda: FakeSonda()),
      );
      await tester.pumpAndSettle();

      final dropdowns = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdowns.at(0), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Otro espacio'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      expect(find.text('Otro espacio'), findsWidgets);
      expect(find.text('Acceso / portería'), findsNothing);
    });

    testWidgets('18. Zona exterior: Jardines, Sendero peatonal y Otra', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(repo: FakeRepo(), sonda: FakeSonda()),
      );
      await tester.pumpAndSettle();

      await _seleccionar(tester, 0, 'Zona exterior / campus abierto');
      final zoneDropdown = find.byType(DropdownButtonFormField<String>).at(1);
      await tester.ensureVisible(zoneDropdown);
      await tester.pumpAndSettle();
      await tester.tap(zoneDropdown, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Jardines'), findsWidgets);
      expect(find.text('Sendero peatonal'), findsWidgets);
      expect(find.text('Otra'), findsWidgets);
      expect(find.text('Cancha deportiva'), findsNothing);
      expect(find.text('Plazoleta central'), findsNothing);
    });
  });
}
