-- =============================================================================
-- Airbnb CDMX — Schema y DDL (bronze / landing)
-- =============================================================================
-- Crea el schema `airbnb` dentro de la base `northwind` y las dos tablas
-- de bronze:
--   - listings     (79 columnas TEXT — réplica fiel del CSV)
--   - neighbourhoods   (16 alcaldías CDMX, tabla limpia con PK)
--
-- En este módulo solo se construye la capa bronze. Una eventual silver
-- (con tipos correctos y JSONB para amenities y host_verifications) tendría
-- nombre distinto (e.g., listings_clean) para no chocar con esta tabla; queda
-- fuera del alcance del temario.
--
-- Conteos esperados tras la carga (snapshot Inside Airbnb 2025-09-27):
--   listings    = 27 051
--   neighbourhoods  =     16
--
-- Decisiones de diseño:
--   * listings: TODAS las columnas TEXT, sin PK, sin NOT NULL. Es la
--     regla del "bronze layer" — preservar el contrato del origen 1:1,
--     que la carga no falle por un valor sucio. Las validaciones se hacen
--     al pasar a silver.
--   * neighbourhoods: como es referencia chica y limpia, sí lleva PK sobre
--     `neighbourhood`. `neighbourhood_group` se preserva (vacío en CDMX
--     porque no hay nivel administrativo superior), pero se mantiene para
--     compatibilidad con el schema multi-ciudad de Inside Airbnb.
--
-- Idempotencia:
--   * CREATE SCHEMA IF NOT EXISTS — seguro re-ejecutar.
--   * CREATE TABLE — falla si ya existe (intencional; reset explícito).
--   Para resetear limpio:
--     DROP TABLE IF EXISTS airbnb.listings, airbnb.neighbourhoods;
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS airbnb;

-- -----------------------------------------------------------------------------
-- listings — 79 columnas, todas TEXT (bronze layer)
-- -----------------------------------------------------------------------------
-- Orden y nombres exactos del CSV de Inside Airbnb. NO modificar el orden
-- de las columnas: facilita la carga directa con COPY o Import Wizard.
-- -----------------------------------------------------------------------------

CREATE TABLE airbnb.listings (
    id                                            TEXT,
    listing_url                                   TEXT,
    scrape_id                                     TEXT,
    last_scraped                                  TEXT,
    source                                        TEXT,
    name                                          TEXT,
    description                                   TEXT,
    neighborhood_overview                         TEXT,
    picture_url                                   TEXT,
    host_id                                       TEXT,
    host_url                                      TEXT,
    host_name                                     TEXT,
    host_since                                    TEXT,
    host_location                                 TEXT,
    host_about                                    TEXT,
    host_response_time                            TEXT,
    host_response_rate                            TEXT,
    host_acceptance_rate                          TEXT,
    host_is_superhost                             TEXT,
    host_thumbnail_url                            TEXT,
    host_picture_url                              TEXT,
    host_neighbourhood                            TEXT,
    host_listings_count                           TEXT,
    host_total_listings_count                     TEXT,
    host_verifications                            TEXT,
    host_has_profile_pic                          TEXT,
    host_identity_verified                        TEXT,
    neighbourhood                                 TEXT,
    neighbourhood_cleansed                        TEXT,
    neighbourhood_group_cleansed                  TEXT,
    latitude                                      TEXT,
    longitude                                     TEXT,
    property_type                                 TEXT,
    room_type                                     TEXT,
    accommodates                                  TEXT,
    bathrooms                                     TEXT,
    bathrooms_text                                TEXT,
    bedrooms                                      TEXT,
    beds                                          TEXT,
    amenities                                     TEXT,
    price                                         TEXT,
    minimum_nights                                TEXT,
    maximum_nights                                TEXT,
    minimum_minimum_nights                        TEXT,
    maximum_minimum_nights                        TEXT,
    minimum_maximum_nights                        TEXT,
    maximum_maximum_nights                        TEXT,
    minimum_nights_avg_ntm                        TEXT,
    maximum_nights_avg_ntm                        TEXT,
    calendar_updated                              TEXT,
    has_availability                              TEXT,
    availability_30                               TEXT,
    availability_60                               TEXT,
    availability_90                               TEXT,
    availability_365                              TEXT,
    calendar_last_scraped                         TEXT,
    number_of_reviews                             TEXT,
    number_of_reviews_ltm                         TEXT,
    number_of_reviews_l30d                        TEXT,
    availability_eoy                              TEXT,
    number_of_reviews_ly                          TEXT,
    estimated_occupancy_l365d                     TEXT,
    estimated_revenue_l365d                       TEXT,
    first_review                                  TEXT,
    last_review                                   TEXT,
    review_scores_rating                          TEXT,
    review_scores_accuracy                        TEXT,
    review_scores_cleanliness                     TEXT,
    review_scores_checkin                         TEXT,
    review_scores_communication                   TEXT,
    review_scores_location                        TEXT,
    review_scores_value                           TEXT,
    license                                       TEXT,
    instant_bookable                              TEXT,
    calculated_host_listings_count                TEXT,
    calculated_host_listings_count_entire_homes   TEXT,
    calculated_host_listings_count_private_rooms  TEXT,
    calculated_host_listings_count_shared_rooms   TEXT,
    reviews_per_month                             TEXT
);

-- -----------------------------------------------------------------------------
-- neighbourhoods — 16 alcaldías CDMX (tabla de referencia)
-- -----------------------------------------------------------------------------

CREATE TABLE airbnb.neighbourhoods (
    neighbourhood_group  TEXT,                            -- vacío para CDMX
    neighbourhood        TEXT NOT NULL PRIMARY KEY        -- nombre de la alcaldía
);

-- =============================================================================
-- VERIFICACIÓN (post-DDL, antes de cargar datos)
-- =============================================================================
-- 1. Schema creado
-- SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'airbnb';
-- Esperado: 1 fila
--
-- 2. Tablas creadas
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'airbnb' ORDER BY table_name;
-- Esperado: listings, neighbourhoods
--
-- 3. listings tiene 79 columnas (todas TEXT)
-- SELECT count(*) AS n_cols FROM information_schema.columns WHERE table_schema = 'airbnb' AND table_name = 'listings';
-- Esperado: 79
--
-- 4. Que efectivamente todas sean TEXT
-- SELECT data_type, count(*) FROM information_schema.columns WHERE table_schema = 'airbnb' AND table_name = 'listings' GROUP BY data_type;
-- Esperado: una sola fila — text | 79

-- =============================================================================
-- VERIFICACIÓN (después de cargar datos)
-- =============================================================================

-- SELECT 'listings'   AS tabla, count(*) FROM airbnb.listings UNION all SELECT 'neighbourhoods', count(*) FROM airbnb.neighbourhoods;
-- Esperado: 27051 / 16

-- SELECT count(*) AS con_descripcion_multilinea FROM airbnb.listings WHERE description LIKE E'%\n%'; 
-- 0
 
-- SELECT max(length(description)) FROM airbnb.listings; 
-- 1000

-- SELECT n.neighbourhood, count(l.id) AS listings FROM airbnb.neighbourhoods n LEFT JOIN airbnb.listings l ON l.neighbourhood_cleansed = n.neighbourhood GROUP BY n.neighbourhood ORDER BY listings DESC; 
-- Esperado: 16 filas, Cuauhtémoc liderando con ~12 514, distribución muy desigual.

-- SELECT data_type, count(*) FROM information_schema.columns WHERE table_schema = 'airbnb' AND table_name = 'listings' GROUP BY data_type; 
-- Esperado: una sola fila — text | 79


