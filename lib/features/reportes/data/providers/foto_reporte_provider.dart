import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/widgets/image_source_sheet.dart';
import '../comprimir_imagen.dart';

/// Selecciona una foto (cámara o galería), la comprime y devuelve sus bytes.
///
/// Devuelve `null` si el usuario cancela el selector de fuente o el picker.
/// Se abstrae detrás de un provider para poder inyectar una foto en pruebas
/// sin abrir la cámara ni la galería del dispositivo.
typedef SeleccionarFotoReporte = Future<Uint8List?> Function(
  BuildContext context,
);

/// Implementación activa: selector de fuente + `image_picker` + compresión.
final seleccionarFotoReporteProvider = Provider<SeleccionarFotoReporte>((ref) {
  return (BuildContext context) async {
    final ImageSource? fuente = await mostrarSelectorFuenteImagen(context);
    if (fuente == null) return null;

    final XFile? archivo = await ImagePicker().pickImage(
      source: fuente,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (archivo == null) return null;

    // Compresión equilibrada: máx. 1280 px y ~150–250 KB
    // (ver data/comprimir_imagen.dart).
    return comprimirImagenReporte(archivo);
  };
});
