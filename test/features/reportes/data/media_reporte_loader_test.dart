import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repcampusoft/features/reportes/data/media_reporte_loader.dart';

import '../../../fakes/fake_almacenamiento_imagen.dart';

void main() {
  group('cargarMediaReporte', () {
    late FakeFirebaseFirestore firestore;
    late FakeAlmacenamientoImagen almacenamiento;
    final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);

    setUp(() {
      firestore = FakeFirebaseFirestore();
      almacenamiento = FakeAlmacenamientoImagen();
    });

    Future<void> sembrarMedia(Map<String, dynamic> data) {
      return firestore
          .collection('reports')
          .doc('reporte-1')
          .collection('media')
          .doc('foto')
          .set(data);
    }

    test('devuelve null si el documento de media no existe', () async {
      final resultado = await cargarMediaReporte(
        reporteId: 'reporte-1',
        mediaId: 'foto',
        almacenamiento: almacenamiento,
        firestore: firestore,
      );

      expect(resultado, isNull);
    });

    test('usa la URL de descarga antes que la ruta de Storage', () async {
      const url = 'https://storage.example/foto.jpg?token=abc';
      await sembrarMedia(<String, dynamic>{
        'storagePath': 'reports/uid/reporte-1/foto.jpg',
        'downloadUrl': url,
        'tamanoBytes': bytes.length,
        'mimeType': 'image/jpeg',
      });
      almacenamiento.urls[url] = bytes;

      final resultado = await cargarMediaReporte(
        reporteId: 'reporte-1',
        mediaId: 'foto',
        almacenamiento: almacenamiento,
        firestore: firestore,
      );

      expect(resultado, bytes);
    });

    test('si la URL falla, usa la ruta de Storage', () async {
      const url = 'https://storage.example/foto.jpg?token=abc';
      const path = 'reports/uid/reporte-1/foto.jpg';
      await sembrarMedia(<String, dynamic>{
        'storagePath': path,
        'downloadUrl': url,
      });
      almacenamiento.objetos[path] = bytes;

      final resultado = await cargarMediaReporte(
        reporteId: 'reporte-1',
        mediaId: 'foto',
        almacenamiento: almacenamiento,
        firestore: firestore,
      );

      expect(resultado, bytes);
    });

    test('mantiene compatibilidad con imágenes antiguas en Base64', () async {
      final String base64 = base64Encode(bytes);
      await sembrarMedia(<String, dynamic>{'base64': base64});

      final resultado = await cargarMediaReporte(
        reporteId: 'reporte-1',
        mediaId: 'foto',
        almacenamiento: almacenamiento,
        firestore: firestore,
      );

      expect(resultado, bytes);
    });

    test('lanza el error si existe imagen pero no se pudo descargar', () async {
      await sembrarMedia(<String, dynamic>{
        'storagePath': 'reports/uid/reporte-1/foto.jpg',
        'downloadUrl': 'https://storage.example/foto.jpg?token=abc',
      });
      almacenamiento.fallarDescarga = true;

      await expectLater(
        cargarMediaReporte(
          reporteId: 'reporte-1',
          mediaId: 'foto',
          almacenamiento: almacenamiento,
          firestore: firestore,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
