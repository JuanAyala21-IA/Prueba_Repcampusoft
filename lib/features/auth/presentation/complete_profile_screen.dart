import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routes/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/results.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/uts_header.dart';
import '../domain/rol_enum.dart';
import 'auth_widgets.dart';

/// "Retomar registro" del gate §5.3: usuario autenticado y con correo
/// verificado, pero sin perfil `users/{uid}` (p. ej. verificó el correo sin
/// completar el registro). Aquí define el rol intentado para crear el perfil.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _cargo = TextEditingController();
  RolEnum _rol = RolEnum.persona;
  bool _enviando = false;

  Future<void> _crearPerfil() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final String correoSesion = ref.read(sesionProvider).correo ?? '';
    setState(() => _enviando = true);
    final Result<RolEnum> resultado = await ref
        .read(sesionProvider.notifier)
        .completarPerfil(
          nombre: _nombre.text,
          correo: correoSesion,
          cargo: _cargo.text,
          rolIntentado: _rol,
        );
    if (!mounted) return;
    setState(() => _enviando = false);
    if (resultado is Failure<RolEnum>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(resultado.message)));
    } else {
      final RolEnum rol = (resultado as Success<RolEnum>).value;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(avisoRolAsignado(intentado: _rol, asignado: rol)),
      ));
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _cargo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const UtsHeader(titulo: 'Completa tu registro'),
              const SizedBox(height: 16),
              Text(
                'Tu correo está verificado. Completa tus datos para asignarte el rol.',
                style: AppTypography.textTheme.bodyMedium,
              ),
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
                      const SizedBox(height: 16),
                      LabelledField(etiqueta: 'Cargo (opcional)', controlador: _cargo),
                      const SizedBox(height: 22),
                      RolSelector(
                        seleccion: _rol,
                        onChanged: (rol) => setState(() => _rol = rol),
                      ),
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
    );
  }
}