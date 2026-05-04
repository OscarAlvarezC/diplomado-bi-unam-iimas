# Bloque 02: Implementación del warehouse

## :dart: Objetivo

Construir un data warehouse funcional sobre PostgreSQL: diseñar el DDL del esquema estrella, generar la dimensión de tiempo, y poblar dimensiones y la tabla de hechos mediante consultas SQL de transformación.

## :clock1: Duración

6 horas.

## :pushpin: Temas

- **Carga de Northwind OLTP** en su schema.
- **DDL del data warehouse:** schema, dimensiones, fact table.
- **Patrones Kimball aplicados:**
  - Surrogate keys + natural keys.
  - Smart key en `dim_date` (YYYYMMDD como entero).
  - Degenerate dimension (ej. `order_id`).
  - Role-playing dimensions (una `dim_date` con múltiples FKs).
  - Generated columns (`extended_price`, `line_total`).
- **Generación de `dim_date`** con `generate_series` y atributos calendáricos.
- **Poblado de dimensiones** con `INSERT … SELECT … JOIN` desde el OLTP. Aplanado de jerarquías. Cast de tipos.
- **Poblado de la tabla de hechos** resolviendo natural keys → surrogate keys.
- **Verificación de integridad** entre OLTP y DWH.

## :books: Material

> Por publicar.

Los scripts SQL de referencia están en [`../scripts/`](../scripts/):

- `01_northwind_dwh_ddl.sql`
- `02_dim_date_populate.sql`
- `03_dims_populate.sql`
- `04_fact_populate.sql`
