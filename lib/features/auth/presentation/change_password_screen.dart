import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/routes/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/circular_button_uts.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/primary_button.dart';

/// Cambiar Contraseña - permite cambiar la contraseña del usuario autenticado.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contrasenaActual = TextEditingController();
  final _contrasenaNueva = TextEditingController();
  final _confirmarContrasena = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _contrasenaActual.dispose();
    _contrasenaNueva.dispose();
    _confirmarContrasena.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final String? error = await ref
        .read(sesionProvider.notifier)
        .cambiarContrasena(
          contrasenaActual: _contrasenaActual.text,
          contrasenaNueva: _contrasenaNueva.text,
        );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña cambiada correctamente')),
      );
      // Cerrar sesión y redirigir a login
      await ref.read(sesionProvider.notifier).cerrarSesion();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'Cambiar Contraseña',
                      style: AppTypography.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Container(
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
                        children: [
                          PillField(
                            hint: 'Contraseña actual',
                            icono: Icons.lock_outline,
                            controlador: _contrasenaActual,
                            esContrasena: true,
                            textInputAction: TextInputAction.next,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          PillField(
                            hint: 'Nueva contraseña',
                            icono: Icons.lock_outline,
                            controlador: _contrasenaNueva,
                            esContrasena: true,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requerido';
                              if (v.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          PillField(
                            hint: 'Confirmar nueva contraseña',
                            icono: Icons.lock_outline,
                            controlador: _confirmarContrasena,
                            esContrasena: true,
                            textInputAction: TextInputAction.done,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requerido';
                              if (v != _contrasenaNueva.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) =>
                                _guardando ? null : _guardar(),
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            texto: _guardando
                                ? 'Guardando…'
                                : 'CAMBIAR CONTRASEÑA',
                            onPressed: _guardando ? null : _guardar,
                          ),
                        ],
                      ),
                    ),
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
