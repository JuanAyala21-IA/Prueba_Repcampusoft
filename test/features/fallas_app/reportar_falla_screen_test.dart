import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:repcampusoft/features/fallas_app/data/providers/fallas_app_providers.dart';
import 'package:repcampusoft/features/fallas_app/domain/falla_app.dart';
import 'package:repcampusoft/features/fallas_app/domain/fallas_app_repository.dart';
import 'package:repcampusoft/features/fallas_app/presentation/reportar_falla_screen.dart';
import 'package:repcampusoft/shared/widgets/primary_button.dart';

class FakeFallasRepo implements FallasAppRepository {
  String? ultimoMensaje;
  String? ultimaPantalla;
  int llamadas = 0;

  @override
  Future<void> reportar({required String mensaje, String? pantalla}) async {
    llamadas++;
    ultimoMensaje = mensaje;
    ultimaPantalla = pantalla;
  }

  @override
  Stream<List<FallaApp>> watchFallas() => Stream.value(<FallaApp>[]);
}

Widget createTestWidget(FakeFallasRepo repo) {
  return ProviderScope(
    overrides: [fallasAppRepositoryProvider.overrideWith((_) => repo)],
    child: const MaterialApp(home: ReportarFallaScreen()),
  );
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ReportarFallaScreen widget tests', () {
    testWidgets('muestra título y botón de envío', (tester) async {
      await tester.pumpWidget(createTestWidget(FakeFallasRepo()));
      await tester.pumpAndSettle();

      expect(find.text('Reportar falla de la app'), findsOneWidget);
      expect(
        find.widgetWithText(PrimaryButton, 'ENVIAR REPORTE'),
        findsOneWidget,
      );
    });

    testWidgets('con mensaje vacío muestra error y no llama al repo', (
      tester,
    ) async {
      final repo = FakeFallasRepo();
      await tester.pumpWidget(createTestWidget(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(PrimaryButton, 'ENVIAR REPORTE'));
      await tester.pump();

      expect(find.text('Describe la falla'), findsOneWidget);
      expect(repo.llamadas, 0);
    });

    testWidgets('con datos válidos llama al repo y muestra confirmación', (
      tester,
    ) async {
      final repo = FakeFallasRepo();
      await tester.pumpWidget(createTestWidget(repo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'El botón Enviar no responde',
      );
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENVIAR REPORTE'));
      await tester.pump();

      expect(repo.llamadas, 1);
      expect(repo.ultimoMensaje, 'El botón Enviar no responde');
      expect(
        find.text('Reporte enviado. Gracias por tu ayuda.'),
        findsOneWidget,
      );
    });
  });
}
