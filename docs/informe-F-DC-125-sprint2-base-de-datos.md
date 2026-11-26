# Diseño y estructuración de la base de datos — Sprint 2 (F-DC-125)

> **Nota de alcance.** Los campos `[SERVICIO Y TIPO]`, `[DESCRIPCIÓN]` y los
> atributos del bloque «Mis datos» llegaron vacíos. El contenido se redactó con
> el modelo real de REPCAMPUSOFT ya definido en el proyecto (Cloud Firestore,
> colecciones `users`, `reports`, `historial`, `media`, `notifications`,
> catálogos y `fallas_app`). Los datos que el proyecto no define se marcan como
> `[DATO FALTANTE]`.

## Diseño y estructuración de la base de datos

Para la persistencia de la información se eligió una base de datos **NoSQL de
documentos**, específicamente **Cloud Firestore** del ecosistema Firebase. La
elección se sustentó en cuatro requerimientos del proyecto. Primero, la
aplicación necesitó reflejar los cambios de estado de los reportes en tiempo
real, y Firestore entregó flujos de datos (*snapshots*) que actualizaron la
interfaz sin consultas repetitivas ni recarga manual. Segundo, el sistema operó
sobre una infraestructura administrada en la nube, lo que eliminó la necesidad
de aprovisionar y mantener un servidor de base de datos propio. Tercero, el
modelo documental se adaptó al crecimiento esperado del volumen de reportes del
campus, porque la plataforma distribuyó la carga de forma automática y permitió
añadir campos sin migraciones estructurales. Cuarto, la integración con Flutter
resultó directa a través de los SDK oficiales, y el modo sin conexión conservó
una copia local que se sincronizó al recuperar la red.

El modelo se estructuró en colecciones y subcolecciones. La colección `users`
almacenó el perfil de cada usuario —nombre, correo, rol, teléfono, estado de la
cuenta y token de notificaciones— y su identificador coincidió con el UID de
Firebase Authentication. La colección `reports` concentró el registro de daños:
autor, clasificación del daño, ubicación, descripción, estado actual, responsable
de la atención y evidencias. La ubicación se representó con los campos
`tipoUbicacion`, `edificio`, `piso`, `espacio`, `referencia` y `ubicacionTexto`,
y con las colecciones `catalogos_edificios`, `catalogos_sitios` y
`catalogos_zonas`, que normalizaron los valores seleccionables. El estado se
modeló como un campo de `reports` con cuatro valores —Pendiente, En revisión, En
proceso y Solucionado— y cada transición se registró en la subcolección
`reports/{id}/historial`, que funcionó como bitácora de atención. Los procesos de
atención se completaron con los campos `asignadoA`, `asignadoNombre`,
`asignadoEn`, `encargadoUid`, `encargadoNombre` y `observacionAdmin`, y con la
subcolección `media`, que conservó los metadatos de la foto inicial y de la
evidencia de solución.

Las relaciones se definieron por referencias entre documentos. Un usuario creó
varios reportes y cada reporte perteneció a un único usuario, relación de uno a
muchos materializada en el campo `reports.uid`. Un reporte tuvo una ubicación y
un estado vigente, y conservó el nombre del sitio y el texto de ubicación como
copia histórica, de modo que un cambio posterior en los catálogos no alteró los
registros anteriores. Cada reporte reunió un historial de atención de uno a
muchos, con el estado anterior, el estado nuevo, la observación, el funcionario y
la fecha. La evidencia fotográfica se vinculó mediante la subcolección `media`,
con dos documentos posibles: `foto`, obligatoria al crear el reporte, y
`solucion`, obligatoria al cerrarlo. Las notificaciones se relacionaron con el
reporte por el campo `reportId` y con el usuario por `uidDestino`, y el estado de
lectura se guardó en `users/{uid}/notificacionesLeidas` para que cada
destinatario conservara su propia marca.

