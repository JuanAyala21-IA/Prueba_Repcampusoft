# Especificación de Pantallas y Diseño - REPCAMPUSOFT

Documento de referencia técnica y de diseño UI/UX basado en los prototipos visuales de `docs/diseno/` (1.png a 13.png).

---

## 1. Guía de Estilos Visuales (Design System)

### 1.1. Paleta de Colores (HEX Aproximados)

| Rol / Uso | Nombre de Color | Código HEX | Muestra / Aplicación |
| :--- | :--- | :--- | :--- |
| **Primario Institucional** | Verde Lima UTS | `#C2D500` / `#B8D400` | Fondos curvos de pantalla, botones principales, insignias activas, logo UTS. |
| **Fondo Tarjetas / Base** | Blanco | `#FFFFFF` | Contenedores principales (Cards), inputs contrastados, fondo superior de pantallas. |
| **Superficie / Inputs / Chips** | Gris Claro / Slate | `#ECEEF1` / `#E8ECF2` | Cajas de texto (inputs de login y búsqueda), chips de filtros inactivos. |
| **Texto Principal** | Negro Carbón | `#111111` / `#000000` | Títulos, encabezados, nombres, textos destacados. |
| **Texto Secundario** | Gris Medio | `#555555` / `#666666` | Subtítulos ("Área encargada", "Información personal"), descripciones, placeholders. |
| **Estado: Pendiente** | Coral / Rosa Suave | `#FF6F61` / `#FF7675` | Badge con icono de reloj (`Icons.access_time_rounded`). |
| **Estado: En Revisión** | Ámbar / Amarillo | `#FFD13B` / `#F8C644` | Badge con icono de lupa (`Icons.search_rounded`). |
| **Estado: En Proceso** | Azul Cielo / Cian | `#29B6F6` | Badge con icono de herramienta (`Icons.build_rounded`). |
| **Estado: Solucionado** | Verde Éxito | `#8CEE55` / `#94E04B` | Badge con icono de check (`Icons.check_circle_rounded`). |
| **Bordes y Divisores** | Gris Neutro Tenue | `#D1D5DB` / `#E5E7EB` | Líneas divisorias internas en tarjetas y formularios. |

---

### 1.2. Tipografía

- **Familia tipográfica recomendada**: Sans-Serif moderna (ej. `Roboto`, `Inter`, `Open Sans` o la tipografía nativa de Material/Flutter).
- **Jerarquía tipográfica**:
  - **Títulos de Pantalla / Encabezados principales**: Bold / Extra-Bold, ~20px - 24px, color negro.
  - **Títulos de Tarjeta / Categorías**: Semi-Bold / Bold, ~16px - 18px, color negro.
  - **Subtítulos y Metadatos**: Regular / Medium, ~13px - 15px, color gris medio (`#555555`).
  - **Cuerpo de Texto**: Regular, ~13px - 14px, interlineado cómodo para lectura.
  - **Textos de Botones**: Bold, ~14px - 16px, texto centrado (mayúsculas o capitalizado).
  - **Fechas y Tiempos**: Regular / Light, ~11px - 12px, color gris tenue con icono de calendario.

---

### 1.3. Estilo de Bordes, Sombras y Geometría

- **Tarjetas Principales (Cards)**:
  - Bordes redondeados pronunciados: `BorderRadius.circular(20.0)` a `24.0`.
  - Fondo blanco `#FFFFFF`.
  - Sombras suaves: `BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: Offset(0, 4))`.
- **Botones Principales**:
  - Bordes redondeados tipo píldora o botón curvo: `BorderRadius.circular(24.0)` a `30.0`.
  - Fondo verde UTS `#B8D400` con texto negro en negrita.
- **Campos de Texto (Inputs)**:
  - Estilo 1 (Login / Búsqueda): Píldora redondeada completa (`BorderRadius.circular(30)`), fondo gris suave `#ECEEF1`, sin borde visible o borde muy sutil.
  - Estilo 2 (Formularios de Reporte / Registro): Campo con etiqueta izquierda y línea inferior continua (`UnderlineInputBorder`).
- **Botón de Retroceso / Acción circular**:
  - Botón circular con fondo verde/amarillo UTS (`CircleAvatar`), icono de flecha negra hacia la izquierda (`Icons.arrow_back`).
