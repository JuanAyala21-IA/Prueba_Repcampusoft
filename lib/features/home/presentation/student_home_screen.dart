import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/routes/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/dashboard_tile.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../perfil/data/providers/perfil_providers.dart';
import '../../perfil/presentation/user_header.dart';

/// Pantalla 4: Menú Principal / Dashboard Estudiante.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilUsuarioProvider);
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
                      return UserHeader(
                        nombre: nombre,
                        subtitulo: 'Información personal',
                      );
                    },
                    loading: () => const UserHeader(
                      nombre: 'Cargando...',
                      subtitulo: 'Cargando...',
                    ),
                    error: (e, _) => UserHeader(
                      nombre: 'Error',
                      subtitulo: 'Error al cargar perfil',
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
                        onTap: () => context.push(AppRoutes.perfilEstudiante),
                      ),
                      DashboardTile(
                        icono: Icons.warning_amber_rounded,
                        titulo: 'Reportar daños',
                        destacado: true,
                        onTap: () => context.push(AppRoutes.reportarDanos),
                      ),
                      DashboardTile(
                        icono: Icons.build_outlined,
                        titulo: 'Tus reportes',
                        onTap: () => context.push(AppRoutes.misReportes),
                      ),
                      DashboardTile(
                        icono: Icons.notifications_none,
                        titulo: 'Notificaciones',
                        onTap: () =>
                            context.push(AppRoutes.notificacionesEstudiante),
                      ),
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
