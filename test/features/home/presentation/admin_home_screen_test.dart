import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:repcampusoft/core/routes/app_router.dart';
import 'package:repcampusoft/core/routes/session_provider.dart';
import 'package:repcampusoft/features/auth/data/providers/auth_providers.dart';
import 'package:repcampusoft/features/auth/domain/rol_enum.dart';
import 'package:repcampusoft/features/home/presentation/admin_home_screen.dart';
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
        path: AppRoutes.inicioAdmin,
        builder: (_, _) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.perfilAdmin,
        builder: (_, _) => const Scaffold(body: Text('PERFIL_ADMIN')),
      ),
      GoRoute(
        path: AppRoutes.danosReportados,
        builder: (_, _) => const Scaffold(body: Text('DANOS_REPORTADOS')),
      ),
      GoRoute(
        path: AppRoutes.notificacionesAdmin,
        builder: (_, _) => const Scaffold(body: Text('NOTIF_ADMIN')),
      ),
      GoRoute(
        path: AppRoutes.exportarReportes,
        builder: (_, _) => const Scaffold(body: Text('EXPORTAR_REPORTES')),
      ),
    ],
  );
}

ProviderScope wrapWithProviders(
  GoRouter router,
  FakeAuthRepository fakeAuth, {
  RolEnum rol = RolEnum.administrativo,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fakeAuth),
      localNotificacionesServiceProvider.overrideWith(
        (ref) => FakeLocalNotificacionesService(),
      ),
      sesionProvider.overrideWith(
        () => _FakeSesionController(
          Sesion.rolAplicado(
            uid: 'admin-uid',
            correo: 'admin@uts.edu.co',
            rol: rol,
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

  group('AdminHomeScreen (RF-06)', () {
    late FakeAuthRepository fakeAuth;

    setUp(() {
      fakeAuth = FakeAuthRepository(whitelist: {'admin@uts.edu.co'});
      fakeAuth.marcarVerificado('admin@uts.edu.co');
    });

    testWidgets('dashboard se renderiza con 3 tiles y cerrar sesion', (
      tester,
    ) async {
      final router = createRouter(AppRoutes.inicioAdmin);
      await tester.pumpWidget(wrapWithProviders(router, fakeAuth));
      await tester.pump();

      expect(find.byType(DashboardTile), findsNWidgets(3));
      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Daño y gestión de reportes'), findsOneWidget);
      expect(find.text('Notificaciones'), findsOneWidget);
      expect(
        find.widgetWithText(PrimaryButton, 'Cerrar Sesión'),
        findsOneWidget,
      );
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('tap Perfil navega a perfil-admin', (tester) async {
      final router = createRouter(AppRoutes.inicioAdmin);
      await tester.pumpWidget(wrapWithProviders(router, fakeAuth));
      await tester.pump();

      final finder = find.widgetWithText(DashboardTile, 'Perfil');
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder, warnIfMissed: false);
      await tester.pump();

      expect(find.text('PERFIL_ADMIN'), findsOneWidget);
    });

    testWidgets('tap Daño y gestión navega a danos-reportados', (tester) async {
      final router = createRouter(AppRoutes.inicioAdmin);
      await tester.pumpWidget(wrapWithProviders(router, fakeAuth));
      await tester.pump();

      final finder = find.widgetWithText(
        DashboardTile,
        'Daño y gestión de reportes',
      );
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder, warnIfMissed: false);
      await tester.pump();

      expect(find.text('DANOS_REPORTADOS'), findsOneWidget);
    });

    testWidgets('tap Notificaciones navega a notificaciones-admin', (
      tester,
    ) async {
      final router = createRouter(AppRoutes.inicioAdmin);
      await tester.pumpWidget(wrapWithProviders(router, fakeAuth));
      await tester.pump();

      final finder = find.widgetWithText(DashboardTile, 'Notificaciones');
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder, warnIfMissed: false);
      await tester.pump();

      expect(find.text('NOTIF_ADMIN'), findsOneWidget);
    });

    testWidgets('administrativo no ve la opción de descargar reportes', (
      tester,
    ) async {
      final router = createRouter(AppRoutes.inicioAdmin);
      await tester.pumpWidget(wrapWithProviders(router, fakeAuth));
      await tester.pump();

      expect(find.text('Descargar reportes (CSV)'), findsNothing);
      expect(find.byType(DashboardTile), findsNWidgets(3));
    });

    testWidgets('superadministrador ve Descargar reportes y navega', (
      tester,
    ) async {
      final router = createRouter(AppRoutes.inicioAdmin);
      await tester.pumpWidget(
        wrapWithProviders(router, fakeAuth, rol: RolEnum.superadministrador),
      );
      await tester.pump();

      expect(find.byType(DashboardTile), findsNWidgets(6));
      final finder = find.widgetWithText(
        DashboardTile,
        'Descargar reportes (CSV)',
      );
      expect(finder, findsOneWidget);
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder, warnIfMissed: false);
      await tester.pump();

      expect(find.text('EXPORTAR_REPORTES'), findsOneWidget);
    });
  });
}
