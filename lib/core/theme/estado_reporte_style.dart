import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Estados de un reporte (RF-11/RF-15 §2.6 de requisitos.md).
///
/// ## Canonicidad Firestore (§2.4 / firestore.rules)
/// En Firestore (`reports/{id}.estado`), el historial `_inicial` y la
/// notificación `_creado` se persisten los 4 estados con **identificador
/// ASCII sin acentos**: `'Pendiente'`, `'En revision'`, `'En proceso'`,
/// `'Solucionado'`. Las reglas `create` (§2.4) validan
/// `estado=='Pendiente'` y la transición admin `isAllowedStateTransition` usa
/// esos mismos ASCII (§2.6/Fase 6).
///
/// `valorFirestore` es el identificador canónico ASCII (se escribe en
/// Firestore y se lee con `fromValor`). `nombre` es la etiqueta de UI (con
/// tilde donde corresponde, p. ej. "En revisión").
enum EstadoReporte {
  pendiente(color: AppColors.estadoPendiente, icono: Icons.access_time_rounded),
  enRevision(color: AppColors.estadoEnRevision, icono: Icons.search_rounded),
  enProceso(color: AppColors.estadoEnProceso, icono: Icons.build_rounded),
  solucionado(
    color: AppColors.estadoSolucionado,
    icono: Icons.check_circle_rounded,
  );

  const EstadoReporte({required this.color, required this.icono});

  final Color color;
  final IconData icono;

  /// Identificador canónico ASCII almacenado en Firestore (`estado` de
  /// `reports`, historial y notificación; §2.4/§6.2). SIN acentos, porque
  /// `firestore.rules` comparan estos literales exactos.
  String get valorFirestore => switch (this) {
    EstadoReporte.pendiente => 'Pendiente',
    EstadoReporte.enRevision => 'En revision',
    EstadoReporte.enProceso => 'En proceso',
    EstadoReporte.solucionado => 'Solucionado',
  };

  /// Etiqueta de UI con acentos (contraste: "En revisión", "En proceso", ...).
  String get nombre => switch (this) {
    EstadoReporte.pendiente => 'Pendiente',
    EstadoReporte.enRevision => 'En revisión',
    EstadoReporte.enProceso => 'En proceso',
    EstadoReporte.solucionado => 'Solucionado',
  };

  /// Color de texto legible sobre el color del estado.
  Color get colorTexto =>
      color.computeLuminance() > 0.45 ? AppColors.textPrimary : Colors.white;

  /// Convierte el valor canónico de Firestore a [EstadoReporte].
  ///
  /// Acepta tanto el identificador ASCII (`'En revision'`) como la etiqueta de
  /// UI con tilde (`'En revisión'`), sin distinguir mayúsculas. Si el valor no
  /// corresponde a ningún estado, cae en [EstadoReporte.pendiente].
  static EstadoReporte fromValor(String valor) {
    final String buscado = _sinAcentos(valor).toLowerCase();
    for (final EstadoReporte estado in EstadoReporte.values) {
      if (estado.valorFirestore == valor ||
          estado.nombre == valor ||
          estado.valorFirestore.toLowerCase() == buscado ||
          _sinAcentos(estado.nombre).toLowerCase() == buscado) {
        return estado;
      }
    }
    return EstadoReporte.pendiente;
  }

  /// Quita las tildes/diéresis para comparar valores escritos con o sin acento.
  static String _sinAcentos(String valor) {
    const Map<String, String> reemplazos = <String, String>{
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'Ü': 'U',
    };
    String resultado = valor.trim();
    reemplazos.forEach((String conAcento, String sinAcento) {
      resultado = resultado.replaceAll(conAcento, sinAcento);
    });
    return resultado;
  }
}
