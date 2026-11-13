import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routes/app_router.dart';
import '../../../../core/routes/session_provider.dart';

/// Handler de mensajes con la app en segundo plano o cerrada.
///
/// Android muestra la notificación del sistema automáticamente (mensajes con
/// bloque `notification`), así que aquí solo se registra para depuración.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM en segundo plano: ${message.messageId}');
}

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) => PushNotificationService(ref),
);

/// Registro del token FCM y navegación al tocar una notificación.
///
/// Las notificaciones con la app en primer plano las sigue mostrando
/// [LocalNotificacionesService] (escucha Firestore), por lo que aquí no se
/// vuelven a mostrar para no duplicarlas.
class PushNotificationService {
  PushNotificationService(this._ref);

  final Ref _ref;

  // Se resuelven de forma perezosa para no tocar Firebase al construir el
  // proveedor (importante en pruebas sin Firebase inicializado).
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  StreamSubscription<String>? _tokenRefreshSub;
  String? _uidActual;

  Future<void> inicializar() async {
    try {
      // Permiso de notificaciones (Android 13+/iOS).
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      // En primer plano la alerta la muestra LocalNotificacionesService al
      // escuchar Firestore. Si iOS también presentara el push automático se
      // vería duplicado, así que aquí se desactiva.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      _ref.listen<Sesion>(sesionProvider, (_, sesion) {
        if (sesion.estado == SesionEstado.rolAplicado && sesion.uid != null) {
          _registrarToken(sesion.uid!);
        } else {
          // Al cerrar sesión (o quedar pendiente) se borra el token del
          // usuario para que este dispositivo deje de recibir notificaciones
          // de una cuenta que ya no está activa.
          final String? uidAnterior = _uidActual;
          _detener();
          if (uidAnterior != null) unawaited(_limpiarToken(uidAnterior));
        }
      });

      final Sesion sesionActual = _ref.read(sesionProvider);
      if (sesionActual.estado == SesionEstado.rolAplicado &&
          sesionActual.uid != null) {
        await _registrarToken(sesionActual.uid!);
      }

      // Toque de una notificación con la app abierta/background.
      FirebaseMessaging.onMessageOpenedApp.listen(_abrirDesdeMensaje);

      // Toque que abrió la app desde cerrada.
      final RemoteMessage? inicial = await _messaging.getInitialMessage();
      if (inicial != null) {
        // Dar tiempo a que el router y la sesión estén listos.
        unawaited(
          Future<void>.delayed(
            const Duration(milliseconds: 800),
            () => _abrirDesdeMensaje(inicial),
          ),
        );
      }
    } catch (e) {
      debugPrint('No se pudo inicializar FCM: $e');
    }
  }

  Future<void> _registrarToken(String uid) async {
    if (_uidActual == uid) return;
    final String? uidAnterior = _uidActual;
    _uidActual = uid;
    if (uidAnterior != null) await _limpiarToken(uidAnterior);

    final String? token = await _esperarToken(uid);
    if (token != null && _uidActual == uid) await _guardarToken(uid, token);

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      final String? actual = _uidActual;
      if (actual != null) await _guardarToken(actual, token);
    });
  }

  /// Obtiene el token FCM esperando a que APNs esté listo en iOS.
  ///
  /// Tras conceder el permiso, iOS puede tardar unos segundos en entregar el
  /// token APNs; sin él `getToken()` falla o devuelve `null`. Se reintenta unas
  /// cuantas veces sin bloquear la interfaz.
  Future<String?> _esperarToken(String uid) async {
    const int intentos = 5;
    for (int intento = 0; intento < intentos; intento++) {
      if (_uidActual != uid) return null;
      try {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          final String? apns = await _messaging.getAPNSToken();
          if (apns == null) {
            await Future<void>.delayed(const Duration(seconds: 2));
            continue;
          }
        }
        final String? token = await _messaging.getToken();
        if (token != null) return token;
      } catch (e) {
        debugPrint('No se pudo obtener el token FCM: $e');
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return null;
  }

  Future<void> _guardarToken(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).update({'fcmToken': token});
    } catch (e) {
      debugPrint('No se pudo guardar el token FCM: $e');
    }
  }

  /// Borra el token del usuario que deja la sesión (best-effort).
  Future<void> _limpiarToken(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({'fcmToken': null});
    } catch (e) {
      debugPrint('No se pudo limpiar el token FCM: $e');
    }
  }

  void _detener() {
    _uidActual = null;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
  }

  void _abrirDesdeMensaje(RemoteMessage message) {
    final String fallaId = message.data['fallaId'] as String? ?? '';
    final String tipo = message.data['tipo'] as String? ?? '';
    // Las fallas de la app solo las ve el superadministrador; no tienen un
    // detalle propio, así que se abre el listado.
    if (fallaId.isNotEmpty || tipo == 'sistema') {
      _ref.read(routerProvider).push(AppRoutes.fallasApp);
      return;
    }

    final String reportId = message.data['reportId'] as String? ?? '';
    if (reportId.isEmpty) return;

    final Sesion sesion = _ref.read(sesionProvider);
    final bool gestiona =
        sesion.puedeGestionarReportes || sesion.esSuperadministrador;
    final String ruta = gestiona
        ? '${AppRoutes.gestionReporte}?reportId=$reportId'
        : '${AppRoutes.detalleReporte}/$reportId';
    _ref.read(routerProvider).push(ruta);
  }
}
