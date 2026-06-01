-- =============================================================================
-- Queries analíticas con SQL avanzado
-- =============================================================================
-- Cinco queries que cubren las técnicas del módulo:
--   1. CTE + ranking simple
--   2. Window function (promedio móvil)
--   3. COUNT FILTER (agregación condicional)
--   4. PERCENTILE_CONT (funciones predefinidas no triviales)
--   5. CTE + LAG (window comparativa)
-- =============================================================================

SET search_path TO aire_dwh;


-- -----------------------------------------------------------------------------
-- 1. Top 5 estaciones por PM2.5 promedio (CTE + ranking simple)
-- -----------------------------------------------------------------------------

WITH promedios AS (
    SELECT
        ds.station_name,
        ds.alcaldia,
        ROUND(AVG(fm.valor), 2)            AS pm25_promedio,
        COUNT(*)                           AS lecturas
    FROM      aire_dwh.fact_mediciones fm
    JOIN      aire_dwh.dim_pollutant   dp USING (pollutant_key)
    JOIN      aire_dwh.dim_station     ds USING (station_key)
    WHERE     dp.code = 'PM25' AND fm.is_valid
    GROUP BY  ds.station_name, ds.alcaldia
)
SELECT *
FROM      promedios
ORDER BY  pm25_promedio DESC
LIMIT 5;


-- -----------------------------------------------------------------------------
-- 2. Promedio móvil de 24h (window function con frame de 24 filas)
-- -----------------------------------------------------------------------------

SELECT
    ds.station_name,
    fm.date_key,
    fm.hour_key,
    fm.valor                                       AS valor_horario,
    ROUND(AVG(fm.valor) OVER (
        PARTITION BY fm.station_key, fm.pollutant_key
        ORDER BY    fm.date_key, fm.hour_key
        ROWS BETWEEN 23 PRECEDING AND CURRENT ROW
    ), 2)                                          AS promedio_movil_24h
FROM      aire_dwh.fact_mediciones fm
JOIN      aire_dwh.dim_station    ds USING (station_key)
JOIN      aire_dwh.dim_pollutant  dp USING (pollutant_key)
WHERE     dp.code = 'PM25'
  AND     fm.is_valid
  AND     ds.station_code = 'MER'          -- ejemplo: Merced
ORDER BY  fm.date_key, fm.hour_key
LIMIT 50;


-- -----------------------------------------------------------------------------
-- 3. % horas en violación del límite OMS por estación y mes (COUNT FILTER)
-- -----------------------------------------------------------------------------

SELECT
    ds.station_name,
    dd.month_name,
    COUNT(*)                                                AS horas_validas,
    COUNT(*) FILTER (WHERE fm.valor > dp.who_safe_limit)    AS horas_violacion,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE fm.valor > dp.who_safe_limit) / COUNT(*),
        1
    )                                                       AS pct_violacion
FROM      aire_dwh.fact_mediciones fm
JOIN      aire_dwh.dim_station    ds USING (station_key)
JOIN      aire_dwh.dim_pollutant  dp USING (pollutant_key)
JOIN      aire_dwh.dim_date       dd USING (date_key)
WHERE     dp.code = 'PM25' AND fm.is_valid
GROUP BY  ds.station_name, dd.month_number, dd.month_name
HAVING    COUNT(*) > 500                                    -- estaciones con cobertura
ORDER BY  pct_violacion DESC
LIMIT 20;


-- -----------------------------------------------------------------------------
-- 4. Distribución por banda horaria (mediana + percentil 95)
-- -----------------------------------------------------------------------------

SELECT
    dh.banda,
    COUNT(*)                                                          AS lecturas,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY fm.valor)            AS mediana,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY fm.valor)            AS p95,
    ROUND(AVG(fm.valor), 2)                                           AS promedio
FROM      aire_dwh.fact_mediciones fm
JOIN      aire_dwh.dim_pollutant  dp USING (pollutant_key)
JOIN      aire_dwh.dim_hour       dh USING (hour_key)
WHERE     dp.code = 'PM25' AND fm.is_valid
GROUP BY  dh.banda
ORDER BY  CASE dh.banda
            WHEN 'Madrugada' THEN 1
            WHEN 'Mañana'    THEN 2
            WHEN 'Tarde'     THEN 3
            WHEN 'Noche'     THEN 4
          END;


-- -----------------------------------------------------------------------------
-- 5. Estaciones con peor empeoramiento mes a mes (CTE + LAG)
-- -----------------------------------------------------------------------------

WITH mensual AS (
    SELECT
        ds.station_name,
        dd.month_number,
        dd.month_name,
        ROUND(AVG(fm.valor), 2) AS promedio_mes
    FROM      aire_dwh.fact_mediciones fm
    JOIN      aire_dwh.dim_pollutant  dp USING (pollutant_key)
    JOIN      aire_dwh.dim_station    ds USING (station_key)
    JOIN      aire_dwh.dim_date       dd USING (date_key)
    WHERE     dp.code = 'PM25' AND fm.is_valid
    GROUP BY  ds.station_name, dd.month_number, dd.month_name
)
SELECT
    station_name,
    month_name                                                     AS mes,
    promedio_mes,
    LAG(promedio_mes)  OVER (PARTITION BY station_name ORDER BY month_number) AS mes_anterior,
    promedio_mes - LAG(promedio_mes)
                   OVER (PARTITION BY station_name ORDER BY month_number)     AS delta
FROM      mensual
WHERE     promedio_mes IS NOT NULL
ORDER BY  delta DESC NULLS LAST
LIMIT 10;
