import 'package:cloud_firestore/cloud_firestore.dart';

/// Reporte de una falla de la aplicación enviado por un usuario.
/// Buzón de una sola vía: no tiene estados ni seguimiento.
class FallaApp {
  const FallaApp({
    required this.id,
    required this.uid,
    required this.correo,
    required this.mensaje,
    this.pantalla,
    this.plataforma,
    this.sistemaOperativo,
    this.dispositivo,
    this.versionApp,
    required this.creadoEn,
  });

  final String id;
  final String uid;
  final String correo;
  final String mensaje;
  final String? pantalla;

  /// Datos técnicos capturados automáticamente al reportar.
  final String? plataforma;
  final String? sistemaOperativo;
  final String? dispositivo;
  final String? versionApp;

  final Timestamp creadoEn;

  factory FallaApp.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FallaApp(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      correo: data['correo'] as String? ?? '',
      mensaje: data['mensaje'] as String? ?? '',
      pantalla: data['pantalla'] as String?,
      plataforma: data['plataforma'] as String?,
      sistemaOperativo: data['sistemaOperativo'] as String?,
      dispositivo: data['dispositivo'] as String?,
      versionApp: data['versionApp'] as String?,
      creadoEn: data['creadoEn'] as Timestamp,
    );
  }
}
