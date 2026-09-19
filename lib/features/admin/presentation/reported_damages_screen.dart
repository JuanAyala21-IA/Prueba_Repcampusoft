import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/estado_reporte_style.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/report_card.dart';
import '../../../shared/widgets/uts_header.dart';

/// Pantalla 12: Daños Reportados / Gestión de Reportes (Administrador).
class ReportedDamagesScreen extends StatefulWidget {
  const ReportedDamagesScreen({super.key});

  @override
  State<ReportedDamagesScreen> createState() => _ReportedDamagesScreenState();
}

class _ReportedDamagesScreenState extends State<ReportedDamagesScreen> {
  String _filtro = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const UtsHeader(titulo: 'Daños Reportados'),
              const SizedBox(height: 8),
              const PillField(hint: 'Buscar daño...', icono: Icons.search, borde: true),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('Todos'),
                    _chip('Pendientes'),
                    _chip('En revision'),
                    _chip('Solucionados'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('Ubicacion:', style: AppTypography.textTheme.titleSmall),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Row(
                      children: [
                        Text('Todos', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                        Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ReportCard(
                titulo: 'Silla dañada',
                ubicacion: 'Edificio A - Salon 204',
                estado: EstadoReporte.pendiente,
                fecha: '08/09/2026',
                icono: Icons.chair_outlined,
                onTap: () => context.go(AppRoutes.gestionReporte),
              ),
              const SizedBox(height: 12),
              ReportCard(
                titulo: 'Lampara averiada',
                ubicacion: 'Edificio B - Salon 302',
                estado: EstadoReporte.enRevision,
                fecha: '07/09/2026',
                icono: Icons.lightbulb_outline,
                onTap: () => context.go(AppRoutes.gestionReporte),
              ),
              const SizedBox(height: 12),
              ReportCard(
                titulo: 'Puerta dañada',
                ubicacion: 'Edificio B - Salon 105',
                estado: EstadoReporte.solucionado,
                fecha: '04/09/2026',
                icono: Icons.door_front_door_outlined,
                onTap: () => context.go(AppRoutes.gestionReporte),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String texto) {
    final bool activo = _filtro == texto;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(texto),
        selected: activo,
        onSelected: (_) => setState(() => _filtro = texto),
      ),
    );
  }
}