- **Fondo Orgánico de Pantalla**:
  - Combinación de área blanca superior y fondo curvo inferior verde UTS, o franjas curvas que separan la barra superior del cuerpo de la pantalla (`CustomPainter` / `ClipPath`).

---

### 1.4. Identidad Visual y Logo

- **Logo UTS**:
  - Isotipo: Letras minúsculas "uts" en verde lima característico.
  - Divisor vertical: Línea gris esbelta.
  - Logotipo de texto: "Unidades Tecnológicas de Santander" en color gris plomo en 3 líneas.
- **Icono de Ayuda**:
  - Botón circular amarillo/verde con símbolo de interrogación `?` en negrita negra.
- **Avatar de Usuario Predeterminado**:
  - Círculo negro con silueta blanca de usuario o avatar estándar.

---

## 2. Catálogo Detallado de Pantallas

---

### Pantalla 1: Iniciar Sesión (Login)
- **Archivo de diseño**: `1.png`
- **Propósito**: Permitir el acceso a los usuarios (estudiantes y personal administrativo) autenticándose con sus credenciales institucionales.
- **Elementos**:
  - **Encabezado**:
    - Fondo blanco curvado superior con el logo oficial de las **UTS**.
    - Botón circular de ayuda (`?`) en la esquina superior derecha.
    - Título principal: `REPCAMPUSOFT` (Bold).
    - Subtítulo: `INICIAR SESIÓN` (Bold).
  - **Tarjeta central de formulario (Fondo blanco, bordes redondeados)**:
    - Avatar circular negro con silueta de perfil.
    - Texto instructivo: "Ingresa tus credenciales".
    - Campo de texto 1: Correo institucional, con icono de sobre/correo a la izquierda (`Icons.mail_outline`).
    - Campo de texto 2: Contraseña, con icono de candado (`Icons.lock_outline`) y botón de visibilidad tipo ojo (`Icons.visibility_outlined`).
    - Botón principal: "Iniciar sesión" (Fondo verde UTS, texto negro negrita).
    - Enlace 1: "Ingresar como Administrativo" (texto subrayado).
    - Enlace 2: "¿No tienes una cuenta? Registrate" (texto subrayado).
    - Enlace 3: "Ingresar como persona" (texto subrayado).
  - **Pie de pantalla**:
    - Línea divisoria discontinua blanca.
    - Texto institucional: "UTS - Universitaria Tecnologia de Santander".
- **Acciones y Navegación**:
  - *Tap en "Iniciar sesión"*: Valida credenciales y redirige a **Inicio Estudiante** (`4.png`) o **Inicio Administrativo** (`5.png`) según el rol del usuario.
  - *Tap en botón de ayuda (`?`)*: Lleva a **¿Qué es Repcampusoft?** (`2.png`).
  - *Tap en "Registrate"*: Lleva a **Registro de Usuario** (`3.png`).
  - *Tap en "Ingresar como Administrativo" / "Ingresar como persona"*: Alterna el modo de acceso o preconfigura el rol.

---

### Pantalla 2: ¿Qué es Repcampusoft? (Información / Acerca de)
- **Archivo de diseño**: `2.png`
- **Propósito**: Explicar a los usuarios el propósito de la plataforma, el flujo general del sistema y los beneficios para la comunidad universitaria.
- **Elementos**:
  - **Encabezado**:
    - Botón circular de retroceso (flecha negra en círculo verde/amarillo).
    - Logo oficial de las **UTS**.
    - Título: `¿Qué es Repcampusoft?` (Bold, centrado).
  - **Tarjeta de contenido (Fondo blanco con bordes redondeados)**:
    - Párrafo 1: Descripción de REPCAMPUSOFT como solución móvil multiplataforma desarrollada en Flutter para centralizar y modernizar la gestión de incidencias en la infraestructura de las UTS.
    - Párrafo 2: Explicación de las capacidades para estudiantes, docentes y administrativos (registro ágil de daños en aulas, laboratorios, pasillos, adjuntando ubicación exacta y fotos).
    - Párrafo 3: Explicación del panel centralizado para el personal operativo y de mantenimiento (recepción, categorización, asignación de responsables, priorización y seguimiento en tiempo real).
- **Acciones y Navegación**:
  - *Tap en botón retroceso (flecha)*: Regresa a **Iniciar Sesión** (`1.png`).

---

