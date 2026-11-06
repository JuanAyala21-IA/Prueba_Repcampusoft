import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../core/constants/catalogo_espacios.dart';
import '../../../core/theme/estado_reporte_style.dart';
import '../../../core/utils/result.dart';
import '../domain/historial_entry.dart';
import '../domain/reporte.dart';
import '../domain/reporte_repository.dart';
import '../domain/servicio_almacenamiento_imagen.dart';
import 'firebase_almacenamiento_imagen.dart';

class FirebaseReporteRepository implements ReporteRepository {
  FirebaseReporteRepository({
    FirebaseFirestore? firestore,
    fb.FirebaseAuth? auth,
    ServicioAlmacenamientoImagen? almacenamiento,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? fb.FirebaseAuth.instance,
       _almacenamiento = almacenamiento ?? FirebaseAlmacenamientoImagen();

  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _auth;
  final ServicioAlmacenamientoImagen _almacenamiento;

  DocumentReference<Map<String, dynamic>> reporteDoc(String reporteId) =>
      _firestore.collection('reports').doc(reporteId);

  DocumentReference<Map<String, dynamic>> historialDoc(
    String reporteId, {
    required String historialId,
  }) => reporteDoc(reporteId).collection('historial').doc(historialId);

  DocumentReference<Map<String, dynamic>> notifDoc(String notifId) =>
      _firestore.collection('notifications').doc(notifId);

  DocumentReference<Map<String, dynamic>> mediaFotoDoc(String reporteId) =>
      reporteDoc(reporteId).collection('media').doc('foto');

  /// Foto que prueba que el daño quedó solucionado (la sube el encargado de
  /// mantenimiento asignado al pasar el reporte a `Solucionado`).
  DocumentReference<Map<String, dynamic>> mediaSolucionDoc(String reporteId) =>
      reporteDoc(reporteId).collection('media').doc('solucion');

  /// Valida si una transición es permitida según la matriz del dominio (§6.2).
  static bool _esTransicionValida(String estadoActual, String estadoNuevo) {
    final permitidos = transicionesPermitidas[estadoActual];
    return permitidos != null && permitidos.contains(estadoNuevo);
  }

  @override
  Future<Result<String>> crear(BorradorReporte borrador) async {
    final String reporteId = _firestore.collection('reports').doc().id;

    final fb.User? user = _auth.currentUser;
    if (user == null) {
      return const Failure('Debes iniciar sesion para reportar (RF-11).');
    }

    final String uid = user.uid;
    final String correoAutor = user.email ?? '';

    final bool tieneFoto = borrador.fotoBase64 != null;
    Uint8List? fotoBytes;
    if (tieneFoto) {
      fotoBytes = base64Decode(borrador.fotoBase64!);
      if (fotoBytes.lengthInBytes > 704640) {
        return const Failure('La foto es demasiado grande');
      }
    }

    // La imagen se sube a Storage ANTES del batch: Firestore solo guarda la
    // ruta y el tamaño (así el documento no consume el límite de 1 MB).
    ImagenAlmacenada? fotoAlmacenada;
    if (fotoBytes != null) {
      try {
        fotoAlmacenada = await _almacenamiento.subirFotoReporte(
          reportId: reporteId,
          bytes: fotoBytes,
        );
      } catch (e) {
        return Failure('No se pudo subir la foto: $e');
      }
    }

    final String ubicacionTexto = borrador.ubicacionTexto;
    final Map<String, Object?> datosReporte = {
      'uid': uid,
      'correoAutor': correoAutor,
      'tipoDano': borrador.tipoDano,
      'tipoUbicacion': borrador.tipoUbicacion.slug,
      if (borrador.edificio != null && borrador.edificio!.trim().isNotEmpty)
        'edificio': borrador.edificio!.trim(),
      if (borrador.piso != null && borrador.piso!.trim().isNotEmpty)
        'piso': borrador.piso!.trim(),
      'espacio': borrador.espacio.trim(),
      if (borrador.referencia != null && borrador.referencia!.trim().isNotEmpty)
        'referencia': borrador.referencia!.trim(),
      'ubicacionTexto': ubicacionTexto,
      'descripcion': borrador.descripcion,
      'estado': 'Pendiente',
      'tieneFoto': tieneFoto,
      'creadoEn': FieldValue.serverTimestamp(),
    };

    final String historialId = '${reporteId}_inicial';
    final Map<String, Object?> datosHistorial = {
      'estadoAnterior': 'Pendiente',
      'estadoNuevo': 'Pendiente',
      'creadoEn': FieldValue.serverTimestamp(),
    };

    final String notifId = '${reporteId}_creado';
    final Map<String, Object?> datosNotif = {
      'tipo': 'reporte',
      'titulo': 'Nuevo reporte de dano',
      'mensaje':
          'Se registró tu reporte de ${borrador.tipoDano} en '
          '$ubicacionTexto.',
      'reportId': reporteId,
      'evento': 'creado',
      'estadoNuevo': 'Pendiente',
      'uidDestino': null,
      'destinoRol': 'administrativo',
      'autorUid': uid,
      'creadoEn': FieldValue.serverTimestamp(),
    };

    final WriteBatch batch = _firestore.batch();
    batch.set(reporteDoc(reporteId), datosReporte);
    batch.set(
      historialDoc(reporteId, historialId: historialId),
      datosHistorial,
    );
    batch.set(notifDoc(notifId), datosNotif);
    if (fotoAlmacenada != null) {
      batch.set(mediaFotoDoc(reporteId), {
        'storagePath': fotoAlmacenada.storagePath,
        'downloadUrl': fotoAlmacenada.downloadUrl,
        'tamanoBytes': fotoAlmacenada.tamanoBytes,
        'mimeType': fotoAlmacenada.mimeType,
        'creadoEn': FieldValue.serverTimestamp(),
      });
    }

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (fotoAlmacenada != null) {
        await _almacenamiento.eliminar(fotoAlmacenada.storagePath);
      }
      if (e.code == 'permission-denied' || e.code == 'aborted') {
        DocumentSnapshot<Map<String, dynamic>>? previo;
        try {
          previo = await reporteDoc(reporteId).get();
        } on FirebaseException catch (e2) {
          if (e2.code == 'permission-denied') {
            return Failure(e.message ?? 'No se pudo guardar el reporte.');
          }
          rethrow;
        }
        if (previo.exists && previo.data()?['uid'] == uid) {
          return Success(reporteId);
        }
      }
      return Failure(e.message ?? 'No se pudo guardar el reporte.');
    }

    return Success(reporteId);
  }

  @override
  Stream<List<Reporte>> watchMisReportes() {
    final fb.User? user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('reports')
        .where('uid', isEqualTo: user.uid)
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _mapToReporte(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Stream<Reporte?> watchReporteById(String reportId) {
    return _firestore.collection('reports').doc(reportId).snapshots().map((
      doc,
    ) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return _mapToReporte(doc.id, doc.data()!);
    });
  }

  @override
  Stream<List<HistorialEntry>> watchHistorial(String reportId) {
    return _firestore
        .collection('reports')
        .doc(reportId)
        .collection('historial')
        .orderBy('creadoEn', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _mapToHistorialEntry(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Stream<List<Reporte>> watchTodosLosReportes({
    String? filtroEstado,
    String? filtroEdificio,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('reports')
        .orderBy('creadoEn', descending: true);

    if (filtroEstado != null && filtroEstado != 'Todos') {
      query = query.where('estado', isEqualTo: filtroEstado);
    }
    if (filtroEdificio != null && filtroEdificio != 'Todos') {
      query = query.where('edificio', isEqualTo: filtroEdificio);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => _mapToReporte(doc.id, doc.data()))
          .toList(),
    );
  }

  @override
  Future<Result<void>> cambiarEstado({
    required String reportId,
    required String estadoNuevo,
    String? observacion,
    String? evidenciaBase64,
  }) async {
    // Validación de dominio: estadoNuevo válido y observación si Rechazado
    const estadosValidos = [
      'Pendiente',
      'En revision',
      'En proceso',
      'Solucionado',
      'Rechazado',
    ];
    if (!estadosValidos.contains(estadoNuevo)) {
      return Failure('Estado inválido: $estadoNuevo');
    }
    if (estadoNuevo == 'Rechazado' &&
        (observacion == null || observacion.trim().isEmpty)) {
      return Failure('Observación obligatoria al rechazar');
    }

    // La evidencia es obligatoria al marcar el reporte como solucionado; se
    // valida dentro de la transacción, después de comprobar la transición.
    final String? evidencia = estadoNuevo == 'Solucionado'
        ? evidenciaBase64
        : null;
    Uint8List? evidenciaBytes;
    if (evidencia != null) {
      evidenciaBytes = base64Decode(evidencia);
      if (evidenciaBytes.lengthInBytes > 704640) {
        return const Failure('La imagen de evidencia es demasiado grande.');
      }
    }

    // La evidencia se sube a Storage antes de la transacción; Firestore solo
    // guarda la ruta y el tamaño.
    ImagenAlmacenada? evidenciaAlmacenada;
    if (evidenciaBytes != null) {
      try {
        evidenciaAlmacenada = await _almacenamiento.subirEvidenciaSolucion(
          reportId: reportId,
          bytes: evidenciaBytes,
        );
      } catch (e) {
        return Failure('No se pudo subir la evidencia: $e');
      }
    }

    // Funcionario que atiende el reporte: se guarda en el historial y, al
    // solucionarlo, como encargado de la reparación.
    final fb.User? usuario = _auth.currentUser;
    final String adminUid = usuario?.uid ?? '';
    String adminNombre = (usuario?.displayName ?? '').trim();
    if (adminUid.isNotEmpty && adminNombre.isEmpty) {
      try {
        final DocumentSnapshot<Map<String, dynamic>> perfil = await _firestore
            .collection('users')
            .doc(adminUid)
            .get();
        adminNombre = (perfil.data()?['nombre'] as String? ?? '').trim();
      } catch (_) {
        // Si no se puede leer el perfil se usa el correo o el uid.
      }
    }
    if (adminNombre.isEmpty) {
      adminNombre = (usuario?.email ?? adminUid).trim();
    }

    // Si la transacción falla, no dejar la evidencia huérfana en Storage.
    Future<Result<void>> fallar(String mensaje) async {
      if (evidenciaAlmacenada != null) {
        await _almacenamiento.eliminar(evidenciaAlmacenada.storagePath);
      }
      return Failure(mensaje);
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final reporteRef = reporteDoc(reportId);
        final reporteSnap = await transaction.get(reporteRef);

        if (!reporteSnap.exists) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'not-found',
            message: 'El reporte no existe',
          );
        }

        final data = reporteSnap.data()!;
        final estadoActual = data['estado'] as String;
        final uidAutor = data['uid'] as String;
        final tipoDano = data['tipoDano'] as String;
        // `ubicacionTexto` existe en reportes nuevos; los antiguos solo tienen
        // edificio/piso/salón y se reconstruyen con el mismo helper del dominio.
        final ubicacion =
            data['ubicacionTexto'] as String? ??
            construirUbicacionTexto(
              tipoUbicacion:
                  TipoEspacio.desdeSlug(data['tipoUbicacion'] as String?) ??
                  TipoEspacio.aula,
              edificio: data['edificio'] as String?,
              piso: data['piso'] as String?,
              espacio:
                  (data['espacio'] as String?) ??
                  'Salón ${data['salon'] ?? ''}',
              referencia: data['referencia'] as String?,
            );

        // Validar transición permitida (matriz §6.2)
        if (!_esTransicionValida(estadoActual, estadoNuevo)) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'invalid-transition',
            message: 'Transición no permitida: $estadoActual → $estadoNuevo',
          );
        }

        // Solucionar exige la foto de evidencia (obligatoria).
        if (estadoNuevo == 'Solucionado' && evidencia == null) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'missing-evidence',
            message: 'La evidencia es obligatoria para marcar el reporte como solucionado.',
          );
        }

        // IDs deterministas para idempotencia (arquitectura §6.2)
        final historialId = '${reportId}_$estadoNuevo';
        // notifId debe usar evento (snake_case) para coincidir con regla Firestore
        final evento = estadoNuevo.toLowerCase().replaceAll(' ', '_');
        final notifId = '${reportId}_$evento';

        // Actualizar reporte: estado + actualizadoEn (+ encargado al solucionar)
        transaction.update(reporteRef, {
          'estado': estadoNuevo,
          'actualizadoEn': FieldValue.serverTimestamp(),
          'observacionAdmin': observacion ?? '',
          if (estadoNuevo == 'Solucionado') 'encargadoUid': adminUid,
          if (estadoNuevo == 'Solucionado') 'encargadoNombre': adminNombre,
          if (evidencia != null) 'tieneEvidenciaSolucion': true,
        });

        // Foto de evidencia de la solución (objeto ya subido a Storage).
        if (evidenciaAlmacenada != null) {
          transaction.set(mediaSolucionDoc(reportId), {
            'storagePath': evidenciaAlmacenada.storagePath,
            'downloadUrl': evidenciaAlmacenada.downloadUrl,
            'tamanoBytes': evidenciaAlmacenada.tamanoBytes,
            'mimeType': evidenciaAlmacenada.mimeType,
            'creadoEn': FieldValue.serverTimestamp(),
          });
        }

        // Crear entrada de historial
        transaction.set(historialDoc(reportId, historialId: historialId), {
          'estadoAnterior': estadoActual,
          'estadoNuevo': estadoNuevo,
          'observacion': observacion ?? '',
          'adminUid': adminUid,
          'adminNombre': adminNombre,
          'creadoEn': FieldValue.serverTimestamp(),
        });

        // Crear notificación al AUTOR del reporte (uidDestino = uidAutor)
        final titulo = switch (estadoNuevo) {
          'En revision' => 'Reporte en revisi\u00f3n',
          'En proceso' => 'Reporte en proceso',
          'Solucionado' => 'Reporte solucionado',
          'Rechazado' => 'Reporte rechazado',
          _ => 'Actualizaci\u00f3n de reporte',
        };
        final mensaje = switch (estadoNuevo) {
          'En revision' =>
            'Tu reporte de $tipoDano en $ubicacion est\u00e1 siendo revisado.',
          'En proceso' =>
            'Tu reporte de $tipoDano en $ubicacion est\u00e1 en proceso de reparaci\u00f3n.',
          'Solucionado' =>
            'Tu reporte de $tipoDano en $ubicacion ha sido solucionado.',
          'Rechazado' =>
            'Tu reporte de $tipoDano en $ubicacion ha sido rechazado.',
          _ =>
            'Tu reporte de $tipoDano en $ubicacion cambi\u00f3 a $estadoNuevo.',
        };

        transaction.set(notifDoc(notifId), {
          'tipo': 'reporte',
          'titulo': titulo,
          'mensaje': mensaje,
          'reportId': reportId,
          'evento': evento,
          'estadoNuevo': estadoNuevo,
          'uidDestino': uidAutor,
          'destinoRol': null,
          'autorUid': adminUid,
          'creadoEn': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      // Patrón idempotente: si falla con PERMISSION_DENIED, verificar si el historial ya existe
      if (e.code == 'permission-denied' || e.code == 'aborted') {
        final historialId = '${reportId}_$estadoNuevo';
        try {
          final historialSnap = await historialDoc(
            reportId,
            historialId: historialId,
          ).get();
          if (historialSnap.exists) {
            // El intento previo tuvo éxito (batch atómico), no duplicar
            return const Success(null);
          }
        } on FirebaseException catch (e2) {
          if (e2.code == 'permission-denied') {
            return fallar(e.message ?? 'No se pudo cambiar el estado.');
          }
          rethrow;
        }
      }
      if (e.code == 'not-found') {
        return fallar(e.message ?? 'El reporte no existe');
      }
      if (e.code == 'invalid-transition') {
        return fallar(e.message ?? 'Transición no permitida');
      }
      if (e.code == 'missing-evidence') {
        return fallar(
          e.message ?? 'La evidencia es obligatoria para marcar el reporte como solucionado.',
        );
      }
      return fallar(e.message ?? 'No se pudo cambiar el estado.');
    }

    return const Success(null);
  }

  @override
  Future<Result<void>> tomarReporte({required String reportId}) async {
    final fb.User? usuario = _auth.currentUser;
    final String uid = usuario?.uid ?? '';
    if (uid.isEmpty) {
      return const Failure('Debes iniciar sesión para tomar un reporte.');
    }

    String nombre = (usuario?.displayName ?? '').trim();
    if (nombre.isEmpty) {
      try {
        final DocumentSnapshot<Map<String, dynamic>> perfil = await _firestore
            .collection('users')
            .doc(uid)
            .get();
        nombre = (perfil.data()?['nombre'] as String? ?? '').trim();
      } catch (_) {
        // Si no se puede leer el perfil se usa el correo o el uid.
      }
    }
    if (nombre.isEmpty) {
      nombre = (usuario?.email ?? uid).trim();
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final reporteRef = reporteDoc(reportId);
        final reporteSnap = await transaction.get(reporteRef);

        if (!reporteSnap.exists) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'not-found',
            message: 'El reporte no existe',
          );
        }

        final data = reporteSnap.data()!;
        final estadoActual = data['estado'] as String? ?? '';
        if (estadoActual == 'Solucionado' || estadoActual == 'Rechazado') {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'closed-report',
            message: 'El reporte ya está cerrado.',
          );
        }

