# Configuración del inicio de sesión con Google

Guía para habilitar el acceso y registro con Google en REPCAMPUSOFT.
El código ya está implementado; esta guía cubre lo que debe configurarse en
Firebase y cómo verificar el flujo de extremo a extremo.

> **Resumen:** en Android/iOS la app usa el **selector nativo de Google**
> (`google_sign_in` + `signInWithCredential`). En **web** usa
> `signInWithPopup` de Firebase Auth, porque `google_sign_in` no implementa
> `authenticate()` en el navegador. No hay Client Secret en la app. No se
> restringe el dominio del correo (decisión del proyecto); el rol
> administrativo sigue dependiendo de `admins_permitidos`.

## 1. Datos del proyecto

| Dato | Valor |
| --- | --- |
| Proyecto Firebase | `repcampusoft` |
| Paquete Android | `co.edu.uts.repcampusoft` |
| Bundle ID iOS | `co.edu.uts.repcampusoft` |
| App ID Android | `1:895201556108:android:4e370572af163deca4eda9` |
| Cliente Android (SHA-1 debug) | `895201556108-b1hoa75brnp72a17nuc8qblsscgko2ps.apps.googleusercontent.com` |
| Cliente **web** (serverClientId) | `895201556108-c9t7qn5s0e1d4gt9cr2pmnhosrfncaip.apps.googleusercontent.com` |
| Cliente iOS | `895201556108-io1s78v7a4vilr9478kp3advms7g588c.apps.googleusercontent.com` |
| Encoded App ID iOS | `app-1-895201556108-ios-df51473b18a0b84da4eda9` |
| SHA-1 registrada (debug) | `5C:4F:46:DE:1F:F2:78:24:15:37:9C:86:88:54:D1:B9:45:8F:45:8A` |
| SHA-256 registrada (debug) | `B5:B9:E6:1C:03:CE:F3:64:C5:0B:26:A0:FD:DA:15:5A:CE:B4:37:DD:4D:70:6A:98:96:9C:4B:A8:66:3E:E7:C9` |

## 2. Requisitos previos

- Acceso a la **consola de Firebase** del proyecto `repcampusoft` con rol
  *Editor* u *Owner*.
- Una cuenta de Google configurada en el teléfono. Puede ser personal
  (`@gmail.com`): la app acepta cualquier cuenta de Google.
- El APK instalado en el dispositivo (ver §5).

No se necesita acceso a Microsoft Entra, Azure ni a un tenant institucional.

## 3. Habilitar Google en Firebase

1. Entra en <https://console.firebase.google.com/project/repcampusoft/authentication/providers>.
2. En **Sign-in method**, selecciona **Google**.
3. Activa **Enable**.
4. Elige el **Project support email** y guarda con **Save**.

Firebase crea automáticamente los clientes OAuth (Android, web e iOS). El
cliente **web** es el que usa el SDK nativo de Android para pedir el ID token.
Si más adelante se quiere limitar el acceso a cuentas de un dominio concreto,
se configura en la sección *Configure* del proveedor (no es el caso de este
proyecto).

## 4. Huella SHA-1 y `google-services.json`

Google en Android verifica la firma de la app. La huella del keystore de debug
ya está registrada:

```text
5C:4F:46:DE:1F:F2:78:24:15:37:9C:86:88:54:D1:B9:45:8F:45:8A
```

> **Importante:** `android/app/build.gradle.kts` firma también las compilaciones
> `release` con la clave de debug, así que el mismo SHA-1 cubre debug y release.
> Cuando se genere un keystore propio para producción, hay que registrar su
> SHA-1 (y SHA-256) y volver a descargar `google-services.json`.

El archivo `android/app/google-services.json` **debe contener** los clientes
OAuth. Si se ve `"oauth_client": []`, el archivo está desactualizado y el login
nativo fallará con `GoogleSignInExceptionCode.clientConfigurationError`:

```powershell
# Descarga la configuración vigente (sobrescribe) y verifica los clientes
Remove-Item android\app\google-services.json
firebase apps:sdkconfig ANDROID 1:895201556108:android:4e370572af163deca4eda9 `
  --project repcampusoft --out android/app/google-services.json
```

Debe haber un `client_type: 1` (Android, con el SHA-1) y un `client_type: 3`
(web). El SDK lee el cliente web de ese archivo; la app no lo escribe a mano.

Para consultar la huella del keystore de debug (en Windows el `keytool` de
Java 26 falla con locale en español; fuerza el idioma):

```powershell
$env:JAVA_TOOL_OPTIONS="-Duser.language=en -Duser.country=US"
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

## 5. Compilar e instalar

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

El APK queda en `build\app\outputs\flutter-apk\app-release.apk` (unos 55 MB).
No se necesitan `--dart-define` para Google.

Instalación por USB:

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

También se puede copiar el APK al teléfono y abrirlo desde el explorador de
archivos (hay que permitir «instalar apps desconocidas»).

## 6. Flujo esperado en la app

1. **Login:** el botón **Continuar con Google** abre la hoja nativa de cuentas
   de Google (Credential Manager en Android). No se abre Chrome.
2. **Cualquier cuenta:** se acepta una cuenta personal o institucional; no hay
   validación de dominio.
3. **Primer acceso:** si no existe `users/{uid}`, la app pasa a
   *Completa tu registro* con el nombre prellenado desde Google. El usuario
   elige el rol persona/administrativo en la UI.
4. **Perfil creado:** se guarda `users/{uid}` con el correo de Google. En
   Firebase Console → Authentication el proveedor aparece como `google.com`.
5. **Correo ya registrado con contraseña:** Firebase devuelve
   `account-exists-with-different-credential` y la app pide iniciar sesión con
   la contraseña (no se vinculan cuentas automáticamente).
6. **Cancelación:** cerrar la hoja de cuentas devuelve a Login con
   «Inicio de sesión cancelado.» y sin sesión abierta.
7. **Rol administrativo:** solo se obtiene si el correo está en
   `admins_permitidos`; cualquier otra cuenta queda como `persona` (la regla de
   Firestore lo garantiza).

## 7. Verificación actual (31/10/2026)

- ✅ Proveedor **Google** habilitado en Firebase.
- ✅ Configuración nativa: `google_sign_in` 7.2.0 + `signInWithCredential` con
  el ID token; `google-services.json` regenerado con los clientes OAuth.
- ✅ `flutter analyze`: sin issues.
- ✅ `flutter test`: `+155 ~3`, solo los 2 fallos preexistentes de
  `test/features/perfil/presentation/admin_profile_screen_test.dart` (la prueba
  inestable de fallas por orden de `creadoEn` pasó en la última ejecución).
- ✅ Reglas desplegadas con `firebase deploy --only firestore:rules`.
- ✅ Verificado en el teléfono `V2322` (Android 15) con el APK de release: al
  pulsar **Continuar con Google** aparece la hoja nativa **«Elegir una cuenta»**
  con las cuentas del dispositivo, sin abrir Chrome.
- ⏳ Pendiente: seleccionar una cuenta nueva y completar el registro en el
  teléfono (requiere credenciales del usuario), y confirmar la cancelación.

> **Historial:** con el flujo anterior (`signInWithProvider`) Chrome mostraba
> «Unable to process request due to missing initial state» al volver del
> consentimiento, porque el handler web de Firebase no podía leer el estado en
> la pestaña. El flujo nativo elimina esa página y el paso por el navegador.

## 8. Errores frecuentes