### Pantalla 3: Registro de Usuario (Register)
- **Archivo de diseño**: `3.png`
- **Propósito**: Permitir la creación de una cuenta nueva especificando el correo institucional, contraseña y rol (Persona/Estudiante o Administrativo).
- **Elementos**:
  - **Encabezado**:
    - Botón circular de retroceso.
    - Logo oficial de las **UTS**.
    - Título: `REGISTRO` (Bold, mayúsculas).
  - **Tarjeta de formulario (Fondo blanco con bordes redondeados)**:
    - Campo: "Correo: ____________" (con línea inferior).
    - Campo: "Contraseña: ____________" (con línea inferior).
    - Campo: "Confirmar clave: ____________" (con línea inferior).
    - Campo: "Cargo: ____________" (con línea inferior).
    - Selector de Rol (Radio buttons / Círculos de selección):
      - Opción 1: `Persona` (Estudiante / Usuario común).
      - Opción 2: `Administrativo` (Personal administrativo / mantenimiento).
- **Acciones y Navegación**:
  - *Tap en botón retroceso*: Regresa a **Iniciar Sesión** (`1.png`).
  - *Completar registro*: Crea la cuenta y navega al Dashboard correspondiente (`4.png` o `5.png`).

---

### Pantalla 4: Menú Principal / Dashboard - Estudiante (Inicio)
- **Archivo de diseño**: `4.png`
- **Propósito**: Pantalla principal para el rol estudiante/usuario general, brindando acceso a todas las opciones de su flujo.
- **Elementos**:
  - **Encabezado superior**:
    - Botón circular de retroceso / salida.
    - Logo oficial de las **UTS**.
    - Avatar circular de perfil de usuario.
    - Nombre del estudiante: `Nombre` (Bold).
    - Subtítulo: `Informacion personal`.
  - **Cuadrícula de accesos rápidos (Tarjetas blancas con esquinas redondeadas)**:
    - Tarjeta 1: Icono de usuario (`Icons.person_outline`) + Texto `Perfil`.
    - Tarjeta 2: Icono de alerta (`Icons.warning_amber_rounded`) + Texto `Reportar daños` (subrayado).
    - Tarjeta 3: Icono de herramienta/llave inglesa (`Icons.build_outlined`) + Texto `Tus reportes`.
    - Tarjeta 4: Icono de campana (`Icons.notifications_none`) + Texto `Notificaciones`.
  - **Tarjeta inferior de ancho completo**:
    - Icono de salida (`Icons.logout`) + Texto `Cerrar Sesion`.
- **Acciones y Navegación**:
  - *Tap en "Perfil"*: Lleva a **Perfil Estudiante** (`6.png`).
  - *Tap en "Reportar daños"*: Lleva a **Reportar Daños** (`8.png`).
  - *Tap en "Tus reportes"*: Lleva a **Tus Reportes (Lista/Detalle)** (`9.png` / `10.png`).
  - *Tap en "Notificaciones"*: Lleva a **Notificaciones Estudiante** (`11.png`).
  - *Tap en "Cerrar Sesion"*: Cierra sesión y regresa a **Iniciar Sesión** (`1.png`).

---

### Pantalla 5: Menú Principal / Dashboard - Administrativo (Inicio)
- **Archivo de diseño**: `5.png`
- **Propósito**: Pantalla principal para el rol administrativo/mantenimiento, orientada a la gestión operativa de reportes.
- **Elementos**:
  - **Encabezado superior**:
    - Botón circular de retroceso.
    - Logo oficial de las **UTS**.
    - Avatar circular de perfil de usuario.
    - Nombre del encargado: `Nombre` (Bold).
    - Subtítulo: `Área encargada`.
  - **Cuadrícula de accesos rápidos (Tarjetas blancas 2x2)**:
    - Tarjeta 1: Icono de usuario (`Icons.person_outline`) + Texto `Perfil`.
    - Tarjeta 2: Icono de megáfono (`Icons.campaign_outlined`) + Texto `Daño y gestion de reportes`.
    - Tarjeta 3: Icono de campana (`Icons.notifications_none`) + Texto `Notificaciones`.
    - Tarjeta 4: Icono de salida (`Icons.logout`) + Texto `Cerrar Sesion`.
