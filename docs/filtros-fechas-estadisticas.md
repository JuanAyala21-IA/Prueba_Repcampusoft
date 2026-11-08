# Filtros por fecha y dashboard de reportes

## Dónde están los filtros

| Rol | Pantalla | Filtro |
|---|---|---|
| Estudiante | Tus Reportes | Fechas + agrupación por día |
| Administrativo | Daños Reportados | Fechas + estado + edificio + búsqueda |
| Mantenimiento | Daños Reportados | Fechas + estado + edificio + búsqueda |
| Mantenimiento | Mis reportes asignados | Fechas |
| Superadministrador | Daños Reportados | Fechas + estado + edificio + búsqueda |
| Superadministrador | Exportación CSV | Fechas + estado |

Rangos disponibles: **Todo el tiempo**, **Hoy**, **Últimos 7 días**,
**Este mes**, **Este año** y **Personalizado** (calendario desde/hasta).

Los reportes se agrupan visualmente por fecha (Hoy, Ayer o `dd/MM/yyyy`) en las
listas de estudiante y de gestión. El agrupamiento usa `creadoEn`, que ya se
guarda en cada documento: no se cambia la estructura de Firestore ni se migran
datos.

## Dashboard del superadministrador

En **Daños Reportados** el superadministrador tiene dos pestañas:

- **Reportes**: listado con todos los filtros y agrupación por fecha.
- **Estadísticas**: dashboard con:
  - **General histórico**: total, solucionados, sin cerrar y porcentaje de
    solución de todos los reportes.
  - **Periodo seleccionado**: total, porcentaje resuelto y promedio de días
    hasta la solución.
  - **Distribución por estado**: barras de Pendiente, En revisión, En proceso
    y Solucionado.
  - **Reportes por día o por mes**: si el rango supera 90 días se agrupa por
    mes; si no, por día.
  - **Detalle por fecha**: totales exactos por cada día/mes.

El dashboard usa la **fecha de creación** del reporte y el **estado actual**.
El botón de descarga CSV conserva el rango de fechas y, en la pestaña de
listado, también el estado seleccionado.

## Implementación

| Elemento | Archivo |
|---|---|
| Rangos de fecha | `lib/core/utils/rango_fechas.dart` |
| Widget de filtros | `lib/shared/widgets/date_range_filter.dart` |
| Agrupación por día | `lib/features/reportes/domain/reporte_agrupacion.dart` |
| Lista agrupada | `lib/shared/widgets/reportes_agrupados_por_fecha.dart` |
| Estadísticas | `lib/features/reportes/domain/estadisticas_reportes.dart` |
| Dashboard | `lib/features/reportes/presentation/widgets/reportes_estadisticas_panel.dart` |
