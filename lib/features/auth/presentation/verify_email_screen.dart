import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routes/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/uts_header.dart';

/// Pantalla intermedia del gate §5.3: correo autenticado pero sin verificar.
class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const UtsHeader(titulo: 'Verifica tu correo', mostrarRetroceso: false),
              const SizedBox(height: 30),
              const Icon(Icons.mark_email_read_outlined, size: 72, color: AppColors.utsGreen),
              const SizedBox(height: 20),
              Text(
                'Tu cuenta aún no verifica el correo institucional.\n'
                'Revisa tu bandeja de entrada y confirma el enlace para continuar.',
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.bodyMedium,
              ),
              const SizedBox(height: 30),
              PrimaryButton(
                texto: 'Cerrar sesión',
                onPressed: () => ref.read(sesionProvider.notifier).cerrarSesion(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}