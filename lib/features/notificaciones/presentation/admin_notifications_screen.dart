import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/bell_badge.dart';
import '../../../shared/widgets/notification_card.dart';
import '../../../shared/widgets/uts_header.dart';

/// Pantalla 13: Notificaciones Área Encargada (datos simulados).
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  String _filtro = 'Todas';

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
                subtitulo: 'Área Encargada',
                accion: BellBadge(conteo: 3),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('Todas'),
                    _chip('Reportes'),
                    _chip('Administrativo'),
                    _chip('Sistema'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              NotificationCard(
                titulo: 'Nuevo reporte de daño',
                mensaje: 'El estudiante Carlos Perez reportó una silla dañada en el salon 402A',
                fecha: '08/09/2026 - 10:24 a.m.',
                icono: Icons.person_outline,
                onTap: () => context.go(AppRoutes.gestionReporte),
              ),
              const SizedBox(height: 12),
              NotificationCard(
                titulo: 'Reporte en proceso',
                mensaje: 'El reporte #024 esta siendo revisado por el areá de mantenimiento.',
                fecha: '08/09/2026 - 9:15 a.m.',
                icono: Icons.build_outlined,
                onTap: () => context.go(AppRoutes.gestionReporte),
              ),
              const SizedBox(height: 12),
              NotificationCard(
                titulo: 'Reporte Solucionado',
                mensaje: 'El daño en el salon 204A ha sido solucionado.',
                fecha: '07/09/2026 - 4:32 p.m.',
                icono: Icons.check_circle_outline,
                onTap: () => context.go(AppRoutes.gestionReporte),
              ),
              const SizedBox(height: 12),
              NotificationCard(
                titulo: 'Aviso Administrativo',
                mensaje: 'Se realizara mantenimiento en el salon 204A el proximo viernes',
                fecha: '03/09/2026 - 2:45 p.m.',
                icono: Icons.campaign_outlined,
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