- **Acciones y Navegación**:
  - *Tap en "Perfil"*: Lleva a **Perfil Administrativo** (`7.png`).
  - *Tap en "Daño y gestion de reportes"*: Lleva a **Daños Reportados** (`12.png`).
  - *Tap en "Notificaciones"*: Lleva a **Notificaciones Administrativo** (`13.png`).
  - *Tap en "Cerrar Sesion"*: Cierra sesión y regresa a **Iniciar Sesión** (`1.png`).

---

### Pantalla 6: Perfil de Usuario - Estudiante
- **Archivo de diseño**: `6.png`
- **Propósito**: Consultar y administrar los datos personales, de contacto y seguridad del estudiante.
- **Elementos**:
  - **Encabezado**:
    - Botón circular de retroceso.
    - Logo oficial de las **UTS**.
    - Avatar circular de perfil.
    - Título: `Perfil` (Bold).
    - Subtítulo: `Informacion personal`.
  - **Tarjeta 1: Identificación**:
    - Icono de usuario.
    - Nombre completo: "Carlos Santiago Blanco Avila" (Bold).
    - Rol/Área: "Área encargada: Persona - Estudiante".
    - Flecha derecha (`>`).
  - **Tarjeta 2: Información de contacto**:
    - Encabezado con icono de sobre + "Informacion de contacto".
    - Línea divisoria.
    - Fila Correo: Icono sobre + "Correo: csblanco@uts.edu.co".
    - Línea divisoria.
    - Fila Teléfono: Icono teléfono + "Telefono: +57 300 123 4567".
  - **Tarjeta 3: Configuración de la cuenta**:
    - Encabezado con icono de engranaje (`Icons.settings`) + "Configuracion de la cuenta".
    - Opción 1: Icono de lápiz + "Editar informacion" + flecha derecha (`>`).
    - Línea divisoria.
    - Opción 2: Icono de candado + "Cambiar contraseña" + flecha derecha (`>`).
- **Acciones y Navegación**:
  - *Tap en botón retroceso*: Regresa a **Inicio Estudiante** (`4.png`).
  - *Tap en "Editar informacion"*: Abre modal o pantalla de edición de datos personales.
  - *Tap en "Cambiar contraseña"*: Abre modal o flujo de actualización de contraseña.

---

### Pantalla 7: Perfil de Usuario - Administrativo
- **Archivo de diseño**: `7.png`
- **Propósito**: Consultar la información del funcionario, área a la que pertenece, cargo y ajustes de cuenta.
- **Elementos**:
  - **Encabezado**:
    - Botón circular de retroceso.
    - Logo oficial de las **UTS**.
    - Avatar circular de perfil.
    - Título: `PERFIL` (Bold).
    - Subtítulo: `Área encargada`.
  - **Tarjeta 1: Dependencia / Área**:
    - Icono de edificio institucional (`Icons.apartment_outlined`).
    - Título del área: "Área de Mantenimiento" (Bold).
    - Subtítulo: "Encargado de infraestructura".
  - **Tarjeta 2: Datos del Funcionario**:
    - Fila 1: Icono usuario + Etiqueta "Nombre" + Valor "Juan Pérez Gracía".
    - Fila 2: Icono sobre + Etiqueta "Correo Institucional" + Valor "juan.perez@uts.edu.co".
    - Fila 3: Icono teléfono + Etiqueta "Telefono" + Valor "+57 310 123 7892".
    - Fila 4: Icono maletín (`Icons.work_outline`) + Etiqueta "Cargo" + Valor "Coordinador de Mantenimiento".
  - **Tarjeta 3: Opciones de Cuenta**:
    - Icono de lápiz + "Editar informacion" + flecha derecha (`>`).
    - Icono de candado + "Cambiar contraseña" + flecha derecha (`>`).
  - **Tarjeta 4: Botón Cerrar Sesión**:
    - Icono de salida + "Cerrar sesión" (negrita).
- **Acciones y Navegación**:
  - *Tap en botón retroceso*: Regresa a **Inicio Administrativo** (`5.png`).
  - *Tap en "Editar informacion" / "Cambiar contraseña"*: Abre flujos correspondientes.
  - *Tap en "Cerrar sesión"*: Cierra sesión y lleva a **Iniciar Sesión** (`1.png`).

---

