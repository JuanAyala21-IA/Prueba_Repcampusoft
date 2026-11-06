import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/servicio_almacenamiento_imagen.dart';

/// Implementación sobre Firebase Storage.
///
/// Las fotos se guardan comprimidas (máx. 1280 px, JPEG) y se sirven desde el
/// bucket `repcampusoft.firebasestorage.app`.
///
/// La ruta incluye el uid del que sube (`reports/{uid}/{reportId}/...`) para
/// que las reglas de Storage puedan validar la propiedad sin llamadas entre
/// servicios (Firestore) que no están disponibles en las reglas de Storage.
class FirebaseAlmacenamientoImagen implements ServicioAlmacenamientoImagen {
  FirebaseAlmacenamientoImagen({FirebaseStorage? storage, FirebaseAuth? auth})
    : _storage = storage ?? FirebaseStorage.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  /// Límite de lectura defensivo (5 MB); las imágenes subidas pesan mucho menos.
  static const int _maxBytesDescarga = 5 * 1024 * 1024;

  String get _uid => _auth.currentUser?.uid ?? 'anonimo';

  @override
  Future<ImagenAlmacenada> subirFotoReporte({
    required String reportId,
    required Uint8List bytes,
  }) => _subir('reports/$_uid/$reportId/foto.jpg', bytes);

  @override
  Future<ImagenAlmacenada> subirEvidenciaSolucion({
    required String reportId,
    required Uint8List bytes,
  }) => _subir('reports/$_uid/$reportId/solucion.jpg', bytes);

  Future<ImagenAlmacenada> _subir(String storagePath, Uint8List bytes) async {
    final Reference ref = _storage.ref(storagePath);
    final TaskSnapshot snapshot = await ref.putData(
      bytes,
      SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public,max-age=86400',
      ),
    );
    final String downloadUrl = await snapshot.ref.getDownloadURL();
    return ImagenAlmacenada(
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      tamanoBytes: bytes.lengthInBytes,
      mimeType: 'image/jpeg',
    );
  }

  @override
  Future<Uint8List> descargar(String storagePath) async {
    final Uint8List? data = await _storage
        .ref(storagePath)
        .getData(_maxBytesDescarga);
    if (data == null) {
      throw StateError('La imagen no existe en Storage: $storagePath');
    }
    return data;
  }

  @override
  Future<void> eliminar(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
    } on FirebaseException {
      // Limpieza best-effort: si falla, el objeto queda huérfano pero no
      // bloquea la operación principal.
    }
  }
}
