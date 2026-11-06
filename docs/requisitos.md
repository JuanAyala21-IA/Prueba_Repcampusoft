# Documento de Especificación de Requisitos de Software (ERS)
## Proyecto: REPCAMPUSOFT (Fase 1: Requerimientos)

---

## 1. Descripción del Problema y Alcance

### 1.1. Contexto y Problemática
En las **Unidades Tecnológicas de Santander (UTS)**, el reporte y seguimiento de incidencias o daños en la infraestructura física (aulas, laboratorios, pasillos, mobiliario, sistemas eléctricos, sanitarios y áreas comunes) se realiza tradicionalmente de forma verbal, mediante notas físicas o correos dispersos. Esta falta de estandarización ocasiona:
- Ausencia de un canal único, estructurado y accesible para que los estudiantes y la comunidad universitaria informen averías.
- Pérdida de trazabilidad sobre el estado de atención y resolución de cada daño.
- Reportes duplicados y falta de evidencia gráfica/fotográfica oportuna.
- Falta de retroalimentación para el usuario que reporta, quien desconoce si su solicitud fue recibida, procesada o solucionada.
- Dificultad para que el personal de mantenimiento categorice, priorice y asigne responsables con base en datos centralizados.

### 1.2. Propósito y Alcance del Producto
**REPCAMPUSOFT** es una aplicación móvil multiplataforma (Android e iOS) construida con **Flutter** y respaldada por los servicios de **Firebase (Authentication y Cloud Firestore activos; Cloud Storage y Firebase Cloud Messaging previstos para la migración a plan Blaze)**.

El alcance del sistema abarca:
1. **Módulo de Autenticación y Perfiles**: Registro e inicio de sesión con correo institucional y asignación controlada de roles (Estudiante/Persona y Administrativo).
2. **Módulo de Reporte de Daños (Estudiantes)**: Captura de incidencias con categorización, ubicación precisa adaptada al tipo de espacio (aula, laboratorio, sala de cómputo, baño, pasillo, oficina, auditorio, biblioteca, cafetería, escaleras, ascensor, zona exterior, parqueadero u otro), descripción detallada y captura/adjunto de evidencia fotográfica.
3. **Módulo de Consulta y Seguimiento (Estudiantes)**: Historial de reportes propios con visualización del estado actual y detalle de la información reportada.
4. **Módulo de Gestión Operativa (Administrativo / Mantenimiento)**: Panel de control con búsqueda textual, filtros por estado y ubicación, visualización de evidencias, cambio de estados en tiempo real e ingreso de observaciones.
5. **Módulo de Notificaciones y Comunicación**: Historial de notificaciones en Firestore (marcado de leídas/no leídas, badge) entregado dentro de la app mediante listeners en tiempo real; el push (FCM) se incorpora en la migración a plan Blaze.

---

## 2. Actores del Sistema

| Actor | Descripción y Responsabilidades |
| :--- | :--- |
| **Persona / Estudiante** | Usuario perteneciente a la comunidad de las UTS (estudiantes, docentes o usuarios generales). Tiene permisos para registrarse, consultar información general, crear reportes de daños con fotografías, consultar el historial y estado de sus propios reportes, recibir notificaciones y gestionar su perfil. |
| **Administrativo (Mantenimiento / Infraestructura)** | Funcionario o personal operativo del área de infraestructura y mantenimiento. Requiere que su correo institucional esté registrado en la lista blanca (`admins_permitidos`). Posee permisos para ver todos los reportes del campus, buscar, filtrar por ubicación y estado, inspeccionar evidencias, actualizar estados de atención, emitir avisos y recibir notificaciones operativas. |
| **Sistema / Backend (Firebase)** | Componente automatizado que gestiona la autenticación, almacena datos en Firestore (incluida la evidencia en `reports/{id}/media/foto`), persiste notificaciones con historial, aplica reglas de seguridad de acceso y, en la migración a Blaze, aloja imágenes en Storage y despacha push (FCM). |

---

## 3. Requerimientos Funcionales (RF) con Prioridad MoSCoW

*Prioridades según metodología MoSCoW: **Must Have** (Indispensable), **Should Have** (Deseable de alta prioridad), **Could Have** (Opcional si hay tiempo), **Won't Have** (Fuera de alcance en esta fase).*

