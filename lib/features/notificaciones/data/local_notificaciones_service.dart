import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/notificacion.dart';
import 'providers/notificacion_providers.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/routes/session_provider.dart';

final localNotificacionesServiceProvider = Provider<LocalNotificacionesService>(
  (ref) => LocalNotificacionesService(ref),
);

/// Notificaciones del sistema mientras la app está en primer plano.
///
/// Con la app cerrada o en segundo plano las muestra FCM. Aquí solo se
/// notifican los eventos que ocurren en tiempo real mientras el usuario está
/// dentro de la app; al abrirla NO se vuelven a mostrar las notificaciones
/// antiguas que ya existían.
class LocalNotificacionesService {
  LocalNotificacionesService(this._ref);

  final Ref _ref;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Set<String> _notificacionesYaNotificadas = <String>{};

  StreamSubscription<List<Notificacion>>? _subEstudiante;
  StreamSubscription<List<Notificacion>>? _subAdmin;

  /// La primera emisión del stream es el estado actual de la bandeja: se usa
  /// como línea base y no se muestra.
  bool _primeraCarga = true;

  /// Momento desde el que se consideran "en tiempo real" las notificaciones.
  DateTime _escuchandoDesde = DateTime.now();

  /// Observa el ciclo de vida para saber cuándo se vuelve a primer plano.
  late final WidgetsBindingObserver _lifecycleObserver = _LifecycleObserver(
    onResumed: () => _escuchandoDesde = DateTime.now(),
  );

  Future<void> inicializar() async {
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _ref.onDispose(
      () => WidgetsBinding.instance.removeObserver(_lifecycleObserver),
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear el canal de Android desde el arranque para que FCM (con la app en
    // segundo plano) use el mismo canal de alta prioridad.
    const AndroidNotificationChannel canal = AndroidNotificationChannel(
      'notificaciones_repcampusoft',
      'Notificaciones REPCAMPUSOFT',
      description: 'Notificaciones de reportes y avisos del sistema',
      importance: Importance.high,
    );
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(canal);

    // Solicitar permisos en Android 13+ e iOS
    await _solicitarPermisos();

    // Escuchar cambios de sesión para iniciar/detener listeners
    _ref.listen<Sesion>(sesionProvider, (_, sesion) {
      if (sesion.estado == SesionEstado.rolAplicado) {
        _iniciarListeners(sesion);
      } else {
        _detenerListeners();
      }
    });

    // Si ya hay sesión activa al inicializar
    final sesionActual = _ref.read(sesionProvider);
    if (sesionActual.estado == SesionEstado.rolAplicado) {
      _iniciarListeners(sesionActual);
    }
  }

  Future<void> _solicitarPermisos() async {
    // Android 13+ (API 33+)
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // iOS
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _iniciarListeners(Sesion sesion) {
    _detenerListeners();

    final uid = sesion.uid!;
    final bool gestionaNotificaciones =
        sesion.puedeGestionarReportes || sesion.esSuperadministrador;
    final bool esSuperadministrador = sesion.esSuperadministrador;
    final List<String> destinoRoles = esSuperadministrador
        ? const <String>['administrativo', 'superadministrador']
        : const <String>['administrativo'];
    final repository = _ref.read(notificacionRepositoryProvider);

    // Al iniciar sesión se toma el estado actual como línea base: todo lo que
    // ya estaba en la bandeja se marca como notificado y no se muestra.
    _notificacionesYaNotificadas.clear();
    _primeraCarga = true;
    _escuchandoDesde = DateTime.now();

    if (gestionaNotificaciones) {
      _subAdmin = repository
          .watchNotificacionesAdmin(uid, destinoRoles: destinoRoles)
          .map(
            (notifs) => notifs.where((notif) {
              if (esSuperadministrador) {
                return notif.tipo == NotificacionTipo.reporte ||
                    notif.tipo == NotificacionTipo.sistema;
              }
              return notif.tipo == NotificacionTipo.reporte;
            }).toList(),
          )
          .listen(_alRecibirNotificaciones);
    } else {
      _subEstudiante = repository
          .watchNotificacionesEstudiante(uid)
          .listen(_alRecibirNotificaciones);
    }
  }

  void _alRecibirNotificaciones(List<Notificacion> notificaciones) {
    // La primera emisión es la foto actual de la bandeja: se registra como
    // base para no notificar lo que ya existía antes de abrir la app.
    if (_primeraCarga) {
      for (final n in notificaciones) {
        _notificacionesYaNotificadas.add(n.id);
      }
      _primeraCarga = false;
      return;
    }
    _procesarNotificacionesNuevas(notificaciones);
  }

  /// Solo se muestra la notificación del sistema si la app está en primer
  /// plano; en segundo plano/cerrada FCM muestra la notificación (evita
  /// duplicados).
  bool get _enPrimerPlano {
    final AppLifecycleState? estado = WidgetsBinding.instance.lifecycleState;
    return estado == null || estado == AppLifecycleState.resumed;
  }

  /// `true` si la notificación se creó mientras la app estaba abierta.
  ///
  /// La tolerancia de 5 s absorbe el pequeño desfase entre el reloj del
  /// servidor (Firestore) y el del dispositivo.
  bool _esEnTiempoReal(Notificacion notif) {
    return !notif.creadoEn.toDate().isBefore(
      _escuchandoDesde.subtract(const Duration(seconds: 5)),
    );
  }

  void _procesarNotificacionesNuevas(List<Notificacion> notificaciones) {
    for (final notif in notificaciones) {
      if (_notificacionesYaNotificadas.contains(notif.id) || notif.leida) {
        continue;
      }
      _notificacionesYaNotificadas.add(notif.id);
      if (_enPrimerPlano && _esEnTiempoReal(notif)) {
        _mostrarNotificacionLocal(notif);
      }
    }
  }

  Future<void> _mostrarNotificacionLocal(Notificacion notif) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'notificaciones_repcampusoft',
          'Notificaciones REPCAMPUSOFT',
          channelDescription: 'Notificaciones de reportes y avisos del sistema',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      notif.id.hashCode, // id único numérico para la notificación local
      notif.titulo,
      notif.mensaje,
      platformDetails,
      payload: notif.reportId, // reportId para navegación al tocar
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    final reportId = response.payload;
    if (reportId != null && reportId.isNotEmpty) {
      // Navegar al detalle/gestión según el rol
      final sesion = _ref.read(sesionProvider);
      final bool gestionaReportes =
          sesion.puedeGestionarReportes || sesion.esSuperadministrador;
      final ruta = gestionaReportes
          ? '${AppRoutes.gestionReporte}?reportId=$reportId'
          : '${AppRoutes.detalleReporte}/$reportId';
      _ref.read(routerProvider).push(ruta);
    } else {
      // Sin reporte asociado (p. ej. fallas de la app): abrir la bandeja
      // correspondiente al rol.
      final sesion = _ref.read(sesionProvider);
      final String ruta = sesion.esSuperadministrador
          ? AppRoutes.fallasApp
          : (sesion.puedeGestionarReportes
                ? AppRoutes.notificacionesAdmin
                : AppRoutes.notificacionesEstudiante);
      _ref.read(routerProvider).push(ruta);
    }
  }

  void _detenerListeners() {
    _subEstudiante?.cancel();
    _subEstudiante = null;
    _subAdmin?.cancel();
    _subAdmin = null;
    _primeraCarga = true;
  }
}

/// Observer de ciclo de vida que avisa cuando la app vuelve a primer plano.
class _LifecycleObserver with WidgetsBindingObserver {
  _LifecycleObserver({required this.onResumed});

  final VoidCallback onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResumed();
  }
}
