-- =============================================================================
-- Northwind DWH — Población de las 4 dimensiones derivadas del OLTP
-- =============================================================================
-- Carga dim_customer, dim_product, dim_employee, dim_shipper desde
-- northwind_oltp mediante INSERT … SELECT … JOIN.
--
-- Es el ETL hecho a mano en SQL puro: mueve datos, aplana jerarquías y
-- aplica fixes de tipo. El mismo trabajo se reimplementará en Python en
-- el Bloque 3 — aquí se muestra primero el "qué" antes que el "con qué".
--
-- Conteos esperados tras la carga (según pthom dump):
--   dim_customer = 91
--   dim_product  = 77
--   dim_employee = 9
--   dim_shipper  = 6   (la Northwind original solo tiene 3; pthom añadió 3)
--
-- NO se cargan unit_price ni columnas de inventario en dim_product:
-- son métricas operativas (cambian); en el DW interesa el contexto
-- descriptivo estable. El precio histórico de la venta vive en fact_sales.
--
-- Idempotencia: re-ejecutar dispara violación de UNIQUE en las natural keys.
-- Para reiniciar limpio (sin tocar la fact, que aún no existe):
--   TRUNCATE TABLE northwind_dwh.dim_customer, northwind_dwh.dim_product,
--                  northwind_dwh.dim_employee, northwind_dwh.dim_shipper
--   RESTART IDENTITY;
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- dim_customer (91 filas) — mapeo directo desde customers
-- -----------------------------------------------------------------------------

INSERT INTO northwind_dwh.dim_customer (
    customer_id, company_name, contact_name, contact_title,
    city, region, postal_code, country
)
SELECT
    customer_id, company_name, contact_name, contact_title,
    city, region, postal_code, country
FROM northwind_oltp.customers;

-- -----------------------------------------------------------------------------
-- dim_product (77 filas) — aplana products + categories + suppliers
-- -----------------------------------------------------------------------------
-- INNER JOIN porque en Northwind todos los productos tienen categoría y
-- proveedor (NOT NULL en el origen). En un ETL real con datos sucios,
-- LEFT JOIN sería la defensa: preserva productos huérfanos con
-- category_name = NULL para inspección y limpieza posterior.
--
-- Cast de discontinued: el OLTP guarda smallint 0/1; el DWH lo expresa
-- como BOOLEAN para queries más legibles (`WHERE discontinued`).
-- -----------------------------------------------------------------------------

INSERT INTO northwind_dwh.dim_product (
    product_id, product_name,
    category_id, category_name, category_desc,
    supplier_id, supplier_name, supplier_country, supplier_city,
    discontinued
)
SELECT
    p.product_id,
    p.product_name,
    c.category_id,
    c.category_name,
    c.description,
    s.supplier_id,
    s.company_name,
    s.country,
    s.city,
    (p.discontinued <> 0)::BOOLEAN
FROM      northwind_oltp.products   p
JOIN      northwind_oltp.categories c ON c.category_id = p.category_id
JOIN      northwind_oltp.suppliers  s ON s.supplier_id = p.supplier_id;

-- -----------------------------------------------------------------------------
-- dim_employee (9 filas) — full_name concatenado, reports_to_name por self-join
-- -----------------------------------------------------------------------------
-- LEFT JOIN sobre la self-FK reports_to: el CEO de Northwind tiene
-- reports_to IS NULL y se perdería con INNER JOIN. Patrón general
-- en jerarquías auto-referenciales: LEFT JOIN para conservar la raíz.
--
-- 'e' es el empleado; 'm' es su manager (mismo physical table, alias distinto).
-- -----------------------------------------------------------------------------

INSERT INTO northwind_dwh.dim_employee (
    employee_id, full_name, title, city, country, region,
    hire_date, reports_to_name
)
SELECT
    e.employee_id,
    e.first_name || ' ' || e.last_name             AS full_name,
    e.title,
    e.city,
    e.country,
    e.region,
    e.hire_date,
    m.first_name || ' ' || m.last_name             AS reports_to_name
FROM      northwind_oltp.employees e
LEFT JOIN northwind_oltp.employees m ON m.employee_id = e.reports_to;

-- -----------------------------------------------------------------------------
-- dim_shipper (6 filas) — mapeo directo
-- -----------------------------------------------------------------------------

INSERT INTO northwind_dwh.dim_shipper (
    shipper_id, company_name, phone
)
SELECT
    shipper_id, company_name, phone
FROM northwind_oltp.shippers;

COMMIT;

-- =============================================================================
-- VERIFICACIÓN
-- =============================================================================
-- 1. Conteos por dim (deben coincidir con el origen)
-- SELECT 'dim_customer' AS dim, count(*) FROM northwind_dwh.dim_customer
-- UNION ALL
-- SELECT 'dim_product',         count(*) FROM northwind_dwh.dim_product
-- UNION ALL
-- SELECT 'dim_employee',        count(*) FROM northwind_dwh.dim_employee
-- UNION ALL
-- SELECT 'dim_shipper',         count(*) FROM northwind_dwh.dim_shipper;
-- Esperado: 91 / 77 / 9 / 6
--
-- 2. CEO sin manager (LEFT JOIN funcionó)
-- SELECT employee_id, full_name, reports_to_name FROM northwind_dwh.dim_employee WHERE reports_to_name IS NULL;
-- Esperado: 1 fila — el CEO de Northwind (Andrew Fuller) con reports_to_name = NULL
--
-- 3. Surrogate keys consecutivas desde 1
-- SELECT min(customer_key), max(customer_key), count(*) FROM northwind_dwh.dim_customer;
-- Esperado: 1 | 91 | 91
--
-- 4. No hay nulls por aplanamiento defectuoso en dim_product
-- SELECT count(*) FROM northwind_dwh.dim_product WHERE category_name IS NULL OR supplier_name IS NULL;
-- Esperado: 0
--
-- 5. Cast de discontinued correcto
-- SELECT discontinued, count(*) FROM northwind_dwh.dim_product GROUP BY discontinued;
-- Esperado: dos filas (true / false), suma = 77