| Código | Requerimiento Funcional | Prioridad | Pantallas Asociadas |
| :--- | :--- | :---: | :--- |
| **RF-01** | **Autenticación con Correo Institucional y Contraseña**: El sistema debe permitir iniciar sesión validando las credenciales contra Firebase Authentication, verificando que pertenezca a un correo válido de las UTS. | **Must Have** | `1.png` (Pantalla 1: Iniciar Sesión) |
| **RF-02** | **Consulta de Información Institucional ("¿Qué es Repcampusoft?")**: El sistema debe permitir a cualquier usuario consultar una pantalla informativa con la descripción, propósito y alcance de la plataforma. | **Must Have** | `2.png` (Pantalla 2: Información) |
| **RF-03** | **Registro de Nuevos Usuarios con Verificación de Correo**: El sistema debe permitir el autoregistro ingresando correo institucional, contraseña, confirmación de contraseña, cargo y selección inicial de rol pretendido. Tras crear la cuenta envía un correo de verificación y NO crea el perfil `users/{uid}` ni concede rol alguno hasta que el correo esté verificado (`emailVerified == true`), evitando suplantación de correos ajenos. | **Must Have** | `3.png` (Pantalla 3: Registro) |
| **RF-04** | **Validación y Asignación Segura de Rol Administrativo**: Solo se asigna el rol `administrativo` si el correo (normalizado a minúsculas) está **verificado** y existe en la colección `admins_permitidos`. La pertenencia a la lista la comprueba el servidor con `exists()` en la regla de creación de `users/{uid}` (exige `request.auth.token.email_verified == true`); si el correo no está en la lista, el rol queda obligatoriamente en `persona`. El correo se normaliza a minúsculas en ambos lados y la colección `admins_permitidos` no tiene escritura desde la app. | **Must Have** | `1.png`, `3.png` |
| **RF-05** | **Dashboard Principal para Estudiante**: La app debe presentar un menú principal con accesos directos a: Perfil, Reportar daños, Tus reportes, Notificaciones y Cerrar sesión. | **Must Have** | `4.png` (Pantalla 4: Inicio Estudiante) |
| **RF-06** | **Dashboard Principal para Administrativo**: La app debe presentar un menú principal con accesos directos a: Perfil, Daño y gestión de reportes, Notificaciones y Cerrar sesión. | **Must Have** | `5.png` (Pantalla 5: Inicio Administrativo) |
| **RF-07** | **Visualización de Perfil - Estudiante**: El sistema debe mostrar el nombre completo, rol ("Persona - Estudiante"), correo institucional, teléfono de contacto y accesos a configuración de cuenta. | **Must Have** | `6.png` (Pantalla 6: Perfil Estudiante) |
| **RF-08** | **Visualización de Perfil - Administrativo**: El sistema debe mostrar la dependencia ("Área de Mantenimiento"), cargo, nombre, correo institucional, teléfono y opciones de configuración de cuenta y cierre de sesión. | **Must Have** | `7.png` (Pantalla 7: Perfil Admin) |
| **RF-09** | **Edición de Información de Perfil**: El sistema debe permitir al usuario (estudiante o administrativo) actualizar su número de teléfono y nombre desde su perfil. *(Hueco de diseño cubierto)* — **NO implementado — placeholder sin lógica (botón deshabilitado)**. | **Should Have** | `6.png`, `7.png` (Modal / Pantalla Edición) |
| **RF-10** | **Recuperación y Cambio de Contraseña**: El sistema debe permitir solicitar un enlace de restablecimiento de contraseña vía correo electrónico en el Login, y cambiar la contraseña actual desde la vista de Perfil. *(Hueco de diseño cubierto)* — **PARCIALMENTE implementado — el envío del correo de recuperación funciona y está ruteado; falta 'cambiar contraseña desde el perfil', que no se incluye en esta entrega**. | **Should Have** | `1.png`, `6.png`, `7.png` |
| **RF-11** | **Creación y Envío de Reporte de Daños con Evidencia**: El estudiante debe poder crear un reporte mediante un formulario adaptativo: primero elige el **tipo de espacio** (aula, laboratorio, sala de cómputo, baño, pasillo, oficina, auditorio, biblioteca, cafetería, escaleras, ascensor, zona exterior, parqueadero u otro) y el formulario muestra solo los campos de ubicación que aplican (edificio y piso para interiores; zona o tramo para exteriores y áreas comunes; referencia obligatoria en zonas exteriores). Luego elige el **tipo de daño**, cuyo catálogo se filtra según el espacio, escribe la descripción y adjunta opcionalmente una fotografía desde la cámara o la galería. La fotografía se comprime en el cliente (~500 KB) y se guarda en el documento separado `reports/{id}/media/foto`; el reporte solo almacena `tieneFoto: boolean` para que las consultas de lista no descarguen la imagen. Se persisten `tipoUbicacion`, `edificio`/`piso` (solo interiores), `espacio`, `referencia` (opcional) y `ubicacionTexto` (resumen listo para listas, detalle y notificaciones); `salon` deja de escribirse en reportes nuevos y se mantiene compatibilidad de lectura con los existentes. | **Must Have** | `8.png` (Pantalla 8: Reportar Daños) |
| **RF-12** | **Listado de Reportes Propios del Estudiante**: El sistema debe listar cronológicamente los reportes generados por el estudiante autenticado, mostrando tipo de daño, descripción resumida y miniatura de la evidencia. | **Must Have** | `10.png` (Pantalla 10: Lista Tus Reportes) |
| **RF-13** | **Detalle de Reporte para Estudiante**: Al seleccionar un reporte propio, el estudiante debe poder visualizar toda la información enviada: ubicación exacta, descripción completa, imagen de evidencia en tamaño completo y estado actual de atención. | **Must Have** | `9.png` (Pantalla 9: Detalle Reporte) |
| **RF-14** | **Panel de Gestión, Búsqueda y Filtrado de Incidencias (Admin)**: El personal administrativo debe poder listar todos los reportes de la institución, buscar por término clave, filtrar mediante chips por estado (`Todos`, `Pendientes`, `En revision`, `Solucionados`) y filtrar por ubicación (`Edificio`). | **Must Have** | `12.png` (Pantalla 12: Daños Reportados) |
| **RF-15** | **Detalle y Actualización de Estado de Reporte (Admin)**: El administrativo debe poder abrir un reporte, visualizar la evidencia y datos del estudiante que reportó, modificar su estado (`Pendiente`, `En revision`, `En proceso`, `Solucionado`, `Rechazado`) y agregar una nota u observación de atención. *(Hueco de diseño cubierto)* | **Must Have** | `12.png` -> *Detalle Gestión Admin* |
| **RF-16** | **Bandeja de Notificaciones para Estudiante**: El estudiante debe visualizar una lista de notificaciones generadas por el cambio de estado de sus reportes, con indicación de fecha/hora, icono temático y estado de lectura (leída/no leída) persistido por usuario en `users/{uid}/notificacionesLeidas`. | **Must Have** | `11.png` (Pantalla 11: Notificaciones Estudiante) |
| **RF-17** | **Bandeja de Notificaciones para Administrativo**: El personal administrativo debe contar con una bandeja con pestañas de filtro (`Todas`, `Reportes`, `Administrativo`, `Sistema`) para ver nuevos reportes (avisos `destinoRol == 'administrativo'`) y avisos institucionales, con lectura por usuario. | **Must Have** | `13.png` (Pantalla 13: Notificaciones Admin) |
| **RF-18** | **Notificaciones en la App con Historial Persistente y Push (FCM)**: El sistema debe notificar al estudiante cuando un reporte cambie de estado y a los administrativos cuando se registre un nuevo reporte. Las notificaciones se persisten en Firestore (bandeja con estado leída/no leída) y se muestran dentro de la app en tiempo real mediante listeners sobre la colección `notifications`. El push real (alerta con la app fuera de primer plano) se habilita cuando el proyecto pase al plan Blaze (Cloud Function + FCM); **sin servidor, la alerta local NO se dispara con la app en segundo plano o cerrada** (se verifica en dispositivo real); la notificación aparece en la bandeja al reabrir la app gracias al historial persistente en Firestore. | **Must Have** | `11.png`, `13.png` + integración de notificaciones locales |
| **RF-19** | **Cierre de Sesión Seguro**: El sistema debe permitir al usuario cerrar su sesión de forma explícita desde el menú principal o su perfil, invalidando tokens locales y retornando a la pantalla de Login. | **Must Have** | `4.png`, `5.png`, `7.png` |
| **RF-20** | **Inicio de Sesión y Registro con Google**: El sistema debe ofrecer, además de correo/contraseña, el acceso con una cuenta de Google desde el Login y el Registro. Se acepta cualquier cuenta de Google (no se restringe el dominio). El primer acceso lleva a completar el perfil con el nombre prellenado desde Google. Si el correo ya tiene una cuenta con contraseña, se informa al usuario que debe iniciar sesión con su contraseña (no se vinculan cuentas automáticamente). El rol administrativo sigue dependiendo de `admins_permitidos` y la excepción de `google.com` en `correoConfiable()` se aplica en las reglas de Firestore. | **Should Have** | `1.png`, `3.png` |

