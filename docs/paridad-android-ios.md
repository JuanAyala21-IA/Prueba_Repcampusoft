# Paridad Android / iOS

La app es Flutter, por lo que toda la lógica y la interfaz son compartidas. Esta
lista resume la configuración nativa y las verificaciones de cada plataforma.

## Configuración común

| Elemento | Android | iOS |
|---|---|---|
| Identificador | `co.edu.uts.repcampusoft` | `co.edu.uts.repcampusoft` |
| Nombre visible | REPCAMPUSOFT | REPCAMPUSOFT |
| Firebase | `google-services.json` | `GoogleService-Info.plist` |
| Autenticación | Firebase Auth | Firebase Auth |
| Google Sign-In | `google_sign_in` | `google_sign_in` + URL scheme |
| Base de datos | Cloud Firestore | Cloud Firestore |
| Fotos | `image_picker` + compresión | `image_picker` + compresión |
| Almacenamiento | Firebase Storage | Firebase Storage |
| Notificaciones | FCM + locales | FCM/APNs + locales |
| Exportación CSV | Diálogo SAF | Selector de documentos |
| Catálogos dinámicos | Firestore | Firestore |
| Filtros y dashboard | Dart/Flutter | Dart/Flutter |

## Permisos

- **Android:** `INTERNET`, `POST_NOTIFICATIONS`.
- **iOS:** `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`,
  `UIBackgroundModes = remote-notification`.
- **iOS push:** `Runner.entitlements` con `aps-environment`; la llave APNs se
  configura en Firebase Console.

## Mínimos

- **Android:** el `minSdk` de Flutter.
- **iOS:** 15.0.

## Verificación

| Prueba | Android | iOS |
|---|---|---|
| `flutter analyze` | ✅ | ✅ (mismo código) |
| `flutter test` | ✅ 269 pruebas | ✅ 269 pruebas |
| Build release | ✅ APK 60.4 MB | ✅ workflow `iOS-ipa-build` |
| Artefacto | `dist/REPCAMPUSOFT-1.0.0.apk` | `REPCAMPUSOFT-ipa-sin-firma` |

### Evidencia iOS

- Run: <https://github.com/JuanAyala21-IA/Prueba_Repcampusoft/actions/runs/42696505412>
- `pod install`: 437.4 s
- Xcode build: 964.9 s
- `Runner.app`: 58.8 MB
- IPA sin firma: 19.301.307 bytes, 369 entradas
- El IPA contiene `Payload/Runner.app`, `GoogleService-Info.plist` y los
  frameworks de Firebase.

## Diferencias esperadas

- **Push**: en iOS requiere APNs Auth Key en Firebase y firma con Apple
  Developer. En Android usa FCM directamente.
- **Simulador iOS**: no tiene cámara y no recibe push. La galería se puede probar
  arrastrando imágenes al simulador.
- **Firma**: el IPA del workflow es sin firma; para instalarlo en un iPhone hay
  que firmarlo con una cuenta de Apple o usar TestFlight.
- **APK del repositorio**: es la compilación release de Android lista para
  instalar.
