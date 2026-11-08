# Ubicaciones de reportes — formulario adaptativo (RF-11)

> **Alcance:** contrato de datos y comportamiento del formulario de reportes de
> daños. Reemplaza la obligatoriedad del campo `salon` por una ubicación
> adaptada al tipo de espacio. No modifica autenticación ni roles.

---

## 1. Escenarios soportados

El formulario es uno solo. Al elegir **¿Dónde ocurrió?**, se muestran únicamente
los campos del escenario seleccionado.

| # | `tipoUbicacion` | Escenario | Campos propios | `espacio` guardado (ejemplo) |
|---|---|---|---|---|
| 1 | `aula` | Aula / salón | Edificio, piso, salón | `Salón 203` |
| 2 | `laboratorio` | Laboratorio | Edificio, piso, nombre | `Laboratorio de Química` |
| 3 | `sala_computo` | Sala de cómputo | Edificio A/B, piso 3, nombre | `Sala de cómputo 305` |
| 4 | `bano` | Baño | Edificio, piso, género (Hombre/Mujer) | `Baño de mujeres` |
| 5 | `pasillo` | Pasillo / corredor | Edificio, piso, referencia | `Pasillo` |
| 6 | `oficina` | Oficina / dependencia | Edificio, piso, dependencia | `Oficina de Registro y Control` |
| 7 | `auditorio` | Auditorio / sala | Nombre, referencia | `Auditorio principal` |
| 8 | `biblioteca` | Biblioteca | Zona, referencia | `Sala de lectura` |
| 9 | `cafeteria` | Cafetería / zona de comidas | Edificio A, C o E | `Cafetería` |
| 10 | `escaleras` | Escaleras | Edificio, tramo | `Escaleras` (el tramo se guarda en `piso`, ej. `Piso 1 a 2`) |
| 11 | `ascensor` | Ascensor | Edificio, ascensor, piso/cabina | `Ascensor 1` |
| 12 | `zona_exterior` | Zona exterior / campus abierto | Zona (`Jardines`, `Sendero peatonal`, `Otra`) + referencia obligatoria | `Jardines` |
| 13 | `parqueadero` | Parqueadero CAR | Referencia opcional | `Parqueadero CAR` |
| 14 | `otro` | Otro espacio | Descripción de ubicación obligatoria; edificio y piso opcionales | `Pasillo técnico detrás de la cafetería` |

Reglas del formulario:

- **Edificios:** A y B tienen 6 pisos; C, D, E y CAR tienen 4. No existe
  sótano en las opciones.
- **Interiores con piso** (1–6, 10–11): edificio y piso obligatorios. En
  escaleras el “piso” guarda el tramo; en ascensor, el piso o cabina.
- **Sala de cómputo:** solo se ofrece en los edificios A y B, y únicamente en
  el piso 3.
- **Baño:** solo `Hombre` o `Mujer`; el género determina el texto
  (`Baño de hombres`, `Baño de mujeres`). No se pide salón.
- **Auditorio** y **biblioteca**: no piden edificio ni piso. El auditorio pide
  nombre y referencia; la biblioteca, zona y referencia.
- **Cafetería:** solo edificios A, C y E. No pide piso, módulo ni referencia.
- **Exteriores y áreas comunes** (12–13): no se pide edificio ni piso.
  `zona_exterior` exige referencia; parqueadero la acepta opcional.
- **Parqueadero:** se registra siempre como `Parqueadero CAR`; ya no se elige
  zona.
- **Otro** (14): texto libre obligatorio; edificio y piso opcionales.
- La **referencia** es opcional en los interiores (salvo zona exterior).
- La opción **Acceso / portería** ya no se ofrece para reportes nuevos; se
  conserva el slug `acceso` solo para leer reportes antiguos.
- Al cambiar de tipo de espacio se limpian los campos del escenario anterior
  para no guardar datos inconsistentes (por ejemplo, un baño con salón).

## 2. Catálogo de daños filtrado

`CatalogoTiposDano.para(TipoEspacio)` devuelve la lista del espacio elegido y
`Otro daño` siempre está disponible. “Baño” ya no es un tipo de daño: es un tipo
de espacio. Los reportes antiguos con `tipoDano: "Baño"` se siguen mostrando sin
cambios.

Ejemplos:

- **Aula:** silla, mesa/pupitre, tablero, lámpara, toma corriente, puerta,
  ventana, aire acondicionado, techo/pared/piso.
- **Baño:** sanitario, lavamanos, grifo/fuga, dispensadores, secador, espejo,
  puerta/cerradura, división, lámpara, drenaje.
- **Laboratorio:** equipo, mesón, silla, toma corriente/red, ventilación,
  lavamanos/ducha de emergencia.
- **Sala de cómputo:** equipo de cómputo, silla, mesa/escritorio, toma
  corriente/red, lámpara, puerta/ventana, aire acondicionado.