---

## 4. Requerimientos No Funcionales (RNF)

| Código | Categoría | Especificación del Requerimiento |
| :--- | :--- | :--- |
| **RNF-01** | **Usabilidad y Diseño** | La interfaz gráfica debe respetar estrictamente la identidad visual de las UTS (verde institucional `#B8D400`, tarjetas redondeadas de radio `20-24px`, botones tipo píldora, tipografía Sans-Serif clara y elementos de navegación intuitivos con iconos explicativos). |
| **RNF-02** | **Rendimiento** | El tiempo de respuesta para la carga de listas (reportes y notificaciones) no debe superar los **1.5 segundos** bajo condiciones normales de red (4G/WiFi). Las imágenes adjuntadas se comprimen en el cliente a **~500–600 KB** y se guardan en Base64 en el documento separado `reports/{id}/media/foto` (respeta el límite de 1 MiB por documento, el Base64 agrega ~33%), de modo que las consultas de lista no descargan la imagen (solo `tieneFoto`). Resolución máxima de 1920x1080 píxeles. |
| **RNF-03** | **Seguridad** | - Toda la comunicación debe realizarse a través de canales seguros cifrados (HTTPS / TLS 1.3).<br>- Las credenciales y contraseñas deben ser gestionadas mediante Firebase Authentication.<br>- Las reglas de seguridad de Firestore deben restringir que un usuario solo pueda leer/editar sus propios reportes y perfil, y que únicamente los usuarios con rol administrativo validado puedan modificar los campos `estado` y `observacionAdmin`. |
| **RNF-04** | **Disponibilidad y Modo Sin Conexión** | La aplicación debe contar con persistencia offline local básica provista por el SDK de Firestore para permitir la **consulta y creación de texto de reportes sin conexión** a Internet. Los documentos de texto creados se sincronizan automáticamente al reconectarse. La subida de fotografías/evidencias multimedia requiere conexión activa a Internet en esta fase. |
| **RNF-05** | **Compatibilidad Multiplataforma** | El código base en Flutter debe ejecutarse sin discrepancias visuales ni funcionales en: **Android 7.0 (API nivel 24) o superior** e **iOS 15.0 o superior** (versiones declaradas por el build actual: `minSdk 24` y `IPHONEOS_DEPLOYMENT_TARGET 15.0`). |
| **RNF-06** | **Privacidad de Datos (Habeas Data)** | En cumplimiento de la Ley 1581 de 2012 (Colombia), la información de contacto y datos personales de los estudiantes solo serán visibles para fines del seguimiento del daño reportado por el personal de mantenimiento autorizado. |

