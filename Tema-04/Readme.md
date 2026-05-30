# Tema 04: ETL con Python

Este tema cubre el **proceso ETL completo** (Extract, Transform, Load) construido en Python con `pandas`, `SQLAlchemy` y `psycopg2`. Tomamos los datos de `northwind_oltp`, los profilamos, los limpiamos, los transformamos al modelo dimensional y los cargamos en `northwind_dwh` — el equivalente programático de la transformación SQL que estudiaste en el Tema 02, pero ahora en código.

## :wrench: Setup técnico inicial

- Instalación de **Miniconda** y creación del ambiente `bi-unam` — guía paso a paso en [**`anexos/instalar_miniconda.md`**](../anexos/instalar_miniconda.md).
- Librerías del módulo: `pandas`, `sqlalchemy`, `psycopg2-binary`, `notebook` (las instala el [anexo de Miniconda](../anexos/instalar_miniconda.md) como parte del setup).
- Configuración del **engine SQLAlchemy** con la URL de conexión a Aurora (en el Notebook 01).
- Validación: notebook que abre conexión y corre `SELECT version()` en Aurora desde Jupyter.

## :dart: Objetivos

- Comprender el rol del ETL como integrador de fuentes heterogéneas y por qué es la pieza central de cualquier arquitectura de BI.
- Extraer datos desde Aurora hacia DataFrames de pandas con `pd.read_sql`.
- Perfilar datasets para detectar problemas de calidad (nulos, duplicados, tipos incorrectos, valores anómalos).
- Limpiar y normalizar datos con las herramientas de pandas.
- Aplicar reglas de negocio mediante transformaciones tipadas y joins entre DataFrames.
- Cargar el resultado al data warehouse con `to_sql`, eligiendo la estrategia correcta (replace, append, upsert).
- Estructurar todo el pipeline como un script Python productivo con logging, manejo de errores y validaciones post-carga.

## :file_folder: Contenido

El tema se cubre en cuatro notebooks Jupyter, en orden:

<ins>1. Fundamentos y extracción</ins>

Conceptos: por qué existe el ETL, los tres pasos (E/T/L), **ETL vs ELT** y cuándo usar cada uno, **idempotencia** y por qué importa. Setup del entorno Python. **Extracción desde Aurora con `pd.read_sql`**: lectura completa, lectura por chunks. Mención de archivos CSV/JSON locales y de cómo lucen las fuentes en la realidad (object storage, APIs, message queues).

[**`Notebook 01`**](https://colab.research.google.com/github/OscarAlvarezC/diplomado-bi-unam-iimas/blob/main/Tema-04/01_fundamentos_y_extraccion.ipynb)

<ins>2. Limpieza y perfilado</ins>

**Perfilado del DataFrame** con `df.info()`, `df.describe()`, `df.isna().sum()`, `df.value_counts()`. **Limpieza:** manejo de nulos (drop, fillna, indicadores), deduplicación con `drop_duplicates`, normalización de strings (`str.strip`, `str.lower`, regex). **Conversión de tipos:** `astype` para tipos numéricos y categóricos, parseo de fechas con `pd.to_datetime`. **Estandarización:** catálogos de valores controlados, unificación de formatos.

[**`Notebook 02`**](https://colab.research.google.com/github/OscarAlvarezC/diplomado-bi-unam-iimas/blob/main/Tema-04/02_limpieza_y_perfilado.ipynb)

<ins>3. Transformación según reglas de negocio</ins>

**Cálculo de valores derivados** (márgenes, totales, ratios) con operaciones vectorizadas. **Joins entre DataFrames** con `merge`: `how='inner'/'left'/'outer'`, múltiples keys. **Generación de `dim_date`** en pandas con `pd.date_range` + atributos calendáricos derivados. **Construcción de las dimensiones desnormalizadas** — el equivalente a los `INSERT…SELECT…JOIN` de los scripts de población del DWH, ahora en código Python. **Construcción de la tabla de hechos** con resolución de surrogate keys vía merge sucesivo. Estrategias para garantizar **integridad referencial** antes de la carga.

[**`Notebook 03`**](https://colab.research.google.com/github/OscarAlvarezC/diplomado-bi-unam-iimas/blob/main/Tema-04/03_transformacion.ipynb)

<ins>4. Carga, orquestación y buenas prácticas</ins>

**Carga al data warehouse con `to_sql()`:** estrategias `replace`, `append`, upsert manual; `chunksize` y performance; especificación de tipos con `dtype` para evitar inferencias sub-óptimas. **Estructura de un pipeline modular** en un script `etl_pipeline.py`: funciones separadas para `extract()`, `transform()`, `load()` orquestadas por un `main()`. **Logging básico** con el módulo `logging` de la stdlib. **Manejo de excepciones:** rollback, retry policies básicas. **Validaciones post-carga:** conteos vs origen, sumas y agregados.

**Cierre — ETL en producción real:** patrones de object storage (S3), pipelines orquestados (Airflow, Prefect), formatos columnares (Parquet), compute serverless (Glue, Lambda). Discusión, sin hands-on. Da contexto sobre dónde encaja lo aprendido en el ecosistema mayor.

[**`Notebook 04`**](https://colab.research.google.com/github/OscarAlvarezC/diplomado-bi-unam-iimas/blob/main/Tema-04/04_carga_y_orquestacion.ipynb)

## :books: Material

Los cuatro notebooks viven en este mismo directorio. Cada notebook es **auto-contenido** — puedes abrir cualquiera y correrlo sin depender del estado de los anteriores; solo asegúrate de tener el cluster Aurora del Tema 01 accesible y de reemplazar `AURORA_HOST` y `AURORA_PASSWORD` en la primera celda de cada notebook con los tuyos.

> **Estado:** estructura completa con esqueleto de secciones; el contenido detallado de cada notebook (celdas markdown + código) está en desarrollo. Cada sección de cada notebook lleva un marcador *"Por publicar"* hasta que se complete.

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="../Tema-05/Readme.md">Siguiente: Tema 05 →</a>
</p>
