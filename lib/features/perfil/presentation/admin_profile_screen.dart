import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/routes/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/circular_button_uts.dart';
import '../data/providers/perfil_providers.dart';
import 'profile_widgets.dart';

/// Pantalla 7: Perfil Administrativo (datos reales de Firestore).
class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilUsuarioProvider);
    final Sesion sesion = ref.watch(sesionProvider);
    final bool esSuperadministrador = sesion.esSuperadministrador;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(color: AppColors.background, height: screenHeight),
          Positioned.fill(child: CustomPaint(painter: _CurvaVerdeInferior())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircularButtonUts(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.welcome);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('PERFIL', style: AppTypography.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    sesion.rol?.etiqueta ?? 'Área encargada',
                    style: AppTypography.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  perfilAsync.when(
                    data: (perfil) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileCard(
                            titulo: 'Dependencia / Área',
                            iconoTitulo: Icons.apartment_outlined,
                            hijos: [
                              if (perfil != null &&
                                  perfil.dependencia != null &&
                                  perfil.dependencia!.isNotEmpty)
                                ProfileRow(
                                  icono: Icons.business_outlined,
                                  etiqueta: 'Dependencia',
                                  valor: perfil.dependencia!,
                                ),
                              if (perfil != null &&
                                  perfil.cargo != null &&
                                  perfil.cargo!.isNotEmpty)
                                ProfileRow(
                                  icono: Icons.badge_outlined,
                                  etiqueta: 'Cargo',
                                  valor: perfil.cargo!,
                                ),
                              if (perfil == null ||
                                  (perfil.dependencia == null &&
                                      perfil.cargo == null))
                                const ProfileRow(
                                  icono: Icons.info_outline,
                                  etiqueta: 'Sin información registrada',
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ProfileCard(
                            titulo: 'Datos del funcionario',
                            iconoTitulo: Icons.person_outline,
                            hijos: [
                              if (perfil != null)
                                ProfileRow(
                                  icono: Icons.mail_outline,
                                  etiqueta: 'Correo Institucional',
                                  valor: perfil.correo,
                                ),
                              if (perfil != null &&
                                  perfil.telefono != null &&
                                  perfil.telefono!.isNotEmpty)
                                ProfileRow(
                                  icono: Icons.phone_outlined,
                                  etiqueta: 'Teléfono',
                                  valor: perfil.telefono!,
                                ),
                              if (perfil == null ||
                                  perfil.telefono == null ||
                                  perfil.telefono!.isEmpty)
                                const ProfileRow(
                                  icono: Icons.phone_outlined,
                                  etiqueta: 'Teléfono',
                                  valor: 'No registrado',
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ProfileCard(
                            titulo: 'Opciones de cuenta',
                            iconoTitulo: Icons.settings,
                            hijos: [
                              ProfileRow(
                                icono: Icons.edit_outlined,
                                etiqueta: 'Editar información',
                                onTap: () =>
                                    context.push(AppRoutes.editarPerfil),
                              ),
                              ProfileRow(
                                icono: Icons.lock_outline,
                                etiqueta: 'Cambiar contraseña',
                                onTap: () =>
                                    context.push(AppRoutes.cambiarContrasena),
                              ),
                              if (esSuperadministrador) ...[
                                ProfileRow(
                                  icono: Icons.manage_accounts_outlined,
                                  etiqueta: 'Gestión de usuarios',
                                  onTap: () =>
                                      context.push(AppRoutes.gestionUsuarios),
                                ),
                                ProfileRow(
                                  icono: Icons.bug_report_outlined,
                                  etiqueta: 'Fallas de la app',
                                  onTap: () =>
                                      context.push(AppRoutes.fallasApp),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Center(
                            child: Text(
                              'UTS - Universitaria Tecnologica de Santander',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Center(child: Text('Error al cargar perfil: $e')),
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