---

## 5. Historias de Usuario con Criterios de Aceptación

### HU-01: Iniciar Sesión en la Plataforma
- **Como** usuario registrado (estudiante o administrativo),
- **quiero** ingresar mi correo institucional y contraseña,
- **para** acceder al panel de funciones correspondientes a mi rol.
- **Criterios de Aceptación**:
  - **CA-01.1**: Si las credenciales son válidas y el rol es estudiante, el sistema redirige a la pantalla de Inicio Estudiante (`4.png`).
  - **CA-01.2**: Si las credenciales son válidas y el usuario es administrativo autorizado, el sistema redirige a Inicio Administrativo (`5.png`).
  - **CA-01.3**: Si las credenciales son incorrectas o el usuario no existe, se muestra un mensaje de error claro sin bloquear la aplicación.
  - **CA-01.4**: La contraseña cuenta con un botón para alternar la visibilidad del texto (mostrar/ocultar).

---

### HU-02: Registro de Usuario con Verificación de Rol
- **Como** nuevo estudiante o funcionario de las UTS,
- **quiero** crear una cuenta con mi correo institucional,
- **para** poder utilizar los servicios de reporte o gestión de la aplicación.
- **Criterios de Aceptación**:
  - **CA-02.1**: El formulario valida que las contraseñas coincidan y tengan mínimo 6 caracteres.
  - **CA-02.2**: Tras crear la cuenta en Firebase Auth, el sistema envía un correo de verificación (normalizando el correo a minúsculas). Hasta que no se confirme el enlace, la app NO crea el perfil `users/{uid}` ni permite acceso a los módulos.
  - **CA-02.3**: Solo con el correo verificado se crea `users/{uid}`; allí la regla de Firestore comprueba `exists()` contra `admins_permitidos` (correos en minúsculas): si está en la lista se asigna rol `administrativo`; si no, se asigna `persona` y se informa al usuario del rol efectivo.
  - **CA-02.4**: Si el correo ya se encuentra registrado, el sistema arroja la alerta correspondiente.

---

### HU-03: Crear Reporte de Daño en Infraestructura
- **Como** estudiante de las UTS,
- **quiero** registrar una incidencia indicando ubicación, descripción y foto,
- **para** que el área de mantenimiento conozca la falla física y proceda a solucionarla.
- **Criterios de Aceptación**:
  - **CA-03.1**: El formulario exige diligenciar Tipo de daño, Edificio, Piso, Salón y Descripción.
  - **CA-03.2**: Permite capturar una fotografía desde la cámara del dispositivo o seleccionarla desde la galería.
  - **CA-03.3**: Al pulsar "ENVIAR REPORTE", el reporte de texto se crea en Firestore con estado inicial `Pendiente` y fecha/hora del servidor. La fotografía se comprime en el cliente (~500 KB) y se guarda en el documento separado `reports/{id}/media/foto` (operación que requiere conexión activa, según RNF-04); el reporte queda con `tieneFoto == true` pero la lista no descarga la imagen.
  - **CA-03.4**: Se muestra confirmación de envío exitoso y se redirige a la lista de reportes (`10.png`).

---

