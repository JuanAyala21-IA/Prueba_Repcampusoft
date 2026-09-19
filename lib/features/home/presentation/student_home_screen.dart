import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/routes/session_provider.dart';
import '../../../shared/widgets/dashboard_tile.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../perfil/presentation/user_header.dart';

/// Pantalla 4: Menú Principal / Dashboard Estudiante.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void cerrarSesion() => ref.read(sesionProvider.notifier).cerrarSesion();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              const UserHeader(
                nombre: 'Nombre',
                subtitulo: 'Informacion personal',
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1,
                children: [
                  DashboardTile(
                    icono: Icons.person_outline,
                    titulo: 'Perfil',
                    onTap: () => context.go(AppRoutes.perfilEstudiante),
                  ),
                  DashboardTile(
                    icono: Icons.warning_amber_rounded,
                    titulo: 'Reportar daños',
                    destacado: true,
                    onTap: () => context.go(AppRoutes.reportarDanos),
                  ),
                  DashboardTile(
                    icono: Icons.build_outlined,
                    titulo: 'Tus reportes',
                    onTap: () => context.go(AppRoutes.misReportes),
                  ),
                  DashboardTile(
                    icono: Icons.notifications_none,
                    titulo: 'Notificaciones',
                    onTap: () => context.go(AppRoutes.notificacionesEstudiante),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                texto: 'Cerrar Sesión',
                onPressed: cerrarSesion,
              ),
            ],
          ),
        ),
      ),
    );
  }
}