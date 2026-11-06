import 'notificacion.dart';

abstract class NotificacionRepository {
  Stream<List<Notificacion>> watchNotificacionesEstudiante(String uid);

  Stream<List<Notificacion>> watchNotificacionesAdmin(
    String uid, {
    List<String> destinoRoles = const <String>['administrativo'],
    String? filtroTipo,
  });

  Future<void> marcarLeida(String uid, String notifId);

  Stream<int> watchContadorNoLeidasEstudiante(String uid);

  Stream<int> watchContadorNoLeidasAdmin(
    String uid, {
    List<String> destinoRoles = const <String>['administrativo'],
  });
}
