import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:repcampusoft/features/catalogos/domain/catalogos.dart';
import 'package:repcampusoft/features/catalogos/presentation/catalogos_screen.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('slugCatalogo normaliza tildes, espacios y símbolos', () {
    expect(slugCatalogo('Edificio Á'), 'edificio_a');
    expect(slugCatalogo('Zona  verde / jardín'), 'zona_verde_jardin');
    expect(slugCatalogo('  Baño  '), 'bano');
  });

  test('los catálogos por defecto conservan los valores actuales', () {
    final edificios = edificiosPorDefecto();
    final sitios = sitiosPorDefecto();
    final danos = tiposDanoPorDefecto();
    final zonas = zonasPorDefecto();

    expect(edificios.length, 6);
    expect(edificios.first.pisos.length, 6);
    expect(sitios.any((s) => s.nombre == 'Aula / salón'), isTrue);
    expect(
      sitios.any((s) => s.nombre == 'Zona exterior / campus abierto'),
      isTrue,
    );
    expect(danos.any((d) => d.nombre == 'Silla dañada'), isTrue);
    expect(zonas.any((z) => z.nombre == 'Jardines'), isTrue);
  });

  testWidgets('muestra las cuatro secciones de catálogos', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CatalogosScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catálogos de reportes'), findsOneWidget);
    expect(find.text('Edificios'), findsWidgets);
    expect(find.text('Sitios'), findsOneWidget);
    expect(find.text('Daños'), findsOneWidget);
    expect(find.text('Zonas'), findsOneWidget);
    expect(find.text('Edificio A'), findsOneWidget);
    expect(find.text('Agregar edificio'), findsOneWidget);

    await tester.tap(find.text('Sitios'));
    await tester.pumpAndSettle();
    expect(find.text('Aula / salón'), findsOneWidget);
    expect(find.text('Agregar sitio'), findsOneWidget);

    await tester.tap(find.text('Daños'));
    await tester.pumpAndSettle();
    expect(find.text('Silla dañada'), findsOneWidget);
    expect(find.text('Agregar tipo de daño'), findsOneWidget);

    await tester.tap(find.text('Zonas'));
    await tester.pumpAndSettle();
    expect(find.text('Jardines'), findsOneWidget);
    expect(find.text('Agregar zona'), findsOneWidget);
  });
}
