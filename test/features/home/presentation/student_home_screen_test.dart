import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:repcampusoft/core/routes/app_router.dart';
import 'package:repcampusoft/core/routes/session_provider.dart';
import 'package:repcampusoft/features/auth/data/providers/auth_providers.dart';
import 'package:repcampusoft/features/auth/domain/rol_enum.dart';
import 'package:repcampusoft/features/home/presentation/student_home_screen.dart';
import 'package:repcampusoft/features/notificaciones/data/local_notificaciones_service.dart';
import 'package:repcampusoft/shared/widgets/dashboard_tile.dart';
import 'package:repcampusoft/shared/widgets/primary_button.dart';

import '../../../fakes/fake_auth_repository.dart';

class FakeLocalNotificacionesService implements LocalNotificacionesService {
  @override
  Future<void> inicializar() async {}
}

class _FakeSesionController extends SesionController {
  _FakeSesionController(this.sesion);
  final Sesion sesion;
  @override
  Sesion build() => sesion;
}

GoRouter createRouter(String initialRoute) {
  return GoRouter(
    initialLocation: initialRoute,
    routes: [
      GoRoute(
        path: AppRoutes.inicioEstudiante,
        builder: (_, _) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.perfilEstudiante,
        builder: (_, _) => const Scaffold(body: Text('PERFIL_ESTUDIANTE')),
      ),
      GoRoute(
        path: AppRoutes.reportarDanos,
        builder: (_, _) => const Scaffold(body: Text('REPORTAR_DANOS')),
      ),
      GoRoute(
        path: AppRoutes.misReportes,
        builder: (_, _) => const Scaffold(body: Text('MIS_REPORTES')),
      ),
      GoRoute(
        path: AppRoutes.notificacionesEstudiante,
        builder: (_, _) => const Scaffold(body: Text('NOTIF_ESTUDIANTE')),
      ),
    ],
  );
}

ProviderScope wrapWithProviders(GoRouter router, FakeAuthRepository fakeAuth) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fakeAuth),
      localNotificacionesServiceProvider.overrideWith(
        (ref) => FakeLocalNotificacionesService(),
      ),
      sesionProvider.overrideWith(
        () => _FakeSesionController(
          const Sesion.rolAplicado(
            uid: 'student-uid',
            correo: 'student@uts.edu.co',
            rol: RolEnum.persona,
          ),
        ),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('StudentHomeScreen (RF-05)', () {
    late FakeAuthRepository fakeAuth;

    setUp(() {
      fakeAuth = FakeAuthRepository();
      fakeAuth.marcarVerificado('student@uts.edu.co');
    });

    testWidgets('dashboard 2x2 se renderiza con 4 tiles y cerrar sesion', (
      tester,
    ) async {
      final router = createRouter(AppRoutes.inicioEstudiante);
      await tester.pumpWidget(wrapWithProviders(router, fakeAuth));
      await tester.pump();

      expect(find.byType(DashboardTile), findsNWidgets(4));
      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Reportar daños'), findsOneWidget);
      expect(find.text('Tus reportes'), findsOneWidget);
      expect(find.text('Notificaciones'), findsOneWidget);
      expect(
        find.widgetWithText(PrimaryButton, 'Cerrar Sesión'),
        findsOneWidget,
      );
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('tap Perfil navega a perfil-estudiante', (tester) async {
      final router = createRouter(AppRoutes.inicioEstudiante);
      await tester.pumpWidget(wrapWithProviders(router, fakeAuth));
      await tester.pump();

      final finder = find.widgetWithText(DashboardTile, 'Perfil');
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder, warnIfMissed: false);
      await tester.pump();

      expect(find.text('PERFIL_ESTUDIANTE'), findsOneWidget);
    });

    testWidgets('tap Reportar daños navega a reportar-danos', (tester) async {
      final router = createRouter(AppRoutes.inicioEstudiante);
      await tester.pumpWidget(wrapWithProviders(router, fakeAuth));
      await tester.pump();

      final finder = find.widgetWithText(DashboardTile, 'Reportar daños');
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder, warnIfMissed: false);
      await tester.pump();

      expect(find.text('REPORTAR_DANOS'), findsOneWidget);
    });

    testWidgets('tap Tus reportes navega a mis-reportes', (tester) async {
      final router = createRouter(AppRoutes.inicioEstudiante);
      await tester.pumpWidget(wrapWithProviders(router, fakeAuth));
      await tester.pump();

      final finder = find.widgetWithText(DashboardTile, 'Tus reportes');
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder, warnIfMissed: false);
      await tester.pump();

      expect(find.text('MIS_REPORTES'), findsOneWidget);
    });

    testWidgets('tap Notificaciones navega a notificaciones-estudiante', (
      tester,
    ) async {
      final router = createRouter(AppRoutes.inicioEstudiante);
      await tester.pumpWidget(wrapWithProviders(router, fakeAuth));
      await tester.pump();

      final finder = find.widgetWithText(DashboardTile, 'Notificaciones');
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder, warnIfMissed: false);
      await tester.pump();

      expect(find.text('NOTIF_ESTUDIANTE'), findsOneWidget);
    });
  });
}
