import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/uts_header.dart';

/// Pantalla 2: ¿Qué es Repcampusoft?
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const UtsHeader(titulo: '¿Qué es Repcampusoft?', subtitulo: 'Plataforma de reportes'),
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
            ],
          ),
        ),
      ),
    );
  }
}