| Síntoma / código | Causa probable | Solución |
| --- | --- | --- |
| `operation-not-allowed` | Google no está habilitado en Firebase | Completa el §3 |
| `clientConfigurationError` | `google-services.json` sin cliente web/Android o SHA-1 no registrada | Regenera el archivo (§4) y recompila |
| El selector de cuentas no aparece | Falta una cuenta de Google en el teléfono o Google Play Services está desactualizado | Agrega una cuenta en Ajustes y actualiza Play Services |
| `account-exists-with-different-credential` | Ya existe una cuenta con contraseña para ese correo | Inicia sesión con la contraseña |
| `web-context-canceled` | El usuario cerró la hoja de cuentas | Es esperado: se muestra «Inicio de sesión cancelado.» |
| `google-sign-in-failed` | Falló el selector nativo o no se recibió el ID token | Reintenta; revisa la configuración del §4 |
| `network-request-failed` | Sin internet o DNS bloqueado | Revisa la conexión del dispositivo |

## 8.1. Inicio de sesión en web

La app también se ejecuta en navegador (`flutter build web --release`). En web:

- **Correo y contraseña** funciona con el mismo proveedor de Firebase
  Authentication. La `apiKey` web ya está en `lib/firebase_options.dart`.
- **Google** usa `FirebaseAuth.signInWithPopup(GoogleAuthProvider())` con
  `prompt=select_account`. No usa `google_sign_in`, porque en web ese paquete
  no implementa `authenticate()`.
- No se necesita Client ID en Dart ni etiqueta `<meta>` en `web/index.html`:
  Firebase usa el cliente web del proveedor Google.
- Si el navegador bloquea la ventana emergente, la app muestra un mensaje para
  permitir las ventanas emergentes.

Para que el popup funcione, en **Firebase Authentication → Settings →
Authorized domains** deben estar el dominio de producción y, en desarrollo,
`localhost`. En el cliente OAuth web también deben estar los **Authorized
JavaScript origins** correspondientes (`http://localhost:<puerto>` y el dominio
real).

Errores frecuentes en web:

| Código | Causa | Solución |
| --- | --- | --- |
| `popup-blocked` | El navegador bloqueó la ventana | Permite las ventanas emergentes para el sitio |
| `unauthorized-domain` | El dominio no está en Authorized domains | Agrégalo en Firebase Authentication |
| `invalid-api-key` | `apiKey` web incorrecta | Revisa `lib/firebase_options.dart` |

## 9. Seguridad y decisiones

- **Sin restricción de dominio:** el proyecto acepta cualquier cuenta de
  Google (decisión explícita para poder probar con Gmail). El control de
  privilegios no depende del dominio.
- **Rol administrativo:** `users/{uid}.rol == 'administrativo'` solo si el
  correo existe en `admins_permitidos`. Las reglas lo validan en `create` y en
  `update`.
- **`emailVerified` de Google:** Firebase puede dejar ese campo en `false` para
  el proveedor. La app considera la identidad confiable porque Google ya validó
  el correo; `correoConfiable()` en `firestore.rules` incluye la excepción
  `sign_in_provider == 'google.com'`.
- **Token:** la app solo envía el **ID token** de Google a Firebase; no se
  guarda ni se transmite a un backend propio.
- **Sin vinculación automática:** una cuenta con contraseña y una cuenta de
  Google con el mismo correo no se fusionan desde la app.
- **Configuración en la app:** el cliente web se lee de
  `google-services.json`; no hay secretos embebidos.

## 10. Archivos relacionados

- `lib/features/auth/data/firebase_auth_repository.dart`: implementación de
  `iniciarSesionConGoogle()` con `google_sign_in` y `signInWithCredential`.
- `lib/features/auth/data/firebase_auth_messages.dart`: traducción de
  cancelación y `google-sign-in-failed`.
- `lib/core/routes/session_provider.dart`: gate de sesión y creación del perfil
  pendiente.
- `lib/features/auth/presentation/auth_widgets.dart`: `GoogleSignInButton`.
- `firestore.rules`: `correoConfiable()` con la excepción de `google.com`.
- `android/app/google-services.json`: clientes OAuth Android/web.
- `ios/Runner/Info.plist`: `GIDClientID` y esquema invertido del cliente iOS.
- `test/features/auth/presentation/google_sign_in_button_test.dart`: pruebas
  del botón.
