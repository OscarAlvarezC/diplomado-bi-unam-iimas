-- =============================================================================
-- Poblar dim_date y dim_hour
-- =============================================================================
-- Rango 2023 completo + las 24 horas con su banda.
-- =============================================================================

SET search_path TO aire_dwh;

-- -----------------------------------------------------------------------------
-- dim_date (365 filas para 2023)
-- -----------------------------------------------------------------------------

INSERT INTO dim_date (
    date_key, full_date, year, quarter, month_number, month_name,
    day_of_month, day_of_week_number, day_of_week_name, is_weekend
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INT                AS date_key,
    d                                           AS full_date,
    EXTRACT(year    FROM d)::SMALLINT          AS year,
    EXTRACT(quarter FROM d)::SMALLINT          AS quarter,
    EXTRACT(month   FROM d)::SMALLINT          AS month_number,
    CASE EXTRACT(month FROM d)
        WHEN 1  THEN 'Enero'    WHEN 2  THEN 'Febrero'   WHEN 3  THEN 'Marzo'
        WHEN 4  THEN 'Abril'    WHEN 5  THEN 'Mayo'      WHEN 6  THEN 'Junio'
        WHEN 7  THEN 'Julio'    WHEN 8  THEN 'Agosto'    WHEN 9  THEN 'Septiembre'
        WHEN 10 THEN 'Octubre'  WHEN 11 THEN 'Noviembre' WHEN 12 THEN 'Diciembre'
    END                                         AS month_name,
    EXTRACT(day    FROM d)::SMALLINT           AS day_of_month,
    EXTRACT(isodow FROM d)::SMALLINT           AS day_of_week_number,
    CASE EXTRACT(isodow FROM d)
        WHEN 1 THEN 'Lunes'   WHEN 2 THEN 'Martes'  WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'  WHEN 5 THEN 'Viernes' WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo'
    END                                         AS day_of_week_name,
    EXTRACT(isodow FROM d) IN (6, 7)            AS is_weekend
FROM generate_series('2023-01-01'::DATE, '2023-12-31'::DATE, '1 day') AS d;

-- -----------------------------------------------------------------------------
-- dim_hour (24 filas con banda)
-- -----------------------------------------------------------------------------

INSERT INTO dim_hour (hour_key, hour, banda)
SELECT
    h                                           AS hour_key,
    h                                           AS hour,
    CASE
        WHEN h BETWEEN  0 AND  5 THEN 'Madrugada'
        WHEN h BETWEEN  6 AND 11 THEN 'Mañana'
        WHEN h BETWEEN 12 AND 17 THEN 'Tarde'
        ELSE 'Noche'
    END                                         AS banda
FROM generate_series(0, 23) AS h;

-- =============================================================================
-- VERIFICACIÓN
-- =============================================================================
-- SELECT count(*) FROM aire_dwh.dim_date;   -- esperado: 365
-- SELECT count(*) FROM aire_dwh.dim_hour;   -- esperado: 24
-- SELECT banda, count(*) FROM aire_dwh.dim_hour GROUP BY banda;
--   Madrugada=6, Mañana=6, Tarde=6, Noche=6
