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
import 'package:repcampusoft/features/perfil/data/providers/perfil_providers.dart';
import 'package:repcampusoft/features/perfil/presentation/student_profile_screen.dart';
import 'package:repcampusoft/features/notificaciones/data/local_notificaciones_service.dart';

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
        path: AppRoutes.perfilEstudiante,
        builder: (_, _) => const StudentProfileScreen(),
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
            uid: 'student-uid',
            correo: 'csblanco@uts.edu.co',
            rol: RolEnum.persona,
          ),
        ),
      ),
      perfilUsuarioProvider.overrideWith(
        (ref) => Future.value(
          Usuario(
            uid: 'student-uid',
            nombre: 'Carlos Santiago Blanco Avila',
            correo: 'csblanco@uts.edu.co',
            rol: RolEnum.persona,
            telefono: '+57 300 123 4567',
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

  group('StudentProfileScreen (RF-07)', () {
    late FakeAuthRepository fakeAuth;

    setUp(() {
      fakeAuth = FakeAuthRepository();
      fakeAuth.marcarVerificado('csblanco@uts.edu.co');
    });

    testWidgets('muestra los datos del usuario actual', (tester) async {
      final router = createRouter(AppRoutes.perfilEstudiante);
      await tester.pumpWidget(wrapWithProviders(router, fakeAuth));
      await tester.pumpAndSettle();

      expect(find.text('Carlos Santiago Blanco Avila'), findsOneWidget);
      expect(find.textContaining('csblanco@uts.edu.co'), findsOneWidget);
      expect(find.textContaining('+57 300 123 4567'), findsOneWidget);
      expect(find.text('Información de contacto'), findsOneWidget);
      expect(find.text('Configuración de la cuenta'), findsOneWidget);
    });

    testWidgets('tap Editar información navega a editar-perfil', (
      tester,
    ) async {
      final router = createRouter(AppRoutes.perfilEstudiante);
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
      final router = createRouter(AppRoutes.perfilEstudiante);
      await tester.pumpWidget(wrapWithProviders(router, fakeAuth));
      await tester.pumpAndSettle();

      final finder = find.text('Cambiar contraseña');
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder, warnIfMissed: false);
      await tester.pump();

      expect(find.text('CAMBIAR_CONTRASENA'), findsOneWidget);
    });
  });
}
