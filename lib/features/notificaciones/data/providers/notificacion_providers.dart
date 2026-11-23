import 'package:flutter/widgets.dart';
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
  MesAnio? build() {
    // Al cambiar de usuario o cerrar sesión, la bandeja vuelve al mes en curso.
    ref.watch(sesionProvider.select((Sesion sesion) => sesion.uid));
    return null;
  }

  /// Selecciona [mes]. Elegir el mes en curso vuelve a `null` para que la
  /// bandeja siga automáticamente al calendario.
  void seleccionar(MesAnio mes) => state = mes.esActual ? null : mes;

  void volverAlMesActual() => state = null;
}

/// Notificaciones del estudiante de un mes concreto.
///
/// La consulta se limita en Firestore al rango del mes (`creadoEn`), por lo que
/// no se descarga el historial completo. Es una familia por [MesAnio]: la
/// bandeja y el badge comparten la misma suscripción cuando apuntan al mes en
/// curso, evitando lecturas duplicadas.
final notificacionesEstudianteMesProvider = StreamProvider.autoDispose
    .family<List<Notificacion>, MesAnio>((ref, mes) {
      final sesion = ref.watch(sesionProvider);
      final repository = ref.watch(notificacionRepositoryProvider);

      if (sesion.uid == null) {
        return const Stream<List<Notificacion>>.empty();
      }

      return repository.watchNotificacionesEstudiante(
        sesion.uid!,
        desde: mes.inicio,
        hasta: mes.siguienteInicio,
      );
    });

/// Notificaciones del estudiante correspondientes al mes seleccionado.
final notificacionesEstudianteProvider =
    Provider.autoDispose<AsyncValue<List<Notificacion>>>((ref) {
      final MesAnio mes =
          ref.watch(mesNotificacionesSeleccionadoProvider) ?? MesAnio.actual();
      return ref.watch(notificacionesEstudianteMesProvider(mes));
    });

/// Meses consultables en el selector de la bandeja (recientes primero).
///
/// Es una ventana fija de 24 meses para no depender de leer todo el historial
/// de notificaciones solo para construir el menú. Los meses sin movimientos
/// muestran su estado vacío.
final mesesNotificacionesProvider = Provider.autoDispose<List<MesAnio>>((ref) {
  final MesAnio actual = MesAnio.actual();
  final List<MesAnio> meses = <MesAnio>[actual];
  for (int i = 1; i < 24; i++) {
    meses.add(meses.last.anterior);
  }
  return meses;
});

/// Contador de no leídas del estudiante: solo cuenta el mes en curso para que
/// la campana se restablezca al inicio de cada mes.
final contadorNoLeidasEstudianteProvider =
    Provider.autoDispose<AsyncValue<int>>((ref) {
      return ref
          .watch(notificacionesEstudianteMesProvider(MesAnio.actual()))
          .whenData((notificaciones) => _contarNoLeidas(notificaciones));
    });

/// Notificaciones del panel de un mes concreto según el rol actual.
///
/// - Encargado de mantenimiento y administrativo: solo notificaciones de
///   reportes de estudiantes (buzón `administrativo`).
/// - Superadministrador: reportes de estudiantes + fallas de la app
///   (buzones `administrativo` y `superadministrador`), sin avisos
///   administrativos.
final notificacionesAdminMesProvider = StreamProvider.autoDispose
    .family<List<Notificacion>, MesAnio>((ref, mes) {
      return _notificacionesPanelVisibles(ref, mes);
    });

/// Notificaciones del panel correspondientes al mes seleccionado.
final notificacionesAdminProvider =
    Provider.autoDispose<AsyncValue<List<Notificacion>>>((ref) {
      final MesAnio mes =
          ref.watch(mesNotificacionesSeleccionadoProvider) ?? MesAnio.actual();
      return ref.watch(notificacionesAdminMesProvider(mes));
    });

/// Contador de no leídas del panel: solo cuenta el mes en curso.
final contadorNoLeidasAdminProvider = Provider.autoDispose<AsyncValue<int>>((
  ref,
) {
  return ref
      .watch(notificacionesAdminMesProvider(MesAnio.actual()))
      .whenData((notificaciones) => _contarNoLeidas(notificaciones));
});

Stream<List<Notificacion>> _notificacionesPanelVisibles(Ref ref, MesAnio mes) {
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
      .watchNotificacionesAdmin(
        sesion.uid!,
        destinoRoles: destinoRoles,
        desde: mes.inicio,
        hasta: mes.siguienteInicio,
      )
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

int _contarNoLeidas(List<Notificacion> notificaciones) {
  return notificaciones.where((notificacion) => !notificacion.leida).length;
}

/// Inicializa los servicios de notificaciones una sola vez al arrancar la app.
///
/// - [LocalNotificacionesService]: muestra la notificación del sistema cuando
///   la app está en primer plano (escucha la colección `notifications`).
/// - [PushNotificationService]: registra el token FCM y navega al tocar una
///   notificación que llegó con la app en segundo plano o cerrada.
final notificacionesBootstrapProvider = Provider<void>((ref) {
  // Se difiere hasta después del primer frame: registrar FCM y el canal de
  // notificaciones locales son llamadas de plataforma que no deben competir
  // con el primer pintado de la app.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _inicializarNotificaciones(ref);
  });
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
