import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routes/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/results.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/uts_header.dart';
import '../domain/rol_enum.dart';

/// Pantalla intermedia del gate §5.3: correo autenticado pero sin verificar.
/// "Ya verifiqué" recarga la sesión y, con el correo confirmado, crea el
/// perfil `users/{uid}` con el rol efectivo (RF-03, RF-04).
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _enviando = false;
  bool _verificando = false;

  Future<void> _reenviar() async {
    setState(() => _enviando = true);
    final String? error = await ref
        .read(sesionProvider.notifier)
        .reenviarCorreoVerificacion();
    if (!mounted) return;
    setState(() => _enviando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              'Correo de verificación reenviado. Revisa tu bandeja de entrada.',
        ),
      ),
    );
  }

  Future<void> _yaVerifique() async {
    FocusScope.of(context).unfocus();
    setState(() => _verificando = true);
    final Result<RolEnum?> resultado = await ref
        .read(sesionProvider.notifier)
        .completarVerificacion();
    if (!mounted) return;
    setState(() => _verificando = false);
    if (resultado is Failure<RolEnum?>) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(resultado.message)));
      return;
    }
    final RolEnum? rol = (resultado as Success<RolEnum?>).value;
    if (rol != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Correo verificado. Tu rol asignado es: ${rol.etiqueta}.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Sesion sesion = ref.watch(sesionProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const UtsHeader(
                titulo: 'Verifica tu correo',
                mostrarRetroceso: false,
              ),
              const SizedBox(height: 30),
              const Icon(
                Icons.mark_email_read_outlined,
                size: 72,
                color: AppColors.utsGreen,
              ),
              const SizedBox(height: 20),
              Text(
                'Tu cuenta aún no verifica el correo institucional.\n'
                'Revisa tu bandeja de entrada y confirma el enlace para continuar.',
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.bodyMedium,
              ),
              if (sesion.correo != null && sesion.correo!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Cuenta: ${sesion.correo}',
                  textAlign: TextAlign.center,
                  style: AppTypography.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 30),
              PrimaryButton(
                texto: _verificando ? 'Verificando…' : 'Ya verifiqué mi correo',
                onPressed: _verificando ? null : _yaVerifique,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _enviando ? null : _reenviar,
                child: Text(
                  _enviando ? 'Reenviando…' : 'Reenviar correo de verificación',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.read(sesionProvider.notifier).cerrarSesion(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