El diseño garantizó la trazabilidad por dos vías. La primera fue el campo
`estado` de `reports`, que reflejó la situación vigente del daño. La segunda fue
la subcolección `historial`, que conservó cada cambio con su fecha, el funcionario
responsable y la observación, y que no admitió modificaciones ni eliminaciones.
Los identificadores del historial y de las notificaciones se derivaron del
identificador del reporte, lo que evitó duplicados ante un reintento de la
operación. La diferenciación de roles se resolvió con el campo `rol` de `users`.
El rol `persona` (estudiante) creó reportes y consultó únicamente los propios;
los roles `administrativo` y `mantenimiento` gestionaron los reportes, cambiaron
el estado y registraron la evidencia de solución; el rol `superadministrador`
administró las cuentas y los catálogos. La asignación del reporte a un encargado
de mantenimiento restringió el cambio de estado a ese responsable y dejó el
registro correspondiente en el historial.

Las reglas de acceso se definieron en el servidor, no en el cliente. La colección
`users` permitió la lectura del perfil propio y del conjunto solo al
superadministrador, y la escritura de campos personales al propietario, sin
posibilidad de modificar el rol ni el estado de la cuenta. La colección `reports`
permitió la creación al autor con su propio `uid` y con estado Pendiente, la
lectura al autor y al personal de gestión, y la actualización solo por
transiciones válidas de estado. El historial y las notificaciones se declararon
inmutables, y la lectura de notificaciones se limitó al destinatario o al rol
correspondiente. La subcolección `media` exigió la foto en el mismo lote de
creación y la evidencia de solución en el cierre. En materia de protección de
datos personales, el diseño aplicó el principio de minimización, porque solo
almacenó nombre, correo, teléfono y datos de contacto laboral; limitó el acceso
por rol y autoría; exigió autenticación con correo verificado; mantuvo el tráfico
cifrado mediante HTTPS; y conservó la cuenta en estado inactivo en lugar de
eliminarla, con el fin de no perder la trazabilidad de los reportes, en
concordancia con la Ley 1581 de 2012. La política de tratamiento de datos, la
autorización del titular y los plazos de retención se documentaron en
[DATO FALTANTE]. La estructura descrita se representó en la Figura 2. Modelo de
datos.

**Figura 2. Modelo de datos**

*Fuente: Autores.*

## Tabla [N]. Entidades del modelo de datos y sus atributos

