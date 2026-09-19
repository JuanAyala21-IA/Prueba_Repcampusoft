import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';
import 'circular_button_uts.dart';
import 'uts_logo.dart';

/// Encabezado común de las pantallas con logo UTS, título y retroceso circular.
/// [accion] permite colocar un icono de campana con badge, avatar, etc.
class UtsHeader extends StatelessWidget {
  const UtsHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.accion,
    this.onBack,
    this.mostrarRetroceso = true,
    this.mostrarLogo = true,
  });

  final String titulo;
  final String? subtitulo;
  final Widget? accion;
  final VoidCallback? onBack;
  final bool mostrarRetroceso;

  /// Oculta el logo cuando la pantalla lo dibuja más grande (ej. login).
  final bool mostrarLogo;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 44,
                  child: mostrarRetroceso
                      ? CircularButtonUts(
                          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                        )
                      : null,
                ),
                if (mostrarLogo)
                  const Expanded(child: Center(child: UtsLogo(altura: 40, compacto: true))),
                SizedBox(width: 44, child: accion == null ? null : Center(child: accion)),
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