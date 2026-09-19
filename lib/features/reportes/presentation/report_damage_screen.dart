import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/uts_header.dart';

/// Pantalla 8: Reportar Daños (placeholder del formulario).
class ReportDamageScreen extends ConsumerWidget {
  const ReportDamageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const UtsHeader(titulo: 'Reportar Daños'),
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
                    const LabelledField(etiqueta: 'Tipo de daño'),
                    const SizedBox(height: 18),
                    const LabelledField(etiqueta: 'Edificio'),
                    const SizedBox(height: 18),
                    const LabelledField(etiqueta: 'Piso'),
                    const SizedBox(height: 18),
                    const LabelledField(etiqueta: 'Salón'),
                    const SizedBox(height: 18),
                    const LabelledField(etiqueta: 'Descripción', multiline: true),
                    const SizedBox(height: 20),
                    Text('Adjuntar evidencia:', style: AppTypography.textTheme.titleSmall),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 44, color: AppColors.textSecondary),
                          SizedBox(height: 8),
                          Text('Toca para adjuntar', style: AppTypographyLocal.bodyHint),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(
                      texto: 'ENVIAR REPORTE',
                      onPressed: () => context.go(AppRoutes.misReportes),
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

abstract final class AppTypographyLocal {
  static const TextStyle bodyHint = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
  );
}