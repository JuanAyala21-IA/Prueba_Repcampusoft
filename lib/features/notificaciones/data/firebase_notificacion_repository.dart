import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/notificacion.dart';
import '../domain/notificacion_repository.dart';

class FirebaseNotificacionRepository implements NotificacionRepository {
  FirebaseNotificacionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Notificacion>> watchNotificacionesEstudiante(String uid) {
    return _combineNotificacionesWithLeidas(
      uid: uid,
      notificationsQuery: _firestore
          .collection('notifications')
          .where('uidDestino', isEqualTo: uid)
          .orderBy('creadoEn', descending: true),
    );
  }

  @override
  Stream<List<Notificacion>> watchNotificacionesAdmin(
    String uid, {
    List<String> destinoRoles = const <String>['administrativo'],
    String? filtroTipo,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection('notifications');

    // Un solo buzón se ordena en Firestore; varios buzones (por ejemplo el
    // superadministrador, que ve reportes y fallas) se unen con `whereIn` y se
    // ordenan en memoria para no depender de un índice compuesto adicional.
    if (destinoRoles.length == 1) {
      query = query
          .where('destinoRol', isEqualTo: destinoRoles.first)
          .orderBy('creadoEn', descending: true);
    } else {
      query = query.where('destinoRol', whereIn: destinoRoles);
    }

    if (filtroTipo != null && filtroTipo != 'Todas') {
      query = query.where('tipo', isEqualTo: filtroTipo.toLowerCase());
    }

    return _combineNotificacionesWithLeidas(
      uid: uid,
      notificationsQuery: query,
    );
  }

  @override
  Future<void> marcarLeida(String uid, String notifId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notificacionesLeidas')
        .doc(notifId)
        .set({
          'leida': true,
          'leidaEn': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Stream<int> watchContadorNoLeidasEstudiante(String uid) {
    return watchNotificacionesEstudiante(uid)
        .map((notifs) => notifs.where((n) => !n.leida).length);
  }

  @override
  Stream<int> watchContadorNoLeidasAdmin(
    String uid, {
    List<String> destinoRoles = const <String>['administrativo'],
  }) {
    return watchNotificacionesAdmin(
      uid,
      destinoRoles: destinoRoles,
    ).map((notifs) => notifs.where((n) => !n.leida).length);
  }

  Stream<List<Notificacion>> _combineNotificacionesWithLeidas({
    required String uid,
    required Query<Map<String, dynamic>> notificationsQuery,
  }) {
    late final StreamController<List<Notificacion>> controller;
    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> notifsSub;
    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> leidasSub;

    Future<void> recompute() async {
      final notifsSnap = await notificationsQuery.get();
      final notifIds = notifsSnap.docs.map((d) => d.id).toList();

      if (notifIds.isEmpty) {
        controller.add([]);
        return;
      }

      final leidasSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notificacionesLeidas')
          .where(FieldPath.documentId, whereIn: notifIds)
          .get();

      final leidasSet = leidasSnap.docs.map((d) => d.id).toSet();
      controller.add(_mapToNotificaciones(notifsSnap.docs, leidasSet));
    }

    controller = StreamController<List<Notificacion>>.broadcast(
      onListen: () {
        // Initial load
        recompute();

        // Listen to notifications changes
        notifsSub = notificationsQuery.snapshots().listen((snap) async {
          final notifIds = snap.docs.map((d) => d.id).toList();
          if (notifIds.isEmpty) {
            controller.add([]);
            return;
          }
          final leidasSnap = await _firestore
              .collection('users')
              .doc(uid)
              .collection('notificacionesLeidas')
              .where(FieldPath.documentId, whereIn: notifIds)
              .get();
          final leidasSet = leidasSnap.docs.map((d) => d.id).toSet();
          controller.add(_mapToNotificaciones(snap.docs, leidasSet));
        });

        // Listen to leidas changes - when user marks as read
        leidasSub = _firestore
            .collection('users')
            .doc(uid)
            .collection('notificacionesLeidas')
            .snapshots()
            .listen((_) async {
              await recompute();
            });
      },
      onCancel: () {
        notifsSub.cancel();
        leidasSub.cancel();
      },
    );
    return controller.stream;
  }

  List<Notificacion> _mapToNotificaciones(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    Set<String> leidasSet,
  ) {
    final notificaciones = docs.map((doc) {
      final data = doc.data();
      final leida = leidasSet.contains(doc.id);
      return Notificacion(
        id: doc.id,
        tipo: Notificacion.parseTipo(data['tipo']),
        titulo: data['titulo'] as String,
        mensaje: data['mensaje'] as String,
        reportId: data['reportId'] as String?,
        evento: Notificacion.parseEvento(data['evento']),
        estadoNuevo: data['estadoNuevo'] as String?,
        uidDestino: data['uidDestino'] as String?,
        destinoRol: data['destinoRol'] as String?,
        autorUid: data['autorUid'] as String?,
        fallaId: data['fallaId'] as String?,
        creadoEn: data['creadoEn'] as Timestamp,
        leida: leida,
      );
    }).toList();

    // Se ordena aquí para cubrir el caso de varios buzones, donde la consulta
    // no lleva `orderBy`.
    notificaciones.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
    return notificaciones;
  }
}
