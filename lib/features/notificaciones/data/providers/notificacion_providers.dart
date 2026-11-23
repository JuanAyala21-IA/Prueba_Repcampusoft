import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../../core/routes/session_provider.dart';
import '../../../../core/utils/mes_anio.dart';
import '../../domain/notificacion.dart';
import '../../domain/notificacion_repository.dart';
import '../firebase_notificacion_repository.dart';
import '../local_notificaciones_service.dart';
import '../push_notification_service.dart';

/// Repositorio de notificaciones inyectable (se sobreescribe en pruebas).
final notificacionRepositoryProvider = Provider<NotificacionRepository>((ref) {
  return FirebaseNotificacionRepository();
});

/// Mes visible en la bandeja de notificaciones.
///
/// `null` representa el mes en curso: así la bandeja se restablece sola al
/// iniciar un nuevo mes, sin borrar ningún dato. Los meses anteriores se
/// consultan eligiéndolos en el selector.
final mesNotificacionesSeleccionadoProvider =
    NotifierProvider<MesNotificacionesController, MesAnio?>(
      MesNotificacionesController.new,
    );

class MesNotificacionesController extends Notifier<MesAnio?> {
  @override
  MesAnio? build() => null;

  /// Selecciona [mes]. Elegir el mes en curso vuelve a `null` para que la
  /// bandeja siga automáticamente al calendario.
  void seleccionar(MesAnio mes) => state = mes.esActual ? null : mes;

  void volverAlMesActual() => state = null;
}

/// Notificaciones del estudiante sin filtrar por mes (stream real).
final notificacionesEstudianteTodasProvider =
    StreamProvider.autoDispose<List<Notificacion>>((ref) {
      final sesion = ref.watch(sesionProvider);
      final repository = ref.watch(notificacionRepositoryProvider);

      if (sesion.uid == null) {
        return const Stream<List<Notificacion>>.empty();
      }

      return repository.watchNotificacionesEstudiante(sesion.uid!);
    });

/// Notificaciones del estudiante correspondientes al mes seleccionado.
final notificacionesEstudianteProvider =
    Provider.autoDispose<AsyncValue<List<Notificacion>>>((ref) {
      final AsyncValue<List<Notificacion>> todas = ref.watch(
        notificacionesEstudianteTodasProvider,
      );
      final MesAnio mes =
          ref.watch(mesNotificacionesSeleccionadoProvider) ?? MesAnio.actual();
      return todas.whenData(
        (notificaciones) => _filtrarPorMes(notificaciones, mes),
      );
    });

/// Meses disponibles en la bandeja del estudiante (recientes primero).
final mesesNotificacionesEstudianteProvider =
    Provider.autoDispose<List<MesAnio>>((ref) {
      final List<Notificacion> notificaciones =
          ref.watch(notificacionesEstudianteTodasProvider).value ??
          const <Notificacion>[];
      return _mesesDisponibles(notificaciones);
    });

/// Contador de no leídas del estudiante: solo cuenta el mes en curso para que
/// la campana se restablezca al inicio de cada mes.
final contadorNoLeidasEstudianteProvider =
    Provider.autoDispose<AsyncValue<int>>((ref) {
      final AsyncValue<List<Notificacion>> todas = ref.watch(
        notificacionesEstudianteTodasProvider,
      );
      final MesAnio mesActual = MesAnio.actual();
      return todas.whenData(
        (notificaciones) => _contarNoLeidas(notificaciones, mesActual),
      );
    });

/// Notificaciones del panel (sin filtrar por mes) según el rol actual.
///
/// - Encargado de mantenimiento y administrativo: solo notificaciones de
///   reportes de estudiantes (buzón `administrativo`).
/// - Superadministrador: reportes de estudiantes + fallas de la app
///   (buzones `administrativo` y `superadministrador`), sin avisos
///   administrativos.
final notificacionesAdminTodasProvider =
    StreamProvider.autoDispose<List<Notificacion>>(
      (ref) => _notificacionesPanelVisibles(ref),
    );

/// Notificaciones del panel correspondientes al mes seleccionado.
final notificacionesAdminProvider =
    Provider.autoDispose<AsyncValue<List<Notificacion>>>((ref) {
      final AsyncValue<List<Notificacion>> todas = ref.watch(
        notificacionesAdminTodasProvider,
      );
      final MesAnio mes =
          ref.watch(mesNotificacionesSeleccionadoProvider) ?? MesAnio.actual();
      return todas.whenData(
        (notificaciones) => _filtrarPorMes(notificaciones, mes),
      );
    });

/// Meses disponibles en la bandeja del panel (recientes primero).
final mesesNotificacionesAdminProvider = Provider.autoDispose<List<MesAnio>>((
  ref,
) {
  final List<Notificacion> notificaciones =
      ref.watch(notificacionesAdminTodasProvider).value ??
      const <Notificacion>[];
  return _mesesDisponibles(notificaciones);
});

/// Contador de no leídas del panel: solo cuenta el mes en curso.
final contadorNoLeidasAdminProvider = Provider.autoDispose<AsyncValue<int>>((
  ref,
) {
  final AsyncValue<List<Notificacion>> todas = ref.watch(
    notificacionesAdminTodasProvider,
  );
  final MesAnio mesActual = MesAnio.actual();
  return todas.whenData(
    (notificaciones) => _contarNoLeidas(notificaciones, mesActual),
  );
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

List<Notificacion> _filtrarPorMes(
  List<Notificacion> notificaciones,
  MesAnio mes,
) {
  return notificaciones
      .where((notificacion) => mes.contiene(notificacion.creadoEn.toDate()))
      .toList();
}

int _contarNoLeidas(List<Notificacion> notificaciones, MesAnio mes) {
  return notificaciones
      .where(
        (notificacion) =>
            !notificacion.leida && mes.contiene(notificacion.creadoEn.toDate()),
      )
      .length;
}

List<MesAnio> _mesesDisponibles(List<Notificacion> notificaciones) {
  final Set<MesAnio> meses = <MesAnio>{
    for (final Notificacion notificacion in notificaciones)
      MesAnio.desde(notificacion.creadoEn.toDate()),
    MesAnio.actual(),
  };
  return meses.toList()..sort((a, b) => b.compareTo(a));
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
