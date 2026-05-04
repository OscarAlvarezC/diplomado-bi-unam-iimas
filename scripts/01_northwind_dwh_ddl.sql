-- =============================================================================
-- Northwind DWH — DDL del esquema estrella
-- =============================================================================
-- Schema:   northwind_dwh
-- Modelo:   Star (5 dimensiones + 1 fact)
-- Grano:    una fila de fact_sales = una línea de pedido (order_details)
-- Filas esperadas tras carga: fact_sales = 2155
--
-- Patrones Kimball aplicados:
--   - Surrogate keys (GENERATED ALWAYS AS IDENTITY) en las dims
--   - Smart key (YYYYMMDD) en dim_date, sin surrogate
--   - Degenerate dimension: order_id vive en la fact, sin tabla propia
--   - Role-playing: tres FKs distintas hacia el mismo dim_date
--                   (order_date_key, required_date_key, shipped_date_key)
--   - Generated columns para medidas calculadas (extended_price, line_total)
--
-- Prerrequisito: schema northwind_dwh ya existe (renombrado desde northwind_dw).
-- Ejecutar este script desde una sesión SQL conectada a la base `northwind`.
-- =============================================================================

CREATE SCHEMA northwind_dwh;
SET search_path TO northwind_dwh;

-- =============================================================================
-- DIMENSIONES
-- =============================================================================

CREATE TABLE dim_customer (
    customer_key   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id    CHAR(5)      NOT NULL UNIQUE,   -- natural key (e.g. 'ALFKI')
    company_name   VARCHAR(40)  NOT NULL,
    contact_name   VARCHAR(30),
    contact_title  VARCHAR(30),
    city           VARCHAR(15),
    region         VARCHAR(15),
    postal_code    VARCHAR(10),
    country        VARCHAR(15)
);

CREATE TABLE dim_product (
    product_key       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id        SMALLINT    NOT NULL UNIQUE,
    product_name      VARCHAR(40) NOT NULL,
    category_id       SMALLINT,
    category_name     VARCHAR(15),
    category_desc     TEXT,
    supplier_id       SMALLINT,
    supplier_name     VARCHAR(40),
    supplier_country  VARCHAR(15),
    supplier_city     VARCHAR(15),
    discontinued      BOOLEAN     NOT NULL
);

CREATE TABLE dim_employee (
    employee_key     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id      SMALLINT    NOT NULL UNIQUE,
    full_name        VARCHAR(40) NOT NULL,
    title            VARCHAR(30),
    city             VARCHAR(15),
    country          VARCHAR(15),
    region           VARCHAR(15),
    hire_date        DATE,
    reports_to_name  VARCHAR(40)             -- jerarquía aplanada (sin self-FK)
);

CREATE TABLE dim_shipper (
    shipper_key   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shipper_id    SMALLINT    NOT NULL UNIQUE,
    company_name  VARCHAR(40) NOT NULL,
    phone         VARCHAR(24)
);

CREATE TABLE dim_date (
    date_key            INT         PRIMARY KEY,    -- smart key: YYYYMMDD
    full_date           DATE        NOT NULL UNIQUE,
    year                SMALLINT    NOT NULL,
    quarter             SMALLINT    NOT NULL,       -- 1..4
    month_number        SMALLINT    NOT NULL,       -- 1..12
    month_name          VARCHAR(10) NOT NULL,
    week_of_year        SMALLINT    NOT NULL,
    day_of_month        SMALLINT    NOT NULL,
    day_of_week_number  SMALLINT    NOT NULL,       -- 1..7  (ISO: lunes=1)
    day_of_week_name    VARCHAR(10) NOT NULL,
    is_weekend          BOOLEAN     NOT NULL
);

-- =============================================================================
-- FACT
-- =============================================================================

CREATE TABLE fact_sales (
    sale_key            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- degenerate dimension (sin tabla propia)
    order_id            SMALLINT NOT NULL,

    -- foreign keys a dimensiones
    customer_key        INT NOT NULL REFERENCES dim_customer(customer_key),
    product_key         INT NOT NULL REFERENCES dim_product(product_key),
    employee_key        INT NOT NULL REFERENCES dim_employee(employee_key),
    shipper_key         INT          REFERENCES dim_shipper(shipper_key),    -- NULL si aún no se envía

    -- role-playing: tres FKs al MISMO dim_date
    order_date_key      INT NOT NULL REFERENCES dim_date(date_key),
    required_date_key   INT NOT NULL REFERENCES dim_date(date_key),
    shipped_date_key    INT          REFERENCES dim_date(date_key),          -- NULL si aún no se envía

    -- medidas
    quantity            SMALLINT      NOT NULL,
    unit_price          NUMERIC(10,2) NOT NULL,
    discount            NUMERIC(4,2)  NOT NULL DEFAULT 0,

    -- medidas calculadas (PostgreSQL las mantiene automáticamente)
    extended_price      NUMERIC(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    line_total          NUMERIC(12,2) GENERATED ALWAYS AS (quantity * unit_price * (1 - discount)) STORED
);

-- =============================================================================
-- VERIFICACIÓN
-- =============================================================================

-- Listar las 6 tablas recién creadas:
-- SELECT table_name
-- FROM information_schema.tables
-- WHERE table_schema = 'northwind_dwh'
-- ORDER BY table_name;
-- Esperado: dim_customer, dim_date, dim_employee, dim_product, dim_shipper, fact_sales
