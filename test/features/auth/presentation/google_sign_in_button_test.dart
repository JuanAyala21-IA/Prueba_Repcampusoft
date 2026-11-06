import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:repcampusoft/features/auth/presentation/auth_widgets.dart';

Widget _envoltorio(Widget hijo) {
  return MaterialApp(
    home: Scaffold(body: Center(child: hijo)),
  );
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('GoogleSignInButton', () {
    testWidgets('muestra el texto por defecto y el logo', (tester) async {
      await tester.pumpWidget(
        _envoltorio(GoogleSignInButton(onPressed: () {})),
      );
      await tester.pump();

      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('permite personalizar el texto', (tester) async {
      await tester.pumpWidget(
        _envoltorio(
          GoogleSignInButton(texto: 'Registrarme con Google', onPressed: () {}),
        ),
      );
      await tester.pump();

      expect(find.text('Registrarme con Google'), findsOneWidget);
    });

    testWidgets('invoca onPressed al tocar', (tester) async {
      var pulsaciones = 0;
      await tester.pumpWidget(
        _envoltorio(GoogleSignInButton(onPressed: () => pulsaciones++)),
      );
      await tester.pump();

      await tester.tap(find.byType(OutlinedButton));
      expect(pulsaciones, 1);
    });

    testWidgets('sin onPressed el botón queda deshabilitado', (tester) async {
      await tester.pumpWidget(
        _envoltorio(const GoogleSignInButton(onPressed: null)),
      );
      await tester.pump();

      final OutlinedButton boton = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(boton.onPressed, isNull);
    });

    testWidgets('en estado cargando muestra indicador y texto de conexión', (
      tester,
    ) async {
      var pulsaciones = 0;
      await tester.pumpWidget(
        _envoltorio(
          GoogleSignInButton(onPressed: () => pulsaciones++, cargando: true),
        ),
      );
      await tester.pump();

      expect(find.text('Conectando…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final OutlinedButton boton = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(boton.onPressed, isNull);

      await tester.tap(find.byType(OutlinedButton));
      expect(pulsaciones, 0);
    });
  });

  group('AuthDivider', () {
    testWidgets('muestra el separador con el texto por defecto', (
      tester,
    ) async {
      await tester.pumpWidget(_envoltorio(const AuthDivider()));
      await tester.pump();

      expect(find.text('o'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('permite personalizar el texto', (tester) async {
      await tester.pumpWidget(
        _envoltorio(const AuthDivider(texto: 'o continúa con tu correo')),
      );
      await tester.pump();

      expect(find.text('o continúa con tu correo'), findsOneWidget);
    });
  });
}
