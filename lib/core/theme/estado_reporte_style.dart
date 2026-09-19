import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Estados de un reporte (nombres en español, según dominio de arquitectura §2.4).
enum EstadoReporte {
  pendiente(
    nombre: 'Pendiente',
    color: AppColors.estadoPendiente,
    icono: Icons.access_time_rounded,
  ),
  enRevision(
    nombre: 'En revisión',
    color: AppColors.estadoEnRevision,
    icono: Icons.search_rounded,
  ),
  enProceso(
    nombre: 'En proceso',
    color: AppColors.estadoEnProceso,
    icono: Icons.build_rounded,
  ),
  solucionado(
    nombre: 'Solucionado',
    color: AppColors.estadoSolucionado,
    icono: Icons.check_circle_rounded,
  ),
  rechazado(
    nombre: 'Rechazado',
    color: AppColors.estadoRechazado,
    icono: Icons.cancel_rounded,
  );

  const EstadoReporte({
    required this.nombre,
    required this.color,
    required this.icono,
  });

  final String nombre;
  final Color color;
  final IconData icono;

  /// Valor almacenado en Firestore (`estado` de la colección `reports`).
  String get valorFirestore => nombre;

  /// Texto de contraste legible sobre el color del estado.
  Color get colorTexto => color.computeLuminance() > 0.45 ? AppColors.textPrimary : Colors.white;

  /// Convierte el valor de Firestore a [EstadoReporte].
  static EstadoReporte fromValor(String valor) {
    return EstadoReporte.values.firstWhere(
      (estado) => estado.nombre == valor,
      orElse: () => EstadoReporte.pendiente,
    );
  }
}