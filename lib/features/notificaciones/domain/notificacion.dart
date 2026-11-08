import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificacionTipo { reporte, administrativo, sistema }

enum NotificacionEvento { creado, enRevision, enProceso, solucionado }

class Notificacion {
  const Notificacion({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    this.reportId,
    this.evento,
    this.estadoNuevo,
    this.uidDestino,
    this.destinoRol,
    this.autorUid,
    this.fallaId,
    required this.creadoEn,
    required this.leida,
  });

  final String id;
  final NotificacionTipo tipo;
  final String titulo;
  final String mensaje;
  final String? reportId;
  final NotificacionEvento? evento;
  final String? estadoNuevo;
  final String? uidDestino;
  final String? destinoRol;
  final String? autorUid;
  final String? fallaId;
  final Timestamp creadoEn;
  final bool leida;

  factory Notificacion.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    bool leida,
  ) {
    final data = doc.data()!;
    return Notificacion(
      id: doc.id,
      tipo: parseTipo(data['tipo']),
      titulo: data['titulo'] as String,
      mensaje: data['mensaje'] as String,
      reportId: data['reportId'] as String?,
      evento: parseEvento(data['evento']),
      estadoNuevo: data['estadoNuevo'] as String?,
      uidDestino: data['uidDestino'] as String?,
      destinoRol: data['destinoRol'] as String?,
      autorUid: data['autorUid'] as String?,
      fallaId: data['fallaId'] as String?,
      creadoEn: data['creadoEn'] as Timestamp,
      leida: leida,
    );
  }

  static NotificacionTipo parseTipo(String? value) {
    switch (value) {
      case 'reporte':
        return NotificacionTipo.reporte;
      case 'administrativo':
        return NotificacionTipo.administrativo;
      case 'sistema':
        return NotificacionTipo.sistema;
      default:
        return NotificacionTipo.sistema;
    }
  }

  static NotificacionEvento? parseEvento(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'creado':
        return NotificacionEvento.creado;
      case 'en_revision':
        return NotificacionEvento.enRevision;
      case 'en_proceso':
        return NotificacionEvento.enProceso;
      case 'solucionado':
        return NotificacionEvento.solucionado;
      default:
        return null;
    }
  }

  Notificacion copyWith({bool? leida}) {
    return Notificacion(
      id: id,
      tipo: tipo,
      titulo: titulo,
      mensaje: mensaje,
      reportId: reportId,
      evento: evento,
      estadoNuevo: estadoNuevo,
      uidDestino: uidDestino,
      destinoRol: destinoRol,
      autorUid: autorUid,
      fallaId: fallaId,
      creadoEn: creadoEn,
      leida: leida ?? this.leida,
    );
  }
}
