# Acceso por tipo de usuario

## Selector del inicio de sesión

La pantalla de **Iniciar sesión** muestra un selector con dos opciones:

- **Estudiante**
- **Administrativo**

El selector no cambia el rol del usuario ni se guarda en Firestore; solo indica
con qué tipo de cuenta se está intentando entrar. El rol real siempre se lee de
`users/{uid}`.

| Acceso elegido | Roles que permite |
|---|---|
| Estudiante | `persona` |
| Administrativo | `administrativo`, `mantenimiento`, `superadministrador` |

Si la cuenta no corresponde al acceso elegido, la app cierra la sesión y
muestra un mensaje. Ejemplos:

- Una cuenta `persona` que elige **Administrativo** recibe: “Esta cuenta está
  registrada como Estudiante. Cambia el tipo de acceso a Estudiante”.
- Una cuenta `administrativo` que elige **Estudiante** recibe el mensaje
  equivalente para cambiar a **Administrativo**.
- Con **Administrativo** no se permite continuar si el correo todavía no tiene
  perfil; las cuentas administrativas las crea el superadministrador.
- El acceso **Estudiante** sí permite continuar sin perfil: es el flujo normal
  de autorregistro (correo pendiente o completar perfil).

La validación aplica igual para el inicio de sesión con correo/contraseña y con
Google.

## Rol administrativo

El rol **administrativo** comparte la experiencia completa del estudiante:

- Perfil.
- Reportar daños.
- Tus reportes (solo los propios).
- Notificaciones.
- Editar perfil, cambiar contraseña y reportar fallas de la app.

La única diferencia es el valor del rol en `users/{uid}` y la etiqueta que se
muestra en la gestión de usuarios.

El panel de gestión de reportes, catálogos, usuarios y fallas de la app queda
para:

- **mantenimiento**: reportes y catálogos.
- **superadministrador**: además usuarios, fallas y exportación CSV.

## Reglas de Firestore

`firestore.rules` define `isReportante()` como `isPersona() || isAdministrativo()`
y lo usa para:

- crear reportes;
- leer el reporte propio, su historial y sus fotos;
- crear el historial inicial y la notificación `creado`;
- reportar fallas de la app.

Los reportes que crea un administrativo también llegan al buzón compartido
`destinoRol == 'administrativo'` para que mantenimiento los gestione.

## Pruebas

- `test/sesion_controller_test.dart`: validación del tipo de acceso con cuentas
  persona, administrativo, mantenimiento y superadministrador, y con Google.
- `test/core/routes/app_router_guard_test.dart`: el administrativo navega como
  estudiante y no accede al panel de gestión.
- `test/features/auth/tipo_acceso_selector_test.dart`: selector de la pantalla
  de login.
