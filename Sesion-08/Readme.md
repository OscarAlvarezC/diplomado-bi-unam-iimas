# Sesión 08: ETL con Python IV — Carga, orquestación y buenas prácticas

## :dart: Objetivo

Cargar los DataFrames transformados al data warehouse, estructurar el pipeline ETL como un script productivo y aplicar buenas prácticas de logging, manejo de errores y validación.

## :pushpin: Temas

- **Carga al data warehouse con `to_sql()`:**
  - Estrategias: `replace`, `append`, upsert manual.
  - Chunksize y performance.
  - Especificación de tipos con `dtype` para evitar inferencias sub-óptimas.
- **Estructura de un pipeline modular** en un script `etl_pipeline.py`:
  - Funciones separadas para `extract()`, `transform()`, `load()`.
  - `main()` orquestador.
- **Logging básico** con el módulo `logging` de la stdlib.
- **Manejo de excepciones:** rollback, retry policies básicas.
- **Validaciones post-carga:**
  - Conteos vs origen.
  - Sumas y agregados.
  - Integridad referencial.
- **Cierre del bloque:** ETL en producción real — patrones de object storage (S3), pipelines orquestados (Airflow, Prefect), formatos columnares (Parquet), compute serverless. Discusión, sin hands-on.

## :books: Material

> Por publicar.

**Entregable:** cada alumno consolida su trabajo en un script `etl_pipeline.py` ejecutable de extremo a extremo. Forma parte del caso integrador (Sesión 16).

---

[← Volver al inicio](../README.md) | [Siguiente: Sesión 09 →](../Sesion-09/Readme.md)