        final String asignadoA = (data['asignadoA'] as String? ?? '').trim();
        if (asignadoA.isNotEmpty && asignadoA != uid) {
          throw FirebaseException(
            plugin: 'firestore',
            code: 'already-assigned',
            message: 'Otro encargado ya tomó este reporte.',
          );
        }
        // Idempotente: si ya lo tomó el mismo usuario, no se reescribe.
        if (asignadoA == uid) return;

        transaction.update(reporteRef, {
          'asignadoA': uid,
          'asignadoNombre': nombre,
          'asignadoEn': FieldValue.serverTimestamp(),
          'actualizadoEn': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        return Failure(e.message ?? 'El reporte no existe');
      }
      if (e.code == 'already-assigned') {
        return Failure(e.message ?? 'Otro encargado ya tomó este reporte.');
      }
      if (e.code == 'closed-report') {
        return Failure(e.message ?? 'El reporte ya está cerrado.');
      }
      return Failure(e.message ?? 'No se pudo tomar el reporte.');
    }

    return const Success(null);
  }

  Reporte _mapToReporte(String id, Map<String, dynamic> data) {
    final String? espacioGuardado = data['espacio'] as String?;
    final String? salon = data['salon'] as String?;
    final String espacio =
        (espacioGuardado != null && espacioGuardado.trim().isNotEmpty)
        ? espacioGuardado.trim()
        : (salon != null && salon.trim().isNotEmpty
              ? 'Salón ${salon.trim()}'
              : 'Sin ubicación');

    return Reporte(
      reporteId: id,
      uid: data['uid'] as String,
      correoAutor: data['correoAutor'] as String,
      tipoDano: data['tipoDano'] as String,
      tipoUbicacion:
          TipoEspacio.desdeSlug(data['tipoUbicacion'] as String?) ??
          TipoEspacio.aula,
      edificio: data['edificio'] as String?,
      piso: data['piso'] as String?,
      espacio: espacio,
      referencia: data['referencia'] as String?,
      descripcion: data['descripcion'] as String,
      estado: EstadoReporte.fromValor(data['estado'] as String),
      tieneFoto: data['tieneFoto'] as bool? ?? false,
      creadoEn: (data['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      encargadoUid: data['encargadoUid'] as String?,
      encargadoNombre: data['encargadoNombre'] as String?,
      asignadoA: data['asignadoA'] as String?,
      asignadoNombre: data['asignadoNombre'] as String?,
      asignadoEn: (data['asignadoEn'] as Timestamp?)?.toDate(),
      tieneEvidenciaSolucion: data['tieneEvidenciaSolucion'] as bool? ?? false,
    );
  }

  HistorialEntry _mapToHistorialEntry(String id, Map<String, dynamic> data) {
    return HistorialEntry(
      historialId: id,
      estadoAnterior: EstadoReporte.fromValor(data['estadoAnterior'] as String),
      estadoNuevo: EstadoReporte.fromValor(data['estadoNuevo'] as String),
      observacion: data['observacion'] as String?,
      fecha: (data['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminUid: data['adminUid'] as String?,
      adminNombre: data['adminNombre'] as String?,
    );
  }
}
