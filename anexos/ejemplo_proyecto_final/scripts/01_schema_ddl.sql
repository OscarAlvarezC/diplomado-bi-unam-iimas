-- =============================================================================
-- Ejemplo proyecto final — Calidad del aire CDMX
-- =============================================================================
-- Schema: aire_dwh
-- Grano de la fact: una fila por (estación × contaminante × hora)
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS aire_dwh;
SET search_path TO aire_dwh;

-- -----------------------------------------------------------------------------
-- DIMENSIONES
-- -----------------------------------------------------------------------------

CREATE TABLE dim_date (
    date_key            INT         PRIMARY KEY,   -- smart key YYYYMMDD
    full_date           DATE        NOT NULL UNIQUE,
    year                SMALLINT    NOT NULL,
    quarter             SMALLINT    NOT NULL,
    month_number        SMALLINT    NOT NULL,
    month_name          VARCHAR(10) NOT NULL,
    day_of_month        SMALLINT    NOT NULL,
    day_of_week_number  SMALLINT    NOT NULL,
    day_of_week_name    VARCHAR(10) NOT NULL,
    is_weekend          BOOLEAN     NOT NULL
);

CREATE TABLE dim_hour (
    hour_key    SMALLINT    PRIMARY KEY,    -- 0..23, smart key
    hour        SMALLINT    NOT NULL UNIQUE,
    banda       VARCHAR(12) NOT NULL        -- madrugada, mañana, tarde, noche
);

CREATE TABLE dim_station (
    station_key   INT         GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    station_code  VARCHAR(5)  NOT NULL UNIQUE,    -- código RAMA (e.g. MER, PED)
    station_name  VARCHAR(80) NOT NULL,
    alcaldia      VARCHAR(40),
    latitude      NUMERIC(9, 6),
    longitude     NUMERIC(9, 6),
    altitud_msnm  SMALLINT,
    tipo_zona     VARCHAR(20)                     -- urbana, suburbana, rural
);

CREATE TABLE dim_pollutant (
    pollutant_key   INT          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code            VARCHAR(8)   NOT NULL UNIQUE, -- PM25, PM10, O3, NO2, SO2, CO
    name            VARCHAR(40)  NOT NULL,
    unit            VARCHAR(10)  NOT NULL,        -- µg/m³, ppm, ppb
    who_safe_limit  NUMERIC(8,2),                 -- guía OMS 2021
    nom_safe_limit  NUMERIC(8,2),                 -- norma oficial mexicana
    descripcion     TEXT
);

-- -----------------------------------------------------------------------------
-- FACT
-- -----------------------------------------------------------------------------

CREATE TABLE fact_mediciones (
    medicion_id     BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key        INT          NOT NULL REFERENCES dim_date(date_key),
    hour_key        SMALLINT     NOT NULL REFERENCES dim_hour(hour_key),
    station_key     INT          NOT NULL REFERENCES dim_station(station_key),
    pollutant_key   INT          NOT NULL REFERENCES dim_pollutant(pollutant_key),
    valor           NUMERIC(8,2),
    is_valid        BOOLEAN      NOT NULL DEFAULT TRUE
);

-- Índices para queries analíticas
CREATE INDEX idx_fact_station_pollutant ON fact_mediciones(station_key, pollutant_key);
CREATE INDEX idx_fact_date              ON fact_mediciones(date_key);
CREATE INDEX idx_fact_pollutant_date    ON fact_mediciones(pollutant_key, date_key) WHERE is_valid;

-- =============================================================================
-- VERIFICACIÓN
-- =============================================================================
-- Listar tablas creadas:
--   SELECT table_name FROM information_schema.tables WHERE table_schema = 'aire_dwh';
--   Esperado: dim_date, dim_hour, dim_station, dim_pollutant, fact_mediciones
