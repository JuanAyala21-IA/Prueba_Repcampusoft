import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/tipo_acceso.dart';

/// Avatar circular negro con silueta de usuario (pantallas 1, 3, 4, 5, 6, 7.png).
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.tamano});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: const BoxDecoration(
        color: AppColors.textPrimary,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.person, color: Colors.white, size: tamano * 0.55),
    );
  }
}

/// Selector "Estudiante / Administrativo" exclusivo del inicio de sesión.
///
/// No cambia el rol del usuario: solo indica con qué tipo de cuenta se está
/// intentando entrar. La validación real se hace contra `users/{uid}` al
/// autenticarse.
class TipoAccesoSelector extends StatelessWidget {
  const TipoAccesoSelector({
    super.key,
    required this.seleccionado,
    required this.onChanged,
    this.habilitado = true,
  });

  final TipoAcceso seleccionado;
  final ValueChanged<TipoAcceso>? onChanged;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          for (final TipoAcceso acceso in TipoAcceso.values)
            Expanded(
              child: _OpcionAcceso(
                acceso: acceso,
                activa: acceso == seleccionado,
                onTap: habilitado ? () => onChanged?.call(acceso) : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _OpcionAcceso extends StatelessWidget {
  const _OpcionAcceso({
    required this.acceso,
    required this.activa,
    required this.onTap,
  });

  final TipoAcceso acceso;
  final bool activa;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final IconData icono = acceso == TipoAcceso.estudiante
        ? Icons.school_outlined
        : Icons.badge_outlined;
    final Color colorTexto = activa
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: activa,
      label: 'Ingresar como ${acceso.etiqueta}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
            decoration: BoxDecoration(
              color: activa ? AppColors.utsGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono, size: 18, color: colorTexto),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    acceso.etiqueta,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      color: colorTexto,
                      fontWeight: activa ? FontWeight.w700 : FontWeight.w600,
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

/// Separador "o" para alternar entre Google y correo/contraseña.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, this.texto = 'o'});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            texto,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider, height: 1)),
      ],
    );
  }
}

/// Botón de inicio de sesión/registro con Google.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.texto = 'Continuar con Google',
    this.cargando = false,
  });

  final VoidCallback? onPressed;
  final String texto;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: cargando ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: AppTypography.textTheme.labelLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (cargando)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textPrimary,
                ),
              )
            else
              const _GoogleLogo(),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                cargando ? 'Conectando…' : texto,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Isotipo de Google (G de cuatro colores) dibujado sin dependencias externas.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: const _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double lado = size.width;
    final Offset centro = Offset(lado / 2, lado / 2);
    final double grosor = lado * 0.22;
    final double radio = lado * 0.38;
    final Rect arco = Rect.fromCircle(center: centro, radius: radio);

    final Paint pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.butt;

    // Arcos del isotipo en sentido horario: rojo, azul, verde y amarillo.
    canvas.drawArc(
      arco,
      -0.79,
      1.57,
      false,
      pincel..color = const Color(0xFFEA4335),
    );
    canvas.drawArc(
      arco,
      0.79,
      1.57,
      false,
      pincel..color = const Color(0xFF4285F4),
    );
    canvas.drawArc(
      arco,
      2.36,
      1.57,
      false,
      pincel..color = const Color(0xFF34A853),
    );
    canvas.drawArc(
      arco,
      3.93,
      1.57,
      false,
      pincel..color = const Color(0xFFFBBC05),
    );

    // Barra azul horizontal que cierra la G por la derecha.
    canvas.drawRect(
      Rect.fromLTWH(
        centro.dx,
        centro.dy - grosor / 2,
        radio + grosor / 2,
        grosor,
      ),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
