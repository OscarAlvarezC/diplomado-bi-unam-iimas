-- =============================================================================
-- Northwind DWH — Población de fact_sales
-- =============================================================================
-- Carga la tabla de hechos desde northwind_oltp.order_details + orders,
-- resolviendo cada natural key a su surrogate key vía join con la dim
-- correspondiente. Es el patrón central del star schema.
--
-- Conteo esperado: 2 155 filas (= total de order_details).
--
-- Cinco joins:
--   - dim_customer  (resuelve customer_id  → customer_key)
--   - dim_product   (resuelve product_id   → product_key)
--   - dim_employee  (resuelve employee_id  → employee_key)
--   - dim_shipper   (resuelve ship_via     → shipper_key)   ← LEFT JOIN
--   - orders        (provee customer_id, employee_id, ship_via, fechas)
--
-- Las tres date_keys se calculan in-line con TO_CHAR — no joinea contra
-- dim_date porque la smart key YYYYMMDD se deriva directamente de la
-- fecha. shipped_date_key será NULL automáticamente si shipped_date es NULL.
--
-- Fixes de tipo: ROUND(unit_price::NUMERIC, 2) y ROUND(discount::NUMERIC, 2)
-- corrigen la imprecisión de REAL en el origen (REAL guarda 19.99 como
-- 19.989999771…; NUMERIC restaura la intención original con redondeo).
--
-- Columnas calculadas (extended_price, line_total) NO se insertan: PG las
-- mantiene automáticamente vía GENERATED ALWAYS AS … STORED.
--
-- Idempotencia: re-ejecutar duplicaría los datos (no hay UNIQUE en sale_key
-- aparte del PK identity). Para reiniciar limpio:
--   TRUNCATE TABLE northwind_dwh.fact_sales RESTART IDENTITY;
-- =============================================================================

BEGIN;

INSERT INTO northwind_dwh.fact_sales (
    order_id,
    customer_key, product_key, employee_key, shipper_key,
    order_date_key, required_date_key, shipped_date_key,
    quantity, unit_price, discount
)
SELECT
    od.order_id,
    dc.customer_key,
    dp.product_key,
    de.employee_key,
    ds.shipper_key,                                          -- NULL si pedido sin enviar
    TO_CHAR(o.order_date,    'YYYYMMDD')::INT  AS order_date_key,
    TO_CHAR(o.required_date, 'YYYYMMDD')::INT  AS required_date_key,
    TO_CHAR(o.shipped_date,  'YYYYMMDD')::INT  AS shipped_date_key,  -- NULL si NULL en origen
    od.quantity,
    ROUND(od.unit_price::NUMERIC, 2)           AS unit_price,
    ROUND(od.discount  ::NUMERIC, 2)           AS discount
FROM       northwind_oltp.order_details od
JOIN       northwind_oltp.orders        o   ON o.order_id     = od.order_id
JOIN       northwind_dwh.dim_customer   dc  ON dc.customer_id = o.customer_id
JOIN       northwind_dwh.dim_product    dp  ON dp.product_id  = od.product_id
JOIN       northwind_dwh.dim_employee   de  ON de.employee_id = o.employee_id
LEFT JOIN  northwind_dwh.dim_shipper    ds  ON ds.shipper_id  = o.ship_via;

COMMIT;

-- =============================================================================
-- VERIFICACIÓN
-- =============================================================================
-- 1. Conteo total
-- SELECT count(*) FROM northwind_dwh.fact_sales;
-- Esperado: 2155
--
-- 2. Asimetría de poblamiento entre shipper y shipped_date
-- SELECT
--   count(*) FILTER (WHERE shipper_key IS NULL)      AS sin_shipper,
--   count(*) FILTER (WHERE shipped_date_key IS NULL) AS sin_fecha_envio
-- FROM northwind_dwh.fact_sales;
-- Esperado:
--   sin_shipper = 0       (ship_via siempre poblado en el origen — decisión comercial
--                          al crear el pedido)
--   sin_fecha_envio = 73  (shipped_date se llena al despacho real; NULL en pedidos
--                          pendientes — evento operativo posterior)
-- En pthom Northwind hay 21 pedidos no enviados, lo que se traduce a varias decenas
-- de líneas en fact_sales (cada pedido tiene múltiples order_details).
-- Punto pedagógico: distintas columnas del mismo "evento" pueden poblarse en momentos
-- distintos del flujo de negocio (lifecycle de cada atributo).

-- Para confirmar consistencia con el origen:
-- SELECT count(*) FROM northwind_oltp.order_details od
-- JOIN northwind_oltp.orders o ON o.order_id = od.order_id
-- WHERE o.shipped_date IS NULL;
-- Debe coincidir con sin_fecha_envio.
--
-- 3. Coherencia con el origen — SUM(quantity)
-- SELECT
--   (SELECT SUM(quantity) FROM northwind_oltp.order_details) AS oltp,
--   (SELECT SUM(quantity) FROM northwind_dwh.fact_sales)     AS dwh;
-- Esperado: idénticos (51317 en Northwind clásico).
--
-- 4. SUM(line_total) — comparación con el cálculo en OLTP
-- SELECT
--   ROUND((SELECT SUM(quantity * unit_price * (1-discount))::NUMERIC FROM northwind_oltp.order_details), 2) AS oltp_redondeado,
--   (SELECT SUM(line_total) FROM northwind_dwh.fact_sales)                                                  AS dwh_exacto;
-- Esperado: muy cercanos. Pequeñas diferencias de centavos son ESPERADAS y demuestran
-- que la imprecisión de REAL en el origen se eliminó al pasar a NUMERIC en el DW.
--
-- 5. Generated columns funcionan
-- SELECT order_id, quantity, unit_price, discount, extended_price, line_total
-- FROM northwind_dwh.fact_sales LIMIT 5;
-- Esperado: extended_price = quantity*unit_price; line_total = ext * (1-discount).
--
-- 6. No hay surrogate keys NULL en columnas NOT NULL
-- SELECT count(*) FROM northwind_dwh.fact_sales
-- WHERE customer_key IS NULL OR product_key IS NULL OR employee_key IS NULL
--    OR order_date_key IS NULL OR required_date_key IS NULL;
-- Esperado: 0 (si hubiera, el INSERT habría fallado por la FK NOT NULL).
--
-- 7. Distribución por categoría — sanity check de toda la cadena de joins
-- SELECT dp.category_name, count(*) AS lineas, ROUND(SUM(fs.line_total), 2) AS ventas_netas
-- FROM northwind_dwh.fact_sales fs
-- JOIN northwind_dwh.dim_product dp USING (product_key)
-- GROUP BY dp.category_name ORDER BY ventas_netas DESC;
-- Esperado: 8 categorías, "Beverages" típicamente la más vendida.
--
-- SELECT                                                                                                           
--    c.category_name,
--    count(*) AS lineas,                                                                                            
--    ROUND(SUM(od.quantity * od.unit_price * (1 - od.discount))::NUMERIC, 2) AS ventas_netas
--  FROM northwind_oltp.order_details od                                                                             
--  JOIN northwind_oltp.products      p ON p.product_id  = od.product_id
--  JOIN northwind_oltp.categories    c ON c.category_id = p.category_id                                             
--  GROUP BY c.category_name                                        
--  ORDER BY ventas_netas DESC; 