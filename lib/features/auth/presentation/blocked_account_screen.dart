import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routes/session_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/uts_header.dart';

/// Cuenta deshabilitada por el superadministrador. El gate de sesión no deja
/// avanzar a ningún módulo; la única acción disponible es cerrar sesión.
class BlockedAccountScreen extends ConsumerWidget {
  const BlockedAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Sesion sesion = ref.watch(sesionProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const UtsHeader(
                titulo: 'Cuenta deshabilitada',
                mostrarRetroceso: false,
              ),
              const SizedBox(height: 40),
              const Icon(
                Icons.block_outlined,
                size: 80,
                color: AppColors.estadoRechazado,
              ),
              const SizedBox(height: 20),
              Text(
                'Tu cuenta fue deshabilitada por el superadministrador.',
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (sesion.correo != null && sesion.correo!.isNotEmpty)
                Text(
                  'Cuenta: ${sesion.correo}',
                  textAlign: TextAlign.center,
                  style: AppTypography.textTheme.bodySmall,
                ),
              const SizedBox(height: 12),
              Text(
                'Si crees que se trata de un error, comunícate con la oficina de las UTS encargada de REPCAMPUSOFT.',
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                texto: 'Cerrar sesión',
                onPressed: () =>
                    ref.read(sesionProvider.notifier).cerrarSesion(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
