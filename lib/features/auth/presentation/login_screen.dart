import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/routes/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/circular_button_uts.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/primary_button.dart';
import 'auth_widgets.dart';

/// Pantalla 1: Iniciar Sesión (RF-01, HU-01). El rol se resuelve desde
/// `users/{uid}` según el gate §5.3, no por modo seleccionado.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _enviando = false;
  bool _enviandoGoogle = false;

  Future<void> _iniciarSesion() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    final String? error = await ref
        .read(sesionProvider.notifier)
        .iniciarSesion(correo: _correo.text, contrasena: _clave.text);
    if (!mounted) return;
    setState(() => _enviando = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _iniciarSesionConGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() => _enviandoGoogle = true);
    final String? error = await ref
        .read(sesionProvider.notifier)
        .iniciarSesionConGoogle();
    if (!mounted) return;
    setState(() => _enviandoGoogle = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                  const SizedBox(height: 24),
                  Text(
                    'REPCAMPUSOFT',
                    style: AppTypography.textTheme.displayLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'INICIAR SESIÓN',
                    style: AppTypography.textTheme.titleMedium,
                  ),
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
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          const UserAvatarInline(),
                          const SizedBox(height: 12),
                          Text(
                            'Ingresa tus credenciales',
                            style: AppTypography.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 18),
                          PillField(
                            hint: 'Correo institucional',
                            icono: Icons.mail_outline,
                            controlador: _correo,
                            textInputAction: TextInputAction.next,
                            validator: Validators.correo,
                          ),
                          const SizedBox(height: 14),
                          PillField(
                            hint: 'Contraseña',
                            icono: Icons.lock_outline,
                            esContrasena: true,
                            controlador: _clave,
                            textInputAction: TextInputAction.done,
                            validator: Validators.contrasena,
                            onFieldSubmitted: (_) =>
                                _enviando ? null : _iniciarSesion(),
                          ),
                          const SizedBox(height: 20),
                          PrimaryButton(
                            texto: _enviando ? 'Ingresando…' : 'Iniciar sesión',
                            onPressed: (_enviando || _enviandoGoogle)
                                ? null
                                : _iniciarSesion,
                          ),
                          const SizedBox(height: 16),
                          const AuthDivider(),
                          const SizedBox(height: 16),
                          GoogleSignInButton(
                            onPressed: (_enviando || _enviandoGoogle)
                                ? null
                                : _iniciarSesionConGoogle,
                            cargando: _enviandoGoogle,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.recuperar),
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'UTS - Universitaria Tecnologia de Santander',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

class UserAvatarInline extends StatelessWidget {
  const UserAvatarInline({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: const BoxDecoration(
        color: AppColors.textPrimary,
        shape: BoxShape.circle,
      ),
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
