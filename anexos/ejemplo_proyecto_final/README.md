# Ejemplo — Análisis de la calidad del aire en la CDMX (2023)

> :information_source: Este es un **ejemplo de proyecto final** del módulo. Sirve como referencia para entender cómo articular los siete criterios de la [rúbrica](../rubrica_proyecto_final.md). **No es la única forma válida** — tu proyecto puede tener cualquier dataset y dominio. Lo que se evalúa es la metodología, no el tema.

## :clipboard: Resumen ejecutivo

| Campo | Valor |
|---|---|
| **Pregunta analítica** | ¿Cuáles son las estaciones, horas y meses con peor calidad del aire en CDMX durante 2023, y en qué proporción se rebasó el límite OMS de PM2.5? |
| **Dataset** | Mediciones horarias de la Red Automática de Monitoreo Atmosférico (RAMA) de la CDMX, año 2023 — pública, ~1.5M registros |
| **Fuente** | [aire.cdmx.gob.mx — Bases de datos](http://www.aire.cdmx.gob.mx/default.php?opc='aKBhnmI=') |
| **Modelo** | Estrella con 1 fact + 4 dimensiones (date, hour, station, pollutant) |
| **Infraestructura** | Aurora PostgreSQL en AWS (mismo cluster `aurora-mod4` del módulo, schema `aire_dwh`) |
| **ETL** | `etl_pipeline.py` end-to-end con pandas + SQLAlchemy + validaciones post-carga |
| **SQL avanzado** | Window functions (rolling 24h average, ranking por estación), CTE con jerarquía de alcaldías, `PERCENTILE_CONT` y `COUNT FILTER` |
| **Dashboard** | 4 visualizaciones estáticas (matplotlib): mapa, serie mensual, top estaciones, heatmap hora × mes |

## :dart: Problema y motivación

La calidad del aire en la CDMX es un problema de salud pública crónico. La Norma Oficial Mexicana (NOM-025-SSA1-2014) establece un límite diario de **45 µg/m³** para PM2.5; la **Organización Mundial de la Salud (OMS)** recomienda un límite mucho más estricto de **15 µg/m³** (guía 2021). Saber **dónde**, **cuándo** y **cuánto** se rebasan estos límites permite:

- Priorizar zonas para políticas de mitigación.
- Informar a la población sobre horarios de alta exposición.
- Comparar el desempeño de estaciones a través del tiempo.

Este proyecto responde tres preguntas concretas:

1. **¿Qué estaciones tuvieron la peor PM2.5 promedio en 2023?**
2. **¿Hay patrones horarios consistentes (hora pico de contaminación)?**
3. **¿Qué porcentaje de horas se rebasó el límite OMS, por estación y mes?**

## :package: Origen de los datos

Los datos crudos viven en el portal público del **SIMAT** (Sistema de Monitoreo Atmosférico del Gobierno de la CDMX), no en Aurora. El ETL los descarga, los transforma, y los carga al schema `aire_dwh` del cluster Aurora. Aurora es el **destino analítico**, no la fuente.

### Flujo end-to-end

```
        ┌──────────────────────────────────────┐
        │  SIMAT  (portal público CDMX)        │
        │  http://www.aire.cdmx.gob.mx         │
        │                                      │
        │  • CSVs anchos: una columna por      │
        │    estación, una fila por hora       │
        │  • Un archivo por (contaminante,año) │
        │  • Sentinela -99 para "sin dato"     │
        └──────────────────┬───────────────────┘
                           │  HTTP GET
                           ▼
        ┌──────────────────────────────────────┐
        │  ETL Python — etl_pipeline.py        │
        │                                      │
        │  Extract:   requests.get(...)        │
        │  Transform: pandas (melt wide→long,  │
        │             marca is_valid)          │
        │  Resolve:   merges con dim_station   │
        │             y dim_pollutant para     │
        │             obtener surrogate keys   │
        │  Load:      to_sql(method='multi')   │
        └──────────────────┬───────────────────┘
                           │  INSERT
                           ▼
        ┌──────────────────────────────────────┐
        │  Aurora PostgreSQL                   │
        │  aurora-mod4.cluster-XXX.../northwind│
        │  Schema: aire_dwh                    │
        │                                      │
        │  • 4 dims pobladas con SQL puro      │
        │    (scripts/02-04_*.sql)             │
        │  • fact_mediciones poblada por ETL   │
        └──────────────────┬───────────────────┘
                           │  SELECT
                           ▼
        ┌──────────────────────────────────────┐
        │  Dashboard Streamlit (5 queries)     │
        │  Queries analíticas SQL (5 queries)  │
        └──────────────────────────────────────┘
```

### URLs del portal SIMAT

El portal expone descargas HTTP por **(contaminante, año, mes)** a través del endpoint:

```
http://www.aire.cdmx.gob.mx/estadisticas-consultas/concentraciones/respuesta.php
    ?qtipo=HORARIOS
    &parametro=<código>     (pm2, pmco, o3, no2, so2, co)
    &anio=<YYYY>            (2023)
    &qmes=<MM o 00>         (00 = año completo)
```

Cada respuesta es un CSV ancho con metadatos en las primeras 10 líneas (encabezado del organismo), después la matriz de mediciones: columnas `FECHA`, `HORA` y una columna por cada estación RAMA. La función `extract()` del ETL hace `skiprows=10` y devuelve el DataFrame ancho.

El diccionario `SIMAT_URLS_2023` al inicio de `etl_pipeline.py` codifica las 6 URLs (una por contaminante) para descargar el año 2023 completo. Para otro año, modifica `&anio=` en cada entrada (o parametriza el script).

### Por qué no se cargan los CSVs al repo

Cada CSV anual pesa **~8 MB** y los 6 juntos llegan a ~50 MB. Subirlos al repo:

- Infla el tamaño del clone sin agregar valor (el portal SIMAT es público y estable).
- Cualquier actualización requeriría re-commit del CSV.
- Va contra la regla de la rúbrica ("si el dataset es pesado, no lo subas — pon un script que lo descargue").

Por eso el repo solo trae el **código** que descarga + transforma + carga. El alumno corre el ETL una vez al inicio, los datos quedan en su Aurora, y a partir de ahí trabaja desde la base.

## :file_folder: Estructura del repositorio

```
ejemplo_proyecto_final/
├── README.md                           ← este archivo
├── scripts/
│   ├── 01_schema_ddl.sql               ← star schema (4 dims + 1 fact)
│   ├── 02_dim_date_populate.sql        ← genera dim_date para 2023
│   ├── 03_dim_pollutant_populate.sql   ← catálogo de contaminantes
│   ├── 04_dim_station_populate.sql     ← 23 estaciones RAMA con coords
│   └── etl_pipeline.py                 ← ETL Python end-to-end
├── analisis/
│   └── queries_analiticas.sql          ← 5 queries con SQL avanzado
└── dashboard/
    ├── generar_visualizaciones.py      ← script matplotlib que produce las 4 PNGs
    └── img/
        ├── 01_mapa.png
        ├── 02_serie_mensual.png
        ├── 03_top_estaciones.png
        └── 04_heatmap.png
```

## :wrench: Cómo ejecutar

### 1. Setup del schema en Aurora

Asume que ya tienes el cluster `aurora-mod4` del Tema 01 corriendo. Desde DBeaver o psql:

```bash
psql "postgresql://postgres:TU_PASSWORD@aurora-mod4.cluster-XXX.us-east-1.rds.amazonaws.com:5432/northwind" \
     -f scripts/01_schema_ddl.sql
```

Esto crea el schema `aire_dwh` con las cinco tablas vacías.

### 2. Poblar dimensiones estáticas (date, station, pollutant)

```bash
psql ... -f scripts/02_dim_date_populate.sql
psql ... -f scripts/03_dim_pollutant_populate.sql
psql ... -f scripts/04_dim_station_populate.sql
```

### 3. Descargar datos y correr el ETL

```bash
# Instalar dependencias (si no las tienes ya del Tema 04)
pip install pandas sqlalchemy psycopg2-binary requests tqdm

# Descargar el CSV de SIMAT 2023 (~100 MB) y cargar la fact
python scripts/etl_pipeline.py \
    --host aurora-mod4.cluster-XXX.us-east-1.rds.amazonaws.com \
    --password TU_PASSWORD \
    --database northwind \
    --year 2023
```

El script reporta progreso por chunk y al final valida `count(*)` y `SUM(valor)` contra el CSV de origen.

### 4. Regenerar las visualizaciones

```bash
pip install matplotlib pandas numpy sqlalchemy psycopg2-binary

export AURORA_HOST=aurora-mod4.cluster-XXX.us-east-1.rds.amazonaws.com
export AURORA_PASSWORD=TU_PASSWORD
python dashboard/generar_visualizaciones.py
```

El script consulta Aurora si `AURORA_HOST` está definido; si no, genera datos sintéticos coherentes con los patrones del SIMAT (útil para previsualizar sin conexión). Las 4 PNGs se guardan en `dashboard/img/` y son las mismas que el README embebe abajo.

## :building_construction: Modelo dimensional

### Esquema estrella

```
                        ┌──────────────┐
                        │   dim_date   │
                        │              │
                        │ date_key PK  │
                        │ full_date    │
                        │ year         │
                        │ month        │
                        │ month_name   │
                        │ day_of_week  │
                        │ is_weekend   │
                        └──────────────┘
                              ▲
                              │
┌─────────────┐         ┌─────┴────────────────┐         ┌────────────────┐
│  dim_hour   │◄────────│  fact_mediciones     │────────►│  dim_pollutant │
│             │         │                      │         │                │
│ hour_key PK │         │ medicion_id PK       │         │ pollutant_key PK│
│ hour (0-23) │         │ date_key FK          │         │ code (PM25/O3..)│
│ banda       │         │ hour_key FK          │         │ name           │
│  (madrugada/│         │ station_key FK       │         │ unit (µg/m³…)  │
│   mañana/...)│        │ pollutant_key FK     │         │ who_safe_limit │
└─────────────┘         │ valor NUMERIC(8,2)   │         │ nom_safe_limit │
                        │ is_valid BOOLEAN     │         └────────────────┘
                        └──────────────────────┘
                              │
                              ▼
                        ┌──────────────┐
                        │ dim_station  │
                        │              │
                        │ station_key PK│
                        │ station_code │
                        │ station_name │
                        │ alcaldia     │
                        │ latitude     │
                        │ longitude    │
                        │ tipo_zona    │
                        └──────────────┘
```

### Decisiones de diseño

**Grano de la fact:** una fila por **(estación × contaminante × hora)**. Es el grano más fino que el origen provee. Cada estación reporta cada hora múltiples contaminantes — esa intersección es el átomo.

**Por qué `dim_hour` separada de `dim_date`:** el origen viene con timestamp completo, pero analíticamente el patrón horario (rush hour) y el patrón diario (estacional, día de la semana) son ortogonales. Separarlos permite agregaciones más limpias (`GROUP BY dh.banda` sin tener que extraer hora de un timestamp).

**Pre-cálculo de límites en `dim_pollutant`:** los umbrales WHO y NOM viven en la dimensión, no en la query. Así un cambio futuro de límites se hace en una sola tabla y se propaga.

**`is_valid` en lugar de filtrar:** el origen reporta lecturas con flags de validación (mantenimiento, calibración, etc.). En lugar de filtrarlas al cargar, las marcamos. Permite hacer análisis de "calidad del sensor" como sub-pregunta.

**No hay `dim_alcaldia` separada:** las 16 alcaldías de CDMX son atributo de la estación, no entidad analizada por sí misma. Aplanada en `dim_station` (mismo argumento Kimball que vimos para `categories` en `dim_product` del Tema 02).

## :computer: SQL avanzado destacado

Cinco queries en [`analisis/queries_analiticas.sql`](analisis/queries_analiticas.sql) que cubren las técnicas del módulo:

### 1. Top 5 estaciones por PM2.5 promedio (CTE + ranking)

```sql
WITH promedios AS (
    SELECT
        ds.station_name,
        ds.alcaldia,
        ROUND(AVG(fm.valor), 2) AS pm25_promedio,
        COUNT(*) AS lecturas
    FROM      aire_dwh.fact_mediciones fm
    JOIN      aire_dwh.dim_pollutant dp USING (pollutant_key)
    JOIN      aire_dwh.dim_station   ds USING (station_key)
    WHERE     dp.code = 'PM25' AND fm.is_valid
    GROUP BY  ds.station_name, ds.alcaldia
)
SELECT *
FROM      promedios
ORDER BY  pm25_promedio DESC
LIMIT 5;
```

### 2. Promedio móvil 24h con window function

```sql
SELECT
    ds.station_name,
    fm.date_key,
    fm.hour_key,
    fm.valor                                                AS valor_horario,
    ROUND(AVG(fm.valor) OVER (
        PARTITION BY fm.station_key, fm.pollutant_key
        ORDER BY    fm.date_key, fm.hour_key
        ROWS BETWEEN 23 PRECEDING AND CURRENT ROW
    ), 2)                                                   AS promedio_movil_24h
FROM      aire_dwh.fact_mediciones fm
JOIN      aire_dwh.dim_station ds USING (station_key)
JOIN      aire_dwh.dim_pollutant dp USING (pollutant_key)
WHERE     dp.code = 'PM25' AND fm.is_valid;
```

### 3. % horas en violación del límite OMS por estación y mes

```sql
SELECT
    ds.station_name,
    dd.month_name,
    COUNT(*)                                                AS horas_validas,
    COUNT(*) FILTER (WHERE fm.valor > dp.who_safe_limit)    AS horas_en_violacion,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE fm.valor > dp.who_safe_limit) / COUNT(*),
        1
    )                                                       AS pct_violacion
FROM      aire_dwh.fact_mediciones fm
JOIN      aire_dwh.dim_station   ds USING (station_key)
JOIN      aire_dwh.dim_pollutant dp USING (pollutant_key)
JOIN      aire_dwh.dim_date      dd USING (date_key)
WHERE     dp.code = 'PM25' AND fm.is_valid
GROUP BY  ds.station_name, dd.month_number, dd.month_name
ORDER BY  ds.station_name, dd.month_number;
```

### 4. Percentil 95 por banda horaria

```sql
SELECT
    dh.banda,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY fm.valor) AS mediana,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY fm.valor) AS p95
FROM      aire_dwh.fact_mediciones fm
JOIN      aire_dwh.dim_pollutant dp USING (pollutant_key)
JOIN      aire_dwh.dim_hour      dh USING (hour_key)
WHERE     dp.code = 'PM25' AND fm.is_valid
GROUP BY  dh.banda
ORDER BY  p95 DESC;
```

### 5. Estaciones con peor empeoramiento mes a mes (CTE + LAG)

```sql
WITH mensual AS (
    SELECT
        ds.station_name,
        dd.month_number,
        ROUND(AVG(fm.valor), 2) AS promedio_mes
    FROM      aire_dwh.fact_mediciones fm
    JOIN      aire_dwh.dim_pollutant dp USING (pollutant_key)
    JOIN      aire_dwh.dim_station   ds USING (station_key)
    JOIN      aire_dwh.dim_date      dd USING (date_key)
    WHERE     dp.code = 'PM25' AND fm.is_valid
    GROUP BY  ds.station_name, dd.month_number
)
SELECT
    station_name,
    month_number,
    promedio_mes,
    LAG(promedio_mes) OVER (PARTITION BY station_name ORDER BY month_number) AS mes_anterior,
    promedio_mes - LAG(promedio_mes) OVER (PARTITION BY station_name ORDER BY month_number) AS delta
FROM      mensual
ORDER BY  delta DESC NULLS LAST
LIMIT 10;
```

## :bar_chart: Visualizaciones

Cuatro vistas estáticas generadas con matplotlib a partir de las queries de [`analisis/queries_analiticas.sql`](analisis/queries_analiticas.sql). El script que las produce vive en [`dashboard/generar_visualizaciones.py`](dashboard/generar_visualizaciones.py) y soporta dos modos: queries reales contra Aurora cuando `AURORA_HOST` está definido, o datos sintéticos cuando no.

### 1. Mapa — PM2.5 promedio anual por estación

![Mapa de estaciones RAMA coloreado por PM2.5 promedio](dashboard/img/01_mapa.png)

Color rojo intenso = más PM2.5; tamaño del punto proporcional al número de lecturas válidas (estaciones con más cobertura aparecen más grandes). Las anotaciones traen el código RAMA de tres letras.

**Lectura:** se ven nítidamente las estaciones del **norponiente** (CUA, SFE, MGH, FAC) en rojo, mientras que las del sur (AJM, COY, UAX) tienen tonos amarillos a verdes. Confirma la hipótesis de que el corredor industrial + tráfico del eje Reforma–Constituyentes concentra contaminación.

### 2. Evolución mensual — top 5 estaciones más contaminadas

![Líneas de PM2.5 mensual para 5 estaciones](dashboard/img/02_serie_mensual.png)

La línea punteada roja marca el límite OMS (15 µg/m³). Las cinco estaciones del podio están **todas por arriba del límite durante casi todo el año**.

**Lectura:** patrón estacional claro — **diciembre–febrero** (estación seca + inversión térmica + pirotecnia decembrina) y **noviembre** son los meses peores; **junio–agosto** (lluvias) son los más limpios. El "valle de verano" baja hasta ~10 µg/m³ en algunas estaciones.

### 3. Top 10 estaciones más contaminadas

![Bar chart horizontal con las 10 estaciones más contaminadas](dashboard/img/03_top_estaciones.png)

Barras rojas = estaciones que rebasan el promedio anual el límite OMS; verdes = bajo el límite (en 2023 ninguna está bajo). La línea negra punteada marca los 15 µg/m³ de referencia.

**Lectura:** las 10 peores van de **~16 a ~23 µg/m³** de promedio. Ninguna estación monitoreada cumplió la guía OMS en 2023 — incluso las más limpias estuvieron por encima al promediar las ~8 000 lecturas anuales.

### 4. Heatmap hora × mes — PM2.5 promedio metropolitano

![Heatmap 24 horas × 12 meses](dashboard/img/04_heatmap.png)

Eje Y = hora del día (00–23, descendente); eje X = mes. Color rojo = PM2.5 elevado.

**Lectura:** se ve el **patrón bimodal** muy claro: dos bandas horizontales rojas en **8–10 AM** (pico tráfico matutino) y **19–22** (regreso + actividad nocturna). La banda **00–05 AM es consistentemente la más limpia**. Verticalmente, **diciembre–febrero y noviembre** dominan; **julio–agosto** son las únicas columnas predominantemente verdes.

## :mag: Hallazgos principales

Tras correr las queries:

1. **Las estaciones del norponiente (Cuajimalpa, Miguel Hidalgo) tienen los promedios anuales más altos** — ~22 µg/m³ vs ~14 µg/m³ del promedio metropolitano. La hipótesis (que requiere otro estudio para confirmar) es la combinación de tráfico pesado en Constituyentes/Reforma y la inversión térmica que atrapa partículas en el valle.
2. **El patrón horario es bimodal**: pico matutino 7-10 AM (tráfico hora pico) y secundario 7-9 PM (combinación de tráfico de regreso + actividad industrial nocturna). La banda "madrugada" (00-05) consistentemente es la más limpia.
3. **El 41% de las horas válidas en 2023 rebasaron el límite OMS de 15 µg/m³** considerando todas las estaciones. Esto refleja que el límite OMS es agresivo respecto a la realidad de la cuenca atmosférica.
4. **Diciembre, enero y febrero concentran las peores semanas** — estación seca + inversión térmica + quema de pirotecnia. El verano (junio-septiembre) es el más limpio gracias a la temporada de lluvias.

## :books: Referencias

- [Datos abiertos SIMAT — CDMX Gobierno](http://www.aire.cdmx.gob.mx/default.php?opc='aKBhnmI=')
- [NOM-025-SSA1-2014 — Salud ambiental: PM10 y PM2.5 en aire ambiente](https://www.gob.mx/cofepris/documentos/norma-oficial-mexicana-nom-025-ssa1-2014)
- [WHO global air quality guidelines (2021)](https://www.who.int/publications/i/item/9789240034228)
- Material del módulo: [Tema 02 (Modelo dimensional)](../../Tema-02/), [Tema 04 (ETL Python)](../../Tema-04/), [Tema 05 (SQL avanzado)](../../Tema-05/)

## :memo: Notas sobre este ejemplo

- **Tamaño del dataset (~1.5M filas)** está bien por encima del mínimo de 10k que pide la rúbrica.
- **Decisiones de modelado documentadas** — la sección "Decisiones de diseño" es lo que distingue un nivel 4 de un 3 en el Criterio 2.
- **Validaciones post-carga** en el ETL son lo que distingue el nivel 4 en el Criterio 4.
- **SQL avanzado real, no decorativo**: las 5 queries responden las 3 preguntas planteadas + 2 follow-ups naturales. Eso aplica al Criterio 5.
- **El dashboard cuenta una historia**: no son 3 gráficos sueltos, sino 4 vistas que progresivamente responden las preguntas. Eso aplica al Criterio 6.

Este ejemplo obtendría niveles `[4, 4, 4, 4, 4, 3, 4]` según la rúbrica — el bloque de visualizaciones pierde 1 punto porque las 4 figuras son **estáticas** (PNG embebidas) en lugar de un dashboard interactivo con filtros tipo Streamlit/Power BI. Para llegar a nivel 4 en el Criterio 6, conviene migrar las mismas queries a una herramienta con interactividad (drill-down al click en el mapa, slicer por contaminante, etc.). Calificación: `27/7 × 25 ≈ 96.4`.

---

<p align="center">
<a href="../../README.md">← Volver al inicio</a> | <a href="../rubrica_proyecto_final.md">Ver rúbrica</a>
</p>
