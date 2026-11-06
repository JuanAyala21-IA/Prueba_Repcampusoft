# Superadministrador de REPCAMPUSOFT

REPCAMPUSOFT tiene un único rol con control total sobre las cuentas: el
**superadministrador**. Este documento explica cómo aprovisionarlo y qué puede
hacer dentro de la app.

## Responsabilidades

- Crear cuentas de **estudiante** (`persona`), **administrativo** y
  **mantenimiento** desde el panel de gestión de usuarios.
- Deshabilitar (baja lógica) esas cuentas.
- Consultar todos los reportes de daños en modo **solo lectura**, incluido
  quién atendió/solucionó cada reporte.
- Revisar el buzón de **fallas de la app** (solo él recibe esas
  notificaciones).

Los roles `administrativo` y `mantenimiento` no se autorregistran: únicamente
los crea el superadministrador. Los estudiantes sí pueden crear su cuenta desde
la pantalla de registro.

## Aprovisionamiento manual (una sola vez)

El superadministrador no se crea desde la interfaz. Se siembra su correo en
Firestore y luego se registra normalmente en la app:

1. En **Firebase Console → Authentication**, crea la cuenta del
   superadministrador con correo y contraseña, o deja que la persona se
   registre desde la app.
2. En **Firestore Database**, crea la colección `super_admins_permitidos`.
3. Crea un documento cuyo **ID sea el correo en minúsculas** de la persona
   (por ejemplo `superadmin@uts.edu.co`). El contenido del documento no se usa;
   puede quedar vacío o con un campo descriptivo.
4. La persona se registra o inicia sesión en la app y confirma el correo de
   verificación. El gate de sesión crea `users/{uid}` con
   `rol: "superadministrador"` y `activo: true`.
5. Verifica en Firestore que `users/{uid}.rol` sea `superadministrador`.
6. **Opcional pero recomendado:** elimina el documento de
   `super_admins_permitidos` una vez creado el perfil. El perfil existente
   conserva el rol; la lista blanca solo sirve para el primer aprovisionamiento.

> La colección `super_admins_permitidos` no es legible ni escribible desde la
> app: solo la usan las reglas de Firestore.

## Crear cuentas desde la app

1. Inicia sesión como superadministrador.
2. En el dashboard entra a **Gestión de usuarios → Crear usuario**.
3. Completa nombre, correo institucional, contraseña inicial y rol
   (Estudiante, Administrativo o Mantenimiento).
4. La app crea la cuenta en Firebase Auth con una instancia secundaria, envía
   el correo de verificación y escribe `users/{uid}` con `activo: true`.
5. La persona debe confirmar su correo antes de entrar al sistema.

## Deshabilitar cuentas

La app no puede borrar cuentas de Firebase Auth ajenas sin Admin SDK/Cloud
Functions (plan Blaze). Por eso la eliminación es **lógica**:

- Se marca `users/{uid}.activo = false` y `eliminadoEn`.
- El gate de sesión muestra la pantalla **Cuenta deshabilitada**.
- Las reglas de Firestore rechazan las operaciones de cuentas inactivas.

Para eliminar definitivamente la cuenta de Authentication hay que hacerlo desde
Firebase Console o con el Admin SDK.

## Búsqueda de usuarios

El panel **Gestión de usuarios** incluye un buscador por correo. El filtro se
aplica en memoria sobre la lista ya cargada (sin distinguir mayúsculas ni
minúsculas), así que no genera consultas adicionales a Firestore.

## Asignación exclusiva de reportes (mantenimiento)

- Cuando un reporte no tiene encargado, cualquier usuario con rol
  `mantenimiento` puede abrirlo y pulsar **Tomar reporte**.
- Al tomarlo se guardan `asignadoA`, `asignadoNombre` y `asignadoEn` en
  `reports/{id}`. Desde ese momento **solo esa persona** puede cambiar su
  estado; a los demás encargados de mantenimiento el reporte ya no les aparece
  en la lista.
- El `administrativo` conserva la supervisión: puede ver y gestionar cualquier
  reporte, esté o no asignado.
- La toma se hace con una transacción: si dos encargados intentan tomarlo a la
  vez, solo uno gana y el otro recibe el aviso "Otro encargado ya tomó este
  reporte".
