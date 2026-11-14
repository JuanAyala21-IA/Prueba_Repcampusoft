# Configuración del correo de autenticación

Guía para que los correos de Firebase Authentication (verificación de correo y
restablecimiento de contraseña) salgan desde un dominio propio de la UTS y no
caigan en la carpeta de spam.

> **Resumen:** los correos de autenticación se envían con el método nativo de
> Firebase (`DEFAULT`), no con un servidor SMTP externo. Para usar el dominio
> propio solo hay que publicar unos registros DNS y verificar el dominio; no se
> cambia código de la app.

## 1. Estado actual (14/11/2026)

| Dato | Valor |
| --- | --- |
| Proyecto Firebase | `repcampusoft` (número `895201556108`) |
| Remitente por defecto | `noreply@repcampusoft.firebaseapp.com` |
| Nombre visible | `REPCAMPUSOFT` |
| Nombre en el texto (`%APP_NAME%`) | `project-895201556108` (marca OAuth, pendiente de cambiar) |
| Método de envío | `DEFAULT` (Firebase) |
| Idioma por defecto | `es` |
| Dominio personalizado solicitado | `auth.repcampusoft.uts.edu.co` |
| Estado del dominio | `IN_PROGRESS` (faltan los registros DNS) |
| Acción URL (`callbackUri`) | `https://repcampusoft.firebaseapp.com/__/auth/action` |
| Dominios autorizados | `localhost`, `repcampusoft.firebaseapp.com`, `repcampusoft.web.app`, `auth.repcampusoft.uts.edu.co` |

Las cuatro plantillas ya están en español (plantillas localizadas de Firebase) y
tienen `senderDisplayName = REPCAMPUSOFT` y `replyTo = noreply`.

### Nombre que aparece en los correos (`%APP_NAME%`)

El texto de las plantillas usa `%APP_NAME%`. Ese valor **no** sale del nombre del
proyecto de Firebase ni del nombre visible del remitente: Firebase usa el nombre
de la **marca OAuth** del proyecto. Como la marca se creó automáticamente al
registrar la app Android, se llama `project-895201556108`, y por eso el asunto
llega como «Cambia la contraseña de project-895201556108».

Para corregirlo (una sola vez, desde la consola):

1. Entra a <https://console.cloud.google.com/auth/branding?project=repcampusoft>.
2. En **App information → App name** escribe `REPCAMPUSOFT`.
3. Guarda. Si la consola pide **Verify branding** y luego **Publish branding**,
   completa ese paso.
4. Vuelve a pedir un restablecimiento de contraseña y confirma que el asunto dice
   «Cambia la contraseña de REPCAMPUSOFT».

Ruta alternativa: Firebase Console → **Project settings** → **General** →
**Public-facing name**.

No existe una API pública para cambiar ese nombre (la antigua API de marcas de
IAP quedó restringida y exige una organización), así que este ajuste es manual.

## 2. Registros DNS que debe crear TI de la UTS

El dominio `auth.repcampusoft.uts.edu.co` es un subdominio dedicado solo a
correos de autenticación, para no tocar el SPF del dominio principal
`uts.edu.co`.

Todos los registros se crean **sobre `auth.repcampusoft.uts.edu.co`**. En la
mayoría de paneles DNS el campo «Nombre/Host» debe llevar solo la parte
izquierda (sin repetir el dominio).

| Tipo | Nombre (host) | Valor | Obligatorio |
| --- | --- | --- | --- |
| TXT | `@` (o el subdominio completo) | `v=spf1 include:_spf.firebasemail.com ~all` | Sí |
| TXT | `@` (o el subdominio completo) | `firebase=repcampusoft` | Sí |
| CNAME | `firebase1._domainkey` | `mail-auth-repcampusoft-uts-edu-co.dkim1._domainkey.firebasemail.com.` | Sí |
| CNAME | `firebase2._domainkey` | `mail-auth-repcampusoft-uts-edu-co.dkim2._domainkey.firebasemail.com.` | Sí |
| TXT | `_dmarc` | `v=DMARC1; p=none; rua=mailto:<buzón-real>` | Recomendado |

Notas:

- Solo puede existir **un** registro `v=spf1` por dominio. Si el subdominio ya
  tuviera uno, hay que fusionar los `include:` en una sola línea.
- Si se usa Cloudflare, los CNAME deben quedar en modo **DNS only** (nube gris),
  no proxificados.
- El registro `firebase=repcampusoft` es el que resuelve el error
  `Firebase namespace check failed: couldn't find expected namespace`.
- El `_dmarc` se puede dejar para después, pero ayuda a la entregabilidad.
- La verificación puede tardar entre 24 y 48 horas.

