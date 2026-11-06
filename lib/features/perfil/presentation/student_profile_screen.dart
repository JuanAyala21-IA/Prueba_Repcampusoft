import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/routes/session_provider.dart';
import '../../../shared/widgets/curved_green_background.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/uts_header.dart';
import '../data/providers/perfil_providers.dart';
import 'profile_widgets.dart';

/// Pantalla 6: Perfil Estudiante (datos reales de Firestore).
class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilUsuarioProvider);

    void cerrarSesion() => ref.read(sesionProvider.notifier).cerrarSesion();

    return Scaffold(
      body: CurvedGreenBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                perfilAsync.when(
                  data: (perfil) {
                    final nombre = perfil?.nombre ?? '';
                    return Column(
                      children: [
                        UtsHeader(
                          titulo: 'Perfil',
                          mostrarLogo: false,
                          subtitulo: nombre.isNotEmpty
                              ? nombre
                              : 'Información personal',
                        ),
                        const SizedBox(height: 16),
                        ProfileCard(
                          titulo: 'Información de contacto',
                          iconoTitulo: Icons.mail_outline,
                          hijos: [
                            if (perfil != null)
                              ProfileRow(
                                icono: Icons.mail_outline,
                                etiqueta: 'Correo',
                                valor: perfil.correo,
                              ),
                            if (perfil != null &&
                                perfil.telefono != null &&
                                perfil.telefono!.isNotEmpty)
                              ProfileRow(
                                icono: Icons.phone_outlined,
                                etiqueta: 'Teléfono',
                                valor: perfil.telefono!,
                              ),
                            if (perfil == null ||
                                perfil.telefono == null ||
                                perfil.telefono!.isEmpty)
                              const ProfileRow(
                                icono: Icons.phone_outlined,
                                etiqueta: 'Teléfono',
                                valor: 'No registrado',
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ProfileCard(
                          titulo: 'Configuración de la cuenta',
                          iconoTitulo: Icons.settings,
                          hijos: [
                            ProfileRow(
                              icono: Icons.edit_outlined,
                              etiqueta: 'Editar información',
                              onTap: () => context.push(AppRoutes.editarPerfil),
                            ),
                            ProfileRow(
                              icono: Icons.lock_outline,
                              etiqueta: 'Cambiar contraseña',
                              onTap: () =>
                                  context.push(AppRoutes.cambiarContrasena),
                            ),
                            ProfileRow(
                              icono: Icons.bug_report_outlined,
                              etiqueta: 'Reportar falla de la app',
                              onTap: () =>
                                  context.push(AppRoutes.reportarFalla),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          texto: 'Cerrar sesión',
                          onPressed: cerrarSesion,
                          variante: Variante.verdeOscuro,
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('Error al cargar perfil: $e')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
