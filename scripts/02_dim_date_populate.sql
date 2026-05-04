-- =============================================================================
-- Northwind DWH — Población de dim_date
-- =============================================================================
-- Genera una fila por día entre 1996-01-01 y 1998-12-31 (1096 filas).
--
-- dim_date es la ÚNICA dimensión que NO se carga del OLTP — se construye
-- desde cero porque las fechas son universales y los atributos calendáricos
-- (trimestre, día de la semana, is_weekend) no están en la fuente.
--
-- Cobertura: el rango cubre todos los order_date / required_date / shipped_date
-- de Northwind con buffer. Los pedidos reales van de 1996-07-04 a 1998-05-06.
-- Se usan años calendarios completos (convención DW: facilita queries por año
-- y trimestre que asumen rangos cerrados).
-- =============================================================================

INSERT INTO northwind_dwh.dim_date (
    date_key, full_date, year, quarter, month_number, month_name,
    week_of_year, day_of_month, day_of_week_number, day_of_week_name, is_weekend
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INT                  AS date_key,
    d::date                                       AS full_date,
    EXTRACT(YEAR    FROM d)::SMALLINT            AS year,
    EXTRACT(QUARTER FROM d)::SMALLINT            AS quarter,
    EXTRACT(MONTH   FROM d)::SMALLINT            AS month_number,
    CASE EXTRACT(MONTH FROM d)::INT
        WHEN  1 THEN 'enero'      WHEN  2 THEN 'febrero'
        WHEN  3 THEN 'marzo'      WHEN  4 THEN 'abril'
        WHEN  5 THEN 'mayo'       WHEN  6 THEN 'junio'
        WHEN  7 THEN 'julio'      WHEN  8 THEN 'agosto'
        WHEN  9 THEN 'septiembre' WHEN 10 THEN 'octubre'
        WHEN 11 THEN 'noviembre'  WHEN 12 THEN 'diciembre'
    END                                           AS month_name,
    EXTRACT(WEEK   FROM d)::SMALLINT             AS week_of_year,
    EXTRACT(DAY    FROM d)::SMALLINT             AS day_of_month,
    EXTRACT(ISODOW FROM d)::SMALLINT             AS day_of_week_number,
    CASE EXTRACT(ISODOW FROM d)::INT
        WHEN 1 THEN 'lunes'     WHEN 2 THEN 'martes'
        WHEN 3 THEN 'miércoles' WHEN 4 THEN 'jueves'
        WHEN 5 THEN 'viernes'   WHEN 6 THEN 'sábado'
        WHEN 7 THEN 'domingo'
    END                                           AS day_of_week_name,
    EXTRACT(ISODOW FROM d) IN (6, 7)             AS is_weekend
FROM generate_series(
    '1996-01-01'::date,
    '1998-12-31'::date,
    '1 day'::interval
) AS d;


-- =============================================================================
-- VERIFICACIÓN
-- =============================================================================
-- 1. Conteo total
-- SELECT count(*) FROM northwind_dwh.dim_date;
-- Esperado: 1096
--
-- 2. Rango cubierto
-- SELECT min(full_date), max(full_date) FROM northwind_dwh.dim_date;
-- Esperado: 1996-01-01 | 1998-12-31
--
-- 3. No hay date_key duplicados
-- SELECT count(*) - count(DISTINCT date_key) FROM northwind_dwh.dim_date;
-- Esperado: 0
--
-- 4. Inspección visual de los primeros días
-- SELECT * FROM northwind_dwh.dim_date ORDER BY date_key LIMIT 7;
-- Verificar:
--   - 1996-01-01 fue lunes (ISODOW=1)
--   - month_name='enero', day_of_week_name='lunes'
--   - is_weekend=false para días de semana, true para sáb/dom
--
-- 5. Sanity check de is_weekend
-- SELECT day_of_week_name, count(*), bool_and(is_weekend) AS marcado FROM northwind_dwh.dim_date GROUP BY day_of_week_name;
-- Esperado: sábado y domingo con is_weekend=true; resto con false.
