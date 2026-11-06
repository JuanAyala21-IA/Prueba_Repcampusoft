# Notificaciones push e imágenes en Storage

Esta fase se apoya en el plan **Blaze** de Firebase (Cloud Storage + Cloud
Functions). Resumen de lo implementado.

## Imágenes de reportes

- **Ubicación**: Firebase Storage, bucket `repcampusoft.firebasestorage.app`.
- **Rutas** (incluyen el uid de quien sube para validar propiedad):
  - `reports/{uid}/{reportId}/foto.jpg` — foto inicial del estudiante.
  - `reports/{uid}/{reportId}/solucion.jpg` — evidencia de la solución.
- **Compresión "equilibrada"** (`lib/features/reportes/data/comprimir_imagen.dart`):
  - Máximo 1280 px en el lado mayor, JPEG calidad 60 (~150–250 KB).
  - Si supera 250 KB: calidad 45; si aún supera 300 KB: 1024 px.
  - Nunca amplía imágenes pequeñas.
- **Firestore** guarda solo metadatos ligeros en `reports/{id}/media/{foto|solucion}`:
  `storagePath`, `downloadUrl`, `tamanoBytes`, `mimeType`, `creadoEn`.
- **Compatibilidad**: las imágenes antiguas en Base64 siguen funcionando; la UI
  intenta `base64` y, si no existe, descarga desde Storage.
- **Reglas**: `storage.rules` limita a imágenes < 2 MB y a las rutas
  `foto.jpg` / `solucion.jpg`, y exige que `request.auth.uid` coincida con el
  uid de la ruta. `firestore.rules` valida quién puede registrar cada media
  (dueño para `foto`, administrativo/mantenimiento asignado para `solucion`).

## Notificaciones push (FCM)

- **Token**: `lib/features/notificaciones/data/push_notification_service.dart`
  pide permiso, obtiene el token y lo guarda en `users/{uid}.fcmToken`
  (también escucha `onTokenRefresh`). Se registra al iniciar sesión.
- **Primer plano**: `LocalNotificacionesService` sigue mostrando la notificación
  del sistema al detectar un nuevo documento en `notifications` (solo con la app
  en primer plano, para no duplicar).
- **Segundo plano / app cerrada**: Android muestra la notificación que envía
  FCM. Al tocarla, `onMessageOpenedApp` / `getInitialMessage` navega al detalle
  del reporte o a la gestión según el rol.
- **Envío**: Cloud Function `enviarPushNotificacion`
  (`functions/index.js`, Node.js 22, región `us-central1`) se dispara con
  `onDocumentCreated('notifications/{notifId}')`.
  - `uidDestino` → token de ese usuario.
  - `destinoRol: administrativo` → administrativos + mantenimiento.
  - `destinoRol: superadministrador` → superadministradores.
  - Limpia tokens inválidos (`fcmToken = null`).
- **Canal Android**: `notificaciones_repcampusoft` (creado al arrancar la app y
  declarado como canal por defecto en `AndroidManifest.xml`).

## Paridad iOS

La app quedó configurada también para iOS con el mismo bundle
`co.edu.uts.repcampusoft`:

- **Firebase**: `ios/Runner/GoogleService-Info.plist` está incluido en la fase
  de recursos del target *Runner*, por lo que se empaqueta en el `.app`.
- **Push (APNs)**: `ios/Runner/Runner.entitlements` declara `aps-environment`
  y las configuraciones Debug/Profile/Release del target usan
  `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements`. En
  `ios/Runner/Info.plist` está `UIBackgroundModes = remote-notification`.
- **Primer plano**: `setForegroundNotificationPresentationOptions` se deja en
  `false` en iOS para que la alerta la muestre solo
  `LocalNotificacionesService` (evita duplicados). El token FCM se reintenta
  hasta 5 veces esperando a que APNs entregue el token.
- **Toque de push**: un push con `fallaId` o `tipo == sistema` abre
  *Fallas de la app*; uno con `reportId` abre el detalle o la gestión según el
  rol.
- **Google Sign-In**: `GIDClientID` y el esquema invertido del cliente iOS ya
  están en `Info.plist`; el flujo usa `google_sign_in` +
  `signInWithCredential` igual que Android.
- **Cámara/galería**: `NSCameraUsageDescription` y
  `NSPhotoLibraryUsageDescription` están declarados en `Info.plist`.

### Pasos manuales en macOS/Xcode (una sola vez)

1. Abrir `ios/Runner.xcworkspace` (o `Runner.xcodeproj`) en Xcode.
2. En *Signing & Capabilities* del target **Runner**:
   - Elegir el *Team* y activar **Automatically manage signing**.
   - Verificar que **Push Notifications** aparece habilitado (el entitlements ya
     lo declara; Xcode lo refleja al abrir el proyecto).
3. En <https://console.firebase.google.com/project/repcampusoft/settings/cloudmessaging>
   subir la **APNs Authentication Key** (`.p8`) con su Key ID y Team ID de
   Apple Developer.
4. Compilar y probar en un iPhone físico (el simulador no recibe push APNs):

   ```bash
   flutter pub get
   flutter analyze
   flutter test
   flutter run --release -d <device-id>
   ```

5. Verificar: permiso de notificaciones, recepción con la app cerrada, en
   segundo plano y en primer plano (sin duplicados), y toque de la notificación
   hacia el reporte o *Fallas de la app*.

> Generar un IPA/Archive requiere macOS con Xcode; no es posible desde Windows.

## Comandos de despliegue

```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
cd functions && npm install
firebase deploy --only functions
```

## Notas

- El bucket se creó con la API `firebasestorage.projects.defaultBucket.create`
  y se vinculó con `projects.buckets.addFirebase`.
- Si en el futuro se agregan más roles, actualizar `rolesDelDestino` en
  `functions/index.js`.
- Las notificaciones solo se envían a usuarios que hayan abierto la app con la
  versión que registra el token FCM.
