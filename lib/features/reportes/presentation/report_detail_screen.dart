import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/uts_header.dart';

/// Pantalla 9: Detalle de Reporte Estudiante (placeholder con datos simulados).
class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget dato(String etiqueta, String valor) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(etiqueta,
                  style: AppTypography.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Text(valor, style: AppTypography.textTheme.bodyMedium)),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const UtsHeader(titulo: 'Tus Reportes'),
              const SizedBox(height: 12),
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
                    dato('Tipo de daño:', 'Silla dañada'),
                    dato('Edificio:', 'A'),
                    dato('Piso:', '4'),
                    dato('Salón:', '402 A'),
                    dato(
                      'Descripción:',
                      'En el salón 402 A se encontró la siguiente silla con los tornillos '
                      'sueltos, lo cuál hace que a la hora de utilizarla esta comience a '
                      'tambalearse.',
                    ),
                    const SizedBox(height: 12),
                    Text('Adjuntar evidencia:', style: AppTypography.textTheme.titleSmall),
                    const SizedBox(height: 10),
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Center(
                        child: Icon(Icons.image_outlined, size: 48, color: AppColors.textSecondary),
                      ),
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