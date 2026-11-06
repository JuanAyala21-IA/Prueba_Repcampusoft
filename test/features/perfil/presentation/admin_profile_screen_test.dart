import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:repcampusoft/core/routes/app_router.dart';
import 'package:repcampusoft/core/routes/session_provider.dart';
import 'package:repcampusoft/features/auth/data/providers/auth_providers.dart';
import 'package:repcampusoft/features/auth/domain/rol_enum.dart';
import 'package:repcampusoft/features/auth/domain/usuario.dart';
import 'package:repcampusoft/features/notificaciones/data/local_notificaciones_service.dart';
import 'package:repcampusoft/features/perfil/data/providers/perfil_providers.dart';
import 'package:repcampusoft/features/perfil/presentation/admin_profile_screen.dart';

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
        path: AppRoutes.perfilAdmin,
        builder: (_, _) => const AdminProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editarPerfil,
        builder: (_, _) => const Scaffold(body: Text('EDITAR_PERFIL')),
      ),
      GoRoute(
        path: AppRoutes.cambiarContrasena,
        builder: (_, _) => const Scaffold(body: Text('CAMBIAR_CONTRASENA')),
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
            uid: 'admin-uid',
            correo: 'juan.perez@uts.edu.co',
            rol: RolEnum.administrativo,
          ),
        ),
      ),
      perfilUsuarioProvider.overrideWith(
        (ref) => Future.value(
          Usuario(
            uid: 'admin-uid',
            nombre: 'Juan Pérez García',
            correo: 'juan.perez@uts.edu.co',
            rol: RolEnum.administrativo,
            cargo: 'Coordinador de Mantenimiento',
            dependencia: 'Área de Mantenimiento',
            telefono: '+57 310 123 7892',
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

  group('AdminProfileScreen (RF-08)', () {
    late FakeAuthRepository fakeAuth;

    setUp(() {
      fakeAuth = FakeAuthRepository(whitelist: {'juan.perez@uts.edu.co'});
      fakeAuth.marcarVerificado('juan.perez@uts.edu.co');
    });

    testWidgets('muestra los datos del funcionario', (tester) async {
      final router = createRouter(AppRoutes.perfilAdmin);
      await tester.pumpWidget(wrapWithProviders(router, fakeAuth));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // Debug: print widget tree
      // debugDumpWidgetTree(tester);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data != null &&
              widget.data!.contains('Coordinador'),
        ),
        findsOneWidget,
      );
      expect(find.text('Dependencia / Área'), findsOneWidget);
      expect(find.text('Datos del funcionario'), findsOneWidget);
      expect(find.textContaining('juan.perez@uts.edu.co'), findsOneWidget);
      expect(find.textContaining('+57 310 123 7892'), findsOneWidget);
      expect(find.text('Opciones de cuenta'), findsOneWidget);
      expect(find.text('Editar información'), findsOneWidget);
      expect(find.text('Cambiar contraseña'), findsOneWidget);
    });

    testWidgets('tap Editar información navega a editar-perfil', (
      tester,
    ) async {
      final router = createRouter(AppRoutes.perfilAdmin);
      await tester.pumpWidget(wrapWithProviders(router, fakeAuth));
      await tester.pumpAndSettle();

      final finder = find.text('Editar información');
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder, warnIfMissed: false);
      await tester.pump();

      expect(find.text('EDITAR_PERFIL'), findsOneWidget);
    });

    testWidgets('tap Cambiar contraseña navega a cambiar-contrasena', (
      tester,
    ) async {
      final router = createRouter(AppRoutes.perfilAdmin);
      await tester.pumpWidget(wrapWithProviders(router, fakeAuth));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      final finder = find.text('Cambiar contraseña');
      expect(finder, findsOneWidget);
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder, warnIfMissed: false);
      await tester.pump();

      expect(find.text('CAMBIAR_CONTRASENA'), findsOneWidget);
    });
  });
}
