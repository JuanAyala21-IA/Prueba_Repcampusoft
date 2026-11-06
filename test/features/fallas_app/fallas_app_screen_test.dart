import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:repcampusoft/features/fallas_app/data/providers/fallas_app_providers.dart';
import 'package:repcampusoft/features/fallas_app/domain/falla_app.dart';
import 'package:repcampusoft/features/fallas_app/presentation/fallas_app_screen.dart';

Widget createTestApp(List<FallaApp> fallas) {
  return ProviderScope(
    overrides: [
      fallasAppListProvider.overrideWith((ref) => Stream.value(fallas)),
    ],
    child: const MaterialApp(home: FallasAppScreen()),
  );
}

FallaApp crearFalla({
  String id = 'falla-1',
  String correo = 'estudiante@uts.edu.co',
  String mensaje = 'La app se cierra al guardar',
  String? pantalla = 'Gestión de usuarios',
  String? dispositivo = 'samsung SM-A155M',
  String? sistemaOperativo = 'Android 14 (API 34)',
  String? versionApp = '1.0.0+1',
  Duration antiguedad = const Duration(hours: 2),
}) {
  return FallaApp(
    id: id,
    uid: 'uid-1',
    correo: correo,
    mensaje: mensaje,
    pantalla: pantalla,
    dispositivo: dispositivo,
    sistemaOperativo: sistemaOperativo,
    versionApp: versionApp,
    creadoEn: Timestamp.fromDate(DateTime.now().subtract(antiguedad)),
  );
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('FallasAppScreen', () {
    testWidgets('muestra encabezado, resumen, buscador y filtros', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp([crearFalla()]));
      await tester.pumpAndSettle();

      expect(find.text('Fallas de la app'), findsOneWidget);
      expect(find.text('Reportes enviados por los usuarios'), findsOneWidget);
      expect(find.text('falla'), findsOneWidget);
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('7 días'), findsNWidgets(2));
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('la tarjeta muestra pantalla, correo y datos técnicos', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp([crearFalla()]));
      await tester.pumpAndSettle();

      expect(find.text('Pantalla: Gestión de usuarios'), findsOneWidget);
      expect(find.text('estudiante@uts.edu.co'), findsOneWidget);
      expect(find.text('samsung SM-A155M'), findsOneWidget);
      expect(find.text('Android 14 (API 34)'), findsOneWidget);
      expect(find.text('v1.0.0+1'), findsOneWidget);
      expect(find.text('Nueva'), findsOneWidget);
    });

    testWidgets('el buscador filtra por correo o mensaje', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp([
          crearFalla(),
          crearFalla(
            id: 'falla-2',
            correo: 'otro@uts.edu.co',
            mensaje: 'No carga la foto',
            pantalla: 'Reportar daños',
            dispositivo: 'Xiaomi Redmi 12',
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('La app se cierra al guardar'), findsOneWidget);
      expect(find.text('No carga la foto'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'no carga');
      await tester.pumpAndSettle();

      expect(find.text('La app se cierra al guardar'), findsNothing);
      expect(find.text('No carga la foto'), findsOneWidget);
    });

    testWidgets(
      'muestra estado sin coincidencias cuando el filtro no arroja resultados',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp([crearFalla(antiguedad: const Duration(days: 10))]),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hoy'));
        await tester.pumpAndSettle();

        expect(find.text('Sin coincidencias'), findsOneWidget);
        expect(find.text('Limpiar filtros'), findsOneWidget);
      },
    );

    testWidgets('muestra estado vacío con botón para reportar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(<FallaApp>[]));
      await tester.pumpAndSettle();

      expect(find.text('Todo tranquilo por aquí'), findsOneWidget);
      expect(find.text('REPORTAR UNA FALLA'), findsOneWidget);
    });
  });
}
