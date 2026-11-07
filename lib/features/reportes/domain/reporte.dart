import '../../../core/constants/catalogo_espacios.dart';
import '../../../core/theme/estado_reporte_style.dart';

/// Construye el texto de ubicación que se guarda en `reports.ubicacionTexto`
/// y que usan listas, detalle y notificaciones.
///
/// - Espacios interiores: `Edificio A · Piso 2 · Salón 203`.
/// - Zonas exteriores: `Zona exterior · Jardines · Frente al Edificio B`.
/// - En exteriores, parqueaderos y "otro", la referencia forma parte del
///   texto porque no hay edificio/piso que ubiquen el daño.
String construirUbicacionTexto({
  required TipoEspacio tipoUbicacion,
  String? edificio,
  String? piso,
  required String espacio,
  String? referencia,
}) {
  final partes = <String>[];
  if (tipoUbicacion == TipoEspacio.zonaExterior) {
    partes.add('Zona exterior');
  }
  if (edificio != null && edificio.trim().isNotEmpty) {
    partes.add(edificio.trim());
  }
  if (piso != null && piso.trim().isNotEmpty) {
    partes.add(piso.trim());
  }
  if (espacio.trim().isNotEmpty) {
    partes.add(espacio.trim());
  }

  final incluyeReferencia =
      tipoUbicacion == TipoEspacio.zonaExterior ||
      tipoUbicacion == TipoEspacio.parqueadero ||
      tipoUbicacion == TipoEspacio.otro;
  if (incluyeReferencia && referencia != null && referencia.trim().isNotEmpty) {
    partes.add(referencia.trim());
  }

  return partes.join(' · ');
}

/// Borrador capturado por el formulario Pantalla 8 (RF-11, pantalla 8.png).
/// Sin lógica: es el estado del form antes de construir el [Reporte].
class BorradorReporte {
  const BorradorReporte({
    required this.tipoUbicacion,
    this.edificio,
    this.piso,
    required this.espacio,
    this.referencia,
    required this.tipoDano,
    required this.descripcion,
    this.fotoBase64,
  });

  final TipoEspacio tipoUbicacion;
  final String? edificio;
  final String? piso;

  /// Texto humano del espacio: "Salón 203", "Baño de mujeres",
  /// "Laboratorio de Química", "Jardines", etc.
  final String espacio;

  /// Detalle adicional para ubicar el daño (opcional salvo en zonas
  /// exteriores).
  final String? referencia;

  final String tipoDano;
  final String descripcion;

  /// Foto opcional Base64 comprimida (~500 KB, RNF-06, §8.1).
  final String? fotoBase64;

  String get ubicacionTexto => construirUbicacionTexto(
    tipoUbicacion: tipoUbicacion,
    edificio: edificio,
    piso: piso,
    espacio: espacio,
    referencia: referencia,
  );
}

/// Reporte persistido en Firestore `reports/{reportId}` (arquitectura §2.4).
/// Los nombres de los campos coinciden EXACTAMENTE con las reglas de
/// `firestore.rules` (create persona: `uid`, `correoAutor`, `estado`).
class Reporte {
  const Reporte({
    required this.reporteId,
    required this.uid,
    required this.correoAutor,
    required this.tipoDano,
    required this.tipoUbicacion,
    this.edificio,
    this.piso,
    required this.espacio,
    this.referencia,
    required this.descripcion,
    required this.estado,
    required this.tieneFoto,
    required this.creadoEn,
    this.actualizadoEn,
    this.observacionAdmin,
    this.encargadoUid,
    this.encargadoNombre,
    this.asignadoA,
    this.asignadoNombre,
    this.asignadoEn,
    this.tieneEvidenciaSolucion = false,
  });

  final String reporteId;
  final String uid;
  final String correoAutor;
  final String tipoDano;
  final TipoEspacio tipoUbicacion;
  final String? edificio;
  final String? piso;

  /// Texto humano del espacio (ver [BorradorReporte.espacio]).
  final String espacio;

  /// Detalle adicional para ubicar el daño.
  final String? referencia;

  final String descripcion;

  /// Estado inicial `Pendiente` (RF-11); lo gestiona el admin (RF-15).
  final EstadoReporte estado;

  /// `tieneFoto == true` si existe `reports/{id}/media/foto` (§2.4/RNF-06).
  final bool tieneFoto;
  final DateTime creadoEn;

  /// Última modificación del reporte (`actualizadoEn` en Firestore). También
  /// marca la fecha de solución cuando [estado] es `Solucionado`.
  final DateTime? actualizadoEn;

  /// Observación escrita por el funcionario al gestionar el reporte (por
  /// ejemplo, el motivo del rechazo).
  final String? observacionAdmin;

  /// Funcionario (administrativo o mantenimiento) que solucionó el daño.
  /// Se registra al pasar el reporte a `Solucionado`.
  final String? encargadoUid;
  final String? encargadoNombre;

  /// Encargado de mantenimiento que tomó el reporte para atenderlo. Mientras
  /// esté vacío, cualquier encargado de mantenimiento puede tomarlo; una vez
  /// asignado, solo esa persona puede cambiar su estado.
  final String? asignadoA;
  final String? asignadoNombre;
  final DateTime? asignadoEn;

  /// `true` si existe `reports/{id}/media/solucion` con la foto que prueba
  /// que el daño quedó solucionado.
  final bool tieneEvidenciaSolucion;

  /// `true` cuando ningún encargado de mantenimiento ha tomado el reporte.
  bool get sinAsignar => asignadoA == null || asignadoA!.isEmpty;

  /// `true` si [uid] es el encargado de mantenimiento asignado.
  bool asignadoAUsuario(String? uid) =>
      uid != null && asignadoA != null && asignadoA == uid;

  /// Texto de ubicación listo para listas, detalle y notificaciones.
  String get ubicacionTexto => construirUbicacionTexto(
    tipoUbicacion: tipoUbicacion,
    edificio: edificio,
    piso: piso,
    espacio: espacio,
    referencia: referencia,
  );

  /// Identificadores deterministas del batch §6.2.
  String get historialId => '${reporteId}_inicial';
  String get notificacionId => '${reporteId}_creado';

  Map<String, Object?> toFirestore() {
    return {
      'uid': uid,
      'correoAutor': correoAutor,
      'tipoDano': tipoDano,
      'tipoUbicacion': tipoUbicacion.slug,
      if (edificio != null && edificio!.trim().isNotEmpty)
        'edificio': edificio!.trim(),
      if (piso != null && piso!.trim().isNotEmpty) 'piso': piso!.trim(),
      'espacio': espacio.trim(),
      if (referencia != null && referencia!.trim().isNotEmpty)
        'referencia': referencia!.trim(),
      'ubicacionTexto': ubicacionTexto,
      'descripcion': descripcion,
      'estado': estado.nombre, // 'Pendiente' (valor Firestore §2.4).
      'tieneFoto': tieneFoto,
      'creadoEn': creadoEn, // Timestamp del servidor se asigna en reglas.
    };
  }
}
