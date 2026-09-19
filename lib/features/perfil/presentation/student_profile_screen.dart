import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_router.dart';
import '../../../shared/widgets/uts_header.dart';
import 'profile_widgets.dart';
import 'user_header.dart';

/// Pantalla 6: Perfil Estudiante (datos simulados).
class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const UtsHeader(titulo: 'Perfil', subtitulo: 'Informacion personal'),
              const UserHeader(nombre: 'Carlos Santiago Blanco Avila', subtitulo: 'Persona - Estudiante'),
              const SizedBox(height: 16),
              ProfileCard(
                titulo: 'Información de contacto',
                iconoTitulo: Icons.mail_outline,
                hijos: [
                  const ProfileRow(
                    icono: Icons.mail_outline,
                    etiqueta: 'Correo',
                    valor: 'csblanco@uts.edu.co',
                  ),
                  const ProfileRow(
                    icono: Icons.phone_outlined,
                    etiqueta: 'Teléfono',
                    valor: '+57 300 123 4567',
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
                    onTap: () => context.go(AppRoutes.editarPerfil),
                  ),
                  ProfileRow(
                    icono: Icons.lock_outline,
                    etiqueta: 'Cambiar contraseña',
                    onTap: () => context.go(AppRoutes.recuperar),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}