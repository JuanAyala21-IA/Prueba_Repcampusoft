import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/circular_button_uts.dart';
import '../../../shared/widgets/primary_button.dart';

/// Pantalla de bienvenida previa al login (ruta inicial '/').
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.welcomeBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CircularButtonUts(
                  icono: Icons.question_mark,
                  fondo: AppColors.utsGreen,
                  onPressed: () => context.go(AppRoutes.info),
                ),
              ),
              const Spacer(),
              // Logo UTS en blanco (mismo isotipo que UtsHeader, sin círculo anotado)
              Image.asset(
                'assets/images/logo_uts_blanco.png',
                width: 260,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 44),
              Container(
                width: 36,
                height: 1.2,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 12),
              Text(
                'Sistema de reporte de daños',
                textAlign: TextAlign.center,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Botón sólido INICIAR SESIÓN
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  texto: 'INICIAR SESIÓN',
                  onPressed: () => context.go(AppRoutes.login),
                ),
              ),
              const SizedBox(height: 12),
              // Botón contorno REGISTRARSE
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.registro),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: AppTypography.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  child: const Text('REGISTRARSE'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
