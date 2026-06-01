-- =============================================================================
-- Poblar dim_station con las estaciones RAMA activas en 2023
-- =============================================================================
-- Fuente: directorio público de SIMAT.
-- Coordenadas verificadas con el portal de aire.cdmx.gob.mx.
-- =============================================================================

SET search_path TO aire_dwh;

INSERT INTO dim_station (station_code, station_name, alcaldia, latitude, longitude, altitud_msnm, tipo_zona) VALUES
    ('ACO', 'Acolman',                 'Acolman (EdoMex)',         19.635,  -98.912, 2236, 'Suburbana'),
    ('AJM', 'Ajusco Medio',             'Tlalpan',                  19.272,  -99.207, 2548, 'Suburbana'),
    ('AJU', 'Ajusco',                   'Tlalpan',                  19.155,  -99.163, 3010, 'Rural'),
    ('BJU', 'Benito Juárez',            'Benito Juárez',            19.371,  -99.158, 2280, 'Urbana'),
    ('CAM', 'Camarones',                'Azcapotzalco',             19.468,  -99.169, 2249, 'Urbana'),
    ('CCA', 'Centro de Ciencias Atmosféricas', 'Coyoacán',         19.326,  -99.176, 2273, 'Urbana'),
    ('CHO', 'Chalco',                   'Chalco (EdoMex)',          19.266,  -98.886, 2272, 'Suburbana'),
    ('COY', 'Coyoacán',                 'Coyoacán',                 19.350,  -99.158, 2300, 'Urbana'),
    ('CUA', 'Cuajimalpa',               'Cuajimalpa',               19.365,  -99.293, 2700, 'Urbana'),
    ('CUT', 'Cuautitlán',               'Cuautitlán (EdoMex)',      19.722,  -99.198, 2255, 'Suburbana'),
    ('FAC', 'FES Acatlán',              'Naucalpan (EdoMex)',       19.483,  -99.244, 2299, 'Urbana'),
    ('GAM', 'Gustavo A. Madero',        'Gustavo A. Madero',        19.491,  -99.094, 2257, 'Urbana'),
    ('HGM', 'Hospital General México',  'Cuauhtémoc',               19.412,  -99.152, 2234, 'Urbana'),
    ('INN', 'Investigaciones Nucleares','Ocoyoacac (EdoMex)',       19.293,  -99.388, 3025, 'Rural'),
    ('IZT', 'Iztacalco',                'Iztacalco',                19.384,  -99.117, 2235, 'Urbana'),
    ('LPR', 'La Presa',                 'Tlalnepantla (EdoMex)',    19.534,  -99.117, 2330, 'Urbana'),
    ('MER', 'Merced',                   'Cuauhtémoc',               19.424,  -99.119, 2245, 'Urbana'),
    ('MGH', 'Miguel Hidalgo',           'Miguel Hidalgo',           19.404,  -99.202, 2329, 'Urbana'),
    ('MON', 'Montecillo',               'Texcoco (EdoMex)',         19.460,  -98.902, 2252, 'Rural'),
    ('NEZ', 'Nezahualcóyotl',           'Nezahualcóyotl (EdoMex)',  19.395,  -99.028, 2233, 'Urbana'),
    ('PED', 'Pedregal',                 'Álvaro Obregón',           19.325,  -99.204, 2326, 'Urbana'),
    ('SAG', 'San Agustín',              'Ecatepec (EdoMex)',        19.532,  -99.030, 2240, 'Urbana'),
    ('SFE', 'Santa Fe',                 'Cuajimalpa',               19.357,  -99.262, 2599, 'Urbana'),
    ('TLA', 'Tlalnepantla',             'Tlalnepantla (EdoMex)',    19.529,  -99.205, 2320, 'Urbana'),
    ('TLI', 'Tultitlán',                'Tultitlán (EdoMex)',       19.602,  -99.177, 2240, 'Suburbana'),
    ('UAX', 'UAM Xochimilco',           'Coyoacán',                 19.305,  -99.103, 2247, 'Urbana'),
    ('UIZ', 'UAM Iztapalapa',           'Iztapalapa',               19.360,  -99.074, 2222, 'Urbana'),
    ('VIF', 'Villa de las Flores',      'Coacalco (EdoMex)',        19.659,  -99.097, 2242, 'Suburbana'),
    ('XAL', 'Xalostoc',                 'Ecatepec (EdoMex)',        19.526,  -99.082, 2235, 'Urbana');

-- =============================================================================
-- VERIFICACIÓN
-- =============================================================================
-- SELECT count(*), tipo_zona FROM aire_dwh.dim_station GROUP BY tipo_zona;
-- SELECT alcaldia, count(*) FROM aire_dwh.dim_station GROUP BY alcaldia ORDER BY count(*) DESC;
