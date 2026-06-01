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
| **Dashboard** | Streamlit con 4 vistas: mapa, serie temporal, top estaciones, % horas en violación |

## :dart: Problema y motivación

La calidad del aire en la CDMX es un problema de salud pública crónico. La Norma Oficial Mexicana (NOM-025-SSA1-2014) establece un límite diario de **45 µg/m³** para PM2.5; la **Organización Mundial de la Salud (OMS)** recomienda un límite mucho más estricto de **15 µg/m³** (guía 2021). Saber **dónde**, **cuándo** y **cuánto** se rebasan estos límites permite:

- Priorizar zonas para políticas de mitigación.
- Informar a la población sobre horarios de alta exposición.
- Comparar el desempeño de estaciones a través del tiempo.

Este proyecto responde tres preguntas concretas:

1. **¿Qué estaciones tuvieron la peor PM2.5 promedio en 2023?**
2. **¿Hay patrones horarios consistentes (hora pico de contaminación)?**
3. **¿Qué porcentaje de horas se rebasó el límite OMS, por estación y mes?**

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
    └── dashboard_streamlit.py          ← 4 vistas interactivas
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

### 4. Abrir el dashboard

```bash
pip install streamlit plotly
streamlit run dashboard/dashboard_streamlit.py
```

El dashboard requiere las mismas credenciales de Aurora — léelas de variables de entorno (`AURORA_HOST`, `AURORA_PASSWORD`).

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

## :bar_chart: Dashboard — 4 vistas

El dashboard en Streamlit ([`dashboard/dashboard_streamlit.py`](dashboard/dashboard_streamlit.py)) tiene:

1. **Mapa de PM2.5 promedio anual por estación** — color codificado por nivel (verde/amarillo/rojo según norma OMS), tamaño del punto por número de lecturas válidas.
2. **Serie temporal mensual** — line chart por estación, filtrable por contaminante. Sirve para identificar tendencias y comparar.
3. **Top 10 estaciones más contaminadas** — bar chart horizontal, ordenado, con el límite OMS marcado como referencia.
4. **Heatmap horas × meses** — matriz de PM2.5 promedio mostrando patrones combinados temporales (las "horas pico" cambian de estación lluviosa a seca).

**Interactividad:** sidebar con filtros de estación, contaminante y rango de fechas. Todas las viz se actualizan en conjunto.

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

Este ejemplo obtendría niveles `[4, 4, 4, 4, 4, 3, 4]` según la rúbrica — el dashboard pierde 1 punto porque podría tener más interactividad (drill-down al hacer click en una estación del mapa). Calificación: `27/7 × 25 ≈ 96.4`.

---

<p align="center">
<a href="../../README.md">← Volver al inicio</a> | <a href="../rubrica_proyecto_final.md">Ver rúbrica</a>
</p>