### Pantalla 8: Reportar Daños (Crear Incidencia)
- **Archivo de diseño**: `8.png`
- **Propósito**: Formulario para que el estudiante registre un nuevo daño en la infraestructura del campus, detallando ubicación y evidencia fotográfica.
- **Elementos**:
  - **Encabezado**:
    - Botón circular de retroceso.
    - Logo oficial de las **UTS**.
    - Título: `Reportar Daños` (Bold).
  - **Tarjeta de formulario (Fondo blanco, bordes curvos)**:
    - Campo: "Tipo de daño: ____________"
    - Campo: "Edificio: ____________"
    - Campo: "Piso: ____________"
    - Campo: "Salón: ____________"
    - Campo: "Descripción: ____________" (área de texto multilínea).
    - Sección: "Adjuntar evidencia:".
    - Icono de carga en la nube con flecha hacia arriba (`Icons.cloud_upload_outlined`).
    - Botón principal: `ENVIAR REPORTE` (Fondo verde UTS, texto negro negrita).
- **Acciones y Navegación**:
  - *Tap en botón retroceso*: Regresa a **Inicio Estudiante** (`4.png`).
  - *Tap en área de nube / "Adjuntar evidencia"*: Abre el selector de archivos / cámara / galería.
  - *Tap en "ENVIAR REPORTE"*: Envía los datos del reporte a Firebase y redirige a **Tus Reportes** (`9.png` / `10.png`) o muestra confirmación.

---

### Pantalla 9: Detalle de Reporte - Estudiante
- **Archivo de diseño**: `9.png`
- **Propósito**: Visualizar la información completa y evidencia gráfica de un reporte específico enviado por el estudiante.
- **Elementos**:
  - **Encabezado**:
    - Botón circular de retroceso.
    - Logo oficial de las **UTS**.
    - Título: `Tus Reportes` (Bold).
  - **Tarjeta de detalle (Fondo blanco)**:
    - "Tipo de daño: ____________"
    - "Edificio: A"
    - "Piso: 4"
    - "Salón: 402 A"
    - "Descripción: En el salón 402 A se encontró la siguiente silla con los tornillos sueltos, lo cuál hace que a la hora de utilizarla esta comience a tambalearse."
    - "Adjuntar evidencia:"
    - Imagen de evidencia: Fotografía del elemento averiado (ej. silla universitaria con paleta rota/desajustada).
- **Acciones y Navegación**:
  - *Tap en botón retroceso*: Regresa a **Tus Reportes (Lista)** (`10.png`) o **Inicio Estudiante** (`4.png`).

---

### Pantalla 10: Lista de Reportes - Estudiante
- **Archivo de diseño**: `10.png`
- **Propósito**: Listar el historial de reportes creados por el estudiante para hacerles seguimiento.
- **Elementos**:
  - **Encabezado**:
    - Botón circular de retroceso.
    - Logo oficial de las **UTS**.
    - Título: `Tus Reportes` (Bold).
  - **Listado de tarjetas de reportes**:
    - Cada tarjeta contiene:
      - "Tipo de daño: ____________"
      - "Descripción: ____________"
      - "Adjuntar evidencia: ____________"
- **Acciones y Navegación**:
  - *Tap en botón retroceso*: Regresa a **Inicio Estudiante** (`4.png`).
  - *Tap en una tarjeta de reporte*: Abre la vista ampliada de **Detalle de Reporte** (`9.png`).

---

### Pantalla 11: Notificaciones - Estudiante
- **Archivo de diseño**: `11.png`
- **Propósito**: Informar al estudiante sobre los cambios de estado en sus reportes de daños enviados.
- **Elementos**:
  - **Encabezado**:
    - Botón circular de retroceso.
    - Logo oficial de las **UTS**.
    - Icono de campana con badge numérico circular verde: `3`.
    - Título: `Notificaciones` (Bold).
  - **Listado de tarjetas de notificación (Fondo verde UTS con tarjetas blancas)**:
    - **Notificación 1 (Recibido)**:
      - Icono de documento (`Icons.description_outlined`).
      - Título: "Reporte recibido" (Bold).
      - Mensaje: "Tu reporte #02 ha sido recibido correctamente".
      - Fecha/hora: Icono de calendario + "Hoy, 10:30 a.m.".
      - Flecha (`>`).
    - **Notificación 2 (En Proceso)**:
      - Icono de llave inglesa (`Icons.build_outlined`).
      - Título: "Reporte en proceso" (Bold).
      - Mensaje: "El daño reportado en el edicio A se encuentra en proceso de reparacion.".
      - Fecha/hora: Icono de calendario + "Ayer, 3:15 p.m.".
      - Flecha (`>`).
    - **Notificación 3 (Solucionado)**:
      - Icono de check dentro de círculo (`Icons.check_circle_outline`).
      - Título: "Reporte Solucionado" (Bold).
      - Mensaje: "El daño en el salon 204A ha sido solucionado. ¡Gracias por tu reporte!".
      - Fecha/hora: Icono de calendario + "06/09/2026".
      - Flecha (`>`).
