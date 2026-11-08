# Catálogos dinámicos de reportes

Mantenimiento y superadministrador pueden agregar, editar y desactivar los
catálogos que usa el formulario de reportes. Los estudiantes ven los cambios
inmediatamente; no hace falta recompilar la app.

## Acceso

- Panel de **mantenimiento** o **superadministrador** → tarjeta **Catálogos de reportes**.
- También abre en la ruta `/reportar-danos`; para esos dos roles la ruta
  muestra la administración de catálogos en lugar del formulario de estudiante.
- El rol **administrativo** no tiene acceso.

## Secciones

| Sección | Qué administra |
|---|---|
| **Edificios** | Nombre y lista de pisos. Los pisos se escriben separados por coma. |
| **Sitios** | Tipos de espacio (aula, baño, laboratorio, etc.). Definen si el formulario pide edificio, piso y referencia. |
| **Daños** | Tipos de daño y los sitios donde aparecen. |
| **Zonas** | Opciones de zona cuando el sitio es una zona exterior. |

Cada elemento tiene un interruptor para **activarlo o desactivarlo** y un botón
para **eliminarlo** con confirmación. Desactivar no borra reportes históricos.
Eliminar quita el elemento del catálogo; los reportes anteriores conservan el
texto que ya tienen guardado.

## Reglas de los sitios

- **Sitios integrados** (aula, baño, etc.): se puede cambiar el nombre y
  activarlos/desactivarlos, pero sus campos obligatorios quedan fijados para
  mantener compatibilidad con las reglas de Firestore.
- **Sitios nuevos**: se pueden configurar libremente:
  - Pide edificio.
  - Pide piso (activa automáticamente “pide edificio”).
  - Muestra referencia.
  - Referencia obligatoria.
  - Comportamiento especial: baño, escaleras, ascensor o zona exterior.
- Los sitios nuevos se guardan en el reporte como `tipoUbicacion: "otro"` y
  conservan su nombre en `tipoUbicacionNombre`, para que aparezcan correctamente
  en listas, detalle y CSV.

## Tipos de daño

Todos los tipos de daño activos se muestran únicamente en los sitios que se les
asignen. Al crear o editar un daño se eligen uno o varios sitios, o **Todos los
sitios**. Los daños iniciales ya vienen categorizados (por ejemplo, “Sanitario
dañado” solo en baños y “Silla dañada” en aulas, laboratorios, oficinas, etc.).

## Edificios y pisos

Al crear un edificio se indica su lista de pisos, por ejemplo:

```text
Piso 1, Piso 2, Piso 3
```

Los edificios personalizados se usan en los sitios que piden edificio. Las
restricciones históricas de cafetería (A, C, E) y sala de cómputo (A, B, Piso 3)
se mantienen para los sitios integrados.

## Persistencia

Colecciones de Firestore:

- `catalogos_edificios`
- `catalogos_sitios`
- `catalogos_danos`
- `catalogos_zonas`

Las reglas permiten lectura a usuarios autenticados y escritura solo a
mantenimiento y superadministrador. No se permite eliminar documentos; solo
desactivarlos. Los catálogos iniciales se siembran automáticamente si las
colecciones están vacías y también se dejaron cargados en el proyecto.

## Implementación

| Elemento | Archivo |
|---|---|
| Modelos y valores iniciales | `lib/features/catalogos/domain/catalogos.dart` |
| Repositorio | `lib/features/catalogos/data/firebase_catalogo_repository.dart` |
| Proveedores | `lib/features/catalogos/data/providers/catalogo_providers.dart` |
| Pantalla de administración | `lib/features/catalogos/presentation/catalogos_screen.dart` |
| Integración con el formulario | `lib/features/reportes/presentation/report_damage_screen.dart` |
| Reglas | `firestore.rules` |