| Entidad | Atributo | Tipo de dato | Descripción |
| :--- | :--- | :--- | :--- |
| users | uid | Cadena (ID del documento) | Identificador del usuario; coincide con el UID de Firebase Authentication |
| users | nombre | Cadena | Nombre completo del usuario |
| users | correo | Cadena | Correo institucional verificado; único por cuenta |
| users | rol | Cadena enumerada | persona, administrativo, mantenimiento o superadministrador |
| users | telefono | Cadena opcional | Teléfono de contacto de 10 dígitos |
| users | cargo | Cadena opcional | Cargo del funcionario; solo en cuentas administrativas |
| users | dependencia | Cadena opcional | Dependencia del funcionario; solo en cuentas administrativas |
| users | fcmToken | Cadena opcional | Token del dispositivo para notificaciones push |
| users | activo | Booleano | Estado de la cuenta; falso equivale a baja lógica |
| users | creadoEn | Marca de tiempo | Fecha de creación del perfil |
| users | actualizadoEn | Marca de tiempo | Fecha de la última actualización del perfil |
| users | eliminadoEn | Marca de tiempo opcional | Fecha de la baja lógica de la cuenta |
| users | reactivadoEn | Marca de tiempo opcional | Fecha de la reactivación de la cuenta |
| reports | reportId | Cadena (ID del documento) | Identificador del reporte, generado antes del registro |
| reports | uid | Cadena (referencia a users) | Identificador del autor del reporte |
| reports | correoAutor | Cadena | Correo del autor, conservado como copia histórica |
| reports | tipoUbicacion | Cadena | Slug del tipo de espacio (aula, laboratorio, baño, zona exterior, entre otros) |
| reports | tipoUbicacionNombre | Cadena opcional | Nombre visible del sitio seleccionado |
| reports | edificio | Cadena opcional | Edificio donde se ubicó el daño |
| reports | piso | Cadena opcional | Piso, tramo o cabina donde se ubicó el daño |
| reports | espacio | Cadena | Texto del espacio (por ejemplo, Salón 305) |
| reports | referencia | Cadena opcional | Detalle adicional de ubicación |
| reports | ubicacionTexto | Cadena | Ubicación consolidada para listas, detalle y notificaciones |
| reports | tipoDano | Cadena | Clasificación del daño reportado |
| reports | descripcion | Cadena | Descripción del daño realizada por el autor |
| reports | estado | Cadena enumerada | Pendiente, En revisión, En proceso o Solucionado |
| reports | tieneFoto | Booleano | Indica la existencia de la foto inicial del reporte |
| reports | observacionAdmin | Cadena opcional | Observación del funcionario durante la gestión |
| reports | asignadoA | Cadena opcional (referencia a users) | UID del encargado de mantenimiento asignado |
| reports | asignadoNombre | Cadena opcional | Nombre del encargado asignado, como copia histórica |
| reports | asignadoEn | Marca de tiempo opcional | Fecha de asignación del encargado |
| reports | encargadoUid | Cadena opcional | UID del funcionario que solucionó el daño |
| reports | encargadoNombre | Cadena opcional | Nombre del funcionario que solucionó el daño |
| reports | tieneEvidenciaSolucion | Booleano | Indica la existencia de la foto de solución |
| reports | creadoEn | Marca de tiempo | Fecha de creación del reporte |
| reports | actualizadoEn | Marca de tiempo | Fecha de la última modificación del reporte |
| historial | historialId | Cadena (ID del documento) | Identificador derivado del reporte y del estado alcanzado |
| historial | estadoAnterior | Cadena enumerada | Estado del reporte antes del cambio |
| historial | estadoNuevo | Cadena enumerada | Estado del reporte después del cambio |
| historial | observacion | Cadena opcional | Nota registrada en la transición |
| historial | adminUid | Cadena | UID del funcionario que realizó el cambio |
| historial | adminNombre | Cadena | Nombre del funcionario que realizó el cambio |
| historial | creadoEn | Marca de tiempo | Fecha y hora de la transición |
| media | mediaId | Cadena (ID del documento) | Identificador fijo: foto o solucion |
| media | storagePath | Cadena | Ruta del archivo en Firebase Storage |
| media | downloadUrl | Cadena | URL de descarga del archivo |
| media | tamanoBytes | Entero | Tamaño del archivo en bytes |
| media | mimeType | Cadena | Tipo de archivo (image/jpeg o image/png) |
| media | base64 | Cadena opcional (legado) | Imagen codificada de reportes anteriores a Firebase Storage |
| media | creadoEn | Marca de tiempo | Fecha de carga del archivo |
| notifications | notifId | Cadena (ID del documento) | Identificador derivado del reporte y del evento |
| notifications | tipo | Cadena enumerada | reporte, administrativo o sistema |
| notifications | titulo | Cadena | Título del aviso |
| notifications | mensaje | Cadena | Texto del aviso |
| notifications | reportId | Cadena opcional (referencia a reports) | Reporte asociado al aviso |
| notifications | evento | Cadena opcional | creado, en_revision, en_proceso o solucionado |
| notifications | estadoNuevo | Cadena opcional | Estado alcanzado por el reporte |
| notifications | uidDestino | Cadena opcional (referencia a users) | Destinatario directo del aviso |
| notifications | destinoRol | Cadena opcional | Rol destinatario del aviso (por ejemplo, administrativo) |
| notifications | autorUid | Cadena opcional | UID del emisor del aviso |
| notifications | fallaId | Cadena opcional | Identificador de la falla de la aplicación asociada |
| notifications | creadoEn | Marca de tiempo | Fecha de creación del aviso |
| notificacionesLeidas | notifId | Cadena (ID del documento) | Notificación marcada como leída |
| notificacionesLeidas | leida | Booleano | Marca de lectura; la existencia del documento equivale a leída |
| notificacionesLeidas | leidaEn | Marca de tiempo | Fecha en la que el usuario leyó el aviso |
| catalogos_edificios | id | Cadena (ID del documento) | Identificador del edificio |
| catalogos_edificios | nombre | Cadena | Nombre del edificio |
| catalogos_edificios | pisos | Arreglo de cadenas | Pisos disponibles del edificio |
| catalogos_edificios | activo | Booleano | Indica si el edificio está disponible en el formulario |
| catalogos_edificios | orden | Entero | Orden de presentación en la lista |
| catalogos_edificios | creadoEn | Marca de tiempo | Fecha de creación del registro |
| catalogos_edificios | creadoPor | Cadena | UID del usuario que creó el registro |
| catalogos_edificios | actualizadoEn | Marca de tiempo | Fecha de la última modificación |
| catalogos_edificios | actualizadoPor | Cadena | UID del usuario que modificó el registro |
| catalogos_sitios | id | Cadena (ID del documento) | Identificador del tipo de espacio |
| catalogos_sitios | nombre | Cadena | Nombre visible del sitio |
| catalogos_sitios | slug | Cadena | Identificador estable usado en reports.tipoUbicacion |
| catalogos_sitios | requiereEdificio | Booleano | Indica si el formulario exige edificio |
| catalogos_sitios | requierePiso | Booleano | Indica si el formulario exige piso |
| catalogos_sitios | muestraReferencia | Booleano | Indica si el formulario muestra el campo referencia |
| catalogos_sitios | referenciaObligatoria | Booleano | Indica si la referencia es obligatoria |
| catalogos_sitios | tipoEspecial | Cadena opcional | Comportamiento especial: bano, escaleras, ascensor o zona_exterior |
| catalogos_sitios | activo | Booleano | Indica si el sitio está disponible en el formulario |
| catalogos_sitios | orden | Entero | Orden de presentación en la lista |
| catalogos_sitios | creadoEn | Marca de tiempo | Fecha de creación del registro |
| catalogos_sitios | creadoPor | Cadena | UID del usuario que creó el registro |
| catalogos_sitios | actualizadoEn | Marca de tiempo | Fecha de la última modificación |
| catalogos_sitios | actualizadoPor | Cadena | UID del usuario que modificó el registro |
| catalogos_danos | id | Cadena (ID del documento) | Identificador del tipo de daño |
| catalogos_danos | nombre | Cadena | Nombre del tipo de daño |
| catalogos_danos | sitios | Arreglo de cadenas | Identificadores de los sitios donde aplica; vacío equivale a todos |
| catalogos_danos | activo | Booleano | Indica si el tipo de daño está disponible |
| catalogos_danos | orden | Entero | Orden de presentación en la lista |
| catalogos_danos | actualizadoEn | Marca de tiempo | Fecha de la última modificación |
| catalogos_danos | actualizadoPor | Cadena | UID del usuario que modificó el registro |
| catalogos_zonas | id | Cadena (ID del documento) | Identificador de la zona exterior |
| catalogos_zonas | nombre | Cadena | Nombre de la zona exterior |
| catalogos_zonas | activo | Booleano | Indica si la zona está disponible en el formulario |
| catalogos_zonas | orden | Entero | Orden de presentación en la lista |
| catalogos_zonas | actualizadoEn | Marca de tiempo | Fecha de la última modificación |
| catalogos_zonas | actualizadoPor | Cadena | UID del usuario que modificó el registro |
| fallas_app | fallaId | Cadena (ID del documento) | Identificador de la falla reportada |
| fallas_app | uid | Cadena (referencia a users) | UID del usuario que reportó la falla |
| fallas_app | correo | Cadena | Correo del usuario que reportó la falla |
| fallas_app | mensaje | Cadena | Descripción de la falla de la aplicación |
| fallas_app | pantalla | Cadena opcional | Pantalla donde ocurrió la falla |
| fallas_app | plataforma | Cadena opcional | Plataforma del dispositivo |
| fallas_app | sistemaOperativo | Cadena opcional | Versión del sistema operativo |
| fallas_app | dispositivo | Cadena opcional | Modelo del dispositivo |
| fallas_app | versionApp | Cadena opcional | Versión de la aplicación |
| fallas_app | creadoEn | Marca de tiempo | Fecha del reporte de la falla |
| super_admins_permitidos | correo | Cadena (ID del documento) | Correo autorizado para el rol de superadministrador |
| super_admins_permitidos | creadoEn | Marca de tiempo | Fecha de registro del correo autorizado |
| super_admins_permitidos | notas | Cadena opcional | Observaciones del registro |

