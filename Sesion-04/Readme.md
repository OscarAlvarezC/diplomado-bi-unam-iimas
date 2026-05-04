# Sesión 04: Implementación del DW II — Población y verificación

## :dart: Objetivo

Poblar el data warehouse con datos del OLTP usando SQL puro como ETL, y verificar que la transformación preservó la integridad de los datos.

## :clock1: Duración

2.5 horas.

## :pushpin: Temas

- **Generación de `dim_date`** con `generate_series` y `EXTRACT` para los atributos calendáricos.
- **Población de las 4 dims OLTP-derivadas** con `INSERT … SELECT … JOIN`:
  - Aplanamiento de `categories` y `suppliers` dentro de `dim_product`.
  - Self-join sobre `employees.reports_to` para `dim_employee.reports_to_name`.
- **Población de `fact_sales`**: la pieza clave — resolución de **natural keys → surrogate keys** vía joins con cada dim.
- **Tipo fixes durante el ETL**: `REAL` → `NUMERIC` con `ROUND(..., 2)` para corregir la imprecisión binaria del origen.
- **Verificación cross-OLTP/DWH**: `SUM(quantity)` y `SUM(line_total)` consistentes entre las dos representaciones.
- Comparación de la misma query analítica (ventas por categoría) en OLTP vs DWH — la justificación del modelado dimensional en una imagen.

## :books: Material

> Por publicar.

Scripts de referencia:
- [`../scripts/02_dim_date_populate.sql`](../scripts/02_dim_date_populate.sql)
- [`../scripts/03_dims_populate.sql`](../scripts/03_dims_populate.sql)
- [`../scripts/04_fact_populate.sql`](../scripts/04_fact_populate.sql)
