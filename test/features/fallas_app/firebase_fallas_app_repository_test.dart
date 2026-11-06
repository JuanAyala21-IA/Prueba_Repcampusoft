import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/features/fallas_app/data/app_metadata.dart';
import 'package:repcampusoft/features/fallas_app/data/firebase_fallas_app_repository.dart';

void main() {
  group('FirebaseFallasAppRepository.reportar', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late FirebaseFallasAppRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'test-uid', email: 'test@uts.edu.co'),
        signedIn: true,
      );
      repository = FirebaseFallasAppRepository(
        firestore: fakeFirestore,
        auth: mockAuth,
        cargarMetadata: () async => const AppMetadata(
          plataforma: 'Android',
          sistemaOperativo: 'Android 14 (API 34)',
          dispositivo: 'samsung SM-A155M',
          versionApp: '1.0.0+1',
        ),
      );
    });

    test('guarda uid, correo, mensaje, pantalla y creadoEn', () async {
      await repository.reportar(
        mensaje: 'El botón Enviar no responde',
        pantalla: 'Reportar daños',
      );

      final snap = await fakeFirestore.collection('fallas_app').get();
      expect(snap.docs, hasLength(1));
      final data = snap.docs.first.data();
      expect(data['uid'], 'test-uid');
      expect(data['correo'], 'test@uts.edu.co');
      expect(data['mensaje'], 'El botón Enviar no responde');
      expect(data['pantalla'], 'Reportar daños');
      expect(data['creadoEn'], isNotNull);
    });

    test(
      'captura automáticamente los datos del dispositivo y la versión',
      () async {
        await repository.reportar(mensaje: 'Se cierra sola');

        final snap = await fakeFirestore.collection('fallas_app').get();
        final data = snap.docs.first.data();
        expect(data['plataforma'], 'Android');
        expect(data['sistemaOperativo'], 'Android 14 (API 34)');
        expect(data['dispositivo'], 'samsung SM-A155M');
        expect(data['versionApp'], '1.0.0+1');
      },
    );

    test('omite los datos técnicos que no se pudieron obtener', () async {
      final sinMetadata = FirebaseFallasAppRepository(
        firestore: fakeFirestore,
        auth: mockAuth,
        cargarMetadata: () async => const AppMetadata(),
      );
      await sinMetadata.reportar(mensaje: 'Se cierra sola');

      final snap = await fakeFirestore.collection('fallas_app').get();
      final data = snap.docs.first.data();
      expect(data.containsKey('plataforma'), isFalse);
      expect(data.containsKey('sistemaOperativo'), isFalse);
      expect(data.containsKey('dispositivo'), isFalse);
      expect(data.containsKey('versionApp'), isFalse);
    });

    test('crea aviso en notifications para el superadministrador', () async {
      await repository.reportar(mensaje: 'Se cierra sola');

      final fallaSnap = await fakeFirestore.collection('fallas_app').get();
      final fallaId = fallaSnap.docs.first.id;

      final notifSnap = await fakeFirestore.collection('notifications').get();
      expect(notifSnap.docs, hasLength(1));
      final notif = notifSnap.docs.first;
      expect(notif.id, '${fallaId}_falla');
      expect(notif.data()['tipo'], 'sistema');
      expect(notif.data()['titulo'], 'Nueva falla de la app');
      expect(notif.data()['mensaje'], 'Se cierra sola');
      expect(notif.data()['destinoRol'], 'superadministrador');
      expect(notif.data()['fallaId'], fallaId);
      expect(notif.data()['autorUid'], 'test-uid');
    });

    test('sin pantalla omite el campo', () async {
      await repository.reportar(mensaje: 'Se cierra sola');

      final snap = await fakeFirestore.collection('fallas_app').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first.data().containsKey('pantalla'), isFalse);
    });

    test('mensaje vacío lanza ArgumentError y no guarda', () async {
      expect(() => repository.reportar(mensaje: '   '), throwsArgumentError);
      final snap = await fakeFirestore.collection('fallas_app').get();
      expect(snap.docs, isEmpty);
    });

    test('sin sesión lanza StateError', () async {
      final signedOut = FirebaseFallasAppRepository(
        firestore: fakeFirestore,
        auth: MockFirebaseAuth(signedIn: false),
      );
      expect(() => signedOut.reportar(mensaje: 'Falla'), throwsStateError);
    });
  });

  group('FirebaseFallasAppRepository.watchFallas', () {
    test('emite la lista ordenada por creadoEn descendente', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'test-uid', email: 'test@uts.edu.co'),
        signedIn: true,
      );
      final repository = FirebaseFallasAppRepository(
        firestore: fakeFirestore,
        auth: mockAuth,
      );

      // Se escriben fechas explícitas: con `reportar` las dos fallas podrían
      // recibir el mismo `serverTimestamp` y el orden quedaría indefinido.
      await fakeFirestore.collection('fallas_app').doc('antigua').set({
        'uid': 'test-uid',
        'correo': 'test@uts.edu.co',
        'mensaje': 'Primera falla',
        'creadoEn': Timestamp.fromDate(DateTime(2026, 1, 1, 8)),
      });
      await fakeFirestore.collection('fallas_app').doc('nueva').set({
        'uid': 'test-uid',
        'correo': 'test@uts.edu.co',
        'mensaje': 'Segunda falla',
        'creadoEn': Timestamp.fromDate(DateTime(2026, 1, 2, 8)),
      });

      final fallas = await repository.watchFallas().first;
      expect(fallas, hasLength(2));
      expect(fallas.first.mensaje, 'Segunda falla');
      expect(fallas.last.mensaje, 'Primera falla');
    });
  });
}