### HU-04: Consultar Lista e Historial de Reportes Creados
- **Como** estudiante,
- **quiero** consultar el listado de todos los daños que he reportado,
- **para** verificar su avance y estado de atención.
- **Criterios de Aceptación**:
  - **CA-04.1**: La pantalla muestra únicamente los reportes creados por el usuario activo ordenados cronológicamente descendente.
  - **CA-04.2**: Cada elemento del listado muestra el tipo de daño, resumen de la descripción y miniatura.
  - **CA-04.3**: Al pulsar sobre una tarjeta, se abre la vista detallada (`9.png`).

---

### HU-05: Buscar y Filtrar Reportes como Administrativo
- **Como** funcionario del área de mantenimiento,
- **quiero** filtrar los reportes por estado (`Pendientes`, `En revision`, `Solucionados`) y por edificio, además de buscar por texto,
- **para** organizar y priorizar las labores de reparación en el campus.
- **Criterios de Aceptación**:
  - **CA-05.1**: La barra de búsqueda filtra dinámicamente en tiempo real por el tipo de daño, la descripción, el correo del autor o el texto de ubicación (`ubicacionTexto`: edificio, piso, espacio y referencia).
  - **CA-05.2**: Los chips de estado filtran con precisión: `Todos`, `Pendientes`, `En revision`, `Solucionados`.
  - **CA-05.3**: El selector de ubicación permite aislar los reportes pertenecientes a un Edificio específico.
  - **CA-05.4**: Cada tarjeta muestra el badge de color correspondiente al estado actual del reporte.

---

### HU-06: Gestionar y Cambiar Estado de un Reporte (Administrador)
- **Como** encargado de mantenimiento,
- **quiero** abrir el detalle de una incidencia, revisar la evidencia y actualizar su estado,
- **para** registrar el progreso de la reparación y notificar al estudiante.
- **Criterios de Aceptación**:
  - **CA-06.1**: El administrador puede cambiar el estado siguiendo la máquina de estados permitida.
  - **CA-06.2**: Puede ingresar una observación o nota justificativa (obligatoria en caso de `Rechazado`).
  - **CA-06.3**: Al guardar, se actualiza el documento en Firestore, se genera un registro en la colección de `notificaciones` para el estudiante y la app del estudiante lo muestra como notificación local (push real vía FCM solo al activarse el plan Blaze).

---

### HU-07: Recibir y Consultar Notificaciones
- **Como** estudiante o administrativo,
- **quiero** recibir alertas dentro de la app y consultar una bandeja de notificaciones con historial persistente,
- **para** enterarme de novedades sobre los reportes de infraestructura en tiempo real.
- **Criterios de Aceptación**:
  - **CA-07.1**: El contador en el icono de campana indica el número de notificaciones no leídas (intersección entre las notificaciones visibles y `users/{uid}/notificacionesLeidas`).
  - **CA-07.2**: Al ingresar a la bandeja, las notificaciones se muestran con icono temático, título, mensaje y fecha, persistidas en Firestore e historial leída/no leída.
  - **CA-07.3**: Al presionar una notificación, se marca como leída y navega al detalle del reporte relacionado.
  - **CA-07.4**: La alerta se muestra dentro de la app (notificación local) al detectar el documento nuevo; el push fuera de la app (FCM) se considera habilitado solo con plan Blaze (migración futura).

---

## 6. Decisiones Arquitectónicas y de Dominio Tomadas

### 6.1. Verificación y Autorización de Roles
- El rol `admin` no se concede únicamente por selección en el formulario.
- **Mecanismo**:
  1. **Correo verificado (puerta principal de seguridad)**: Firebase Auth permite crear cuentas sin probar la titularidad del correo. Por eso el perfil `users/{uid}` NO se crea hasta que el usuario confirma el enlace de verificación. La regla exige `request.auth.token.email_verified == true`.
  2. **Colección `admins_permitidos`**: cada documento tiene como ID el correo institucional autorizado **en minúsculas** (Firebase Auth normaliza el correo a minúsculas, por lo que la comparación con `exists(...)` es exacta). La colección **no se escribe desde la app** (solo consola/script).
  3. Durante la creación del perfil, la regla asigna el rol de forma determinista:
     - Si `correo in admins_permitidos` → Rol = `administrativo` (acceso a pantallas 5, 7, 12, 13).
     - Si `correo not in admins_permitidos` → Rol = `persona` (acceso a pantallas 4, 6, 8, 9, 10, 11).
- El intento de auto-promoción queda siempre bloqueado por la regla (un usuario sin autorización jamás se almacena como `administrativo`).

---

### 6.2. Ciclo de Vida y Estados del Reporte
Se definen **5 estados oficiales** para todo reporte de daño:

