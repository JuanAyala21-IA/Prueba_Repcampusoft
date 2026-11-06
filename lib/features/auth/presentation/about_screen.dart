import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/circular_button_uts.dart';

/// Pantalla 2: ¿Qué es Repcampusoft?
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(color: AppColors.background, height: screenHeight),
          Positioned.fill(child: CustomPaint(painter: _CurvaVerdeInferior())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircularButtonUts(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.welcome);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '¿Qué es Repcampusoft?',
                          style: AppTypography.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Plataforma de reportes',
                          style: AppTypography.textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REPCAMPUSOFT es una solución móvil multiplataforma desarrollada en '
                          'Flutter para centralizar y modernizar la gestión de incidencias en la '
                          'infraestructura de las UTS.',
                          style: AppTypography.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Permite a estudiantes, docentes y administrativos registrar de forma ágil '
                          'daños en aulas, laboratorios y pasillos, adjuntando ubicación exacta y fotos.',
                          style: AppTypography.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'El personal operativo y de mantenimiento recibe, categoriza, asigna '
                          'responsables, prioriza y hace seguimiento en tiempo real desde un panel '
                          'centralizado.',
                          style: AppTypography.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'UTS - Universitaria Tecnologia de Santander',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fondo curvo verde UTS en la parte inferior (pantalla 1.png).
class _CurvaVerdeInferior extends CustomPainter {
  const _CurvaVerdeInferior();

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
