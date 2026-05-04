# Bloque 06: Datos semiestructurados (hstore, JSONB)

## :dart: Objetivo

Gestionar datos semiestructurados en hstore, JSON y JSONB, aplicando operadores, funciones e indexación para optimizar consultas y rendimiento.

## :clock1: Duración

4.5 horas.

## :pushpin: Temas

### hstore (key-value plano)

- Habilitación de la extensión `hstore`.
- Tipo de datos `hstore`.
- Almacenamiento en una sola columna.
- Operadores y funciones: `->`, `->>`, `||`, `?`.
- Indexación con índices **GIN** y rendimiento.

### JSONB (key-value jerárquico)

- Diferencia entre `JSON` (texto) y `JSONB` (binario optimizado).
- Operadores: `->`, `->>`, `#>>`, `@>`.
- Funciones: `jsonb_array_elements()`, `jsonb_extract_path()`.
- Indexación con **GIN** vs **btree** y cuándo usar cada una.

### Práctica con Airbnb CDMX

- Dataset Inside Airbnb CDMX (snapshot 2025-09-27, ~27 000 listings) como fuente de datos semi-estructurados reales.
- Columna `amenities`: array JSON de amenidades ("Wifi", "Kitchen", "Pool", ...) — cargada como TEXT en la capa bronze, transformada a JSONB para queries.
- Columna `host_verifications`: lista de métodos de verificación del anfitrión.
- Queries analíticas: ¿qué amenidades son más comunes en cada alcaldía?, ¿qué hosts tienen más verificaciones?

## :books: Material

> Por publicar.

Los datos viven en [`../datasets/airbnb/`](../datasets/airbnb/). El schema bronze se crea con [`../scripts/05_airbnb_ddl.sql`](../scripts/05_airbnb_ddl.sql).
