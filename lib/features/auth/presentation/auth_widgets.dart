import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/rol_enum.dart';

/// Texto del aviso cuando el correo ya fue verificado. Si el rol efectivo
/// difiere del intentado (reglas Firestore), se informa quién está autorizado.
String avisoRolAsignado({RolEnum? intentado, required RolEnum asignado}) {
  if (intentado == null || intentado == asignado) {
    return 'Tu rol asignado es: ${asignado.etiqueta}.';
  }
  return 'No tienes autorización para ${intentado.etiqueta}. Tu rol asignado es: ${asignado.etiqueta}.';
}

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

/// Selección de rol en el registro (pantallas 3.png).
class RolSelector extends StatelessWidget {
  const RolSelector({super.key, required this.seleccion, required this.onChanged});

  final RolEnum? seleccion;
  final ValueChanged<RolEnum> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget opcion(RolEnum rol, String texto, String detalle) {
      final bool activo = seleccion == rol;
      return InkWell(
        onTap: () => onChanged(rol),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: activo ? AppColors.utsGreen : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                activo ? Icons.radio_button_checked : Icons.radio_button_off,
                color: activo ? AppColors.textPrimary : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(texto,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  Text(detalle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        opcion(RolEnum.persona, 'Persona', 'Estudiante / Usuario común'),
        const SizedBox(height: 10),
        opcion(RolEnum.administrativo, 'Administrativo', 'Personal administrativo / mantenimiento'),
      ],
    );
  }
}