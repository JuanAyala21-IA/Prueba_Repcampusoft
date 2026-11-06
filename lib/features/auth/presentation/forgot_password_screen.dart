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

/// Recuperar contraseña (RF-10; arquitectura §5.1 la conecta desde login y perfil).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  bool _enviando = false;

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    final String? error = await ref
        .read(sesionProvider.notifier)
        .recuperarContrasena(_correo.text);
    if (!mounted) return;
    setState(() => _enviando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'Te enviamos un enlace de recuperación a tu correo institucional.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _correo.dispose();
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                            context.go(AppRoutes.login);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 90),
                  Center(
                    child: Text(
                      'Recuperar contraseña',
                      style: AppTypography.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 30),
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
                          PillField(
                            hint: 'Correo institucional',
                            icono: Icons.mail_outline,
                            controlador: _correo,
                            textInputAction: TextInputAction.done,
                            validator: Validators.correo,
                            onFieldSubmitted: (_) =>
                                _enviando ? null : _enviar(),
                          ),
                          const SizedBox(height: 20),
                          PrimaryButton(
                            texto: _enviando
                                ? 'Enviando…'
                                : 'Enviar enlace de recuperación',
                            onPressed: _enviando ? null : _enviar,
                          ),
                        ],
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