- El personal de mantenimiento tiene una sección propia, **Mis reportes
  asignados**, con los reportes que tomó y todavía debe resolver. Así no se
  pierden entre todos los daños reportados.

## Evidencia de la solución

Al elegir el estado **Solucionado**, el encargado **debe** adjuntar una foto
desde la galería: sin evidencia el botón de guardar queda deshabilitado y el
repositorio/reglas rechazan la operación. La imagen se comprime (~500 KB JPEG),
se guarda en `reports/{id}/media/solucion` (Base64, igual que la foto inicial)
y el reporte queda con `tieneEvidenciaSolucion: true`. La evidencia se muestra
en el detalle del reporte para el autor, el administrativo y el
superadministrador.

Todas las imágenes de evidencia (la foto inicial y la de la solución) se pueden
tocar para abrirlas a pantalla completa, con pellizco y doble toque para hacer
zoom. El visor compartido vive en `lib/shared/widgets/image_preview.dart`.

## Reglas de Firestore

Las reglas de `firestore.rules` aplican estos criterios:

- `isActivo()` exige un perfil `users/{uid}` con `activo != false`.
- `canManageReports()` agrupa a `administrativo` y `mantenimiento`.
- Solo `isSuperadministrador()` puede leer `fallas_app` y crear/deshabilitar
  cuentas ajenas.
- El superadministrador puede leer todos los reportes, pero no actualizarlos:
  la transición de estados está reservada a `administrativo` y al encargado de
  mantenimiento asignado.
- `mantenimiento` solo puede tomar reportes sin asignar y, una vez tomados,
  solo él puede cambiar su estado.
- Al pasar un reporte a `Solucionado` se guardan `encargadoUid` y
  `encargadoNombre`; cada cambio de estado guarda `adminUid` y `adminNombre`
  en el historial.
- `media/solucion` solo se puede crear si el reporte queda en `Solucionado`
  con `tieneEvidenciaSolucion: true`.
- Solucionar exige que la transacción cree `media/solucion`; sin evidencia la
  actualización del reporte se rechaza.

## Dónde está implementado

| Pieza | Archivo |
| --- | --- |
| Roles y roles gestionables | `lib/features/auth/domain/rol_enum.dart` |
| Perfil con `activo` (baja lógica) | `lib/features/auth/domain/usuario.dart` |
| Gate de sesión y cuenta bloqueada | `lib/core/routes/session_provider.dart` |
| Pantalla de cuenta deshabilitada | `lib/features/auth/presentation/blocked_account_screen.dart` |
| Rutas y guard por rol | `lib/core/routes/app_router.dart` |
| Repositorio de cuentas (instancia secundaria de Auth) | `lib/features/usuarios/data/firebase_usuario_repository.dart` |
| Panel de usuarios | `lib/features/usuarios/presentation/manage_users_screen.dart` |
| Buscador por correo | `lib/features/usuarios/presentation/manage_users_screen.dart` |
| Formulario de creación | `lib/features/usuarios/presentation/create_user_screen.dart` |
| Accesos por rol en el dashboard | `lib/features/home/presentation/admin_home_screen.dart` |
| Accesos por rol en el perfil | `lib/features/perfil/presentation/admin_profile_screen.dart` |
| Buzones de notificación por rol | `lib/features/notificaciones/data/providers/notificacion_providers.dart` |
| Registro de encargado en reportes | `lib/features/reportes/data/firebase_reporte_repository.dart` |
| Asignación exclusiva y evidencia | `lib/features/reportes/data/firebase_reporte_repository.dart` |
| Toma de reporte y evidencia de solución | `lib/features/admin/presentation/manage_report_screen.dart` |
| Mis reportes asignados (mantenimiento) | `lib/features/admin/presentation/assigned_reports_screen.dart` |
| Filtro de reportes para mantenimiento | `lib/features/admin/presentation/reported_damages_screen.dart` |
| Consulta de reportes en solo lectura | `lib/features/admin/presentation/manage_report_screen.dart` |
| Reglas de seguridad | `firestore.rules` |

Pruebas: `test/core/routes/app_router_guard_test.dart`,
`test/features/usuarios/presentation/manage_users_screen_test.dart`,
`test/features/usuarios/presentation/create_user_screen_test.dart` y
`test/sesion_controller_test.dart`.