*Fuente: Autores.*

## Guía para armar la Figura 2. Modelo de datos

**1. Tipo de diagrama.** Al tratarse de una base de datos **NoSQL de documentos**,
corresponde un **diagrama de colecciones** (modelo de documentos con referencias),
no un diagrama entidad-relación clásico. Cada colección se dibuja como una caja
con el nombre de la colección en el encabezado y la lista de campos debajo; las
subcolecciones se dibujan como cajas contenidas dentro de la colección padre o
como cajas anidadas con borde punteado.

**2. Cajas por dibujar (nueve, más el almacenamiento).**

| Caja | Contenido mínimo | Color sugerido |
| :--- | :--- | :--- |
| users | uid, nombre, correo, rol, telefono, activo, fcmToken | Azul |
| notificacionesLeidas | notifId, leida, leidaEn | Azul claro, borde punteado |
| reports | reportId, uid, tipoUbicacion, ubicacionTexto, tipoDano, descripcion, estado, tieneFoto | Naranja |
| historial | historialId, estadoAnterior, estadoNuevo, adminUid, creadoEn | Naranja claro, borde punteado |
| media | mediaId, storagePath, downloadUrl, tamanoBytes, mimeType | Naranja claro, borde punteado |
| notifications | notifId, tipo, titulo, mensaje, reportId, uidDestino, destinoRol | Morado |
| catálogos (una caja agrupada) | catalogos_edificios, catalogos_sitios, catalogos_danos, catalogos_zonas | Verde |
| fallas_app | fallaId, uid, mensaje, pantalla, versionApp | Gris |
| super_admins_permitidos | correo, creadoEn | Beige |
| Firebase Storage | reports/{uid}/{reportId}/foto.jpg y solucion.jpg | Recuadro sin relleno |

