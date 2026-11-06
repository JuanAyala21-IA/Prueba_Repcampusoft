import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:repcampusoft/features/auth/presentation/about_screen.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AboutScreen (RF-02)', () {
    testWidgets('se renderiza con la info de la app', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
      await tester.pump();

      expect(find.textContaining('¿Qué es Repcampusoft?'), findsOneWidget);
      expect(
        find.textContaining('REPCAMPUSOFT es una solución móvil'),
        findsOneWidget,
      );
      expect(find.textContaining('Permite a estudiantes'), findsOneWidget);
      expect(find.textContaining('El personal operativo'), findsOneWidget);
      expect(find.text('Plataforma de reportes'), findsOneWidget);
    });

    testWidgets('muestra SingleChildScrollView y Container con bordes', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });
  });
}
