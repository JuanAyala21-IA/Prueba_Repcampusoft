import 'package:flutter/material.dart';

import '../../core/theme/estado_reporte_style.dart';

/// Chip/badge de estado en píldora: color propio + icono (pantallas 12.png).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.estado, this.compacto = false});

  final EstadoReporte estado;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 8 : 10,
        vertical: compacto ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: estado.color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(estado.icono, size: compacto ? 12 : 14, color: estado.colorTexto),
          if (!compacto) ...[
            const SizedBox(width: 4),
            Text(
              estado.nombre,
              style: TextStyle(
                color: estado.colorTexto,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}