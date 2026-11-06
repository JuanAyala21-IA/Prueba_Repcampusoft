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
import 'package:repcampusoft/features/notificaciones/presentation/student_notifications_screen.dart';
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
  required List<Notificacion> notifications,
  Stream<List<Notificacion>>? notificationsStream,
  String initialRoute = AppRoutes.notificacionesEstudiante,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fakeAuth),
      notificacionRepositoryProvider.overrideWithValue(
        FakeNotificacionRepository(firestore: FakeFirebaseFirestore()),
      ),
      localNotificacionesServiceProvider.overrideWith(
        (ref) => FakeLocalNotificacionesService(),
      ),
      sesionProvider.overrideWith(
        () => _FakeSesionController(
          const Sesion.rolAplicado(
            uid: 'test-student-uid',
            correo: 'student@test.com',
            rol: RolEnum.persona,
          ),
        ),
      ),
      // Override StreamProvider directly with synchronous Stream.value() like Phase 7
      notificacionesEstudianteProvider.overrideWith(
        (ref) => notificationsStream ?? Stream.value(notifications),
      ),
    ],
    child: MaterialApp.router(routerConfig: createRouter(initialRoute)),
  );
}

GoRouter createRouter(String initialRoute) {
  return GoRouter(
    initialLocation: initialRoute,
    routes: [
      GoRoute(
        path: AppRoutes.notificacionesEstudiante,
        builder: (_, _) => const StudentNotificationsScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.detalleReporte}/:reportId',
        builder: (_, state) => Scaffold(
          appBar: AppBar(
            title: Text('Detalle ${state.pathParameters['reportId']}'),
          ),
        ),
      ),
    ],
  );
}

void main() {
  group('StudentNotificationsScreen', () {
    late FakeAuthRepository fakeAuth;
    late List<Notificacion> testNotifications;

    setUp(() {
      fakeAuth = FakeAuthRepository();
      fakeAuth.marcarVerificado('student@test.com');
      fakeAuth.perfiles['test-student-uid'] = Usuario(
        uid: 'test-student-uid',
        nombre: 'Estudiante Test',
        correo: 'student@test.com',
        rol: RolEnum.persona,
      );

      // Pre-compute test notifications (like Phase 7 pattern)
      final now = Timestamp.now();
      testNotifications = [
        Notificacion(
          id: 'notif-1',
          tipo: NotificacionTipo.reporte,
          titulo: 'Reporte recibido',
          mensaje: 'Tu reporte #01 ha sido recibido',
          reportId: 'rep-1',
          evento: NotificacionEvento.creado,
          uidDestino: 'test-student-uid',
          destinoRol: null,
          autorUid: 'admin-1',
          creadoEn: Timestamp.fromDate(
            now.toDate().subtract(const Duration(hours: 2)),
          ),
          leida: false,
        ),
        Notificacion(
          id: 'notif-2',
          tipo: NotificacionTipo.reporte,
          titulo: 'Reporte en proceso',
          mensaje: 'El reporte está en proceso',
          reportId: 'rep-1',
          evento: NotificacionEvento.enProceso,
          uidDestino: 'test-student-uid',
          destinoRol: null,
          autorUid: 'admin-1',
          creadoEn: Timestamp.fromDate(
            now.toDate().subtract(const Duration(hours: 1)),
          ),
          leida: false,
        ),
        Notificacion(
          id: 'notif-3',
          tipo: NotificacionTipo.reporte,
          titulo: 'Reporte Solucionado',
          mensaje: 'El reporte ha sido solucionado',
          reportId: 'rep-2',
          evento: NotificacionEvento.solucionado,
          uidDestino: 'test-student-uid',
          destinoRol: null,
          autorUid: 'admin-1',
          creadoEn: Timestamp.fromDate(now.toDate()),
          leida: false,
        ),
      ];
    });

    testWidgets('muestra loading mientras carga', (WidgetTester tester) async {
      // Stream que nunca emite para bloquear el estado loading (patrón Fase 7)
      final controller = StreamController<List<Notificacion>>();
      await tester.pumpWidget(
        createTestApp(
          fakeAuth: fakeAuth,
          notifications: [],
          notificationsStream: controller.stream,
        ),
      );

      // Usar pump() en lugar de pumpAndSettle()
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'muestra lista de notificaciones con diferenciación leída/no leída',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(fakeAuth: fakeAuth, notifications: testNotifications),
        );

        // Usar pump() en lugar de pumpAndSettle()
        await tester.pump();

        // Debe mostrar 3 notificaciones
        expect(find.byType(NotificationCard), findsNWidgets(3));

        // Verificar que están diferenciadas visualmente (no leídas por defecto)
        final cards = tester.widgetList<NotificationCard>(
          find.byType(NotificationCard),
        );
        expect(cards.every((c) => !c.leida), isTrue);
      },
    );

    testWidgets('al tocar notificación con reportId navega al detalle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(fakeAuth: fakeAuth, notifications: testNotifications),
      );

      await tester.pump();

      // Tocar la primera notificación
      await tester.tap(find.byType(NotificationCard).first);
      await tester.pump();

      // Debe navegar al detalle
      expect(find.text('Detalle rep-1'), findsOneWidget);
    });

    testWidgets('lista vacía muestra mensaje correspondiente', (
      WidgetTester tester,
    ) async {
      // Notificaciones vacías
      await tester.pumpWidget(
        createTestApp(fakeAuth: fakeAuth, notifications: []),
      );

      await tester.pump();

      expect(find.text('No tienes notificaciones'), findsOneWidget);
    });
  });
}
