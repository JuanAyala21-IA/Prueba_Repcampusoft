import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routes/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/circular_button_uts.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/uts_logo.dart';
import '../../auth/domain/rol_enum.dart';
import 'auth_widgets.dart';

/// Pantalla 3: Registro de Usuario.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  RolEnum _rol = RolEnum.persona;

  void _registrar() {
    ref.read(sesionProvider.notifier).simularLogin(_rol);
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LabelledField(etiqueta: 'Correo'),
                    const SizedBox(height: 16),
                    const LabelledField(etiqueta: 'Contraseña'),
                    const SizedBox(height: 16),
                    const LabelledField(etiqueta: 'Confirmar clave'),
                    const SizedBox(height: 16),
                    const LabelledField(etiqueta: 'Cargo'),
                    const SizedBox(height: 22),
                    RolSelector(seleccion: _rol, onChanged: (rol) => setState(() => _rol = rol)),
                    const SizedBox(height: 22),
                    PrimaryButton(texto: 'REGISTRARSE', onPressed: _registrar),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}