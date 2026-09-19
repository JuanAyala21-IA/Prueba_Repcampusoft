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
import '../../../shared/widgets/uts_logo.dart';
import '../../auth/domain/rol_enum.dart';

/// Pantalla 1: Iniciar Sesión.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  RolEnum? _modo;

  void _iniciarSesion() {
    final RolEnum rol = _modo ?? RolEnum.persona;
    ref.read(sesionProvider.notifier).simularLogin(rol);
  }

  void _seleccionarModo(RolEnum rol) {
    setState(() => _modo = rol);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _CurvaVerdeInferior())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: CircularButtonUts(
                      icono: Icons.question_mark,
                      onPressed: () => context.go(AppRoutes.info),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const UtsLogo(altura: 60),
                  const SizedBox(height: 16),
                  Text('REPCAMPUSOFT', style: AppTypography.textTheme.displayLarge),
                  const SizedBox(height: 4),
                  Text('INICIAR SESIÓN', style: AppTypography.textTheme.titleMedium),
                  const SizedBox(height: 20),
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
                      children: [
                        const UserAvatarInline(),
                        const SizedBox(height: 12),
                        Text('Ingresa tus credenciales',
                            style: AppTypography.textTheme.titleSmall),
                        const SizedBox(height: 18),
                        PillField(
                          hint: 'Correo institucional',
                          icono: Icons.mail_outline,
                          controlador: _correo,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        PillField(
                          hint: 'Contraseña',
                          icono: Icons.lock_outline,
                          esContrasena: true,
                          controlador: _clave,
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          texto: 'Iniciar sesión',
                          onPressed: _iniciarSesion,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => _seleccionarModo(RolEnum.administrativo),
                          child: Text(
                            _modo == RolEnum.administrativo
                                ? 'Modo: Administrativo (seleccionado)'
                                : 'Ingresar como Administrativo',
                          ),
                        ),
                        TextButton(
                          onPressed: () => _seleccionarModo(RolEnum.persona),
                          child: Text(
                            _modo == RolEnum.persona
                                ? 'Modo: Persona (seleccionado)'
                                : 'Ingresar como persona',
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.registro),
                          child: const Text('¿No tienes una cuenta? Registrate'),
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.recuperar),
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('- - - - - - - - - - - -',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                  const SizedBox(height: 8),
                  const Text(
                    'UTS - Universitaria Tecnologia de Santander',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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

class UserAvatarInline extends StatelessWidget {
  const UserAvatarInline({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: const BoxDecoration(color: AppColors.textPrimary, shape: BoxShape.circle),
      child: const Icon(Icons.person, color: Colors.white, size: 40),
    );
  }
}

/// Fondo curvo verde UTS en la parte inferior (pantalla 1.png).
class _CurvaVerdeInferior extends CustomPainter {
  const _CurvaVerdeInferior();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = AppColors.utsGreen;
    final Path path = Path()
      ..moveTo(0, size.height * 0.78)
      ..cubicTo(size.width * 0.18, size.height * 0.68, size.width * 0.4, size.height * 0.78,
          size.width, size.height * 0.72)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}