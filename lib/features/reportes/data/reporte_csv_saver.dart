import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Guarda el CSV en el almacenamiento del dispositivo usando el diálogo
/// nativo de "Guardar como" (SAF en Android, selector de documentos en iOS).
abstract interface class ReporteCsvSaver {
  /// Devuelve la ruta/URI elegida por el usuario, o `null` si cancela.
  Future<String?> guardar({
    required String nombreArchivo,
    required String contenido,
  });
}

class FileSaverReporteCsvSaver implements ReporteCsvSaver {
  const FileSaverReporteCsvSaver();

  @override
  Future<String?> guardar({
    required String nombreArchivo,
    required String contenido,
  }) {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(contenido));
    return FileSaver.instance.saveAs(
      name: nombreArchivo,
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }
}

/// Se sobreescribe en las pruebas para no abrir el diálogo del sistema.
final reporteCsvSaverProvider = Provider<ReporteCsvSaver>(
  (ref) => const FileSaverReporteCsvSaver(),
);
