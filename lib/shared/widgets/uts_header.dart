import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/app_router.dart';
import '../../core/theme/app_typography.dart';
import 'circular_button_uts.dart';

/// Encabezado común de las pantallas con logo UTS, título y retroceso circular.
/// [accion] permite colocar un icono de campana con badge, avatar, etc.
/// [retrocesoADerecha] si true, pone el botón de retroceso a la derecha (para AboutScreen).
class UtsHeader extends StatelessWidget {
  const UtsHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.accion,
    this.onBack,
    this.mostrarRetroceso = true,
    this.mostrarLogo = true,
    this.retrocesoADerecha = false,
  });

  final String titulo;
  final String? subtitulo;
  final Widget? accion;
  final VoidCallback? onBack;
  final bool mostrarRetroceso;
  final bool mostrarLogo;
  final bool retrocesoADerecha;

  @override
  Widget build(BuildContext context) {
    final backButton = mostrarRetroceso
        ? CircularButtonUts(
            onPressed:
                onBack ??
                () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.welcome);
                  }
                },
          )
        : const SizedBox(width: 44, height: 44);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!retrocesoADerecha) SizedBox(width: 44, child: backButton),
                if (mostrarLogo)
                  const Expanded(
                    child: Center(
                      child: Image(
                        image: AssetImage('assets/images/logo_uts.png'),
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
                if (retrocesoADerecha)
                  SizedBox(width: 44, child: backButton)
                else
                  SizedBox(
                    width: 44,
                    child: accion == null ? null : Center(child: accion),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.titleLarge,
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitulo ?? '',
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.titleSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
