import 'notificacion.dart';

abstract class NotificacionRepository {
  /// Notificaciones del usuario. Si se indican [desde] (incluido) y [hasta]
  /// (excluido), la consulta se limita a ese rango de fechas en Firestore.
  Stream<List<Notificacion>> watchNotificacionesEstudiante(
    String uid, {
    DateTime? desde,
    DateTime? hasta,
  });

  Stream<List<Notificacion>> watchNotificacionesAdmin(
    String uid, {
    List<String> destinoRoles = const <String>['administrativo'],
    String? filtroTipo,
    DateTime? desde,
    DateTime? hasta,
  });

  Future<void> marcarLeida(String uid, String notifId);

  Stream<int> watchContadorNoLeidasEstudiante(String uid);

  Stream<int> watchContadorNoLeidasAdmin(
    String uid, {
    List<String> destinoRoles = const <String>['administrativo'],
  });
}
