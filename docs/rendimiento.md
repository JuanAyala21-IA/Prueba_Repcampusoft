# Optimización de rendimiento

> Registro de las optimizaciones aplicadas para que la app se sienta fluida en
> Android e iOS. Todas las mejoras son de código compartido (Dart), salvo los
> assets empaquetados, que aplican a ambas plataformas.

## 1. Notificaciones

- **Corrección del cuelgue del superadministrador.** La consulta de
  `users/{uid}/notificacionesLeidas` usaba `whereIn` con **todos** los IDs de
  notificaciones visibles; Firestore limita `whereIn` a **30 valores** y la
  excepción no se capturaba dentro del `StreamController`, por lo que la
  pantalla se quedaba cargando de forma indefinida. Ahora:
  - la lectura de leídas se hace **en lotes de 30** (`_leerLeidas`);
  - cualquier error del stream se propaga con `controller.addError` y la
    pantalla muestra el estado de error con opción de reintentar.
- **Consultas por mes en Firestore.** La bandeja y el badge consultan solo el
  rango del mes visible (`creadoEn >= inicio` y `creadoEn < inicio del mes
  siguiente`) usando los índices `destinoRol/uidDestino + creadoEn` ya
  declarados en `firestore.indexes.json`. Se evita descargar el historial
  completo cada vez que se abre la pantalla.
- **Familia de providers por mes.** `notificacionesEstudianteMesProvider` y
  `notificacionesAdminMesProvider` (`.family<MesAnio>`) comparten la misma
  suscripción entre la lista y el badge cuando ambos apuntan al mes en curso,
  evitando lecturas duplicadas.
- **Selector de meses sin lectura extra.** El menú se construye con una ventana
  fija de los últimos **24 meses**; antes era necesario descargar todo el
  historial solo para saber qué meses tenían datos.
- **Listas virtualizadas.** Las bandejas usan `ListView.separated` en lugar de
  `SingleChildScrollView` + `Column`, de modo que solo se construyen las
  tarjetas visibles.

## 2. Imágenes de evidencia

- **Caché en memoria (LRU) de 12 entradas** en `media_reporte_loader.dart`:
  al volver a abrir un reporte no se repite la lectura de Firestore/Storage ni
  la decodificación Base64.
- **Decodificación al tamaño de pantalla** (`cacheWidth` calculado con
  `anchoDecodificacionImagen`), en lugar de decodificar la foto a resolución
  completa para mostrarla en una tarjeta de 160 px. Menos RAM y menos tirones.
- En la pantalla de gestión se decodifica la evidencia **una sola vez por
  build** (antes se hacía dos veces: vista previa y ampliación).

## 3. Arranque

- **Fuentes Inter empaquetadas** en `assets/google_fonts/` y
  `GoogleFonts.config.allowRuntimeFetching = false`. Ya no se descargan fuentes
  por red en el primer arranque ni se produce el cambio de tipografía cuando la
  descarga termina.
- **Inicialización diferida de FCM y notificaciones locales** hasta después del
  primer frame (`addPostFrameCallback`), para no competir con el primer pintado.

## 4. Datos y consultas

- Las consultas de notificaciones están acotadas por rango de fechas.
- Persisten como deuda documentada: paginación de la lista de reportes
  (`reports` sin `limit()`), búsqueda textual en el panel admin (filtro en
  cliente) y consultas de catálogos completos.

## 5. APK

- Se mantiene **un APK universal** por decisión de distribución; las mejoras de
  arranque y memoria aplican igual en Android e iOS.
