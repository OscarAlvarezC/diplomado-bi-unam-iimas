# Bloque 03: ETL con Python

## :dart: Objetivo

Aplicar procesos ETL (extracción, limpieza, transformación y carga) para integrar datos provenientes de fuentes heterogéneas, asegurando calidad y consistencia. Reimplementar la carga del data warehouse del Bloque 2 con `pandas + SQLAlchemy`.

## :clock1: Duración

8 horas, divididas en 4 subsesiones de 2 horas cada una.

## :pushpin: Temas

### Sesión 3.1 — Fundamentos y extracción

- Por qué existe el ETL: el problema de las fuentes heterogéneas.
- Los tres pasos: extract, transform, load.
- ETL vs ELT.
- Idempotencia.
- Setup del entorno Python: Anaconda + pandas + SQLAlchemy + psycopg2.
- Extracción desde Aurora con `pd.read_sql`: lectura completa y por chunks.
- Mención de fuentes en la realidad (object storage, APIs, message queues), sin hands-on.

### Sesión 3.2 — Limpieza y perfilado

- Perfilado: `df.info()`, `df.describe()`, `df.isna().sum()`.
- Manejo de nulos.
- Deduplicación.
- Normalización de strings.
- Conversión de tipos.
- Parseo de fechas.
- Estandarización: catálogos de valores, unificación de formatos.

### Sesión 3.3 — Transformación según reglas de negocio

- Cálculo de valores derivados (márgenes, totales, ratios).
- Joins entre DataFrames con `merge`.
- Generación de `dim_date` con `pd.date_range` y enriquecimiento con atributos calendáricos.
- Construcción de las dimensiones desnormalizadas.
- Construcción de la tabla de hechos.

### Sesión 3.4 — Carga, orquestación y buenas prácticas

- Carga al esquema `_dwh` de Aurora con `to_sql()`.
- Estrategias: replace, append, upsert manual.
- Estructura de un pipeline completo en script Python (extract / transform / load separados en funciones).
- Logging básico.
- Manejo de excepciones.
- Validaciones post-carga (conteos, totales, integridad).
- **Cierre del bloque (~30 min):** ETL en producción real — patrones de object storage (S3), pipelines orquestados (Airflow, Prefect), formatos columnares (Parquet), compute serverless. Discusión, sin hands-on.

## :books: Material

> Por publicar.

Cada alumno consolida su trabajo en un script `etl_pipeline.py` ejecutable de extremo a extremo.
