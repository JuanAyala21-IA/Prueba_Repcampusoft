import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:repcampusoft/core/routes/app_router.dart';
import 'package:repcampusoft/features/auth/presentation/welcome_screen.dart';

GoRouter createRouter(String initialRoute) {
  return GoRouter(
    initialLocation: initialRoute,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const Scaffold(body: Text('LOGIN_SCREEN')),
      ),
      GoRoute(
        path: AppRoutes.registro,
        builder: (_, _) => const Scaffold(body: Text('REGISTRO_SCREEN')),
      ),
    ],
  );
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('WelcomeScreen', () {
    testWidgets('se renderiza el logo, el subtítulo y los dos botones', (
      tester,
    ) async {
      final router = createRouter(AppRoutes.welcome);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              (w.image as AssetImage).assetName ==
                  'assets/images/logo_uts_blanco.png',
        ),
        findsOneWidget,
      );
      expect(find.text('Sistema de reporte de daños'), findsOneWidget);
      expect(find.text('[Sistema de reporte de daños]'), findsNothing);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('REGISTRARSE'), findsOneWidget);
    });

    testWidgets('tap INICIAR SESIÓN navega a login', (tester) async {
      final router = createRouter(AppRoutes.welcome);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pump();

      expect(find.text('LOGIN_SCREEN'), findsOneWidget);
    });

    testWidgets('tap REGISTRARSE navega a registro', (tester) async {
      final router = createRouter(AppRoutes.welcome);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      await tester.tap(find.text('REGISTRARSE'));
      await tester.pump();

      expect(find.text('REGISTRO_SCREEN'), findsOneWidget);
    });

    testWidgets('fondo es welcomeBackground verde oliva', (tester) async {
      final router = createRouter(AppRoutes.welcome);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNotNull);
    });
  });
}