- **Acciones y Navegación**:
  - *Tap en botón retroceso*: Regresa a **Inicio Estudiante** (`4.png`).
  - *Tap en una notificación*: Dirige al detalle del reporte correspondiente (`9.png`).

---

### Pantalla 12: Daños Reportados / Gestión de Reportes (Administrador)
- **Archivo de diseño**: `12.png`
- **Propósito**: Panel administrativo para que el personal de infraestructura busque, filtre por estado y ubicación, y gestione los reportes generados por la comunidad.
- **Elementos**:
  - **Encabezado superior**:
    - Botón circular de retroceso.
    - Logo oficial de las **UTS**.
    - Icono de llave inglesa + Título: `Daños Reportados` (Bold).
  - **Barra de búsqueda**:
    - Caja de texto con icono de lupa a la izquierda, placeholder "Buscar daño..." y botón `X` a la derecha para limpiar.
  - **Filtros por Estado (Chips / Píldoras horizontales)**:
    - Chip 1: `Todos` (Seleccionado, fondo verde UTS `#B8D400`).
    - Chip 2: `Pendientes` (Gris suave con sombra).
    - Chip 3: `En revision` (Gris suave con sombra).
    - Chip 4: `Solucionados` (Gris suave con sombra).
  - **Filtro por Ubicación**:
    - Etiqueta "Ubicacion:" + Menú desplegable tipo píldora: `[ Todos v ]`.
  - **Listado de tarjetas de incidencias (Fondo verde UTS, tarjetas blancas)**:
    - **Tarjeta 1**:
      - Icono de silla.
      - Título: "Silla dañada" (Bold).
      - Ubicación: Icono de pin (`Icons.location_on_outlined`) + "Edificio A - Salon 204".
      - Badge de estado: Píldora coral con icono de reloj (`Icons.access_time_rounded`) + `Pendiente`.
      - Fecha: Icono de calendario + "08/09/2026".
      - Flecha (`>`).
    - **Tarjeta 2**:
      - Icono de bombilla / lámpara (`Icons.lightbulb_outline`).
      - Título: "Lampara averiada" (Bold).
      - Ubicación: Icono de pin + "Edficio B - Salon 302".
      - Badge de estado: Píldora ámbar con icono de lupa (`Icons.search_rounded`) + `En revision`.
      - Fecha: Icono de calendario + "07/09/2026".
      - Flecha (`>`).
    - **Tarjeta 3**:
      - Icono de puerta (`Icons.door_front_door_outlined`).
      - Título: "Puerta dañada" (Bold).
      - Ubicación: Icono de pin + "Edficio B - Salon 105".
      - Badge de estado: Píldora verde claro con icono de check (`Icons.check_circle_rounded`) + `Solucionado`.
      - Fecha: Icono de calendario + "04/09/2026".
      - Flecha (`>`).
- **Acciones y Navegación**:
  - *Tap en botón retroceso*: Regresa a **Inicio Administrativo** (`5.png`).
  - *Buscar / Filtrar por estado / Filtrar por ubicación*: Actualiza dinámicamente la lista de reportes.
  - *Tap en una tarjeta de daño*: Abre la pantalla de gestión/edición del reporte para cambiar su estado o asignar responsables.

---

