# Exportación de reportes a CSV

## Acceso

Solo el rol **superadministrador** puede exportar. La opción está en el panel
principal, tarjeta **Descargar reportes (CSV)**, y abre la ruta
`/exportar-reportes`.

El acceso también está restringido en el *gate* de navegación
(`rutasSuperadministrador`): administrativo, mantenimiento y persona no pueden
entrar a la pantalla.

## Qué contiene el archivo

El CSV incluye **todos** los reportes de Firestore (`reports`), sin importar su
estado: `Pendiente`, `En revision`, `En proceso` y `Solucionado`.
La pantalla muestra un resumen con el total y la cantidad por estado antes de
descargar.

Si se abre desde **Daños Reportados**, el CSV respeta el filtro de fechas y el
estado que estén activos en esa pantalla. Dentro de la pantalla de exportación
también se pueden ajustar ambos filtros o limpiarlos para exportar todo.

Columnas (en este orden):

1. ID del reporte
2. Fecha de creación
3. Última actualización
4. Estado
5. Tipo de daño
6. Tipo de ubicación
7. Edificio
8. Piso
9. Espacio
10. Referencia
11. Ubicación completa
12. Descripción
13. Correo del autor
14. UID del autor
15. Tiene foto del daño
16. Asignado a
17. UID del asignado
18. Fecha de asignación
19. Solucionado por
20. UID de quien solucionó
21. Tiene evidencia de solución
22. Observación de gestión
23. Días desde la creación
24. Días hasta la solución

La fecha de solución se toma de `actualizadoEn` cuando el estado es
`Solucionado`. Los días hasta la solución se calculan entre `creadoEn` y esa
fecha; si el reporte aún no está solucionado, la columna queda vacía.

## Formato

- Codificación **UTF-8 con BOM** para que Excel muestre bien tildes y eñes.
- Separador **`;`**: Excel en español (Colombia) abre el archivo directamente en
  columnas con doble clic.
- Fin de línea `CRLF` y escape RFC 4180 para comillas, separadores y saltos de
  línea.
- Fechas locales en `dd/MM/yyyy HH:mm`.
- Orden: del reporte más reciente al más antiguo.
- Los textos que empiezan por `=`, `+`, `-` o `@` se neutralizan con un
  apóstrofo para evitar inyección de fórmulas en Excel.

## Guardado en el dispositivo

`file_saver` abre el diálogo nativo de guardado:

- **Android**: selector SAF; el usuario elige carpeta (Descargas, Drive, etc.).
- **iOS**: selector de documentos; el usuario elige ubicación en Archivos.

No se requieren permisos adicionales de almacenamiento.

## Implementación

| Capa | Archivo |
|---|---|
| Generador CSV (puro) | `lib/features/reportes/domain/reporte_csv.dart` |
| Guardado nativo | `lib/features/reportes/data/reporte_csv_saver.dart` |
| Pantalla | `lib/features/reportes/presentation/export_reports_screen.dart` |
| Ruta y gate | `lib/core/routes/app_router.dart` |
| Acceso desde el panel | `lib/features/home/presentation/admin_home_screen.dart` |

El generador es una función pura y se prueba en
`test/features/reportes/domain/reporte_csv_test.dart`. La pantalla se prueba con
un guardador falso en
`test/features/reportes/presentation/export_reports_screen_test.dart`.