- **Zona exterior:** banca, luminaria, basurero, zona verde, sendero,
  estructura/techo.
- **Parqueadero:** señalización, luminaria, superficie.

La lista genérica se usa mientras no se ha elegido el tipo de espacio.

## 3. Modelo persistido en `reports/{id}`

```json
{
  "uid": "auth-uid",
  "correoAutor": "estudiante@uts.edu.co",
  "tipoUbicacion": "bano",
  "edificio": "Edificio A",
  "piso": "Piso 2",
  "espacio": "Baño de mujeres",
  "referencia": "Junto a las escaleras",
  "ubicacionTexto": "Edificio A · Piso 2 · Baño de mujeres",
  "tipoDano": "Sanitario dañado",
  "descripcion": "El sanitario no descarga",
  "estado": "Pendiente",
  "tieneFoto": false,
  "creadoEn": "<timestamp>"
}
```

Zona exterior:

```json
{
  "tipoUbicacion": "zona_exterior",
  "espacio": "Jardines",
  "referencia": "Frente al Edificio B",
  "ubicacionTexto": "Zona exterior · Jardines · Frente al Edificio B"
}
```

Campos:

- `tipoUbicacion`: slug estable del catálogo (sin tildes).
- `edificio`, `piso`: presentes solo en espacios interiores.
- `espacio`: texto humano obligatorio.
- `referencia`: opcional; obligatoria en `zona_exterior`.
- `ubicacionTexto`: resumen generado por `construirUbicacionTexto(...)` en
  `lib/features/reportes/domain/reporte.dart`. Se usa en listas, detalle,
  notificaciones y búsqueda del admin.
- `salon`: **no se escribe** en reportes nuevos.

`construirUbicacionTexto` incluye la referencia en el texto solo para
`zona_exterior`, `parqueadero` y `otro`; en interiores la ubicación es
`Edificio · Piso · Espacio`.

## 4. Reglas de Firestore (`reports/create`)

La regla exige:

- `tipoUbicacion` dentro de los slugs permitidos (`sala_computo` incluido;
  `acceso` se conserva solo por compatibilidad).
- `espacio`, `ubicacionTexto`, `tipoDano` y `descripcion` no vacíos.
- `edificio` y `piso` no vacíos para `aula`, `laboratorio`, `sala_computo`,
  `bano`, `pasillo`, `oficina`, `escaleras` y `ascensor`.
- `cafeteria`: `edificio` obligatorio y restringido a `Edificio A`,
  `Edificio C` o `Edificio E`; sin `piso`.
- `sala_computo`: `edificio` en `Edificio A` o `Edificio B` y
  `piso == Piso 3`.
- `auditorio` y `biblioteca` no exigen `edificio` ni `piso`.
- `referencia` no vacía para `zona_exterior`.
- Se conserva la validación atómica de la foto (`existsAfter` sobre
  `media/foto` cuando `tieneFoto == true`).
- La regla de `update` del admin no cambia: solo `estado`,
  `observacionAdmin` y `actualizadoEn`.

## 5. Compatibilidad con reportes existentes

No hay migración de datos. Al leer un documento antiguo:

- Si falta `tipoUbicacion`, se interpreta como `TipoEspacio.aula`.
- Si el slug es `acceso` (tipo retirado del formulario), se conserva para
  mostrar el reporte antiguo con su etiqueta original.
- Si falta `espacio`, se usa `Salón {salon}`.
- `ubicacionTexto` se reconstruye con el mismo helper si el documento no lo
  tiene (por ejemplo, al cambiar de estado y notificar al autor).

Así los reportes previos siguen visibles en “Tus reportes”, “Daños reportados”
y el detalle, y el admin puede cambiarles el estado sin errores.

## 6. Pruebas

- `test/core/constants/catalogo_espacios_test.dart`: pisos por edificio sin
  sótano, baños Hombre/Mujer, zonas exteriores, sala de cómputo, tramos de
  escaleras, tipos de daño y opciones retiradas.
- `test/features/reportes/presentation/report_damage_screen_test.dart`:
  selector inicial, aula, baño sin salón, zona exterior con referencia
  obligatoria, catálogo por espacio, auditorio, biblioteca, cafetería,
  parqueadero, sala de cómputo, errores y `Failure`.
- `test/features/reportes/data/firebase_reporte_repository_test.dart`:
  persistencia de aula, baño y zona exterior; descarte de foto grande; lectura
  de documentos legados con `salon`; notificación con ubicación reconstruida.
- `test/features/admin/presentation/reported_damages_screen_test.dart`:
  búsqueda por `ubicacionTexto` en reportes exteriores.
- `test/features/reportes/presentation/my_reports_screen_test.dart` y
  `report_detail_screen_test.dart`: visualización de la nueva ubicación.
