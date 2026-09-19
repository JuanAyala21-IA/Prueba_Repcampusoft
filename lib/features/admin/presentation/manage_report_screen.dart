import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/estado_reporte_style.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/uts_header.dart';

/// Pantalla de gestión de un reporte por el administrativo
/// (arquitectura §5.2 "Detalle/Gestión Admin").
class ManageReportScreen extends StatefulWidget {
  const ManageReportScreen({super.key});

  @override
  State<ManageReportScreen> createState() => _ManageReportScreenState();
}

class _ManageReportScreenState extends State<ManageReportScreen> {
  EstadoReporte _estado = EstadoReporte.enRevision;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const UtsHeader(titulo: 'Gestionar Reporte'),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Silla dañada', style: AppTypography.textTheme.titleMedium),
                        StatusBadge(estado: _estado),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Edificio A - Salon 204',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    Text('Cambiar estado', style: AppTypography.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: EstadoReporte.values.map((estado) {
                        return ChoiceChip(
                          label: Text(estado.nombre),
                          selected: _estado == estado,
                          onSelected: (_) => setState(() => _estado = estado),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    const Text('Observación', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Escribe la observación del cambio de estado...',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(texto: 'Guardar cambios', onPressed: () {}),
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