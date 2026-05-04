# Sesión 03: Implementación del DW I — DDL del esquema estrella

## :dart: Objetivo

Construir la estructura completa del data warehouse de Northwind en PostgreSQL: schema, dimensiones y tabla de hechos, aplicando los patrones canónicos de Kimball.

## :clock1: Duración

2.5 horas.

## :pushpin: Temas

- Creación del schema `northwind_dwh`.
- DDL de las 5 dimensiones (`dim_customer`, `dim_product`, `dim_employee`, `dim_shipper`, `dim_date`).
- **Surrogate keys** vs **natural keys**: por qué las dims tienen ambos.
- **Smart key** en `dim_date` (YYYYMMDD como entero).
- DDL de `fact_sales`: FKs a las dims, **degenerate dimension** (`order_id`), **role-playing** (3 FKs a `dim_date`).
- **Generated columns** (`extended_price`, `line_total`) — PostgreSQL las mantiene automáticamente.
- Verificación: las 6 tablas creadas y vacías.

## :books: Material

> Por publicar.

Script de referencia: [`../scripts/01_northwind_dwh_ddl.sql`](../scripts/01_northwind_dwh_ddl.sql).
