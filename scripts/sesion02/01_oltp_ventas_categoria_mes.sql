-- =============================================================================
-- Sesión 02 — Ventas netas por categoría y mes en 1997, sobre el OLTP
-- =============================================================================
-- Fuente: northwind_oltp (sistema transaccional, normalizado en 3NF).
--
-- La pregunta de negocio cruza cuatro tablas distintas:
--   - order_details : la línea de pedido con quantity, unit_price y discount
--   - orders        : el pedido con order_date (necesario para filtrar 1997)
--   - products      : enlaza el product_id a su category_id
--   - categories    : aporta el category_name legible para humanos
--
-- Además hay que:
--   - calcular la venta neta a mano: quantity * unit_price * (1 - discount)
--   - corregir la imprecisión de REAL del OLTP con ROUND(...::NUMERIC, 2)
--   - extraer el mes con EXTRACT(MONTH FROM order_date)
--   - filtrar el año con EXTRACT(YEAR FROM order_date) = 1997
-- =============================================================================

SELECT
    c.category_name,
    EXTRACT(MONTH FROM o.order_date)::INT                                         AS mes,
    ROUND(SUM(od.unit_price::NUMERIC * od.quantity * (1 - od.discount::NUMERIC)),
          2)                                                                      AS ventas_netas
FROM northwind_oltp.order_details od
JOIN northwind_oltp.orders        o ON o.order_id    = od.order_id
JOIN northwind_oltp.products      p ON p.product_id  = od.product_id
JOIN northwind_oltp.categories    c ON c.category_id = p.category_id
WHERE EXTRACT(YEAR FROM o.order_date) = 1997
GROUP BY c.category_name, EXTRACT(MONTH FROM o.order_date)
ORDER BY c.category_name, mes;

-- =============================================================================
-- Esperado: 96 filas (8 categorías × 12 meses).
-- =============================================================================
