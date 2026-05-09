# Scripts — Sesión 02

Dos queries que responden la **misma pregunta de negocio** sobre dos modelos distintos: el OLTP normalizado en 3NF y el DWH en esquema estrella. Sirven para la práctica que cierra la sesión.

| # | Script | Fuente | Tablas tocadas |
|---|---|---|---|
| 01 | `01_oltp_ventas_categoria_mes.sql` | `northwind_oltp` | `order_details`, `orders`, `products`, `categories` |
| 02 | `02_dwh_ventas_categoria_mes.sql`  | `northwind_dwh`  | `fact_sales`, `dim_product`, `dim_date` |

**Pregunta común:** *ventas netas por categoría de producto y por mes, durante 1997.*

Las dos producen 96 filas (8 categorías × 12 meses). Los totales coinciden hasta diferencias de centavos por la corrección REAL → NUMERIC aplicada en la carga del DWH.

Se ejecutan en DBeaver con la conexión `aurora-mod4` ya configurada en la Sesión 01.
