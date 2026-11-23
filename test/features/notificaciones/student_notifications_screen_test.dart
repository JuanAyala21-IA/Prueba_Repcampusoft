import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'package:repcampusoft/core/routes/app_router.dart';
import 'package:repcampusoft/core/routes/session_provider.dart';
import 'package:repcampusoft/core/utils/mes_anio.dart';
import 'package:repcampusoft/features/auth/data/providers/auth_providers.dart';
import 'package:repcampusoft/features/auth/domain/rol_enum.dart';
import 'package:repcampusoft/features/auth/domain/usuario.dart';
import 'package:repcampusoft/features/notificaciones/data/providers/notificacion_providers.dart';
import 'package:repcampusoft/features/notificaciones/data/local_notificaciones_service.dart';
import 'package:repcampusoft/features/notificaciones/domain/notificacion.dart';
import 'package:repcampusoft/features/notificaciones/presentation/student_notifications_screen.dart';
import 'package:repcampusoft/shared/widgets/bell_badge.dart';
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
      // Override de la familia por mes con datos fijos; reproduce el filtro de
      // rango que hace el repositorio real.
      notificacionesEstudianteMesProvider.overrideWith((ref, mes) {
        if (notificationsStream != null) return notificationsStream;
        return Stream.value(
          notifications
              .where((n) => mes.contiene(n.creadoEn.toDate()))
              .toList(),
        );
      }),
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

    Notificacion notifPrevioMes({required String id, required String titulo}) {
      return Notificacion(
        id: id,
        tipo: NotificacionTipo.reporte,
        titulo: titulo,
        mensaje: 'Mensaje de $titulo',
        reportId: 'rep-previo',
        evento: NotificacionEvento.creado,
        uidDestino: 'test-student-uid',
        creadoEn: Timestamp.fromDate(
          MesAnio.actual().anterior.inicio.add(const Duration(days: 14)),
        ),
        leida: false,
      );
    }

    testWidgets(
      'muestra el selector del mes y solo notificaciones del mes actual',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(fakeAuth: fakeAuth, notifications: testNotifications),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('${MesAnio.actual().etiqueta} (mes actual)'),
          findsOneWidget,
        );
        expect(find.text('Reporte recibido'), findsOneWidget);
        expect(find.text('Reporte Solucionado'), findsOneWidget);
      },
    );

    testWidgets('no muestra notificaciones de meses anteriores por defecto', (
      WidgetTester tester,
    ) async {
      final List<Notificacion> mesAnterior = [
        notifPrevioMes(id: 'notif-old-1', titulo: 'Reporte del mes pasado'),
        notifPrevioMes(id: 'notif-old-2', titulo: 'Otra del mes pasado'),
      ];
      await tester.pumpWidget(
        createTestApp(fakeAuth: fakeAuth, notifications: mesAnterior),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotificationCard), findsNothing);
      expect(find.text('No tienes notificaciones'), findsOneWidget);
    });

    testWidgets(
      'muestra notificaciones de meses anteriores tras seleccionar el mes',
      (WidgetTester tester) async {
        final DateTime mesAnterior = MesAnio.actual().anterior.inicio;
        final Notificacion old = Notificacion(
          id: 'notif-mes-anterior',
          tipo: NotificacionTipo.reporte,
          titulo: 'Reporte mes pasado',
          mensaje: 'Mensaje del mes pasado',
          reportId: 'rep-previo',
          evento: NotificacionEvento.creado,
          uidDestino: 'test-student-uid',
          creadoEn: Timestamp.fromDate(mesAnterior.toLocal()),
          leida: false,
        );
        await tester.pumpWidget(
          createTestApp(
            fakeAuth: fakeAuth,
            notifications: <Notificacion>[testNotifications.first, old],
          ),
        );
        await tester.pumpAndSettle();

        // Por defecto: el mes actual, con una tarjeta visible y el selector
        // apuntando al mes actual.
        expect(find.byType(NotificationCard), findsOneWidget);
        expect(find.text('Reporte recibido'), findsOneWidget);
        expect(find.text('Reporte mes pasado'), findsNothing);

        // Abrir el selector y elegir el mes anterior.
        final String etiquetaMesAnterior = MesAnio.desde(mesAnterior).etiqueta;
        await tester.tap(find.byType(DropdownButton<MesAnio>));
        await tester.pumpAndSettle();
        expect(find.text(etiquetaMesAnterior), findsOneWidget);
        await tester.tap(find.text(etiquetaMesAnterior));
        await tester.pumpAndSettle();

        // Ahora se ve la notificación del mes pasado y ya no la del actual.
        expect(find.text('Reporte mes pasado'), findsOneWidget);
        expect(find.text('Reporte recibido'), findsNothing);
      },
    );

    testWidgets(
      'el badge cuenta solo notificaciones no leídas del mes actual',
      (WidgetTester tester) async {
        final Notificacion notifActual1 = testNotifications.first;
        final Notificacion notifActual2 = testNotifications[1];
        final Notificacion notifPrevio1 = notifPrevioMes(
          id: 'notif-old-unread-1',
          titulo: 'Previo sin leer 1',
        );
        final Notificacion notifPrevio2 = notifPrevioMes(
          id: 'notif-old-unread-2',
          titulo: 'Previo sin leer 2',
        );
        await tester.pumpWidget(
          createTestApp(
            fakeAuth: fakeAuth,
            notifications: [
              notifActual1,
              notifActual2,
              notifPrevio1,
              notifPrevio2,
            ],
          ),
        );
        await tester.pumpAndSettle();

        final BellBadge badge = tester.widget<BellBadge>(
          find.byType(BellBadge),
        );
        expect(badge.conteo, 2);
      },
    );
  });
}
