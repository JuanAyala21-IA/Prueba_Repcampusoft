import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routes/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/circular_button_uts.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/uts_logo.dart';
import '../domain/rol_enum.dart';
import 'auth_widgets.dart';

/// Pantalla 3: Registro de Usuario (RF-03, RF-04, HU-02). Crea la cuenta y
/// envía verificación; el perfil `users/{uid}` se crea al verificar el correo.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _confirmar = TextEditingController();
  final _cargo = TextEditingController();
  RolEnum _rol = RolEnum.persona;
  bool _enviando = false;

  Future<void> _registrar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    final String? error = await ref.read(sesionProvider.notifier).registrar(
          nombre: _nombre.text,
          correo: _correo.text,
          contrasena: _clave.text,
          cargo: _cargo.text,
          rolIntentado: _rol,
        );
    if (!mounted) return;
    setState(() => _enviando = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cuenta creada. Revisa tu correo institucional y confirma el enlace de verificación.'),
      ));
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _clave.dispose();
    _confirmar.dispose();
    _cargo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Row(
                children: [
                  CircularButtonUts(
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(child: Center(child: UtsLogo(altura: 40, compacto: true))),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 14),
              Text('REGISTRO',
                  textAlign: TextAlign.center, style: AppTypography.textTheme.titleLarge),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabelledField(
                        etiqueta: 'Nombre completo',
                        controlador: _nombre,
                        validator: Validators.requerido,
                      ),
                      const SizedBox(height: 16),
                      LabelledField(
                        etiqueta: 'Correo',
                        controlador: _correo,
                        validator: Validators.correo,
                      ),
                      const SizedBox(height: 16),
                      LabelledField(
                        etiqueta: 'Contraseña',
                        controlador: _clave,
                        esContrasena: true,
                        validator: Validators.contrasena,
                      ),
                      const SizedBox(height: 16),
                      LabelledField(
                        etiqueta: 'Confirmar clave',
                        controlador: _confirmar,
                        esContrasena: true,
                        validator: (valor) => Validators.confirmarContrasena(
                          campo: _clave.text,
                          valor: valor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LabelledField(etiqueta: 'Cargo (opcional)', controlador: _cargo),
                      const SizedBox(height: 22),
                      RolSelector(seleccion: _rol, onChanged: (rol) => setState(() => _rol = rol)),
                      const SizedBox(height: 22),
                      PrimaryButton(
                        texto: _enviando ? 'Registrando…' : 'REGISTRARSE',
                        onPressed: _enviando ? null : _registrar,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}