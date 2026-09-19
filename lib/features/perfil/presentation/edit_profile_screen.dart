import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/fields.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/uts_header.dart';

/// Editar Perfil (arquitectura §5.1/§5.2; placeholder del formulario).
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const UtsHeader(titulo: 'Editar Perfil'),
              const SizedBox(height: 12),
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
                child: const Column(
                  children: [
                    LabelledField(etiqueta: 'Nombre'),
                    SizedBox(height: 16),
                    LabelledField(etiqueta: 'Teléfono'),
                    SizedBox(height: 16),
                    LabelledField(etiqueta: 'Correo'),
                    SizedBox(height: 24),
                    PrimaryButton(texto: 'GUARDAR', onPressed: null),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}