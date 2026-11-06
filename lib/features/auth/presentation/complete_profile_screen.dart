import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/routes/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/results.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/curved_green_background.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/uts_header.dart';
import '../domain/rol_enum.dart';

/// "Retomar registro" del gate §5.3: usuario autenticado y con correo
/// verificado, pero sin perfil `users/{uid}` (p. ej. verificó el correo sin
/// completar el registro). El autorregistro crea únicamente el rol
/// `persona`; los demás roles los asigna el superadministrador.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmarContrasena = TextEditingController();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    // Google entrega el nombre en el proveedor; se usa para prellenar.
    _nombre.text = ref.read(sesionProvider).nombreSugerido ?? '';
  }

  Future<void> _crearPerfil() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final Sesion sesion = ref.read(sesionProvider);
    final String correoSesion = sesion.correo ?? '';
    setState(() => _enviando = true);
    final Result<RolEnum> resultado = await ref
        .read(sesionProvider.notifier)
        .completarPerfil(
          nombre: _nombre.text,
          correo: correoSesion,
          // Las cuentas de Google crean aquí su contraseña para poder entrar
          // también con correo y contraseña.
          contrasena: sesion.autenticadoConGoogle ? _contrasena.text : null,
        );
    if (!mounted) return;
    setState(() => _enviando = false);
    if (resultado is Failure<RolEnum>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(resultado.message)));
    } else {
      final RolEnum rol = (resultado as Success<RolEnum>).value;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sesion.autenticadoConGoogle
                ? 'Perfil creado. Tu rol asignado es: ${rol.etiqueta}. '
                      'Ya puedes iniciar sesión con tu correo y contraseña.'
                : 'Perfil creado. Tu rol asignado es: ${rol.etiqueta}.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _contrasena.dispose();
    _confirmarContrasena.dispose();
    super.dispose();
  }

  /// El botón de regresar cierra la sesión de Google y vuelve al inicio:
  /// al estar autenticado sin perfil, el router redirige de nuevo a esta
  /// pantalla, por eso el retroceso normal no hacía nada.
  Future<void> _regresar() async {
    await ref.read(sesionProvider.notifier).cerrarSesion();
    if (!mounted) return;
    context.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final Sesion sesion = ref.watch(sesionProvider);
    return Scaffold(
      body: CurvedGreenBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UtsHeader(
                  titulo: 'Completa tu registro',
                  mostrarLogo: false,
                  onBack: _regresar,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tu identidad está verificada. Completa tus datos para asignarte el rol.',
                  style: AppTypography.textTheme.bodyMedium,
                ),
                if ((sesion.correo ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Correo: ${sesion.correo}',
                    style: AppTypography.textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 22),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabelledField(
                          etiqueta: 'Nombre completo',
                          controlador: _nombre,
                          validator: Validators.requerido,
                        ),
                        if (sesion.autenticadoConGoogle) ...[
                          const SizedBox(height: 18),
                          Text(
                            'Crea una contraseña para tu cuenta',
                            style: AppTypography.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Con ella podrás iniciar sesión también con tu '
                            'correo y contraseña.',
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          LabelledField(
                            etiqueta: 'Contraseña',
                            controlador: _contrasena,
                            esContrasena: true,
                            hint: 'Mínimo 6 caracteres',
                            validator: Validators.contrasena,
                          ),
                          const SizedBox(height: 18),
                          LabelledField(
                            etiqueta: 'Confirmar contraseña',
                            controlador: _confirmarContrasena,
                            esContrasena: true,
                            hint: 'Repite tu contraseña',
                            validator: (valor) =>
                                Validators.confirmarContrasena(
                                  campo: _contrasena.text,
                                  valor: valor,
                                ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        PrimaryButton(
                          texto: _enviando ? 'Creando perfil…' : 'CREAR PERFIL',
                          onPressed: _enviando ? null : _crearPerfil,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
