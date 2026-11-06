import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/routes/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/data/providers/auth_providers.dart';
import '../../../features/auth/domain/auth_repository.dart';
import '../../../features/auth/domain/auth_usuario.dart';
import '../../../features/auth/domain/usuario.dart';
import '../../../shared/widgets/circular_button_uts.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/providers/perfil_providers.dart';

/// Editar Perfil - permite editar nombre, teléfono, cargo y dependencia.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _cargo = TextEditingController();
  final _dependencia = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final AuthRepository repo = ref.read(authRepositoryProvider);
    final AuthUsuario? auth = repo.usuarioActual();
    if (auth == null) return;

    final Usuario? perfil = await repo.obtenerPerfil(auth.uid);
    if (perfil != null && mounted) {
      _nombre.text = perfil.nombre;
      _telefono.text = perfil.telefono ?? '';
      _cargo.text = perfil.cargo ?? '';
      _dependencia.text = perfil.dependencia ?? '';
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _cargo.dispose();
    _dependencia.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final String? error = await ref
        .read(sesionProvider.notifier)
        .actualizarPerfil(
          nombre: _nombre.text,
          telefono: _telefono.text.trim().isEmpty
              ? null
              : _telefono.text.trim(),
          cargo: _cargo.text.trim().isEmpty ? null : _cargo.text.trim(),
          dependencia: _dependencia.text.trim().isEmpty
              ? null
              : _dependencia.text.trim(),
        );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      // Refresca el perfil compartido para que el nombre y los datos se vean
      // actualizados al volver, sin reiniciar la navegación.
      ref.invalidate(perfilUsuarioProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
      if (context.canPop()) context.pop();
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
                  Text(
                    'Editar Perfil',
                    style: AppTypography.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
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
                          LabelledField(
                            etiqueta: 'Nombre',
                            controlador: _nombre,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Requerido'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          LabelledField(
                            etiqueta: 'Teléfono',
                            controlador: _telefono,
                          ),
                          const SizedBox(height: 16),
                          LabelledField(etiqueta: 'Cargo', controlador: _cargo),
                          const SizedBox(height: 16),
                          LabelledField(
                            etiqueta: 'Dependencia',
                            controlador: _dependencia,
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            texto: _guardando ? 'Guardando…' : 'GUARDAR',
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
