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
    this.validator,
    this.onFieldSubmitted,
    this.enabled = true,
  });

  final String hint;
  final IconData? icono;
  final bool esContrasena;
  final TextEditingController? controlador;
  final TextInputAction? textInputAction;

  /// Con [borde] dibuja un borde sutil gris (búsqueda).
  final bool borde;

  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  @override
  State<PillField> createState() => _PillFieldState();
}

class _PillFieldState extends State<PillField> {
  bool _oculto = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controlador,
      obscureText: widget.esContrasena ? _oculto : false,
      textInputAction: widget.textInputAction,
      enabled: widget.enabled,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTypography.textTheme.bodySmall,
        prefixIcon: widget.icono == null ? null : Icon(widget.icono),
        suffixIcon: widget.esContrasena
            ? IconButton(
                onPressed: () => setState(() => _oculto = !_oculto),
                icon: Icon(
                  _oculto
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              )
            : null,
        enabledBorder: widget.borde
            ? const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                borderSide: BorderSide(color: AppColors.divider, width: 1),
              )
            : null,
        errorStyle: const TextStyle(
          color: AppColors.estadoPendiente,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Campo de formulario con etiqueta y línea inferior (registro / reporte).
class LabelledField extends StatefulWidget {
  const LabelledField({
    super.key,
    required this.etiqueta,
    this.hint,
    this.controlador,
    this.multiline = false,
    this.esContrasena = false,
    this.validator,
  });

  final String etiqueta;
  final String? hint;
  final TextEditingController? controlador;
  final bool multiline;

  /// Con [esContrasena] muestra el botón de visibilidad tipo ojo.
  final bool esContrasena;

  final String? Function(String?)? validator;

  @override
  State<LabelledField> createState() => _LabelledFieldState();
}

class _LabelledFieldState extends State<LabelledField> {
  bool _oculto = true;

  @override
  Widget build(BuildContext context) {
    // La descripción (multilínea) se muestra como caja redondeada, no como
    // línea inferior: es más cómoda de leer y de escribir.
    final bool esCaja = widget.multiline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.etiqueta,
          style: AppTypography.textTheme.titleSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controlador,
          maxLines: widget.multiline ? 6 : 1,
          minLines: widget.multiline ? 4 : 1,
          textAlignVertical: widget.multiline
              ? TextAlignVertical.top
              : TextAlignVertical.center,
          keyboardType: widget.multiline ? TextInputType.multiline : null,
          obscureText: widget.esContrasena ? _oculto : false,
          style: AppTypography.textTheme.bodyMedium,
          validator: widget.validator,
          decoration: InputDecoration(
            filled: esCaja,
            fillColor: AppColors.surface,
            hintText: widget.hint ?? widget.etiqueta,
            hintStyle: AppTypography.textTheme.bodySmall,
            contentPadding: esCaja
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 14)
                : const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            enabledBorder: esCaja
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.divider,
                      width: 1,
                    ),
                  )
                : const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.divider, width: 1),
                  ),
            focusedBorder: esCaja
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.utsGreen,
                      width: 1.8,
                    ),
                  )
                : const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.utsGreen,
                      width: 1.6,
                    ),
                  ),
            errorBorder: esCaja
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.estadoPendiente,
                      width: 1.2,
                    ),
                  )
                : null,
            focusedErrorBorder: esCaja
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.estadoPendiente,
                      width: 1.6,
                    ),
                  )
                : null,
            errorStyle: const TextStyle(
              color: AppColors.estadoPendiente,
              fontSize: 12,
            ),
            suffixIcon: widget.esContrasena
                ? IconButton(
                    onPressed: () => setState(() => _oculto = !_oculto),
                    icon: Icon(
                      _oculto
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
