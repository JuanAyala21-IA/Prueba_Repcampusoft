import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/results.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/curved_green_background.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/uts_header.dart';
import '../../auth/domain/rol_enum.dart';
import '../../auth/domain/usuario.dart';
import '../data/providers/usuario_providers.dart';

/// Formulario del superadministrador para crear una cuenta con rol
/// `persona`, `administrativo` o `mantenimiento`.
class CreateUserScreen extends ConsumerStatefulWidget {
  const CreateUserScreen({super.key});

  @override
  ConsumerState<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends ConsumerState<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _cargo = TextEditingController();
  final _dependencia = TextEditingController();
  final _telefono = TextEditingController();
  RolEnum _rol = RolEnum.persona;
  bool _creando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _contrasena.dispose();
    _cargo.dispose();
    _dependencia.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _crearUsuario() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _creando = true);
    final Result<Usuario> resultado = await ref
        .read(usuarioRepositoryProvider)
        .crearUsuario(
          nombre: _nombre.text,
          correo: _correo.text,
          contrasena: _contrasena.text,
          rol: _rol,
          cargo: _cargo.text,
          dependencia: _dependencia.text,
          telefono: _telefono.text,
        );
    if (!mounted) return;
    setState(() => _creando = false);

    switch (resultado) {
      case Success():
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Cuenta creada'),
            content: Text(
              'Se creó la cuenta de ${_nombre.text.trim()} como '
              '${_rol.etiqueta}. Se envió un correo de verificación a '
              '${_correo.text.trim()}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
        if (mounted) context.pop();
      case Failure():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.message),
            backgroundColor: AppColors.estadoPendiente,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool esPersonal = _rol.esPersonal;
    return Scaffold(
      body: CurvedGreenBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const UtsHeader(
                  titulo: 'Crear usuario',
                  subtitulo: 'La cuenta recibirá un correo de verificación',
                  mostrarLogo: false,
                ),
                const SizedBox(height: 12),
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
                          etiqueta: 'Correo institucional',
                          controlador: _correo,
                          validator: Validators.correo,
                        ),
                        const SizedBox(height: 16),
                        LabelledField(
                          etiqueta: 'Contraseña inicial',
                          controlador: _contrasena,
                          esContrasena: true,
                          validator: Validators.contrasena,
                        ),
                        const SizedBox(height: 20),
                        Text('Rol', style: AppTypography.textTheme.titleSmall),
                        const SizedBox(height: 6),
                        _SelectorRol(
                          rol: _rol,
                          onChanged: (rol) => setState(() => _rol = rol),
                        ),
                        if (esPersonal) ...[
                          const SizedBox(height: 16),
                          LabelledField(
                            etiqueta: 'Cargo',
                            controlador: _cargo,
                            hint: 'Ej. Auxiliar administrativo',
                          ),
                          const SizedBox(height: 16),
                          LabelledField(
                            etiqueta: 'Dependencia / Área',
                            controlador: _dependencia,
                            hint: 'Ej. Oficina de infraestructura',
                          ),
                        ],
                        const SizedBox(height: 16),
                        LabelledField(
                          etiqueta: 'Teléfono (opcional)',
                          controlador: _telefono,
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          texto: _creando ? 'Creando…' : 'CREAR USUARIO',
                          onPressed: _creando ? null : _crearUsuario,
                          cargando: _creando,
                          variante: Variante.verdeOscuro,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorRol extends StatelessWidget {
  const _SelectorRol({required this.rol, required this.onChanged});

  final RolEnum rol;
  final ValueChanged<RolEnum> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RolEnum.rolesGestionables.map((opcion) {
        final bool seleccionado = opcion == rol;
        return ChoiceChip(
          label: Text(opcion.etiqueta),
          selected: seleccionado,
          onSelected: (_) => onChanged(opcion),
          selectedColor: AppColors.utsGreen.withValues(alpha: 0.35),
          side: BorderSide(
            color: seleccionado ? AppColors.utsGreen : AppColors.divider,
          ),
          labelStyle: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: seleccionado ? FontWeight.w700 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
