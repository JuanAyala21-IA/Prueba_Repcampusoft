import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/routes/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/domain/rol_enum.dart';
import '../../../shared/widgets/dashboard_tile.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../perfil/data/providers/perfil_providers.dart';

/// Pantalla 5: Menú Principal / Dashboard Administrativo.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilUsuarioProvider);
    final Sesion sesion = ref.watch(sesionProvider);
    final bool esSuperadministrador = sesion.esSuperadministrador;
    final bool esMantenimiento = sesion.rol == RolEnum.mantenimiento;
    final screenHeight = MediaQuery.of(context).size.height;

    void cerrarSesion() => ref.read(sesionProvider.notifier).cerrarSesion();

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(color: AppColors.background, height: screenHeight),
          Positioned.fill(child: CustomPaint(painter: _CurvaVerdeInferior())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  perfilAsync.when(
                    data: (perfil) {
                      final nombre = perfil?.nombre ?? 'Usuario';
                      final area =
                          perfil?.dependencia ??
                          (perfil?.cargo ??
                              sesion.rol?.etiqueta ??
                              'Área encargada');
                      return Column(
                        children: [
                          const Row(
                            children: [
                              SizedBox(width: 44),
                              Expanded(
                                child: Center(child: SizedBox(height: 40)),
                              ),
                              SizedBox(
                                width: 44,
                                child: Center(
                                  child: SizedBox(width: 36, height: 36),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            nombre,
                            style: AppTypography.textTheme.titleLarge,
                          ),
                          Text(area, style: AppTypography.textTheme.titleSmall),
                          const SizedBox(height: 8),
                          const Divider(color: AppColors.divider),
                        ],
                      );
                    },
                    loading: () => Column(
                      children: [
                        const Row(
                          children: [
                            SizedBox(width: 44),
                            Expanded(
                              child: Center(child: SizedBox(height: 40)),
                            ),
                            SizedBox(
                              width: 44,
                              child: Center(
                                child: SizedBox(width: 36, height: 36),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cargando...',
                          style: AppTypography.textTheme.titleLarge,
                        ),
                        Text(
                          'Cargando...',
                          style: AppTypography.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: AppColors.divider),
                      ],
                    ),
                    error: (e, _) => Column(
                      children: [
                        const Row(
                          children: [
                            SizedBox(width: 44),
                            Expanded(
                              child: Center(child: SizedBox(height: 40)),
                            ),
                            SizedBox(
                              width: 44,
                              child: Center(
                                child: SizedBox(width: 36, height: 36),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error',
                          style: AppTypography.textTheme.titleLarge,
                        ),
                        Text(
                          'Error al cargar perfil',
                          style: AppTypography.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: AppColors.divider),
                      ],
                    ),
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
                        onTap: () => context.push(AppRoutes.perfilAdmin),
                      ),
                      if (esMantenimiento)
                        DashboardTile(
                          icono: Icons.assignment_turned_in_outlined,
                          titulo: 'Mis reportes asignados',
                          destacado: true,
                          onTap: () =>
                              context.push(AppRoutes.misReportesAsignados),
                        ),
                      DashboardTile(
                        icono: Icons.campaign_outlined,
                        titulo: 'Daño y gestión de reportes',
                        onTap: () => context.push(AppRoutes.danosReportados),
                      ),
                      DashboardTile(
                        icono: Icons.notifications_none,
                        titulo: 'Notificaciones',
                        onTap: () =>
                            context.push(AppRoutes.notificacionesAdmin),
                      ),
                      if (esSuperadministrador) ...[
                        DashboardTile(
                          icono: Icons.manage_accounts_outlined,
                          titulo: 'Gestión de usuarios',
                          onTap: () => context.push(AppRoutes.gestionUsuarios),
                        ),
                        DashboardTile(
                          icono: Icons.bug_report_outlined,
                          titulo: 'Fallas de la app',
                          onTap: () => context.push(AppRoutes.fallasApp),
                        ),
                        DashboardTile(
                          icono: Icons.file_download_outlined,
                          titulo: 'Descargar reportes (CSV)',
                          onTap: () => context.push(AppRoutes.exportarReportes),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    texto: 'Cerrar Sesión',
                    onPressed: cerrarSesion,
                    variante: Variante.verdeOscuro,
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

/// Fondo curvo verde UTS en la parte inferior.
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
