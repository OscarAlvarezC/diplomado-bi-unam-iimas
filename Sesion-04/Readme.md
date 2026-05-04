# Sesión 04: Implementación del DW — análisis del DDL y la transformación SQL

## :dart: Objetivo

Analizar a profundidad el data warehouse que ya está cargado en `northwind_dwh`: entender por qué cada decisión de diseño está donde está, qué hace cada script de population, y cómo se resolvieron las natural keys del OLTP a las surrogate keys del DW.

## :clock1: Duración

2.5 horas.

## :pushpin: Temas

### Análisis del DDL (~75 min)

Lectura guiada de [`../scripts/01_northwind_dwh_ddl.sql`](../scripts/01_northwind_dwh_ddl.sql), explicando cada patrón Kimball aplicado:

- **Surrogate keys + natural keys** en cada dim — desacoplamiento del DW del sistema fuente.
- **Smart key** en `dim_date` (YYYYMMDD como entero, sin surrogate) — filtrable sin join.
- **Degenerate dimension** (`order_id` en `fact_sales` sin tabla propia) — sirve para `COUNT(DISTINCT)` pero no tiene atributos descriptivos.
- **Role-playing** — una sola `dim_date` con tres FKs en `fact_sales` (order, required, shipped).
- **Generated columns** (`extended_price`, `line_total`) — PG las calcula automáticamente.

### Análisis de la transformación SQL (~75 min)

Lectura guiada de los scripts `02_..` a `04_..`:

- **`generate_series` para `dim_date`** — la única dimensión "manufacturada" desde cero (no viene del OLTP).
- **`INSERT … SELECT … JOIN`** para poblar las dims OLTP-derivadas. Aplanamiento de jerarquías (`categories` y `suppliers` aplastados en `dim_product`). Self-join sobre `employees.reports_to` para `dim_employee`.
- **Resolución natural→surrogate keys** en `fact_sales`: el patrón central del star schema en código.
- **Tipo fixes durante el ETL**: `REAL` → `NUMERIC(10,2)` con `ROUND` para corregir la imprecisión binaria del origen.
- **Verificación cross-OLTP/DWH**: `SUM(quantity)` y `SUM(line_total)` consistentes entre las dos representaciones.

## :books: Material

> Por publicar.

Scripts de referencia en [`../scripts/`](../scripts/).
