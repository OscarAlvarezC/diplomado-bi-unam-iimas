-- =============================================================================
-- Sesión 02 — Ventas netas por categoría y mes en 1997, sobre el DWH
-- =============================================================================
-- Fuente: northwind_dwh (data warehouse, esquema estrella).
--
-- La misma pregunta sobre el modelo dimensional toca tres tablas:
--   - fact_sales  : una fila por línea de pedido. Ya trae line_total como
--                   columna generada — no hay que multiplicar a mano ni corregir
--                   tipos. Total ya está en NUMERIC(12,2).
--   - dim_product : la categoría está aplanada como atributo (category_name),
--                   sin tabla aparte para categories.
--   - dim_date    : el mes y el año son columnas explícitas. Filtrar por año o
--                   mes es leer una columna, no extraer de una fecha.
-- =============================================================================

SELECT
    p.category_name,
    d.month_number          AS mes,
    SUM(f.line_total)       AS ventas_netas
FROM northwind_dwh.fact_sales  f
JOIN northwind_dwh.dim_product p ON p.product_key  = f.product_key
JOIN northwind_dwh.dim_date    d ON d.date_key     = f.order_date_key
WHERE d.year = 1997
GROUP BY p.category_name, d.month_number
ORDER BY p.category_name, mes;

-- =============================================================================
-- Esperado: 96 filas (8 categorías × 12 meses).
--
-- Diferencias de centavos contra el OLTP son esperadas: el OLTP almacena
-- unit_price y discount como REAL (binario aproximado); el DWH los corrigió
-- a NUMERIC durante la carga. Los totales coinciden con tolerancia de centavos.
-- =============================================================================
