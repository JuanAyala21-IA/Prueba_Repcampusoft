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
- **Lectura en la app** (`lib/features/reportes/data/media_reporte_loader.dart`):
  1. `base64` si existe (documentos antiguos).
  2. `downloadUrl` con token, descargada por HTTP (`descargarDesdeUrl`). Es la
     vía principal porque no depende de que el SDK de Storage resuelva
     metadatos o adjunte el token de Firebase Auth; si eso falla, la foto se
     veía vacía con el ícono de imagen.
  3. `storagePath` con el SDK de Storage como respaldo.
  Si hay imagen registrada pero ninguna vía funciona, la pantalla muestra
  «No se pudo cargar la imagen» con un botón **Reintentar**.
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

> El proyecto compila con **CocoaPods**. Aunque varios plugins soportan Swift
> Package Manager, no se puede usar SPM con las versiones actuales de Firebase:
> `firebase_auth` 6.7.0 fija `firebase-ios-sdk` 12.19.0 y `firebase_core`,
> `firebase_storage` y `firebase_messaging` fijan 12.19.3. SPM exige versiones
> exactas y falla al resolver (`Dependencies could not be resolved because
> 'firebase_auth-6.7.0' depends on 'firebase-ios-sdk' 12.19.0 and
> 'firebase_storage-13.6.1' depends on 'firebase-ios-sdk' 12.19.3`).
> Con CocoaPods todos los plugins toman la versión de `firebase_core`
> (12.19.3) y la resolución es correcta. Además
> `flutter_local_notifications` solo se integra con CocoaPods.
>
> Instala CocoaPods (`brew install cocoapods`): Flutter generará `ios/Podfile`
> y `ios/Runner.xcworkspace` automáticamente al preparar la compilación.

1. Desactivar SPM y preparar las dependencias nativas antes de abrir Xcode
   (genera Podfile, Pods y el paquete Swift vacío):

   ```bash
   flutter config --no-enable-swift-package-manager
   flutter pub get
   flutter build ios --debug --no-codesign
   ```

2. Abrir `ios/Runner.xcworkspace` en Xcode (se crea al ejecutar `pod install`;
   no abras solo el `.xcodeproj`).
3. En *Signing & Capabilities* del target **Runner**:
   - Elegir el *Team* y activar **Automatically manage signing**.
   - Verificar que **Push Notifications** aparece habilitado (el entitlements ya
     lo declara; Xcode lo refleja al abrir el proyecto).
4. En <https://console.firebase.google.com/project/repcampusoft/settings/cloudmessaging>
   subir la **APNs Authentication Key** (`.p8`) con su Key ID y Team ID de
   Apple Developer.
5. Compilar y probar en un iPhone físico (el simulador no recibe push APNs):

   ```bash
   flutter run --release -d <device-id>
   ```

6. Verificar: permiso de notificaciones, recepción con la app cerrada, en
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
