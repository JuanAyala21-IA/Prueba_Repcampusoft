import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/core/constants/catalogo_espacios.dart';
import 'package:repcampusoft/core/utils/results.dart';
import 'package:repcampusoft/features/reportes/data/firebase_reporte_repository.dart';
import 'package:repcampusoft/features/reportes/domain/reporte.dart';

import '../../../fakes/fake_almacenamiento_imagen.dart';

/// Fake compartido de Storage; los paths incluyen el reportId, así que no hay
/// colisiones entre pruebas.
final FakeAlmacenamientoImagen almacenamientoFake = FakeAlmacenamientoImagen();

void main() {
  group('FirebaseReporteRepository.crear', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late FirebaseReporteRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'test-uid', email: 'test@example.com'),
        signedIn: true,
      );
      repository = FirebaseReporteRepository(
        firestore: fakeFirestore,
        auth: mockAuth,
        almacenamiento: almacenamientoFake,
      );
    });

    test(
      'Sin foto: crea reports, historial y notificación con campos exactos',
      () async {
        final borrador = BorradorReporte(
          tipoUbicacion: TipoEspacio.aula,
          tipoDano: 'Grieta',
          edificio: 'Edificio A',
          piso: 'Piso 1',
          espacio: 'Salón 101',
          descripcion: 'Grieta en la pared',
          fotoBase64: null,
        );

        final result = await repository.crear(borrador);

        expect(result, isA<Success<String>>());
        final reportId = (result as Success<String>).value;

        // Verificar reports/{reportId}
        final reportDoc = await fakeFirestore
            .collection('reports')
            .doc(reportId)
            .get();
        expect(reportDoc.exists, isTrue);
        final reportData = reportDoc.data()!;
        expect(reportData['uid'], 'test-uid');
        expect(reportData['correoAutor'], 'test@example.com');
        expect(reportData['tipoDano'], 'Grieta');
        expect(reportData['tipoUbicacion'], 'aula');
        expect(reportData['edificio'], 'Edificio A');
        expect(reportData['piso'], 'Piso 1');
        expect(reportData['espacio'], 'Salón 101');
        expect(reportData['referencia'], isNull);
        expect(reportData['ubicacionTexto'], 'Edificio A · Piso 1 · Salón 101');
        expect(reportData.containsKey('salon'), isFalse);
        expect(reportData['descripcion'], 'Grieta en la pared');
        expect(reportData['estado'], 'Pendiente');
        expect(reportData['tieneFoto'], false);
        expect(reportData['creadoEn'], isNotNull);

        // Verificar historial/{reportId}_inicial
        final historialDoc = await fakeFirestore
            .collection('reports')
            .doc(reportId)
            .collection('historial')
            .doc('${reportId}_inicial')
            .get();
        expect(historialDoc.exists, isTrue);
        final historialData = historialDoc.data()!;
        expect(historialData['estadoAnterior'], 'Pendiente');
        expect(historialData['estadoNuevo'], 'Pendiente');
        expect(historialData['creadoEn'], isNotNull);

        // Verificar notifications/{reportId}_creado
        final notifDoc = await fakeFirestore
            .collection('notifications')
            .doc('${reportId}_creado')
            .get();
        expect(notifDoc.exists, isTrue);
        final notifData = notifDoc.data()!;
        expect(notifData['tipo'], 'reporte');
        expect(notifData['titulo'], 'Nuevo reporte de dano');
        expect(notifData['reportId'], reportId);
        expect(notifData['evento'], 'creado');
        expect(notifData['estadoNuevo'], 'Pendiente');
        expect(notifData['uidDestino'], isNull);
        expect(notifData['destinoRol'], 'administrativo');
        expect(notifData['autorUid'], 'test-uid');
        expect(notifData['creadoEn'], isNotNull);

        // Verificar que NO existe media/foto
        final mediaDoc = await fakeFirestore
            .collection('reports')
            .doc(reportId)
            .collection('media')
            .doc('foto')
            .get();
        expect(mediaDoc.exists, isFalse);
      },
    );

    test(
      'Con foto: sube a Storage y crea media/foto con ruta, tamaño y mimeType',
      () async {
        final base64Image = base64Encode(List<int>.filled(1000, 0xFF));
        final borrador = BorradorReporte(
          tipoUbicacion: TipoEspacio.laboratorio,
          tipoDano: 'Humedad',
          edificio: 'Edificio B',
          piso: 'Piso 2',
          espacio: 'Laboratorio de Química',
          referencia: 'Junto a la ventana',
          descripcion: 'Mancha de humedad',
          fotoBase64: base64Image,
        );

        final result = await repository.crear(borrador);

        expect(result, isA<Success<String>>());
        final reportId = (result as Success<String>).value;

        // Verificar media/foto
        final mediaDoc = await fakeFirestore
            .collection('reports')
            .doc(reportId)
            .collection('media')
            .doc('foto')
            .get();
        expect(mediaDoc.exists, isTrue);
        final mediaData = mediaDoc.data()!;
        expect(mediaData['storagePath'], 'reports/$reportId/foto.jpg');
        expect(
          mediaData['downloadUrl'],
          contains('reports/$reportId/foto.jpg'),
        );
        expect(mediaData['base64'], isNull);
        expect(mediaData['tamanoBytes'], 1000);
        expect(mediaData['mimeType'], 'image/jpeg');
        expect(mediaData['creadoEn'], isNotNull);
        expect(
          almacenamientoFake.objetos['reports/$reportId/foto.jpg']?.length,
          1000,
        );

        // Verificar que reports.tieneFoto == true
        final reportsQuery = await fakeFirestore.collection('reports').get();
        expect(reportsQuery.docs.length, 1);
        final reportData = reportsQuery.docs.first.data();
        expect(reportData['tieneFoto'], true);
      },
    );

    test(
      'Baño: persiste tipoUbicacion, espacio y ubicacionTexto sin salón',
      () async {
        final borrador = BorradorReporte(
          tipoUbicacion: TipoEspacio.bano,
          edificio: 'Edificio A',
          piso: 'Piso 2',
          espacio: 'Baño de mujeres',
          referencia: 'Junto a las escaleras',
          tipoDano: 'Sanitario dañado',
          descripcion: 'Sanitario tapado',
        );

        final result = await repository.crear(borrador);
        expect(result, isA<Success<String>>());
        final reportId = (result as Success<String>).value;

        final reportData =
            (await fakeFirestore.collection('reports').doc(reportId).get())
                .data()!;
        expect(reportData['tipoUbicacion'], 'bano');
        expect(reportData['edificio'], 'Edificio A');
        expect(reportData['piso'], 'Piso 2');
        expect(reportData['espacio'], 'Baño de mujeres');
        expect(reportData['referencia'], 'Junto a las escaleras');
        expect(
          reportData['ubicacionTexto'],
          'Edificio A · Piso 2 · Baño de mujeres',
        );
        expect(reportData.containsKey('salon'), isFalse);
      },
    );

    test(
      'Zona exterior: no persiste edificio/piso y exige referencia',
      () async {
        final borrador = BorradorReporte(
          tipoUbicacion: TipoEspacio.zonaExterior,
          espacio: 'Jardines',
          referencia: 'Frente al Edificio B',
          tipoDano: 'Banca dañada',
          descripcion: 'Banca rota',
        );

        final result = await repository.crear(borrador);
        expect(result, isA<Success<String>>());
        final reportId = (result as Success<String>).value;

        final reportData =
            (await fakeFirestore.collection('reports').doc(reportId).get())
                .data()!;
        expect(reportData['tipoUbicacion'], 'zona_exterior');
        expect(reportData.containsKey('edificio'), isFalse);
        expect(reportData.containsKey('piso'), isFalse);
        expect(reportData['espacio'], 'Jardines');
        expect(reportData['referencia'], 'Frente al Edificio B');
        expect(
          reportData['ubicacionTexto'],
          'Zona exterior · Jardines · Frente al Edificio B',
        );
      },
    );

    test('Foto > 704640 bytes: devuelve Failure sin escribir nada', () async {
      final largeBase64 = base64Encode(List<int>.filled(800000, 0xFF));
      final borrador = BorradorReporte(
        tipoUbicacion: TipoEspacio.aula,
        tipoDano: 'Test',
        edificio: 'Edificio C',
        piso: 'Piso 1',
        espacio: 'Salón 303',
        descripcion: 'Test foto grande',
        fotoBase64: largeBase64,
      );

      final result = await repository.crear(borrador);

      expect(result, isA<Failure<String>>());
      expect(
        (result as Failure<String>).message,
        'La foto es demasiado grande',
      );

      // Verificar que NO se escribió nada en Firestore
      expect((await fakeFirestore.collection('reports').get()).docs, isEmpty);
      expect(
        (await fakeFirestore.collection('notifications').get()).docs,
        isEmpty,
      );
    });

    test('PERMISSION_DENIED en batch.commit con reporte existente y mismo uid -> Success (omitido)', () async {
      // FakeCloudFirestore no simula PERMISSION_DENIED en batch.commit de forma nativa.
      // Se omite la simulación completa por limitación del fake (punto 4 de la tarea).
    });
  });

  group('FirebaseReporteRepository.watchMisReportes', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late FirebaseReporteRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'user-1', email: 'user1@example.com'),
        signedIn: true,
      );
      repository = FirebaseReporteRepository(
        firestore: fakeFirestore,
        auth: mockAuth,
        almacenamiento: almacenamientoFake,
      );
    });

    test('devuelve solo reportes del uid actual, ordenados por creadoEn descendente', () async {
      // Crear 3 reportes: 2 del usuario actual, 1 de otro usuario
      final batch = fakeFirestore.batch();
      final now = DateTime.now();

      // Reporte 1 del usuario actual (más antiguo)
      final doc1 = fakeFirestore.collection('reports').doc();
      batch.set(doc1, {
        'uid': 'user-1',
        'correoAutor': 'user1@example.com',
        'tipoDano': 'Grieta',
        'edificio': 'A',
        'piso': '1',
        'salon': '101',
        'descripcion': 'Grieta 1',
        'estado': 'Pendiente',
        'tieneFoto': false,
        'creadoEn': now.subtract(const Duration(days: 2)),
      });

      // Reporte 2 del usuario actual (más reciente)
      final doc2 = fakeFirestore.collection('reports').doc();
      batch.set(doc2, {
        'uid': 'user-1',
        'correoAutor': 'user1@example.com',
        'tipoDano': 'Humedad',
        'edificio': 'B',
        'piso': '2',
        'salon': '202',
        'descripcion': 'Humedad 2',
        'estado': 'En revision',
        'tieneFoto': false,
        'creadoEn': now.subtract(const Duration(days: 1)),
      });

      // Reporte 3 de OTRO usuario (no debe aparecer)
      final doc3 = fakeFirestore.collection('reports').doc();
      batch.set(doc3, {
        'uid': 'user-2',
        'correoAutor': 'user2@example.com',
        'tipoDano': 'Fuga',
        'edificio': 'C',
        'piso': '3',
        'salon': '303',
        'descripcion': 'Fuga 3',
        'estado': 'Solucionado',
        'tieneFoto': false,
        'creadoEn': now,
      });

      await batch.commit();

      final stream = repository.watchMisReportes();
      final reportes = await stream.first;

      expect(reportes.length, 2);
      // Orden descendente por creadoEn: el más reciente primero
      expect(reportes[0].tipoDano, 'Humedad');
      expect(reportes[1].tipoDano, 'Grieta');
      expect(reportes[0].uid, 'user-1');
      expect(reportes[1].uid, 'user-1');
    });

    test('devuelve lista vacía si no hay reportes del usuario', () async {
      final stream = repository.watchMisReportes();
      final reportes = await stream.first;
      expect(reportes, isEmpty);
    });
  });

  group('FirebaseReporteRepository.watchReporteById', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late FirebaseReporteRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'user-1', email: 'user1@example.com'),
        signedIn: true,
      );
      repository = FirebaseReporteRepository(
        firestore: fakeFirestore,
        auth: mockAuth,
        almacenamiento: almacenamientoFake,
      );
    });

    test('devuelve el reporte correcto por id', () async {
      final docRef = fakeFirestore.collection('reports').doc('test-report-id');
      await docRef.set({
        'uid': 'user-1',
        'correoAutor': 'user1@example.com',
        'tipoDano': 'Grieta',
        'edificio': 'A',
        'piso': '1',
        'salon': '101',
        'descripcion': 'Grieta en la pared',
        'estado': 'En proceso',
        'tieneFoto': true,
        'creadoEn': DateTime.now(),
      });

      final stream = repository.watchReporteById('test-report-id');
      final reporte = await stream.first;

      expect(reporte, isNotNull);
      expect(reporte!.reporteId, 'test-report-id');
      expect(reporte.tipoDano, 'Grieta');
      expect(reporte.estado.valorFirestore, 'En proceso');
      expect(reporte.tieneFoto, true);
      // Compatibilidad: documento antiguo solo con `salon`.
      expect(reporte.tipoUbicacion, TipoEspacio.aula);
      expect(reporte.espacio, 'Salón 101');
      expect(reporte.ubicacionTexto, 'A · 1 · Salón 101');
    });

    test('devuelve null si el reporte no existe', () async {
      final stream = repository.watchReporteById('no-existe');
      final reporte = await stream.first;
      expect(reporte, isNull);
    });
  });

  group('FirebaseReporteRepository.watchHistorial', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late FirebaseReporteRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'user-1', email: 'user1@example.com'),
        signedIn: true,
      );
      repository = FirebaseReporteRepository(
        firestore: fakeFirestore,
        auth: mockAuth,
        almacenamiento: almacenamientoFake,
      );
    });

    test(
      'devuelve entradas de historial ordenadas por fecha ascendente',
      () async {
        final reportId = 'report-with-historial';
        final now = DateTime.now();

        // Crear reporte padre
        await fakeFirestore.collection('reports').doc(reportId).set({
          'uid': 'user-1',
          'correoAutor': 'user1@example.com',
          'tipoDano': 'Test',
          'edificio': 'A',
          'piso': '1',
          'salon': '101',
          'descripcion': 'Test',
          'estado': 'Solucionado',
          'tieneFoto': false,
          'creadoEn': now.subtract(const Duration(days: 3)),
        });

        // Crear 3 entradas de historial en orden desordenado
        final batch = fakeFirestore.batch();
        batch.set(
          fakeFirestore
              .collection('reports')
              .doc(reportId)
              .collection('historial')
              .doc('h3'),
          {
            'estadoAnterior': 'En revision',
            'estadoNuevo': 'Solucionado',
            'creadoEn': now,
          },
        );
        batch.set(
          fakeFirestore
              .collection('reports')
              .doc(reportId)
              .collection('historial')
              .doc('h1'),
          {
            'estadoAnterior': 'Pendiente',
            'estadoNuevo': 'En revision',
            'creadoEn': now.subtract(const Duration(days: 2)),
          },
        );
        batch.set(
          fakeFirestore
              .collection('reports')
              .doc(reportId)
              .collection('historial')
              .doc('h2'),
          {
            'estadoAnterior': 'Pendiente',
            'estadoNuevo': 'En proceso',
            'creadoEn': now.subtract(const Duration(days: 1)),
          },
        );
        await batch.commit();

        final stream = repository.watchHistorial(reportId);
        final historial = await stream.first;

        expect(historial.length, 3);
        // Orden ascendente por creadoEn
        expect(historial[0].estadoAnterior.valorFirestore, 'Pendiente');
        expect(historial[0].estadoNuevo.valorFirestore, 'En revision');
        expect(historial[1].estadoAnterior.valorFirestore, 'Pendiente');
        expect(historial[1].estadoNuevo.valorFirestore, 'En proceso');
        expect(historial[2].estadoAnterior.valorFirestore, 'En revision');
        expect(historial[2].estadoNuevo.valorFirestore, 'Solucionado');
      },
    );

    test('devuelve lista vacía si no hay historial', () async {
      final stream = repository.watchHistorial('report-sin-historial');
      final historial = await stream.first;
      expect(historial, isEmpty);
    });
  });

  group('FirebaseReporteRepository.cambiarEstado', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late FirebaseReporteRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'admin-uid', email: 'admin@example.com'),
        signedIn: true,
      );
      repository = FirebaseReporteRepository(
        firestore: fakeFirestore,
        auth: mockAuth,
        almacenamiento: almacenamientoFake,
      );
    });

    Future<void> crearReporteInicial({
      required String reportId,
      required String estadoInicial,
      required String uidAutor,
    }) async {
      final now = DateTime.now();
      await fakeFirestore.collection('reports').doc(reportId).set({
        'uid': uidAutor,
        'correoAutor': 'autor@example.com',
        'tipoDano': 'Silla dañada',
        'edificio': 'Edificio A',
        'piso': 'Piso 4',
        'salon': '402 A',
        'descripcion': 'Silla con tornillos sueltos',
        'estado': estadoInicial,
        'tieneFoto': false,
        'creadoEn': now.subtract(const Duration(days: 1)),
      });
      // Historial inicial
      await fakeFirestore
          .collection('reports')
          .doc(reportId)
          .collection('historial')
          .doc('${reportId}_inicial')
          .set({
            'estadoAnterior': 'Pendiente',
            'estadoNuevo': 'Pendiente',
            'creadoEn': now.subtract(const Duration(days: 1)),
          });
    }

    test('Transición válida (Pendiente -> En revision) con observación: actualiza estado, crea historial y notificación con IDs correctos', () async {
      const reportId = 'test-report-1';
      await crearReporteInicial(
        reportId: reportId,
        estadoInicial: 'Pendiente',
        uidAutor: 'autor-uid',
      );

      final result = await repository.cambiarEstado(
        reportId: reportId,
        estadoNuevo: 'En revision',
        observacion: 'En revisión por mantenimiento',
      );

      expect(result, isA<Success<void>>());

      // Verificar reports/{reportId} actualizado
      final reportDoc = await fakeFirestore
          .collection('reports')
          .doc(reportId)
          .get();
      expect(reportDoc.exists, isTrue);
      final reportData = reportDoc.data()!;
      expect(reportData['estado'], 'En revision');
      expect(reportData['observacionAdmin'], 'En revisión por mantenimiento');
      expect(reportData['actualizadoEn'], isNotNull);

      // Verificar historial creado con ID determinista: {reportId}_En revision
      final historialDoc = await fakeFirestore
          .collection('reports')
          .doc(reportId)
          .collection('historial')
          .doc('${reportId}_En revision')
          .get();
      expect(historialDoc.exists, isTrue);
      final historialData = historialDoc.data()!;
      expect(historialData['estadoAnterior'], 'Pendiente');
      expect(historialData['estadoNuevo'], 'En revision');
      expect(historialData['observacion'], 'En revisión por mantenimiento');
      expect(historialData['creadoEn'], isNotNull);

      // Verificar notificación creada con ID determinista: {reportId}_en_revision (evento snake_case)
      final notifDoc = await fakeFirestore
          .collection('notifications')
          .doc('${reportId}_en_revision')
          .get();
      expect(notifDoc.exists, isTrue);
      final notifData = notifDoc.data()!;
      expect(notifData['tipo'], 'reporte');
      expect(notifData['titulo'], 'Reporte en revisión');
      expect(notifData['reportId'], reportId);
      expect(notifData['evento'], 'en_revision');
      expect(notifData['estadoNuevo'], 'En revision');
      expect(notifData['uidDestino'], 'autor-uid');
      expect(notifData['destinoRol'], isNull);
      expect(notifData['autorUid'], 'admin-uid');
      expect(notifData['creadoEn'], isNotNull);
      // Documento legado: la notificación reconstruye la ubicación.
      expect(
        notifData['mensaje'],
        contains('Edificio A · Piso 4 · Salón 402 A'),
      );
    });

    test('Transición inválida (Pendiente -> Solucionado, saltando pasos): devuelve Failure sin escribir nada', () async {
      const reportId = 'test-report-2';
      await crearReporteInicial(
        reportId: reportId,
        estadoInicial: 'Pendiente',
        uidAutor: 'autor-uid',
      );

      final result = await repository.cambiarEstado(
        reportId: reportId,
        estadoNuevo: 'Solucionado',
        observacion: 'Observación',
      );

      expect(result, isA<Failure<void>>());
      expect(
        (result as Failure<void>).message,
        contains('Transición no permitida'),
      );

      // Verificar que NO se escribió nada (estado sigue siendo Pendiente)
      final reportDoc = await fakeFirestore
          .collection('reports')
          .doc(reportId)
          .get();
      expect(reportDoc.data()!['estado'], 'Pendiente');

      // Verificar que NO se creó historial adicional
      final historialQuery = await fakeFirestore
          .collection('reports')
          .doc(reportId)
          .collection('historial')
          .get();
      expect(historialQuery.docs.length, 1); // Solo el inicial

      // Verificar que NO se creó notificación
      final notifQuery = await fakeFirestore.collection('notifications').get();
      expect(notifQuery.docs, isEmpty);
    });

    test(
      'Estado desconocido: devuelve Failure y no cambia el estado',
      () async {
        const reportId = 'test-report-3';
        await crearReporteInicial(
          reportId: reportId,
          estadoInicial: 'Pendiente',
          uidAutor: 'autor-uid',
        );

        final result = await repository.cambiarEstado(
          reportId: reportId,
          estadoNuevo: 'Estado inexistente',
          observacion: null,
        );

        expect(result, isA<Failure<void>>());
        expect((result as Failure<void>).message, contains('Estado inválido'));

        // Verificar que NO se cambió el estado
        final reportDoc = await fakeFirestore
            .collection('reports')
            .doc(reportId)
            .get();
        expect(reportDoc.data()!['estado'], 'Pendiente');
      },
    );

    test(
      'Solucionar sin evidencia: devuelve Failure y no cambia el estado',
      () async {
        const reportId = 'test-report-sin-evidencia';
        await crearReporteInicial(
          reportId: reportId,
          estadoInicial: 'En proceso',
          uidAutor: 'autor-uid',
        );

        final result = await repository.cambiarEstado(
          reportId: reportId,
          estadoNuevo: 'Solucionado',
        );

        expect(result, isA<Failure<void>>());
        final data =
            (await fakeFirestore.collection('reports').doc(reportId).get())
                .data()!;
        expect(data['estado'], 'En proceso');
      },
    );

    test(
      'Solucionar con evidencia: guarda media/solucion y marca el flag',
      () async {
        const reportId = 'test-report-con-evidencia';
        await crearReporteInicial(
          reportId: reportId,
          estadoInicial: 'En proceso',
          uidAutor: 'autor-uid',
        );

        final result = await repository.cambiarEstado(
          reportId: reportId,
          estadoNuevo: 'Solucionado',
          evidenciaBase64: 'aGVsbG8=',
        );

        expect(result, isA<Success<void>>());
        final data =
            (await fakeFirestore.collection('reports').doc(reportId).get())
                .data()!;
        expect(data['estado'], 'Solucionado');
        expect(data['tieneEvidenciaSolucion'], isTrue);
        expect(data['encargadoUid'], 'admin-uid');

        final media = await fakeFirestore
            .collection('reports')
            .doc(reportId)
            .collection('media')
            .doc('solucion')
            .get();
        expect(media.exists, isTrue);
        expect(media.data()!['storagePath'], 'reports/$reportId/solucion.jpg');
        expect(
          media.data()!['downloadUrl'],
          contains('reports/$reportId/solucion.jpg'),
        );
        expect(media.data()!['base64'], isNull);
        expect(media.data()!['tamanoBytes'], 5);
        expect(media.data()!['mimeType'], 'image/jpeg');
      },
    );
  });

  group('FirebaseReporteRepository.tomarReporte', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late FirebaseReporteRepository repository;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'mant-1', email: 'mant@example.com'),
        signedIn: true,
      );
      repository = FirebaseReporteRepository(
        firestore: fakeFirestore,
        auth: mockAuth,
        almacenamiento: almacenamientoFake,
      );
      await fakeFirestore.collection('users').doc('mant-1').set({
        'nombre': 'Marta Mantenimiento',
        'correo': 'mant@example.com',
        'rol': 'mantenimiento',
        'activo': true,
      });
    });

    Future<void> crearReporte({
      required String reportId,
      required String estado,
      String asignadoA = '',
    }) async {
      await fakeFirestore.collection('reports').doc(reportId).set({
        'uid': 'autor-uid',
        'correoAutor': 'autor@example.com',
        'tipoDano': 'Silla dañada',
        'edificio': 'Edificio A',
        'piso': 'Piso 4',
        'salon': '402 A',
        'descripcion': 'Silla con tornillos sueltos',
        'estado': estado,
        'tieneFoto': false,
        'creadoEn': DateTime.now().subtract(const Duration(days: 1)),
        if (asignadoA.isNotEmpty) 'asignadoA': asignadoA,
      });
    }

    test(
      'asigna el reporte al encargado actual y no cambia el estado',
      () async {
        const reportId = 'reporte-libre';
        await crearReporte(reportId: reportId, estado: 'Pendiente');

        final result = await repository.tomarReporte(reportId: reportId);

        expect(result, isA<Success<void>>());
        final data =
            (await fakeFirestore.collection('reports').doc(reportId).get())
                .data()!;
        expect(data['asignadoA'], 'mant-1');
        expect(data['asignadoNombre'], 'Marta Mantenimiento');
        expect(data['asignadoEn'], isNotNull);
        expect(data['estado'], 'Pendiente');
      },
    );

    test('falla si otro encargado ya tomó el reporte', () async {
      const reportId = 'reporte-ajeno';
      await crearReporte(
        reportId: reportId,
        estado: 'Pendiente',
        asignadoA: 'mant-2',
      );

      final result = await repository.tomarReporte(reportId: reportId);

      expect(result, isA<Failure<void>>());
      final data =
          (await fakeFirestore.collection('reports').doc(reportId).get())
              .data()!;
      expect(data['asignadoA'], 'mant-2');
    });

    test('falla si el reporte ya está cerrado', () async {
      const reportId = 'reporte-cerrado';
      await crearReporte(reportId: reportId, estado: 'Solucionado');

      final result = await repository.tomarReporte(reportId: reportId);

      expect(result, isA<Failure<void>>());
      final data =
          (await fakeFirestore.collection('reports').doc(reportId).get())
              .data()!;
      expect(data.containsKey('asignadoA'), isFalse);
    });

    test('es idempotente si el mismo encargado vuelve a tomarlo', () async {
      const reportId = 'reporte-mio';
      await crearReporte(
        reportId: reportId,
        estado: 'Pendiente',
        asignadoA: 'mant-1',
      );

      final result = await repository.tomarReporte(reportId: reportId);

      expect(result, isA<Success<void>>());
    });
  });

  group('FirebaseReporteRepository.watchTodosLosReportes', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late FirebaseReporteRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'admin-uid', email: 'admin@example.com'),
        signedIn: true,
      );
      repository = FirebaseReporteRepository(
        firestore: fakeFirestore,
        auth: mockAuth,
        almacenamiento: almacenamientoFake,
      );
    });

    Future<void> crearReportesDePrueba() async {
      final batch = fakeFirestore.batch();
      final now = DateTime.now();

      // Reporte 1: Pendiente, Edificio A
      final doc1 = fakeFirestore.collection('reports').doc('report-1');
      batch.set(doc1, {
        'uid': 'user-1',
        'correoAutor': 'user1@example.com',
        'tipoDano': 'Silla dañada',
        'edificio': 'Edificio A',
        'piso': 'Piso 1',
        'salon': '101',
        'descripcion': 'Silla rota',
        'estado': 'Pendiente',
        'tieneFoto': false,
        'creadoEn': now.subtract(const Duration(days: 3)),
      });

      // Reporte 2: En revision, Edificio A
      final doc2 = fakeFirestore.collection('reports').doc('report-2');
      batch.set(doc2, {
        'uid': 'user-2',
        'correoAutor': 'user2@example.com',
        'tipoDano': 'Lámpara averiada',
        'edificio': 'Edificio A',
        'piso': 'Piso 2',
        'salon': '202',
        'descripcion': 'Lámpara no enciende',
        'estado': 'En revision',
        'tieneFoto': false,
        'creadoEn': now.subtract(const Duration(days: 2)),
      });

      // Reporte 3: Solucionado, Edificio B
      final doc3 = fakeFirestore.collection('reports').doc('report-3');
      batch.set(doc3, {
        'uid': 'user-3',
        'correoAutor': 'user3@example.com',
        'tipoDano': 'Puerta dañada',
        'edificio': 'Edificio B',
        'piso': 'Piso 1',
        'salon': '105',
        'descripcion': 'Puerta no cierra',
        'estado': 'Solucionado',
        'tieneFoto': false,
        'creadoEn': now.subtract(const Duration(days: 1)),
      });

      // Reporte 4: En proceso, Edificio B
      final doc4 = fakeFirestore.collection('reports').doc('report-4');
      batch.set(doc4, {
        'uid': 'user-4',
        'correoAutor': 'user4@example.com',
        'tipoDano': 'Ventana rota',
        'edificio': 'Edificio B',
        'piso': 'Piso 3',
        'salon': '303',
        'descripcion': 'Ventana rota en salón',
        'estado': 'En proceso',
        'tieneFoto': false,
        'creadoEn': now,
      });

      await batch.commit();
    }

    test('sin filtros: devuelve todos los reportes ordenados por creadoEn descendente', () async {
      await crearReportesDePrueba();

      final stream = repository.watchTodosLosReportes(
        filtroEstado: null,
        filtroEdificio: null,
      );
      final reportes = await stream.first;

      expect(reportes.length, 4);
      // Orden descendente: el más reciente primero (report-4, report-3, report-2, report-1)
      expect(reportes[0].reporteId, 'report-4');
      expect(reportes[1].reporteId, 'report-3');
      expect(reportes[2].reporteId, 'report-2');
      expect(reportes[3].reporteId, 'report-1');
    });

    test(
      'con filtroEstado=Pendiente: devuelve solo reportes con ese estado',
      () async {
        await crearReportesDePrueba();

        final stream = repository.watchTodosLosReportes(
          filtroEstado: 'Pendiente',
          filtroEdificio: null,
        );
        final reportes = await stream.first;

        expect(reportes.length, 1);
        expect(reportes[0].reporteId, 'report-1');
        expect(reportes[0].estado.valorFirestore, 'Pendiente');
      },
    );

    test(
      'con filtroEstado=En revision: devuelve solo reportes con ese estado',
      () async {
        await crearReportesDePrueba();

        final stream = repository.watchTodosLosReportes(
          filtroEstado: 'En revision',
          filtroEdificio: null,
        );
        final reportes = await stream.first;

        expect(reportes.length, 1);
        expect(reportes[0].reporteId, 'report-2');
        expect(reportes[0].estado.valorFirestore, 'En revision');
      },
    );

    test(
      'con filtroEdificio=Edificio A: devuelve solo reportes de ese edificio',
      () async {
        await crearReportesDePrueba();

        final stream = repository.watchTodosLosReportes(
          filtroEstado: null,
          filtroEdificio: 'Edificio A',
        );
        final reportes = await stream.first;

        expect(reportes.length, 2);
        expect(reportes.every((r) => r.edificio == 'Edificio A'), isTrue);
        expect(reportes.map((r) => r.reporteId).toSet(), {
          'report-1',
          'report-2',
        });
      },
    );

    test('con filtroEstado=En proceso y filtroEdificio=Edificio B: combina ambos filtros', () async {
      await crearReportesDePrueba();

      final stream = repository.watchTodosLosReportes(
        filtroEstado: 'En proceso',
        filtroEdificio: 'Edificio B',
      );
      final reportes = await stream.first;

      expect(reportes.length, 1);
      expect(reportes[0].reporteId, 'report-4');
      expect(reportes[0].estado.valorFirestore, 'En proceso');
      expect(reportes[0].edificio, 'Edificio B');
    });

    test('filtroEstado="Todos" y filtroEdificio="Todos": equivale a sin filtros (null)', () async {
      await crearReportesDePrueba();

      final stream = repository.watchTodosLosReportes(
        filtroEstado: 'Todos',
        filtroEdificio: 'Todos',
      );
      final reportes = await stream.first;

      expect(reportes.length, 4);
    });
  });
}
