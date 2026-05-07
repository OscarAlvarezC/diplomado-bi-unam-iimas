# Sesión 15: Datos semiestructurados II — JSONB

## :dart: Objetivo

Trabajar con datos jerárquicos JSON usando el tipo `JSONB` de PostgreSQL, dominar sus operadores y funciones específicas, e indexarlos eficientemente. Aplicar todo a queries reales sobre el dataset Airbnb CDMX.

## :pushpin: Temas

- **`JSON` vs `JSONB`:** diferencias de almacenamiento (texto vs binario), performance, cuándo usar cada uno.
- **Operadores:**
  - `->` (acceso, devuelve JSONB).
  - `->>` (acceso, devuelve texto).
  - `#>` y `#>>` (acceso por path).
  - `@>` (containment — clave para queries con índices).
  - `?`, `?&`, `?|` (existencia de keys).
- **Funciones:**
  - `jsonb_array_elements()` — explotar arrays a filas.
  - `jsonb_extract_path()` — equivalente a `#>`.
  - `jsonb_object_keys()`.
  - `jsonb_each()`.
- **Indexación:**
  - Índice **GIN** sobre la columna completa.
  - Índice GIN con `jsonb_path_ops` (más compacto, menos flexible).
  - Índices **btree** sobre path expressions (`(col->>'key')`).
  - Cuándo usar cada estrategia.
- **Práctica sobre Airbnb CDMX:**
  - Cast `amenities` (TEXT con JSON válido) a JSONB.
  - Queries: ¿qué amenidades son más comunes en cada alcaldía?, ¿qué % de listings tienen WiFi y Kitchen?, ¿cuáles tienen amenidades de lujo?
  - Indexación de `amenities` y comparación de planes de ejecución.

## :books: Material

> Por publicar.

Datos en [`../datasets/airbnb/`](../datasets/airbnb/), schema creado en [`../scripts/05_airbnb_ddl.sql`](../scripts/05_airbnb_ddl.sql).

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="../Sesion-16/Readme.md">Siguiente: Sesión 16 →</a>
</p>