### Pantalla 13: Notificaciones - Área Encargada (Administrativo)
- **Archivo de diseño**: `13.png`
- **Propósito**: Bandeja de notificaciones del área de mantenimiento y administración con filtros temáticos (reportes, avisos administrativos y del sistema).
- **Elementos**:
  - **Encabezado superior**:
    - Botón circular de retroceso.
    - Logo oficial de las **UTS**.
    - Icono de campana con badge numérico: `3`.
    - Título: `Notificaciones` (Bold).
    - Subtítulo: `Área Encargada`.
  - **Filtros temáticos (Chips horizontales)**:
    - Chip 1: `Todas` (Seleccionado, fondo verde UTS `#B8D400`).
    - Chip 2: `Reportes` (Gris suave).
    - Chip 3: `Administrativo` (Gris suave).
    - Chip 4: `Sistema` (Gris suave).
  - **Listado de notificaciones (Tarjetas blancas con esquinas redondeadas)**:
    - **Notificación 1 (Nuevo Reporte)**:
      - Icono de usuario.
      - Título: "Nuevo reporte de daño" (Bold).
      - Mensaje: "El estudiante Carlos Perez reportó una silla dañada en el salon 402A".
      - Fecha/hora: Icono calendario + "08/09/2026 - 10:24 a.m.".
      - Flecha (`>`).
    - **Notificación 2 (En Proceso)**:
      - Icono de llave inglesa.
      - Título: "Reporte en proceso" (Bold).
      - Mensaje: "El reporte #024 esta siendo revisado por el areá de mantenimiento.".
      - Fecha/hora: Icono calendario + "08/09/2026 - 9:15 a.m.".
      - Flecha (`>`).
    - **Notificación 3 (Solucionado)**:
      - Icono de check en círculo.
      - Título: "Reporte Solucionado" (Bold).
      - Mensaje: "El daño en el salon 204A ha sido solucionado.".
      - Fecha/hora: Icono calendario + "07/09/2026 - 4:32 p.m.".
      - Flecha (`>`).
    - **Notificación 4 (Aviso Administrativo)**:
      - Icono de megáfono.
      - Título: "Aviso Administrativo" (Bold).
      - Mensaje: "Se realizara mantenimiento en el salon 204A el proximo viernes".
      - Fecha/hora: Icono calendario + "03/09/2026 - 2:45 p.m.".
      - Flecha (`>`).
- **Acciones y Navegación**:
  - *Tap en botón retroceso*: Regresa a **Inicio Administrativo** (`5.png`).
  - *Filtrar por chip (Todas, Reportes, Administrativo, Sistema)*: Filtra el listado de notificaciones.
  - *Tap en una notificación de reporte*: Lleva a la gestión del daño en **Daños Reportados** (`12.png`).

---

## 3. Mapa de Navegación y Flujo de la Aplicación

```
                    ┌─────────────────────────┐
                    │ 1. Iniciar Sesión       │◄────────────────────────┐
                    └────────────┬────────────┘                         │
                                 │                                      │
     ┌───────────────────────────┼───────────────────────────┐          │ (Cerrar Sesión)
     │ [Tap en ?]                │ [Tap en Registro]         │          │
     ▼                           ▼                           │          │
┌─────────────────────────┐ ┌─────────────────────────┐     │          │
│ 2. ¿Qué es Repcampus...?│ │ 3. Registro             │     │          │
└─────────────────────────┘ └─────────────────────────┘     │          │
                                 │                           │          │
             ┌───────────────────┴───────────────────┐       │          │
             │ (Login Estudiante)                    │ (Login Admin)    │
             ▼                                       ▼                  │
┌─────────────────────────┐             ┌─────────────────────────┐     │
│ 4. Inicio - Estudiante  │             │ 5. Inicio - Admin       │─────┤
└────────────┬────────────┘             └────────────┬────────────┘     │
             │                                       │                  │
 ┌───────────┼───────────┐               ┌───────────┴───────────┐      │
 │           │           │               │                       │      │
 ▼           ▼           ▼               ▼                       ▼      │
┌─────────┐ ┌─────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│6. Perfil│ │8. Crear │ │10. Lista    │ │7. Perfil    │ │12. Daños    │ │
│Estudiant│ │ Reporte │ │   Reportes  │ │Admin        │ │  Reportados │ │
└─────────┘ └────┬────┘ └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ │
                 │             │               │               │        │
                 └────────►┌───┴─────────────┐ └───────────────┼────────┤
                           │ 9. Detalle      │                 │        │
                           │    Reporte      │                 │        │
                           └─────────────────┘                 │        │
                                 │                             │        │
             ┌───────────────────┘                             │        │
             ▼                                                 ▼        │
┌─────────────────────────┐                     ┌─────────────────────────┐
│11. Notificaciones       │                     │13. Notificaciones       │
│    Estudiante           │                     │    Administrativo       │
└─────────────────────────┘                     └─────────────────────────┘
```
