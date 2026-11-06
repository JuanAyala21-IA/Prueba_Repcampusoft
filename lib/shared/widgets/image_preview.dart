import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Abre una imagen de evidencia en pantalla completa, con fondo oscuro, zoom
/// con pellizco y doble toque.
///
/// Se usa desde las tarjetas de evidencia de los reportes (foto inicial y foto
/// de la solución) para que el usuario pueda verla con detalle.
Future<void> mostrarImagenAmpliada(
  BuildContext context,
  Uint8List bytes, {
  String? descripcion,
}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _ImagenAmpliada(bytes: bytes, descripcion: descripcion),
    ),
  );
}

/// Indicador visual que invita a ampliar una imagen de evidencia.
class IndicadorAmpliarImagen extends StatelessWidget {
  const IndicadorAmpliarImagen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Colors.black54,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.zoom_in, color: Colors.white, size: 20),
    );
  }
}

class _ImagenAmpliada extends StatefulWidget {
  const _ImagenAmpliada({required this.bytes, this.descripcion});

  final Uint8List bytes;
  final String? descripcion;

  @override
  State<_ImagenAmpliada> createState() => _ImagenAmpliadaState();
}

class _ImagenAmpliadaState extends State<_ImagenAmpliada> {
  final TransformationController _controller = TransformationController();
  Offset _posicionDobleToque = Offset.zero;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _alternarZoom() {
    if (_controller.value.getMaxScaleOnAxis() > 1.01) {
      _controller.value = Matrix4.identity();
      return;
    }
    const double escala = 2.5;
    final Offset posicion = _posicionDobleToque;
    _controller.value = Matrix4.identity()
      ..translateByDouble(
        -posicion.dx * (escala - 1),
        -posicion.dy * (escala - 1),
        0,
        1,
      )
      ..scaleByDouble(escala, escala, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onDoubleTapDown: (detalles) =>
                    _posicionDobleToque = detalles.localPosition,
                onDoubleTap: _alternarZoom,
                child: InteractiveViewer(
                  transformationController: _controller,
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: Image.memory(
                      widget.bytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.descripcion != null &&
                      widget.descripcion!.trim().isNotEmpty) ...[
                    Text(
                      widget.descripcion!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.zoom_in, size: 16, color: Colors.white54),
                      SizedBox(width: 6),
                      Text(
                        'Pellizca o haz doble toque para hacer zoom',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
