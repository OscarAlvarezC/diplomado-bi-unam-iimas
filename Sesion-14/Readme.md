# Sesión 14: Datos semiestructurados I — hstore

## :dart: Objetivo

Modelar y consultar datos clave-valor planos con la extensión `hstore` de PostgreSQL, y aplicar indexación GIN para optimizar queries sobre estos datos. **Al cierre cada alumno tiene cargado el dataset Airbnb CDMX**, base para la siguiente sesión de JSONB.

## :clock1: Duración

2.5 horas.

## :wrench: Setup técnico en vivo (~30 min)

- [`../setup/05_airbnb.md`](../setup/05_airbnb.md) — descargar y cargar el snapshot 2025-09-27 de Inside Airbnb CDMX (27 051 listings) en el schema `airbnb` mediante DBeaver Import Wizard.

## :pushpin: Temas

- **Por qué datos semi-estructurados:** el problema de schemas que cambian por entidad (e.g., propiedades de productos heterogéneos, atributos de usuarios).
- **Habilitación de la extensión** `hstore`.
- **Tipo de datos `hstore`:** sintaxis literal, parsing.
- **Almacenamiento en una sola columna** vs columnas separadas — trade-offs.
- **Operadores y funciones:**
  - `->` (acceso a valor).
  - `->>` (acceso como texto).
  - `||` (concatenación / merge).
  - `?` (existencia de key).
  - `?&`, `?|` (existencia de múltiples keys).
- **Funciones útiles:** `hstore_to_array`, `each`, `keys`, `values`.
- **Indexación con GIN:** cómo funciona, cuándo aporta, costo de mantenimiento.

## :books: Material

> Por publicar.