## 3. Verificar y aplicar el dominio

Cuando TI confirme que los registros están publicados:

1. Entra a <https://console.firebase.google.com/project/repcampusoft/authentication/emails>.
2. En cualquier plantilla, abre **Personalizar dominio** y pulsa **Verificar**.
3. Cuando aparezca «Verificación completa», pulsa **Aplicar dominio
   personalizado**.

También se puede hacer por API con un token de Firebase CLI:

```powershell
$cfg = Get-Content "$env:USERPROFILE\.config\configstore\firebase-tools.json" -Raw | ConvertFrom-Json
$body = @{
  client_id     = '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com'
  client_secret = 'j9iVZfS8kkCEFUPaAeJV0sAi'
  refresh_token = $cfg.tokens.refresh_token
  grant_type    = 'refresh_token'
}
$token = Invoke-RestMethod -Method Post -Uri 'https://oauth2.googleapis.com/token' `
  -Body $body -ContentType 'application/x-www-form-urlencoded'
$headers = @{ Authorization = "Bearer $($token.access_token)"; 'Content-Type' = 'application/json' }

# Verificar
Invoke-RestMethod -Method Post -Headers $headers `
  -Uri 'https://identitytoolkit.googleapis.com/admin/v2/projects/repcampusoft/domain:verify' `
  -Body (@{ domain = 'auth.repcampusoft.uts.edu.co'; action = 'VERIFY' } | ConvertTo-Json)

# Aplicar (solo cuando la verificación haya terminado)
Invoke-RestMethod -Method Post -Headers $headers `
  -Uri 'https://identitytoolkit.googleapis.com/admin/v2/projects/repcampusoft/domain:verify' `
  -Body (@{ domain = 'auth.repcampusoft.uts.edu.co'; action = 'APPLY' } | ConvertTo-Json)
```

Para consultar el estado:

```powershell
Invoke-RestMethod -Headers $headers `
  -Uri 'https://identitytoolkit.googleapis.com/admin/v2/projects/repcampusoft/config' |
  Select-Object -ExpandProperty notification |
  Select-Object -ExpandProperty sendEmail |
  Select-Object -ExpandProperty dnsInfo
```

Estados posibles de `customDomainState`: `NOT_STARTED`, `IN_PROGRESS`,
`SUCCEEDED`, `FAILED`.

## 4. Prueba de extremo a extremo

1. Abre la app e inicia sesión con una cuenta de prueba.
2. Pide **restablecer contraseña** o **verificar correo**.
3. Comprueba que el remitente sea `noreply@auth.repcampusoft.uts.edu.co` y el
   nombre visible `REPCAMPUSOFT`.
4. Revisa la bandeja de entrada, no solo spam. Si cae en spam, revisa que SPF y
   DKIM estén publicados y que DMARC no esté en `p=reject`.

## 5. Limitación conocida: edición de plantillas por API

Firebase bloqueó temporalmente la edición del **texto** de las plantillas y del
`callbackUri` (error `EMAIL_TEMPLATE_UPDATE_NOT_ALLOWED`). Solo se pueden
cambiar por API `senderDisplayName`, `replyTo`, `senderLocalPart` y
`defaultLocale`. Por eso las plantillas usan el texto estándar de Firebase
localizado al español.

Si se necesita un texto propio, hay dos caminos:

- Abrir un caso con el soporte de Firebase para que ellos apliquen el cambio.
- Implementar un flujo propio: generar el enlace de acción con Firebase Admin
  SDK y enviar el correo desde un backend con SMTP propio.

## 6. Mantenimiento

- Cambiar el nombre visible o el `replyTo`: consola de Firebase, pestaña
  **Plantillas**, o la API con `updateMask=notification.sendEmail.*`.
- Cambiar el idioma: `notification.defaultLocale` (`es`).
- El `replyTo` es `noreply` porque todavía no hay un buzón real. Cuando exista
  (por ejemplo `soporte@uts.edu.co`), actualizarlo en las cuatro plantillas.
- El nombre que sale dentro del texto (`%APP_NAME%`) se cambia en la marca OAuth
  (Google Auth Platform → Branding → App name), no en las plantillas.
- Este cambio no afecta las notificaciones push de los reportes: esas viajan por
  FCM, no por correo.

## 7. Archivos relacionados

- `lib/features/auth/data/firebase_auth_repository.dart`: envío de verificación
  y restablecimiento con `sendEmailVerification` y `sendPasswordResetEmail`.
- `docs/configuracion_google.md`: configuración del inicio de sesión con Google.
- `functions/index.js`: función de notificaciones push (no envía correo).