```
                  ┌──────────────┐
                  │  Pendiente   │ (Estado inicial al crear reporte)
                  │ (Recibido)   │
                  └──────┬───────┘
                         │
           ┌─────────────┴─────────────┐
           ▼                           ▼
    ┌──────────────┐            ┌──────────────┐
    │ En revisión  │            │  Rechazado   │◄────────┐
    └──────┬───────┘            └──────────────┘         │
           │                           ▲                 │
           ▼                           │                 │
    ┌──────────────┐                   │                 │
    │  En proceso  ├───────────────────┘                 │
    └──────┬───────┘                                     │
           │                                             │
           ▼                                             │
    ┌──────────────┐                                     │
    │ Solucionado  │                                     │
    └──────────────┘                                     │
```

#### Matriz de Transiciones Permitidas:
1. **`Pendiente` (Recibido)**: Estado asignado automáticamente al crearse el reporte. Puede transicionar a: `En revisión` o `Rechazado`.
2. **`En revisión`**: El equipo de mantenimiento inspecciona el reporte y evalúa recursos. Puede transicionar a: `En proceso` o `Rechazado`.
3. **`En proceso`**: La cuadrilla u operario está ejecutando la reparación en el sitio. Puede transicionar a: `Solucionado` o `Rechazado`.
4. **`Solucionado`**: Reparación finalizada con éxito. Estado final / de cierre.
5. **`Rechazado`**: Reporte desestimado (información insuficiente, daño inexistente o fuera de competencia). Requiere motivo de rechazo.

#### Especificación de Colores e Iconos Distintivos por Estado:
Para garantizar accesibilidad y evitar confusiones visuales en las tarjetas (especialmente entre estados críticos), la identificación no depende únicamente del color, sino de la combinación de **color + icono exclusivo**:

| Estado | Color Oficial | Código HEX | Icono Exclusivo | Justificación de Diseño y Accesibilidad |
| :--- | :--- | :--- | :--- | :--- |
| **Pendiente** (Recibido) | Coral / Rosa Suave | `#FF6F61` | Reloj (`Icons.access_time_rounded`) | Indica recepción y espera de atención inicial. Diseñado en `12.png`. |
| **En revisión** | Ámbar / Mostaza | `#FFD13B` | Lupa (`Icons.search_rounded`) | Denota análisis técnico y evaluación de recursos. Diseñado en `12.png`. |
| **En proceso** | Azul Cielo / Cian | `#29B6F6` | Llave inglesa (`Icons.build_rounded`) | Armoniza con las herramientas operativas y se diferencia con claridad del amarillo y verde. |
| **Solucionado** | Verde Éxito | `#8CEE55` | Check en círculo (`Icons.check_circle_rounded`) | Denota resolución y cierre satisfactorio. Diseñado en `12.png`. |
| **Rechazado** | Gris Oscuro Neutro | `#616161` | Triángulo / Cruz de cancelación (`Icons.cancel_rounded` / `Icons.warning_amber_rounded`) | **Ajuste clave**: El uso de Gris Oscuro `#616161` (o Rojo muy oscuro `#B71C1C`) junto con el icono de alerta/cancelación elimina por completo la confusión con el Coral de *Pendiente*, asegurando contraste y legibilidad. |

---

### 6.3. Arquitectura y Modelo de Notificaciones
1. **Persistencia en Firestore (historial persistente e inmutable)**:
   - Colección: `notifications`.
   - Estructura del documento:
     - `id`: string (UUID / docId)
     - `tipo`: string (`reporte` | `administrativo` | `sistema`)
     - `titulo`: string (Ej: "Reporte Solucionado", "Reporte en proceso", "Aviso Administrativo")
     - `mensaje`: string (Ej: "El daño en el baño de mujeres del Edificio A ha sido solucionado")
     - `reportId`: string (opcional, ID del reporte relacionado para navegación directa)
     - `uidDestino`: string (opcional) — destinatario concreto (SOLO lo crea el administrativo, al autor del reporte).
     - `destinoRol`: string (opcional) — `administrativo` = aviso para TODOS los admins (lo crea una persona al reportar o un admin al emitir aviso).
     - `autorUid`: string — UID del emisor.
     - `creadoEn`: timestamp
     - *Exactamente uno de `uidDestino` / `destinoRol`*. No hay campo `leida` (ver punto 2).
   - **Quién crea qué** (reglas §3 de arquitectura): una persona **no puede notificar a otra persona** (solo aviso `destinoRol == 'administrativo'` con `autorUid == auth.uid`); un administrativo solo notifica al autor del reporte (`uidDestino == reports/{id}.uid`) o emite broadcast `destinoRol == 'administrativo'`.
2. **Estado leída/no leída por usuario**:
   - Se guarda en la **subcolección** `users/{uid}/notificacionesLeidas/{notifId}` (existencia = leída; `leidaEn` timestamp). Así un aviso broadcast puede considerarse leído de forma independiente por cada admin.
   - El **badge** de no leídas = intersección entre las notificaciones visibles (índices 5–8 de arquitectura) y los IDs de `notificacionesLeidas`.
