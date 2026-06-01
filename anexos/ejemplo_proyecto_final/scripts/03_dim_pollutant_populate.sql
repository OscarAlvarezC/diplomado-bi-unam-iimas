-- =============================================================================
-- Poblar dim_pollutant con los seis contaminantes principales del SIMAT
-- =============================================================================
-- Límites: WHO guías 2021, NOM-025-SSA1-2014, NOM-020-SSA1-2014, NOM-023-SSA1-1993.
-- =============================================================================

SET search_path TO aire_dwh;

INSERT INTO dim_pollutant (code, name, unit, who_safe_limit, nom_safe_limit, descripcion) VALUES
    ('PM25', 'Partículas finas (PM2.5)',           'µg/m³', 15.00,  45.00, 'Partículas menores a 2.5 micrómetros. Penetran profundo en pulmones. Asociadas a enfermedad cardiovascular y cáncer de pulmón.'),
    ('PM10', 'Partículas suspendidas (PM10)',      'µg/m³', 45.00,  75.00, 'Partículas menores a 10 micrómetros. Polvo, hollín, polen.'),
    ('O3',   'Ozono troposférico (O3)',            'ppb',  100.00,  95.00, 'Contaminante secundario formado por reacción de NOx + COV con luz solar. Pico vespertino.'),
    ('NO2',  'Dióxido de nitrógeno (NO2)',         'ppb',   25.00, 210.00, 'Producido por combustión vehicular e industrial.'),
    ('SO2',  'Dióxido de azufre (SO2)',            'ppb',   40.00, 110.00, 'Subproducto de combustibles con azufre.'),
    ('CO',   'Monóxido de carbono (CO)',           'ppm',    4.00,  11.00, 'Combustión incompleta. Tráfico vehicular.');

-- =============================================================================
-- VERIFICACIÓN
-- =============================================================================
-- SELECT code, name, unit, who_safe_limit, nom_safe_limit FROM aire_dwh.dim_pollutant ORDER BY code;
-- Esperado: 6 filas
