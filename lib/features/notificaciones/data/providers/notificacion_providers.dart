import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../domain/notificacion.dart';
import '../../domain/notificacion_repository.dart';
import '../firebase_notificacion_repository.dart';
import '../local_notificaciones_service.dart';
import '../push_notification_service.dart';
import '../../../../core/routes/session_provider.dart';

/// Repositorio de notificaciones inyectable (se sobreescribe en pruebas).
final notificacionRepositoryProvider = Provider<NotificacionRepository>((ref) {
  return FirebaseNotificacionRepository();
});

/// StreamProvider.autoDispose que expone las notificaciones del estudiante
/// actual en tiempo real, con el campo `leida` ya resuelto.
final notificacionesEstudianteProvider =
    StreamProvider.autoDispose<List<Notificacion>>((ref) {
      final sesion = ref.watch(sesionProvider);
      final repository = ref.watch(notificacionRepositoryProvider);

      if (sesion.uid == null) {
        return const Stream<List<Notificacion>>.empty();
      }

      return repository.watchNotificacionesEstudiante(sesion.uid!);
    });

/// StreamProvider.autoDispose para el contador de no leídas del estudiante.
final contadorNoLeidasEstudianteProvider = StreamProvider.autoDispose<int>((
  ref,
) {
  final sesion = ref.watch(sesionProvider);
  final repository = ref.watch(notificacionRepositoryProvider);

  if (sesion.uid == null) {
    return const Stream<int>.empty();
  }

  return repository.watchContadorNoLeidasEstudiante(sesion.uid!);
});

/// StreamProvider.autoDispose que expone las notificaciones del panel según el
/// rol actual.
///
/// - Encargado de mantenimiento y administrativo: solo notificaciones de
///   reportes de estudiantes (buzón `administrativo`).
/// - Superadministrador: reportes de estudiantes + fallas de la app
///   (buzones `administrativo` y `superadministrador`), sin avisos
///   administrativos.
final notificacionesAdminProvider =
    StreamProvider.autoDispose<List<Notificacion>>(
      (ref) => _notificacionesPanelVisibles(ref),
    );

/// StreamProvider.autoDispose para el contador de no leídas del panel,
/// contando únicamente las notificaciones visibles para el rol actual.
final contadorNoLeidasAdminProvider = StreamProvider.autoDispose<int>((ref) {
  return _notificacionesPanelVisibles(ref)
      .map((notifs) => notifs.where((n) => !n.leida).length);
});

Stream<List<Notificacion>> _notificacionesPanelVisibles(Ref ref) {
  final sesion = ref.watch(sesionProvider);
  final repository = ref.watch(notificacionRepositoryProvider);

  if (sesion.uid == null) {
    return const Stream<List<Notificacion>>.empty();
  }

  final bool esSuperadministrador = sesion.esSuperadministrador;
  final List<String> destinoRoles = esSuperadministrador
      ? const <String>['administrativo', 'superadministrador']
      : const <String>['administrativo'];

  return repository
      .watchNotificacionesAdmin(sesion.uid!, destinoRoles: destinoRoles)
      .map(
        (notifs) => notifs.where((notif) {
          if (esSuperadministrador) {
            return notif.tipo == NotificacionTipo.reporte ||
                notif.tipo == NotificacionTipo.sistema;
          }
          return notif.tipo == NotificacionTipo.reporte;
        }).toList(),
      );
}

/// Inicializa los servicios de notificaciones una sola vez al arrancar la app.
///
/// - [LocalNotificacionesService]: muestra la notificación del sistema cuando
///   la app está en primer plano (escucha la colección `notifications`).
/// - [PushNotificationService]: registra el token FCM y navega al tocar una
///   notificación que llegó con la app en segundo plano o cerrada.
final notificacionesBootstrapProvider = Provider<void>((ref) {
  _inicializarNotificaciones(ref);
});

Future<void> _inicializarNotificaciones(Ref ref) async {
  try {
    await ref.read(localNotificacionesServiceProvider).inicializar();
  } catch (e) {
    debugPrint('No se pudo inicializar las notificaciones locales: $e');
  }
  try {
    await ref.read(pushNotificationServiceProvider).inicializar();
  } catch (e) {
    debugPrint('No se pudo inicializar FCM: $e');
  }
}

/// Overrides para inyectar el repositorio Firestore real en el ProviderScope.
final List<Override> notificacionesOverrides = <Override>[
  notificacionRepositoryProvider.overrideWith(
    (ref) => FirebaseNotificacionRepository(),
  ),
  localNotificacionesServiceProvider.overrideWith(
    (ref) => LocalNotificacionesService(ref),
  ),
];
