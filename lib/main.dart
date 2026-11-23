import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'features/catalogos/data/providers/catalogo_providers.dart';
import 'features/notificaciones/data/providers/notificacion_providers.dart';
import 'features/notificaciones/data/push_notification_service.dart';
import 'features/reportes/data/providers/reporte_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Las fuentes Inter viajan dentro del APK: sin descarga en el primer arranque
  // ni saltos de tipografía cuando no hay conexión.
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Debe registrarse antes de `runApp` para recibir push con la app cerrada.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    ProviderScope(
      overrides: <Override>[
        ...reportesOverrides,
        ...notificacionesOverrides,
        ...catalogosOverrides,
      ],
      child: const RepcampusoftApp(),
    ),
  );
}
