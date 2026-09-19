import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/bell_badge.dart';
import '../../../shared/widgets/notification_card.dart';
import '../../../shared/widgets/uts_header.dart';

/// Pantalla 11: Notificaciones Estudiante (datos simulados).
class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const UtsHeader(
                titulo: 'Notificaciones',
                accion: BellBadge(conteo: 3),
              ),
              const SizedBox(height: 8),
              NotificationCard(
                titulo: 'Reporte recibido',
                mensaje: 'Tu reporte #02 ha sido recibido correctamente',
                fecha: 'Hoy, 10:30 a.m.',
                icono: Icons.description_outlined,
                onTap: () => context.go(AppRoutes.detalleReporte),
              ),
              const SizedBox(height: 12),
              NotificationCard(
                titulo: 'Reporte en proceso',
                mensaje: 'El daño reportado en el edificio A se encuentra en proceso de reparacion.',
                fecha: 'Ayer, 3:15 p.m.',
                icono: Icons.build_outlined,
                onTap: () => context.go(AppRoutes.detalleReporte),
              ),
              const SizedBox(height: 12),
              NotificationCard(
                titulo: 'Reporte Solucionado',
                mensaje: 'El daño en el salon 204A ha sido solucionado. ¡Gracias por tu reporte!',
                fecha: '06/09/2026',
                icono: Icons.check_circle_outline,
                onTap: () => context.go(AppRoutes.detalleReporte),
              ),
              const SizedBox(height: 12),
              NotificationCard(
                titulo: 'Reporte rechazado',
                mensaje: 'Tu reporte #04 no pudo ser procesado por informacion incompleta.',
                fecha: '03/09/2026',
                icono: Icons.warning_amber_rounded,
                onTap: () => context.go(AppRoutes.detalleReporte),
              ),
            ],
          ),
        ),
      ),
    );
  }
}