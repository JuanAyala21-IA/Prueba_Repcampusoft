import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Muestra una hoja inferior para elegir cómo adjuntar una imagen:
/// tomar una foto con la cámara o elegirla de la galería.
///
/// Devuelve la [ImageSource] seleccionada, o `null` si se cancela.
Future<ImageSource?> mostrarSelectorFuenteImagen(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              subtitle: const Text('Usar la cámara del dispositivo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              subtitle: const Text('Seleccionar una imagen guardada'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
