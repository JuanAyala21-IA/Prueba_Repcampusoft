import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:repcampusoft/features/notificaciones/domain/notificacion.dart';
import 'package:repcampusoft/features/notificaciones/domain/notificacion_repository.dart';

/// Fake in-memory implementation of NotificacionRepository using fake_cloud_firestore.
/// Reproduce el comportamiento reactivo de `FirebaseNotificacionRepository`:
/// al hacer listen() se suscribe a `notifications` y a `notificacionesLeidas`
/// y re-emite la lista combinada cuando cualquiera de los dos cambia.
class FakeNotificacionRepository implements NotificacionRepository {
  FakeNotificacionRepository({FakeFirebaseFirestore? firestore})
    : _firestore = firestore ?? FakeFirebaseFirestore();

  final FakeFirebaseFirestore _firestore;

  // Cache for computed streams to ensure same instance returned
  final Map<String, Stream<List<Notificacion>>> _streamCache = {};

  // Getter para acceso en tests
  FakeFirebaseFirestore get firestore => _firestore;

  @override
  Stream<List<Notificacion>> watchNotificacionesEstudiante(String uid) {
    return _getOrCreateStream(uid, isAdmin: false);
  }

  @override
  Stream<List<Notificacion>> watchNotificacionesAdmin(
    String uid, {
    List<String> destinoRoles = const <String>['administrativo'],
    String? filtroTipo,
  }) {
    return _getOrCreateStream(
      uid,
      isAdmin: true,
      destinoRoles: destinoRoles,
      filtroTipo: filtroTipo,
    );
  }

  @override
  Future<void> marcarLeida(String uid, String notifId) async {
    // Escribir en FakeFirebaseFirestore dispara el listener de
    // `notificacionesLeidas`, que re-emite la lista combinada (igual que el
    // Cloud Firestore real en producción).
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

  Stream<List<Notificacion>> _getOrCreateStream(
    String uid, {
    required bool isAdmin,
    List<String> destinoRoles = const <String>['administrativo'],
    String? filtroTipo,
  }) {
    final cacheKey =
        '$uid-$isAdmin-${destinoRoles.join(',')}-${filtroTipo ?? ''}';
    return _streamCache.putIfAbsent(
      cacheKey,
      () => _createReactiveStream(
        uid,
        isAdmin: isAdmin,
        destinoRoles: destinoRoles,
        filtroTipo: filtroTipo,
      ),
    );
  }

  /// Simula `_combineNotificacionesWithLeidas` de producción: al hacer
  /// listen() ejecuta un recompute inicial y se suscribe a `notifications` y
  /// a `notificacionesLeidas`, re-emitiendo la lista combinada en cada cambio.
  Stream<List<Notificacion>> _createReactiveStream(
    String uid, {
    required bool isAdmin,
    List<String> destinoRoles = const <String>['administrativo'],
    String? filtroTipo,
  }) {
    late final StreamController<List<Notificacion>> controller;
    late StreamSubscription notifsSub;
    late StreamSubscription leidasSub;

    Query<Map<String, dynamic>> notificacionesQuery;
    if (isAdmin) {
      notificacionesQuery = _firestore.collection('notifications');
      if (destinoRoles.length == 1) {
        notificacionesQuery = notificacionesQuery
            .where('destinoRol', isEqualTo: destinoRoles.first)
            .orderBy('creadoEn', descending: true);
      } else {
        notificacionesQuery = notificacionesQuery.where(
          'destinoRol',
          whereIn: destinoRoles,
        );
      }
    } else {
      notificacionesQuery = _firestore
          .collection('notifications')
          .where('uidDestino', isEqualTo: uid)
          .orderBy('creadoEn', descending: true);
    }
    final notificationsQuery = notificacionesQuery;

    Future<void> recompute() async {
      if (controller.isClosed) return;
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
      controller.add(
        _mapToNotificaciones(notifsSnap.docs, leidasSet, filtroTipo),
      );
    }

    controller = StreamController<List<Notificacion>>.broadcast(
      onListen: () {
        // Carga inicial
        recompute();

        // Escuchar cambios en `notifications`
        notifsSub = notificationsQuery.snapshots().listen((_) => recompute());

        // Escuchar cambios en `notificacionesLeidas` (marcarLeida)
        leidasSub = _firestore
            .collection('users')
            .doc(uid)
            .collection('notificacionesLeidas')
            .snapshots()
            .listen((_) => recompute());
      },
      onCancel: () {
        notifsSub.cancel();
        leidasSub.cancel();
      },
    );

    return controller.stream;
  }

  List<Notificacion> _mapToNotificaciones(
    List<QueryDocumentSnapshot<Object?>> docs,
    Set<String> leidasSet,
    String? filtroTipo,
  ) {
    final result = <Notificacion>[];
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final tipoStr = data['tipo'] as String?;
      if (filtroTipo != null && tipoStr != filtroTipo.toLowerCase()) {
        continue;
      }
      final leida = leidasSet.contains(doc.id);
      result.add(
        Notificacion(
          id: doc.id,
          tipo: Notificacion.parseTipo(tipoStr),
          titulo: data['titulo'] as String,
          mensaje: data['mensaje'] as String,
          reportId: data['reportId'] as String?,
          evento: Notificacion.parseEvento(data['evento']),
          estadoNuevo: data['estadoNuevo'] as String?,
          uidDestino: data['uidDestino'] as String?,
          destinoRol: data['destinoRol'] as String?,
          autorUid: data['autorUid'] as String?,
          creadoEn: data['creadoEn'] as Timestamp,
          leida: leida,
        ),
      );
    }
    result.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
    return result;
  }
}
