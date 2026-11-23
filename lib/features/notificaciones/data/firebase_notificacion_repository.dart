import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/notificacion.dart';
import '../domain/notificacion_repository.dart';

class FirebaseNotificacionRepository implements NotificacionRepository {
  FirebaseNotificacionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Notificacion>> watchNotificacionesEstudiante(
    String uid, {
    DateTime? desde,
    DateTime? hasta,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('notifications')
        .where('uidDestino', isEqualTo: uid)
        .orderBy('creadoEn', descending: true);
    query = _aplicarRangoFechas(query, desde: desde, hasta: hasta);
    return _combineNotificacionesWithLeidas(
      uid: uid,
      notificationsQuery: query,
    );
  }

  @override
  Stream<List<Notificacion>> watchNotificacionesAdmin(
    String uid, {
    List<String> destinoRoles = const <String>['administrativo'],
    String? filtroTipo,
    DateTime? desde,
    DateTime? hasta,
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

    query = _aplicarRangoFechas(query, desde: desde, hasta: hasta);

    return _combineNotificacionesWithLeidas(
      uid: uid,
      notificationsQuery: query,
    );
  }

  /// Limita la consulta al mes pedido. El rango usa `hasta` como límite
  /// exclusivo; Firestore resuelve con los índices `destinoRol/uidDestino +
  /// creadoEn` ya declarados, de modo que no se descarga el historial completo.
  Query<Map<String, dynamic>> _aplicarRangoFechas(
    Query<Map<String, dynamic>> query, {
    DateTime? desde,
    DateTime? hasta,
  }) {
    if (desde != null) {
      query = query.where(
        'creadoEn',
        isGreaterThanOrEqualTo: Timestamp.fromDate(desde),
      );
    }
    if (hasta != null) {
      query = query.where('creadoEn', isLessThan: Timestamp.fromDate(hasta));
    }
    return query;
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

  /// Firestore limita `whereIn` a 30 elementos. Se consultan las leídas en
  /// lotes para que la bandeja funcione aunque el usuario acumule cientos de
  /// notificaciones (caso típico del superadministrador).
  static const int _maxIdsPorConsulta = 30;

  Future<Set<String>> _leerLeidas(String uid, List<String> notifIds) async {
    final Set<String> leidas = <String>{};
    for (int i = 0; i < notifIds.length; i += _maxIdsPorConsulta) {
      final int fin = i + _maxIdsPorConsulta < notifIds.length
          ? i + _maxIdsPorConsulta
          : notifIds.length;
      final QuerySnapshot<Map<String, dynamic>> snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('notificacionesLeidas')
          .where(FieldPath.documentId, whereIn: notifIds.sublist(i, fin))
          .get();
      leidas.addAll(snap.docs.map((d) => d.id));
    }
    return leidas;
  }

  Stream<List<Notificacion>> _combineNotificacionesWithLeidas({
    required String uid,
    required Query<Map<String, dynamic>> notificationsQuery,
  }) {
    late final StreamController<List<Notificacion>> controller;
    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> notifsSub;
    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>> leidasSub;

    Future<List<Notificacion>> resolver(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    ) async {
      if (docs.isEmpty) return <Notificacion>[];
      final List<String> notifIds = docs.map((d) => d.id).toList();
      final Set<String> leidasSet = await _leerLeidas(uid, notifIds);
      return _mapToNotificaciones(docs, leidasSet);
    }

    Future<void> recompute() async {
      try {
        final notifsSnap = await notificationsQuery.get();
        controller.add(await resolver(notifsSnap.docs));
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      }
    }

    controller = StreamController<List<Notificacion>>.broadcast(
      onListen: () {
        // Initial load
        recompute();

        // Listen to notifications changes
        notifsSub = notificationsQuery.snapshots().listen(
          (snap) async {
            try {
              controller.add(await resolver(snap.docs));
            } catch (error, stackTrace) {
              controller.addError(error, stackTrace);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            controller.addError(error, stackTrace);
          },
        );

        // Listen to leidas changes - when user marks as read
        leidasSub = _firestore
            .collection('users')
            .doc(uid)
            .collection('notificacionesLeidas')
            .snapshots()
            .listen(
              (_) async {
                await recompute();
              },
              onError: (Object error, StackTrace stackTrace) {
                controller.addError(error, stackTrace);
              },
            );
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