3. **Escritura atómica (WriteBatch / transacción)**:
   - **Crear reporte**: un solo WriteBatch crea de forma atómica `reports/{id}` + `reports/{id}/historial/{h}` (entrada inicial `Pendiente`) + `notifications/{n}` con `destinoRol == 'administrativo'` y `evento == 'creado'`. La foto se sube **después** (no atómica; si falla, el reporte persiste).
   - **Cambio de estado admin**: un solo WriteBatch aplica `reports/{id}` (update) + `historial` (nueva transición) + `notifications` (`uidDestino == report.uid`, `evento` de la transición).
   - **IDs deterministas (idempotencia)**: el `reportId` se genera en el cliente **antes** del batch; `notifId = reportId + '_' + evento` y `historialId = reportId + '_inicial'` (o `reportId + '_' + estadoNuevo`). Un reintento no duplica, pero **Firestore no devuelve `ALREADY_EXISTS`**: la escritura con ID ya existente se evalúa como *update* y la regla la niega → el commit falla con **`PERMISSION_DENIED`**. Procedimiento del cliente:
     1. Si el commit falla con `PERMISSION_DENIED`, se envía 1 `get` a `reports/{reportId}`.
     2. **Existe con `uid == auth.uid`** (o, en la transición del admin, el estado objetivo ya aplicado) → el intento previo **tuvo éxito** (el batch es atómico): se continúa como éxito, sin duplicar notificaciones ni transiciones.
     3. **No existe / no coincide** → el `PERMISSION_DENIED` es un rechazo real de las reglas: se informa el error al usuario (no se asume éxito).
   - **Validación dentro del batch (reglas §3)**: con `getAfter()`/`existsAfter()` la regla comprueba que la notificación y la entrada de historial acompañan al reporte creado/transicionado **en el mismo commit** (p. ej. `!exists(report) && getAfter(report).uid == autorUid`), con máximo 10 accesos por evaluación.
   - Si se requiere leer el estado antes de escribir, se usa `runTransaction` en lugar de batch.
4. **Entrega (notificaciones locales activas; push FCM futuro)**:
   - **Implementación vigente**: listeners (`onSnapshot` sobre `uidDestino == miuid` para personas y sobre `destinoRol == 'administrativo'` para admins) reaniman la bandeja y `NotificacionesService` muestra una notificación **local** (`flutter_local_notifications`). *Limitación*: sin servidor no hay push con la app cerrada o en segundo plano; la alerta aparece al abrir la app.
   - **Migración futura (plan Blaze)**: se registra el token FCM en `users/{uid}/fcmToken` y una Cloud Function dispara el push real en `onCreate` de `notifications` (al `uidDestino` o a todos los admins según `destinoRol`), reforzando además la dedupe por `reportId`; la app intercambia `LocalNotificacionesService` por `FcmNotificacionesService` sin tocar las pantallas.

---

## 7. Huecos del Diseño Identificados, Inconsistencias y Soluciones

### 7.1. Pantallas y Flujos Faltantes en el Prototipo

1. **Pantalla de Detalle y Gestión del Reporte para Administrativo (Crítico - Must Have)**:
   - *Problema*: La pantalla 12 (`12.png`) muestra la lista de reportes con tarjetas clicables (`>`), pero no existe en los prototipos visuales la pantalla de destino donde el administrativo pueda:
     - Ver la fotografía completa enviada por el estudiante.
     - Ver nombre y contacto del estudiante que reportó.
     - Cambiar el estado del reporte mediante un selector (`Dropdown` / botones de estado).
     - Redactar un comentario de retroalimentación u observación técnica.
   - *Solución Requerida*: Se especifica el requerimiento **RF-15** para diseñar e implementar la vista de detalle y edición del reporte para el rol administrativo, conservando la estética del resto de la app.

2. **Flujo de Recuperación de Contraseña (Should Have)**:
   - *Problema*: En el Login (`1.png`) no existe el enlace típico "¿Olvidaste tu contraseña?".
   - *Solución Requerida*: Se incorpora el requerimiento **RF-10** para permitir el envío de correo de restablecimiento vía Firebase Auth.

3. **Flujo de Edición de Perfil (Should Have)**:
   - *Problema*: Las pantallas 6 (`6.png`) y 7 (`7.png`) muestran la opción interactiva "Editar información >", pero no hay diseño para el formulario de edición de teléfono y nombre.
   - *Solución Requerida*: Se incorpora el requerimiento **RF-09** para habilitar un formulario modal o pantalla simple de edición de datos personales.

---

### 7.2. Incoherencias y Errores Detectados en los Prototipos Visuales

