import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/theme/estado_reporte_style.dart';
import '../../../shared/widgets/report_card.dart';
import '../../../shared/widgets/uts_header.dart';

/// Pantalla 10: Lista de Reportes Estudiante (datos simulados).
class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const UtsHeader(titulo: 'Tus Reportes'),
              const SizedBox(height: 8),
              ReportCard(
                titulo: 'Silla dañada',
                ubicacion: 'Edificio A - Salon 402 A',
                estado: EstadoReporte.pendiente,
                fecha: '08/09/2026',
                icono: Icons.chair_outlined,
                onTap: () => context.go(AppRoutes.detalleReporte),
              ),
              const SizedBox(height: 12),
              ReportCard(
                titulo: 'Lámpara averiada',
                ubicacion: 'Edificio B - Salon 302',
                estado: EstadoReporte.enProceso,
                fecha: '05/09/2026',
                icono: Icons.lightbulb_outline,
                onTap: () => context.go(AppRoutes.detalleReporte),
              ),
              const SizedBox(height: 12),
              ReportCard(
                titulo: 'Puerta dañada',
                ubicacion: 'Edificio B - Salon 105',
                estado: EstadoReporte.solucionado,
                fecha: '04/09/2026',
                icono: Icons.door_front_door_outlined,
                onTap: () => context.go(AppRoutes.detalleReporte),
              ),
            ],
          ),
        ),
      ),
    );
  }
}