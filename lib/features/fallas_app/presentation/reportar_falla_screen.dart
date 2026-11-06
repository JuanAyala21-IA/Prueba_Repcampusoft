import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/curved_green_background.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/uts_header.dart';
import '../data/providers/fallas_app_providers.dart';

/// Reportar una falla de la aplicación (buzón sin estados).
/// El usuario describe la falla y listo: sin seguimiento ni estados.
class ReportarFallaScreen extends ConsumerStatefulWidget {
  const ReportarFallaScreen({super.key});

  @override
  ConsumerState<ReportarFallaScreen> createState() =>
      _ReportarFallaScreenState();
}

class _ReportarFallaScreenState extends ConsumerState<ReportarFallaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mensaje = TextEditingController();
  final _pantalla = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _mensaje.dispose();
    _pantalla.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await ref
          .read(fallasAppRepositoryProvider)
          .reportar(
            mensaje: _mensaje.text,
            pantalla: _pantalla.text.trim().isEmpty ? null : _pantalla.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte enviado. Gracias por tu ayuda.')),
      );
      if (context.canPop()) context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo enviar el reporte. Inténtalo de nuevo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CurvedGreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              const UtsHeader(
                titulo: 'Reportar falla de la app',
                subtitulo: 'Cuéntanos qué pasó para revisarlo',
                mostrarLogo: false,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  child: Column(
                    children: [
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
                            children: [
                              LabelledField(
                                etiqueta: '¿Qué falla viste en la app?',
                                controlador: _mensaje,
                                multiline: true,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Describe la falla'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              LabelledField(
                                etiqueta: '¿En qué pantalla pasó? (opcional)',
                                controlador: _pantalla,
                              ),
                              const SizedBox(height: 24),
                              PrimaryButton(
                                texto: _enviando
                                    ? 'Enviando…'
                                    : 'ENVIAR REPORTE',
                                onPressed: _enviando ? null : _enviar,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Color.alphaBlend(
                            AppColors.utsGreen.withValues(alpha: 0.16),
                            Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: AppColors.welcomeBackground,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Se adjuntarán automáticamente la versión de la app, '
                                'el sistema operativo y el modelo del dispositivo.',
                                style: AppTypography.textTheme.bodySmall
                                    ?.copyWith(height: 1.35),
                              ),
                            ),
                          ],
                        ),
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
