import 'dart:typed_data';

import 'package:repcampusoft/features/reportes/domain/servicio_almacenamiento_imagen.dart';

/// Fake en memoria de Firebase Storage para las pruebas del repositorio.
class FakeAlmacenamientoImagen implements ServicioAlmacenamientoImagen {
  final Map<String, Uint8List> objetos = <String, Uint8List>{};
  final List<String> subidas = <String>[];

  @override
  Future<ImagenAlmacenada> subirFotoReporte({
    required String reportId,
    required Uint8List bytes,
  }) => _subir('reports/$reportId/foto.jpg', bytes);

  @override
  Future<ImagenAlmacenada> subirEvidenciaSolucion({
    required String reportId,
    required Uint8List bytes,
  }) => _subir('reports/$reportId/solucion.jpg', bytes);

  Future<ImagenAlmacenada> _subir(String path, Uint8List bytes) async {
    objetos[path] = bytes;
    subidas.add(path);
    return ImagenAlmacenada(
      storagePath: path,
      downloadUrl: 'https://storage.example/$path',
      tamanoBytes: bytes.lengthInBytes,
      mimeType: 'image/jpeg',
    );
  }

  @override
  Future<Uint8List> descargar(String storagePath) async {
    final Uint8List? data = objetos[storagePath];
    if (data == null) {
      throw StateError('No existe la imagen $storagePath');
    }
    return data;
  }

  @override
  Future<void> eliminar(String storagePath) async {
    objetos.remove(storagePath);
    subidas.remove(storagePath);
  }
}
