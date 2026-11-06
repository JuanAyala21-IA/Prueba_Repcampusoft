import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'package:repcampusoft/core/routes/app_router.dart';
import 'package:repcampusoft/core/routes/session_provider.dart';
import 'package:repcampusoft/features/auth/data/providers/auth_providers.dart';
import 'package:repcampusoft/features/auth/domain/rol_enum.dart';
import 'package:repcampusoft/features/auth/domain/usuario.dart';
import 'package:repcampusoft/features/notificaciones/data/providers/notificacion_providers.dart';
import 'package:repcampusoft/features/notificaciones/data/local_notificaciones_service.dart';
import 'package:repcampusoft/features/notificaciones/domain/notificacion.dart';
import 'package:repcampusoft/features/notificaciones/presentation/admin_notifications_screen.dart';
import 'package:repcampusoft/shared/widgets/notification_card.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_notificacion_repository.dart';

/// Fake no-op para tests
class FakeLocalNotificacionesService implements LocalNotificacionesService {
  @override
  Future<void> inicializar() async {}
}

/// Notifier fijo para los widget tests: expone una sesión `rolAplicado`
/// determinista sin depender de Firebase Auth.
class _FakeSesionController extends SesionController {
  _FakeSesionController(this.sesion);

  final Sesion sesion;

  @override
  Sesion build() => sesion;
}

Widget createTestApp({
  required FakeAuthRepository fakeAuth,
  required FakeNotificacionRepository repository,
  RolEnum rol = RolEnum.administrativo,
  Stream<List<Notificacion>>? notificationsStream,
  String initialRoute = AppRoutes.notificacionesAdmin,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fakeAuth),
      notificacionRepositoryProvider.overrideWithValue(repository),
      localNotificacionesServiceProvider.overrideWith(
        (ref) => FakeLocalNotificacionesService(),
      ),
      sesionProvider.overrideWith(
        () => _FakeSesionController(
          Sesion.rolAplicado(
            uid: 'test-admin-uid',
            correo: 'admin@test.com',
            rol: rol,
          ),
        ),
      ),
      if (notificationsStream != null)
        notificacionesAdminProvider.overrideWith((ref) => notificationsStream),
    ],
    child: MaterialApp.router(routerConfig: createRouter(initialRoute)),
  );
}

GoRouter createRouter(String initialRoute) {
  return GoRouter(
    initialLocation: initialRoute,
    routes: [
      GoRoute(
        path: AppRoutes.notificacionesAdmin,
        builder: (_, _) => const AdminNotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.gestionReporte,
        builder: (_, state) => Scaffold(
          appBar: AppBar(
            title: Text('Gestión ${state.uri.queryParameters['reportId']}'),
          ),
        ),
      ),
    ],
  );
}

void main() {
  group('AdminNotificationsScreen', () {
    late FakeAuthRepository fakeAuth;
    late FakeFirebaseFirestore firestore;
    late FakeNotificacionRepository repository;

    setUp(() async {
      fakeAuth = FakeAuthRepository(whitelist: {'admin@test.com'});
      fakeAuth.marcarVerificado('admin@test.com');
      fakeAuth.perfiles['test-admin-uid'] = Usuario(
        uid: 'test-admin-uid',
        nombre: 'Admin Test',
        correo: 'admin@test.com',
        rol: RolEnum.administrativo,
        cargo: 'Coordinador',
      );

      firestore = FakeFirebaseFirestore();
      repository = FakeNotificacionRepository(firestore: firestore);

      final now = Timestamp.now();
      final batch = firestore.batch();
      void seed(
        String id,
        String tipo,
        String titulo,
        String destinoRol,
        Duration antiguedad, {
        String? reportId,
      }) {
        batch.set(firestore.collection('notifications').doc(id), {
          'tipo': tipo,
          'titulo': titulo,
          'mensaje': 'Mensaje de $titulo',
          'reportId': reportId,
          'evento': reportId == null ? null : 'creado',
          'uidDestino': null,
          'destinoRol': destinoRol,
          'autorUid': 'autor-1',
          'creadoEn': Timestamp.fromDate(now.toDate().subtract(antiguedad)),
        });
      }

      // Reporte creado por un estudiante: visible para mantenimiento,
      // administrativo y superadministrador.
      seed(
        'notif-reporte',
        'reporte',
        'Nuevo reporte de daño',
        'administrativo',
        const Duration(hours: 3),
        reportId: 'rep-1',
      );
      // Falla de la app: solo la ve el superadministrador.
      seed(
        'notif-falla',
        'sistema',
        'Nueva falla de la app',
        'superadministrador',
        const Duration(hours: 2),
      );
      // Aviso administrativo antiguo: no debe mostrarse a nadie.
      seed(
        'notif-aviso',
        'administrativo',
        'Aviso administrativo',
        'administrativo',
        const Duration(hours: 1),
      );
      // Notificación individual de un estudiante: no debe verse en el panel.
      seed(
        'notif-estudiante',
        'reporte',
        'Tu reporte cambió de estado',
        '',
        const Duration(minutes: 30),
      );

      await batch.commit();
    });

    testWidgets('muestra loading mientras carga', (WidgetTester tester) async {
      final controller = StreamController<List<Notificacion>>();
      await tester.pumpWidget(
        createTestApp(
          fakeAuth: fakeAuth,
          repository: repository,
          notificationsStream: controller.stream,
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('no muestra chips de filtro', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(fakeAuth: fakeAuth, repository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('Todas'), findsNothing);
      expect(find.text('Reportes'), findsNothing);
      expect(find.text('Administrativo'), findsNothing);
      expect(find.text('Sistema'), findsNothing);
    });

    testWidgets('administrativo solo ve reportes de estudiantes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(fakeAuth: fakeAuth, repository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotificationCard), findsOneWidget);
      expect(find.text('Nuevo reporte de daño'), findsOneWidget);
      expect(find.text('Nueva falla de la app'), findsNothing);
      expect(find.text('Aviso administrativo'), findsNothing);
      expect(find.text('Tu reporte cambió de estado'), findsNothing);
    });

    testWidgets('mantenimiento solo ve reportes de estudiantes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          fakeAuth: fakeAuth,
          repository: repository,
          rol: RolEnum.mantenimiento,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotificationCard), findsOneWidget);
      expect(find.text('Nuevo reporte de daño'), findsOneWidget);
      expect(find.text('Nueva falla de la app'), findsNothing);
      expect(find.text('Aviso administrativo'), findsNothing);
    });

    testWidgets('superadministrador ve reportes de estudiantes y fallas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          fakeAuth: fakeAuth,
          repository: repository,
          rol: RolEnum.superadministrador,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotificationCard), findsNWidgets(2));
      expect(find.text('Nuevo reporte de daño'), findsOneWidget);
      expect(find.text('Nueva falla de la app'), findsOneWidget);
      expect(find.text('Aviso administrativo'), findsNothing);
      expect(find.text('Tu reporte cambió de estado'), findsNothing);
    });

    testWidgets('al tocar una notificación con reportId navega a gestión', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(fakeAuth: fakeAuth, repository: repository),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NotificationCard).first);
      await tester.pumpAndSettle();

      expect(find.text('Gestión rep-1'), findsOneWidget);
    });

    testWidgets('lista vacía muestra el mensaje según el rol', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          fakeAuth: fakeAuth,
          repository: FakeNotificacionRepository(
            firestore: FakeFirebaseFirestore(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No hay notificaciones'), findsOneWidget);
      expect(
        find.text('Aquí verás los reportes que hacen los estudiantes.'),
        findsOneWidget,
      );
    });
  });
}
