import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../domain/falla_app.dart';
import '../domain/fallas_app_repository.dart';
import 'app_metadata.dart';

/// Implementación sobre Firebase Auth + Cloud Firestore (colección `fallas_app`).
class FirebaseFallasAppRepository implements FallasAppRepository {
  FirebaseFallasAppRepository({
    FirebaseFirestore? firestore,
    fb.FirebaseAuth? auth,
    Future<AppMetadata> Function()? cargarMetadata,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? fb.FirebaseAuth.instance,
       _cargarMetadata = cargarMetadata ?? leerAppMetadata;

  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _auth;
  final Future<AppMetadata> Function() _cargarMetadata;

  @override
  Future<void> reportar({required String mensaje, String? pantalla}) async {
    final fb.User? user = _auth.currentUser;
    if (user == null) {
      throw StateError('Debes iniciar sesión para reportar.');
    }
    final String texto = mensaje.trim();
    if (texto.isEmpty) {
      throw ArgumentError('Describe la falla antes de enviar.');
    }
    final String? donde = (pantalla?.trim().isEmpty ?? true)
        ? null
        : pantalla!.trim();
    final AppMetadata metadata = await _cargarMetadata();
    final String fallaId = _firestore.collection('fallas_app').doc().id;
    final String notifId = '${fallaId}_falla';

    final Map<String, dynamic> datosFalla = {
      'uid': user.uid,
      'correo': (user.email ?? '').trim().toLowerCase(),
      'mensaje': texto,
      if (donde case final String d) 'pantalla': d,
      if (metadata.plataforma case final String p) 'plataforma': p,
      if (metadata.sistemaOperativo case final String s) 'sistemaOperativo': s,
      if (metadata.dispositivo case final String disp) 'dispositivo': disp,
      if (metadata.versionApp case final String v) 'versionApp': v,
      'creadoEn': FieldValue.serverTimestamp(),
    };
    final Map<String, dynamic> datosNotif = {
      'tipo': 'sistema',
      'titulo': 'Nueva falla de la app',
      'mensaje': texto,
      'reportId': null,
      'evento': null,
      'uidDestino': null,
      'destinoRol': 'superadministrador',
      'fallaId': fallaId,
      'autorUid': user.uid,
      'creadoEn': FieldValue.serverTimestamp(),
    };

    final WriteBatch batch = _firestore.batch();
    batch.set(_firestore.collection('fallas_app').doc(fallaId), datosFalla);
    batch.set(_firestore.collection('notifications').doc(notifId), datosNotif);
    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'aborted') {
        final previo = await _firestore
            .collection('fallas_app')
            .doc(fallaId)
            .get();
        if (previo.exists && previo.data()?['uid'] == user.uid) {
          return;
        }
      }
      rethrow;
    }
  }

  @override
  Stream<List<FallaApp>> watchFallas() {
    return _firestore
        .collection('fallas_app')
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(FallaApp.fromFirestore).toList());
  }
}
