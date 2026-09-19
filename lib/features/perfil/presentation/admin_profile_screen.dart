import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/routes/session_provider.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/uts_header.dart';
import 'profile_widgets.dart';
import 'user_header.dart';

/// Pantalla 7: Perfil Administrativo (datos simulados).
class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void cerrarSesion() => ref.read(sesionProvider.notifier).cerrarSesion();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const UtsHeader(titulo: 'PERFIL', subtitulo: 'Área encargada'),
              const UserHeader(
                nombre: 'Juan Pérez García',
                subtitulo: 'Coordinador de Mantenimiento',
              ),
              const SizedBox(height: 16),
              ProfileCard(
                titulo: 'Dependencia / Área',
                iconoTitulo: Icons.apartment_outlined,
                hijos: const [
                  ProfileRow(
                    icono: Icons.business_outlined,
                    etiqueta: 'Área de Mantenimiento',
                  ),
                  ProfileRow(
                    icono: Icons.badge_outlined,
                    etiqueta: 'Cargo',
                    valor: 'Coordinador de Mantenimiento',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ProfileCard(
                titulo: 'Datos del funcionario',
                iconoTitulo: Icons.person_outline,
                hijos: const [
                  ProfileRow(
                    icono: Icons.mail_outline,
                    etiqueta: 'Correo Institucional',
                    valor: 'juan.perez@uts.edu.co',
                  ),
                  ProfileRow(
                    icono: Icons.phone_outlined,
                    etiqueta: 'Teléfono',
                    valor: '+57 310 123 7892',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ProfileCard(
                titulo: 'Opciones de cuenta',
                iconoTitulo: Icons.settings,
                hijos: [
                  ProfileRow(
                    icono: Icons.edit_outlined,
                    etiqueta: 'Editar información',
                    onTap: () => context.go(AppRoutes.editarPerfil),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                texto: 'Cerrar sesión',
                onPressed: cerrarSesion,
              ),
            ],
          ),
        ),
      ),
    );
  }
}