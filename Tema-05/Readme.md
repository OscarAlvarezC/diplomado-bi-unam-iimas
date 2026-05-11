# Tema 05: ETL con Python

Este tema cubre el **proceso ETL completo** (Extract, Transform, Load) construido en Python con `pandas`, `SQLAlchemy` y `psycopg2`. Tomamos los datos de `northwind_oltp`, los profilamos, los limpiamos, los transformamos al modelo dimensional y los cargamos en `northwind_dwh` — el equivalente programático de la transformación SQL que estudiaste en el Tema 04, pero ahora en código.

## :wrench: Setup técnico inicial

- Instalación / verificación de **Anaconda** (incluye Jupyter Lab).
- Librerías del módulo: `pandas`, `sqlalchemy`, `psycopg2-binary`.
- Configuración del **engine SQLAlchemy** con la URL de conexión a Aurora.
- Validación: notebook que abre conexión y corre `SELECT 1` en Aurora desde Jupyter.

## :dart: Objetivos

- Comprender el rol del ETL como integrador de fuentes heterogéneas y por qué es la pieza central de cualquier arquitectura de BI.
- Extraer datos desde Aurora hacia DataFrames de pandas con `pd.read_sql`.
- Perfilar datasets para detectar problemas de calidad (nulos, duplicados, tipos incorrectos, valores anómalos).
- Limpiar y normalizar datos con las herramientas de pandas.
- Aplicar reglas de negocio mediante transformaciones tipadas y joins entre DataFrames.
- Cargar el resultado al data warehouse con `to_sql`, eligiendo la estrategia correcta (replace, append, upsert).
- Estructurar todo el pipeline como un script Python productivo con logging, manejo de errores y validaciones post-carga.

## :file_folder: Contenido

El tema se cubre en cuatro sub-bloques, en orden:

<ins>1. Fundamentos y extracción</ins>

Conceptos: por qué existe el ETL, los tres pasos (E/T/L), **ETL vs ELT** y cuándo usar cada uno, **idempotencia** y por qué importa. Setup del entorno Python. **Extracción desde Aurora con `pd.read_sql`**: lectura completa, lectura por chunks. Mención de archivos CSV/JSON locales y de cómo lucen las fuentes en la realidad (object storage, APIs, message queues).

<ins>2. Limpieza y perfilado</ins>

**Perfilado del DataFrame** con `df.info()`, `df.describe()`, `df.isna().sum()`, `df.value_counts()`. **Limpieza:** manejo de nulos (drop, fillna, indicadores), deduplicación con `drop_duplicates`, normalización de strings (`str.strip`, `str.lower`, regex). **Conversión de tipos:** `astype` para tipos numéricos y categóricos, parseo de fechas con `pd.to_datetime`. **Estandarización:** catálogos de valores controlados, unificación de formatos.

<ins>3. Transformación según reglas de negocio</ins>

**Cálculo de valores derivados** (márgenes, totales, ratios) con operaciones vectorizadas. **Joins entre DataFrames** con `merge`: `how='inner'/'left'/'outer'`, múltiples keys. **Generación de `dim_date`** en pandas con `pd.date_range` + atributos calendáricos derivados. **Construcción de las dimensiones desnormalizadas** — el equivalente a los `INSERT…SELECT…JOIN` que vimos en el Tema 04, ahora en código Python. **Construcción de la tabla de hechos** con resolución de surrogate keys vía merge sucesivo. Estrategias para garantizar **integridad referencial** antes de la carga.

<ins>4. Carga, orquestación y buenas prácticas</ins>

**Carga al data warehouse con `to_sql()`:** estrategias `replace`, `append`, upsert manual; `chunksize` y performance; especificación de tipos con `dtype` para evitar inferencias sub-óptimas. **Estructura de un pipeline modular** en un script `etl_pipeline.py`: funciones separadas para `extract()`, `transform()`, `load()` orquestadas por un `main()`. **Logging básico** con el módulo `logging` de la stdlib. **Manejo de excepciones:** rollback, retry policies básicas. **Validaciones post-carga:** conteos vs origen, sumas y agregados.

**Cierre — ETL en producción real:** patrones de object storage (S3), pipelines orquestados (Airflow, Prefect), formatos columnares (Parquet), compute serverless (Glue, Lambda). Discusión, sin hands-on. Da contexto sobre dónde encaja lo aprendido en el ecosistema mayor.

## :books: Material

> Por publicar.

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="../Tema-06/Readme.md">Siguiente: Tema 06 →</a>
</p>
