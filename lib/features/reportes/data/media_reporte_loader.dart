import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/servicio_almacenamiento_imagen.dart';

/// Caché en memoria (LRU simple) de las imágenes de evidencia ya cargadas.
///
/// Evita volver a leer Firestore/Storage y volver a decodificar Base64 cada vez
/// que se abre el detalle de un reporte. Se limita el número de entradas para
/// no crecer sin control en memoria.
final LinkedHashMap<String, Uint8List> _cacheMedia =
    LinkedHashMap<String, Uint8List>();
const int _maxCacheMedia = 12;

String _clave(String reporteId, String mediaId) => '$reporteId/$mediaId';

Uint8List? _tomarDeCache(String clave) {
  final Uint8List? bytes = _cacheMedia.remove(clave);
  if (bytes != null) {
    // Se reinserta para que quede como el más reciente (LRU).
    _cacheMedia[clave] = bytes;
  }
  return bytes;
}

void _guardarEnCache(String clave, Uint8List bytes) {
  _cacheMedia.remove(clave);
  _cacheMedia[clave] = bytes;
  while (_cacheMedia.length > _maxCacheMedia) {
    _cacheMedia.remove(_cacheMedia.keys.first);
  }
}

/// Limpia la caché (por ejemplo, al cerrar sesión o en pruebas).
void limpiarCacheMediaReporte() => _cacheMedia.clear();

/// Carga los bytes de `reports/{reporteId}/media/{mediaId}`.
///
/// Orden de preferencia:
/// 1. `base64` (documentos antiguos guardados en Firestore).
/// 2. `downloadUrl` con token, descargada por HTTP. Es la vía más fiable:
///    la URL ya autoriza la lectura y no depende de que el SDK de Storage
///    adjunte el token de Firebase Auth (en web `getData` fallaba y la foto
///    se mostraba vacía).
/// 3. `storagePath` a través de Firebase Storage (respaldo).
///
/// Devuelve `null` cuando el documento no existe o no tiene imagen. Si hay una
/// imagen registrada pero no se pudo descargar, lanza el último error para que
/// la pantalla pueda ofrecer reintentar.
Future<Uint8List?> cargarMediaReporte({
  required String reporteId,
  required String mediaId,
  required ServicioAlmacenamientoImagen almacenamiento,
  FirebaseFirestore? firestore,
}) async {
  final String clave = _clave(reporteId, mediaId);
  final Uint8List? cacheado = _tomarDeCache(clave);
  if (cacheado != null) return cacheado;

  final Uint8List? bytes = await _cargarMediaSinCache(
    reporteId: reporteId,
    mediaId: mediaId,
    almacenamiento: almacenamiento,
    firestore: firestore,
  );
  if (bytes != null) _guardarEnCache(clave, bytes);
  return bytes;
}

Future<Uint8List?> _cargarMediaSinCache({
  required String reporteId,
  required String mediaId,
  required ServicioAlmacenamientoImagen almacenamiento,
  FirebaseFirestore? firestore,
}) async {
  final FirebaseFirestore db = firestore ?? FirebaseFirestore.instance;
  final DocumentSnapshot<Map<String, dynamic>> doc = await db
      .collection('reports')
      .doc(reporteId)
      .collection('media')
      .doc(mediaId)
      .get();
  if (!doc.exists || doc.data() == null) return null;

  final Map<String, dynamic> data = doc.data()!;

  final String? base64Value = (data['base64'] as String?)?.trim();
  if (base64Value != null && base64Value.isNotEmpty) {
    return base64Decode(base64Value);
  }

  final String? downloadUrl = (data['downloadUrl'] as String?)?.trim();
  final String? storagePath = (data['storagePath'] as String?)?.trim();

  Object? ultimoError;
  if (downloadUrl != null && downloadUrl.isNotEmpty) {
    try {
      return await almacenamiento.descargarDesdeUrl(downloadUrl);
    } catch (error) {
      ultimoError = error;
    }
  }

  if (storagePath != null && storagePath.isNotEmpty) {
    try {
      return await almacenamiento.descargar(storagePath);
    } catch (error) {
      ultimoError = error;
    }
  }

  if (ultimoError != null) throw ultimoError;
  return null;
}
