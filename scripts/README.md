# Scripts SQL

Scripts ejecutables que construyen el data warehouse de Northwind y el schema de Airbnb. Diseñados para correrse en **PostgreSQL 17** sobre la base `northwind` (creada en `setup/01_cluster_aurora.md`).

## Orden de ejecución

Los nombres tienen prefijo numérico (`01_`, `02_`, ...) que indica el orden estricto de ejecución. Algunos dependen de los anteriores; saltarse uno produce errores de FK o tabla inexistente.

| # | Script | Lo que hace | Filas resultantes |
|---|---|---|---|
| 01 | `01_northwind_dwh_ddl.sql` | Crea schema `northwind_dwh` + 5 dimensiones + `fact_sales` (todas vacías). Aplica patrones Kimball: surrogate keys, smart key en dim_date, role-playing, generated columns. | 6 tablas vacías |
| 02 | `02_dim_date_populate.sql` | Genera `dim_date` con `generate_series` para 1996-01-01 a 1998-12-31. Smart key YYYYMMDD, ISO weekday, nombres en español. | 1 096 |
| 03 | `03_dims_populate.sql` | Pobla `dim_customer`, `dim_product`, `dim_employee`, `dim_shipper` desde `northwind_oltp` con `INSERT … SELECT … JOIN`. Aplana jerarquías (categories+suppliers en dim_product) y resuelve self-FK (reports_to). | 91 / 77 / 9 / 6 |
| 04 | `04_fact_populate.sql` | Pobla `fact_sales` desde `order_details JOIN orders`, **resolviendo cada natural key a su surrogate key** vía joins con cada dim. Aplica `ROUND(...::NUMERIC, 2)` para corregir imprecisión de REAL del origen. | 2 155 |
| 05 | `05_airbnb_ddl.sql` | Crea schema `airbnb` + tabla `listings` (79 cols TEXT) + tabla `neighbourhoods`. **No carga datos** — los CSVs se cargan vía DBeaver Import Wizard. | 2 tablas vacías |

## Cómo ejecutar

Cada script se ejecuta como bloque completo en DBeaver (no fila por fila):

1. **File → Open File** → selecciona el script.
2. **Alt+X** (botón "Execute SQL Script"). NO uses `Ctrl+Enter` — eso solo ejecuta la sentencia bajo el cursor.
3. Lee la sección "VERIFICACIÓN" comentada al final de cada archivo y ejecuta esas queries para confirmar que el paso cerró bien.

## Prerequisitos

- Schema `northwind_oltp` ya cargado (ver `setup/03_northwind_oltp.md`).
- Schema `northwind_dwh` creado (`CREATE SCHEMA IF NOT EXISTS northwind_dwh;`).
- Schema `airbnb` se crea desde el script 05.

## Scripts por sesión

A partir de la Sesión 02, las queries que se ejecutan en clase viven en subdirectorios numerados:

- [`sesion02/`](./sesion02/) — comparación OLTP vs DWH para la misma pregunta analítica.

## Reset / Re-ejecución

Los scripts no son idempotentes. Re-correr los populate sin truncar primero produce duplicados o violaciones de UNIQUE. Para reiniciar limpio el DWH:

```sql
TRUNCATE TABLE northwind_dwh.fact_sales,
               northwind_dwh.dim_customer,
               northwind_dwh.dim_product,
               northwind_dwh.dim_employee,
               northwind_dwh.dim_shipper,
               northwind_dwh.dim_date
RESTART IDENTITY CASCADE;
```

Después corres scripts 02, 03, 04 en orden. El script 01 (DDL) solo se vuelve a correr si dropeaste el schema entero.
