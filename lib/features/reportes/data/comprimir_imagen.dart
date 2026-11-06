import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Compresión "equilibrada" de las fotos de los reportes.
///
/// Objetivo: máximo 1280 px en el lado mayor y JPEG de calidad 60
/// (~150–250 KB). Si la imagen aún supera 250 KB se baja la calidad a 45 y,
/// como último recurso, se reduce a 1024 px. Las imágenes nunca se amplían.
Future<Uint8List> comprimirImagenReporte(XFile archivo) async {
  final Uint8List original = await archivo.readAsBytes();

  Uint8List salida = await FlutterImageCompress.compressWithList(
    original,
    minWidth: 1280,
    minHeight: 1280,
    quality: 60,
    format: CompressFormat.jpeg,
  );
  if (salida.length <= 250 * 1024) return salida;

  salida = await FlutterImageCompress.compressWithList(
    original,
    minWidth: 1280,
    minHeight: 1280,
    quality: 45,
    format: CompressFormat.jpeg,
  );
  if (salida.length <= 300 * 1024) return salida;

  return FlutterImageCompress.compressWithList(
    original,
    minWidth: 1024,
    minHeight: 1024,
    quality: 45,
    format: CompressFormat.jpeg,
  );
}
