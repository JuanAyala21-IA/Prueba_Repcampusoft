import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:repcampusoft/features/notificaciones/domain/notificacion.dart';

import '../../fakes/fake_notificacion_repository.dart';

void main() {
  group('FakeNotificacionRepository', () {
    late FakeFirebaseFirestore firestore;
    late FakeNotificacionRepository repo;
    const String testUid = 'student-uid';
    const String adminUid = 'admin-uid';

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = FakeNotificacionRepository(firestore: firestore);
    });

    Future<void> seedNotifications({
      required String uid,
      required bool isAdmin,
      List<Map<String, dynamic>>? customNotifications,
    }) async {
      final notifications =
          customNotifications ??
          [
            {
              'id': 'notif-1',
              'tipo': 'reporte',
              'titulo': 'Reporte recibido',
              'mensaje': 'Tu reporte ha sido recibido',
              'reportId': 'rep-1',
              'evento': 'creado',
              'uidDestino': uid,
              'destinoRol': null,
              'autorUid': 'admin-1',
              'creadoEn': Timestamp.fromDate(
                DateTime.now().subtract(const Duration(hours: 2)),
              ),
            },
            {
              'id': 'notif-2',
              'tipo': 'reporte',
              'titulo': 'Reporte en proceso',
              'mensaje': 'Tu reporte está en proceso',
              'reportId': 'rep-1',
              'evento': 'en_proceso',
              'uidDestino': uid,
              'destinoRol': null,
              'autorUid': 'admin-1',
              'creadoEn': Timestamp.fromDate(
                DateTime.now().subtract(const Duration(hours: 1)),
              ),
            },
            {
              'id': 'notif-3',
              'tipo': 'administrativo',
              'titulo': 'Aviso administrativo',
              'mensaje': 'Mantenimiento programado',
              'reportId': null,
              'evento': null,
              'uidDestino': null,
              'destinoRol': 'administrativo',
              'autorUid': 'admin-2',
              'creadoEn': Timestamp.fromDate(DateTime.now()),
            },
          ];

      final batch = firestore.batch();
      for (int i = 0; i < notifications.length; i++) {
        final notif = Map<String, dynamic>.from(notifications[i]);
        final id = notif.remove('id') as String;
        batch.set(firestore.collection('notifications').doc(id), notif);
      }
      await batch.commit();
    }

    Future<void> markAsRead(String uid, String notifId) async {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('notificacionesLeidas')
          .doc(notifId)
          .set({'leida': true, 'leidaEn': Timestamp.now()});
    }

    test(
      'watchNotificacionesEstudiante emite lista inicial con leida=false',
      () async {
        await seedNotifications(uid: testUid, isAdmin: false);

        final stream = repo.watchNotificacionesEstudiante(testUid);
        final firstEmission = await stream.first;

        expect(firstEmission.length, 2); // Solo las de uidDestino == testUid
        expect(
          firstEmission.any((n) => n.id == 'notif-3'),
          isFalse,
        ); // notif-3 es broadcast
        expect(firstEmission.every((n) => !n.leida), isTrue);
      },
    );

    test(
      'watchNotificacionesAdmin emite broadcast + propias (si las hay)',
      () async {
        await seedNotifications(uid: adminUid, isAdmin: true);

        final stream = repo.watchNotificacionesAdmin(adminUid);
        final firstEmission = await stream.first;

        // Admin ve todas las broadcast (notif-3) + las suyas (ninguna en seed)
        expect(firstEmission.length, 1);
        expect(firstEmission.first.id, 'notif-3');
        expect(firstEmission.first.tipo, NotificacionTipo.administrativo);
      },
    );

    test(
      'watchNotificacionesAdmin con filtroTipo filtra correctamente',
      () async {
        await seedNotifications(uid: adminUid, isAdmin: true);

        final stream = repo.watchNotificacionesAdmin(
          adminUid,
          filtroTipo: 'reporte',
        );
        final firstEmission = await stream.first;

        expect(
          firstEmission.length,
          0,
        ); // notif-3 es administrativo, no reporte
      },
    );

    test('marcarLeida actualiza notificacionesLeidas y stream reacciona en tiempo real', () async {
      await seedNotifications(uid: testUid, isAdmin: false);

      final stream = repo.watchNotificacionesEstudiante(testUid);

      // Primera emisión: todas no leídas
      final initial = await stream.first;
      expect(initial.every((n) => !n.leida), isTrue);

      // Marcar una como leída
      await markAsRead(testUid, 'notif-1');

      // Segunda emisión: notif-1 debe estar leída
      final afterRead = await stream.skip(1).first;
      final notif1 = afterRead.firstWhere((n) => n.id == 'notif-1');
      expect(notif1.leida, isTrue);
    });

    test('stream combinado emite segunda lista cuando notificacionesLeidas cambia DESPUÉS de primera emisión (bug fix)', () async {
      await seedNotifications(uid: testUid, isAdmin: false);

      final stream = repo.watchNotificacionesEstudiante(testUid);
      final emissions = <List<Notificacion>>[];

      final subscription = stream.listen((data) {
        emissions.add(data);
      });

      // Esperar primera emisión (puede haber varias por carga inicial + streams)
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(emissions.length, greaterThanOrEqualTo(1));
      expect(emissions.last.every((n) => !n.leida), isTrue);

      // Marcar como leída DESPUÉS de la primera emisión
      await markAsRead(testUid, 'notif-1');

      // Esperar que emita una lista con leida=true
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
        emissions.length,
        greaterThanOrEqualTo(2),
        reason: 'El stream debe emitir una segunda lista al cambiar notificacionesLeidas',
      );

      final lastEmission = emissions.last;
      final notif1 = lastEmission.firstWhere((n) => n.id == 'notif-1');
      expect(
        notif1.leida,
        isTrue,
        reason: 'La notificación marcada como leída debe reflejarse en la emisión final',
      );

      await subscription.cancel();
    });

    test(
      'watchContadorNoLeidasEstudiante refleja cambios en tiempo real',
      () async {
        await seedNotifications(uid: testUid, isAdmin: false);

        final counterStream = repo.watchContadorNoLeidasEstudiante(testUid);
        final counts = <int>[];

        final sub = counterStream.listen((total) => counts.add(total));

        // Esperar primera emisión (puede haber varias por carga inicial + streams)
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(counts.length, greaterThanOrEqualTo(1));
        expect(counts.last, 2);

        // Marcar una como leída
        await markAsRead(testUid, 'notif-1');

        // Esperar que emita 1 no leída
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(counts.length, greaterThanOrEqualTo(2));
        expect(counts.last, 1);

        await sub.cancel();
      },
    );
  });
}