| Elemento / Pantalla | Discrepancia o Error en Prototipo | Corrección y Especificación para Desarrollo |
| :--- | :--- | :--- |
| **Texto Informativo (`2.png`)** | El texto dice: *"(respaldado en PostgreSQL)"*. | **Corrección**: La arquitectura y stack del proyecto es **Google Cloud Firestore**. El texto en la UI debe reflejar la infraestructura real o mantenerse neutral ("base de datos en la nube"). |
| **Errores Tipográficos en Textos** | - `3.png`: *"Cotraseña"* (falta la 'n').<br>- `11.png` y `12.png`: *"edicio"*, *"areá"*, *"Edficio"*, *"comience"*, *"informacion"* sin tilde. | **Corrección**: Todo el texto de la interfaz debe corregirse ortográficamente en español ("Contraseña", "Edificio", "Área", "Información", "Salón"). |
| **Tipo de Daño (`8.png`, `9.png`, `10.png` vs `12.png`)** | En `8.png` el tipo de daño es una línea en blanco libre, pero en `12.png` se asocian iconos predefinidos (silla, lámpara, puerta). | **Corrección**: Implementar un selector (`DropdownFormField`) con categorías predefinidas: `Mobiliario / Sillas / Mesas`, `Iluminación / Eléctrico`, `Puertas / Cerraduras`, `Ventanas / Vidrios`, `Equipos / Computadores`, `Pintura / Muros`, `Otro`. |
| **Filtro de Ubicación (`12.png`)** | El filtro dice `"Ubicacion: [ Todos v ]"`, mientras que el formulario (`8.png`) guarda Edificio, Piso y Salón por separado. | **Corrección**: El dropdown de ubicación filtrará por `Edificio` (ej: Todos, Edificio A, Edificio B, Edificio C, etc.). |
| **Badge de Notificaciones (`11.png`, `13.png`)** | Muestra un número "3" estático en el icono de la campana. | **Corrección**: El badge debe ser un componente dinámico reactivo: intersección entre las notificaciones visibles al usuario (`uidDestino == miuid` o `destinoRol == 'administrativo'`) y la subcolección `users/{uid}/notificacionesLeidas` (existencia = leída). Si es 0, no se muestra el badge. |

---

## 8. Supuestos y Preguntas Abiertas

### 8.1. Supuestos de Trabajo Asumidos
1. **Dominio de Correo**: Se asume que el registro y acceso está restringido a correos con terminación institucional (ej. `@uts.edu.co` o `@correo.uts.edu.co`).
2. **Almacenamiento de Evidencias (decisión vigente)**: Cada foto se comprime en el cliente (~500 KB) y se codifica en Base64 en el documento separado `reports/{id}/media/foto`; el reporte conserva `tieneFoto`. Si el proyecto migra a plan Blaze, se reemplaza por Firebase Storage en `reportes/{reporte_id}/{timestamp}.jpg` (misma interfaz `FotoRepository`).
3. **Privacidad de Reportes**: Los estudiantes únicamente tienen visibilidad de sus propios reportes creados; el personal administrativo tiene visibilidad global de todos los reportes del campus.
4. **Auditoría e Inmutabilidad**: Los reportes no se eliminan físicamente de la base de datos por motivos de trazabilidad histórica. Si un reporte es inválido, se marca con estado `Rechazado`.
5. **Cantidad de Fotos**: Para mantener la agilidad del prototipo en esta fase, se asume **1 fotografía de evidencia por reporte** (como se ilustra en `8.png` y `9.png`).
6. **Normalización de Correos**: Se asume que Firebase Authentication normaliza los correos a minúsculas al crear cuentas; por ello `admins_permitidos` se almacena en minúsculas y la verificación con `exists()` es exacta.
7. **Alcance v1 — Should Have fuera de esta versión**: RF-09 (Edición de perfil) queda **NO implementado** — placeholder sin lógica, botón deshabilitado; RF-10 (Recuperar contraseña) queda **PARCIALMENTE implementado** — envío de correo ruteado funciona, falta 'cambiar contraseña desde el perfil'. Ambos quedan fuera del alcance de esta entrega sin afectar ningún requisito **Must Have**, todos completos y verificados.

---

### 8.2. Preguntas Abiertas para Definición con el Usuario
Para las siguientes fases del proyecto, se plantean las siguientes preguntas:
1. **Catálogo de Ubicaciones**: ¿Los nombres de los edificios (Edificio A, B, C...) y pisos deben estar preconfigurados en una lista fija en la app o cargarse dinámicamente desde una colección en Firestore (`edificios`)?
2. **Reapertura de Reportes**: Si un reporte queda en estado `Rechazado`, ¿el estudiante podrá editarlo y reenviarlo, o deberá crear un reporte nuevo desde cero?
3. **Múltiples Fotos de Evidencia**: ¿Se requerirá en una fase posterior permitir adjuntar múltiples fotos o solo 1 imagen es suficiente para el alcance del trabajo de grado?
4. **Carga Inicial de Administradores**: ¿Cómo se gestionará la lista inicial de `admins_permitidos`? (¿Directamente desde la consola de Firebase o mediante un script de inicialización?).
