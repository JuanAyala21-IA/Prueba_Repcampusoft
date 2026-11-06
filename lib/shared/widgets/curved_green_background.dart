import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Fondo institucional: blanco con la curva verde en la parte inferior, igual
/// que la pantalla principal del estudiante.
class CurvedGreenBackground extends StatelessWidget {
  const CurvedGreenBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        Container(color: AppColors.background, height: height),
        const Positioned.fill(
          child: CustomPaint(painter: _CurvedGreenPainter()),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _CurvedGreenPainter extends CustomPainter {
  const _CurvedGreenPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = AppColors.utsGreen;
    final Path path = Path()
      ..moveTo(0, size.height * 0.60)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.50,
        size.width * 0.4,
        size.height * 0.60,
        size.width,
        size.height * 0.54,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
