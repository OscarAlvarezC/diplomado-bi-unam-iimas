# Sesión 05: ETL con Python I — Fundamentos y extracción

## :dart: Objetivo

Comprender el rol del ETL como integrador de fuentes heterogéneas, configurar el entorno Python para data engineering, y extraer datos desde Aurora PostgreSQL hacia DataFrames de pandas. **Al cierre cada alumno tiene Anaconda funcionando con las librerías del módulo y conexión validada a su Aurora.**

## :clock1: Duración

2.5 horas.

## :wrench: Setup técnico en vivo (~45 min)

- Instalación / verificación de **Anaconda** (incluye Jupyter Lab).
- Instalación de las librerías del módulo en el environment: `pandas`, `sqlalchemy`, `psycopg2-binary`.
- Configuración del **engine SQLAlchemy** con la URL de conexión de Aurora.
- Validación: notebook que abre conexión y corre `SELECT 1` en Aurora desde Jupyter.

> :bulb: Si ya tenías Anaconda instalado antes de la sesión, este bloque baja a ~15 min.

## :pushpin: Temas (~105 min)

- Por qué existe el ETL: el problema de las fuentes heterogéneas.
- Los tres pasos: **Extract**, **Transform**, **Load**.
- **ETL vs ELT**: cuándo cada uno.
- **Idempotencia**: por qué importa y cómo se garantiza.
- **Extracción desde Aurora con `pd.read_sql`**: lectura completa, lectura por chunks.
- Mención de cómo lucen las fuentes en producción real (object storage, APIs, message queues), sin hands-on.

## :books: Material

> Por publicar.