**3. Relaciones y cardinalidad.**

| Origen | Destino | Cardinalidad | Etiqueta del enlace |
| :--- | :--- | :--- | :--- |
| users | reports | 1 a muchos | uid |
| users | notifications | 1 a muchos | uidDestino (o destinoRol por rol) |
| users | notificacionesLeidas | 1 a muchos | notifId |
| users | fallas_app | 1 a muchos | uid |
| users | super_admins_permitidos | 1 a 0..1 | correo |
| reports | historial | 1 a muchos | subcolección |
| reports | media | 1 a 2 | foto y solucion |
| reports | notifications | 1 a muchos | reportId |
| notificacionesLeidas | notifications | muchos a 1 | notifId |
| catálogos | reports | referencia lógica | tipoUbicacion y tipoDano (slug) |
| media | Firebase Storage | 1 a 1 | storagePath |

Convención de trazo: **línea continua con flecha** para referencias por
identificador y **línea punteada** para referencias lógicas (slug de catálogo,
correo del superadministrador). Escriba la cardinalidad sobre la línea
(`1 —— N`) y el nombre del campo enlace debajo.

**4. Composición legible en tamaño carta (21,59 × 27,94 cm).**

- Orientación vertical, márgenes de 2,5 cm; área útil aproximada de 16,5 × 22,9 cm.
- Tres columnas: `users` a la izquierda, `reports` con sus subcolecciones al
  centro, `notifications` a la derecha. Los catálogos y `fallas_app` van en la
  franja inferior; la leyenda en la esquina inferior derecha.
- Ancho de caja entre 4,5 y 5,5 cm; alto según el número de campos.
- Tipografía sans serif de 8 a 9 pt en los campos y 11 a 12 pt en el título de la
  colección, medidos sobre el tamaño final impreso (no sobre el archivo de
  origen). No use menos de 8 pt.
- Máximo nueve cajas visibles; si necesita incluir los cuatro catálogos por
  separado, agrúpelos en una sola caja con cuatro subtítulos.
- Colores suaves por familia (relleno claro y borde de 1,5 a 2 pt) y una leyenda
  con los dos tipos de línea.
- Exporte en PNG a 300 ppp o en PDF vectorial; evite capturas de pantalla.
- Inserte la imagen en Word con ajuste «En línea con el texto», agréguele el
  rótulo **Figura 2. Modelo de datos** y debajo la línea **Fuente: Autores.**
- Verifique la legibilidad al imprimir en blanco y negro: si dos familias de
  cajas se confunden, agregue tramas o prefijos de texto.

**5. Pasos en Word, draw.io o Lucidchart.** Cree primero las cajas de las tres
columnas, alinee los bordes con la cuadrícula, trace las líneas continuas y luego
las punteadas, escriba las cardinalidades y los campos enlace, agrupe el conjunto
y exporte. El archivo ya generado en el repositorio del proyecto
(`docs/imagenes/modelo-datos-repcampusoft.png`) sirve como referencia directa de
esta composición.
