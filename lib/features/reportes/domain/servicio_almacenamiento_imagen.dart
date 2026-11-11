import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resultado de subir una imagen a Firebase Storage.
class ImagenAlmacenada {
  const ImagenAlmacenada({
    required this.storagePath,
    required this.downloadUrl,
    required this.tamanoBytes,
    required this.mimeType,
  });

  /// Ruta del objeto dentro del bucket (`reports/{id}/foto.jpg`).
  final String storagePath;

  /// URL de descarga con token (útil para compartir o previsualizar).
  final String downloadUrl;

  final int tamanoBytes;
  final String mimeType;
}

/// Abstracción del almacenamiento de imágenes de los reportes.
///
/// Las imágenes se guardan en Firebase Storage (no como Base64 en Firestore),
/// para no consumir el límite de 1 MB por documento y poder almacenar muchas
/// más fotografías.
abstract interface class ServicioAlmacenamientoImagen {
  /// Sube la foto inicial del reporte a `reports/{reportId}/foto.jpg`.
  Future<ImagenAlmacenada> subirFotoReporte({
    required String reportId,
    required Uint8List bytes,
  });

  /// Sube la evidencia de la solución a `reports/{reportId}/solucion.jpg`.
  Future<ImagenAlmacenada> subirEvidenciaSolucion({
    required String reportId,
    required Uint8List bytes,
  });

  /// Descarga una imagen por su ruta de Storage.
  Future<Uint8List> descargar(String storagePath);

  /// Descarga una imagen a partir de su URL de descarga con token.
  ///
  /// Es el método preferido para mostrar evidencias: la URL ya autoriza la
  /// lectura y no depende de que el SDK adjunte el token de Firebase Auth.
  Future<Uint8List> descargarDesdeUrl(String downloadUrl);

  /// Elimina una imagen (limpieza best-effort si falla la escritura).
  Future<void> eliminar(String storagePath);
}

/// Proveedor inyectable (se sobreescribe en
/// `data/providers/reporte_providers.dart`).
final servicioAlmacenamientoImagenProvider =
    Provider<ServicioAlmacenamientoImagen>(
      (ref) => throw UnimplementedError(
        'Se inyecta en data/providers/reporte_providers.dart',
      ),
    );
