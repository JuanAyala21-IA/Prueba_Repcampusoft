import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Campo de texto en píldora (login / búsqueda), fondo gris suave `#ECEEF1`.
/// Con [esContrasena] muestra el botón de visibilidad tipo ojo.
class PillField extends StatefulWidget {
  const PillField({
    super.key,
    required this.hint,
    this.icono,
    this.esContrasena = false,
    this.controlador,
    this.textInputAction,
    this.borde = false,
  });

  final String hint;
  final IconData? icono;
  final bool esContrasena;
  final TextEditingController? controlador;
  final TextInputAction? textInputAction;

  /// Con [borde] dibuja un borde sutil gris (búsqueda).
  final bool borde;

  @override
  State<PillField> createState() => _PillFieldState();
}

class _PillFieldState extends State<PillField> {
  bool _oculto = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controlador,
      obscureText: widget.esContrasena ? _oculto : false,
      textInputAction: widget.textInputAction,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTypography.textTheme.bodySmall,
        prefixIcon: widget.icono == null ? null : Icon(widget.icono),
        suffixIcon: widget.esContrasena
            ? IconButton(
                onPressed: () => setState(() => _oculto = !_oculto),
                icon: Icon(_oculto ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              )
            : null,
        enabledBorder: widget.borde
            ? const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                borderSide: BorderSide(color: AppColors.divider, width: 1),
              )
            : null,
        errorStyle: const TextStyle(color: AppColors.estadoPendiente, fontSize: 12),
      ),
    );
  }
}

/// Campo de formulario con etiqueta y línea inferior (registro / reporte).
class LabelledField extends StatelessWidget {
  const LabelledField({
    super.key,
    required this.etiqueta,
    this.hint,
    this.controlador,
    this.multiline = false,
  });

  final String etiqueta;
  final String? hint;
  final TextEditingController? controlador;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: AppTypography.textTheme.titleSmall),
        const SizedBox(height: 6),
        TextField(
          controller: controlador,
          maxLines: multiline ? 5 : 1,
          style: AppTypography.textTheme.bodyMedium,
          decoration: InputDecoration(
            filled: false,
            hintText: hint ?? etiqueta,
            hintStyle: AppTypography.textTheme.bodySmall,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.divider, width: 1),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.utsGreen, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}