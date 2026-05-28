# Tema 05: SQL avanzado — funciones predefinidas

Este tema cubre las **funciones predefinidas** de PostgreSQL más usadas en queries analíticas: agregadas (`count`, `sum`, `avg`, …), de strings (`upper`, `trim`, `substring`, regex) y de fechas (`date_trunc`, `extract`, `interval`). Son las herramientas con las que escribes el día a día de un reporte de BI — sin ellas, hasta una query simple se vuelve verbose y propensa a errores.

## :wrench: Setup técnico inicial

- **JupySQL** — extensión moderna de Jupyter que permite escribir SQL directamente en celdas con el *magic* `%%sql`, sin envolver cada query en `pd.read_sql`. Se instala con `pip install jupysql` dentro del ambiente `bi-unam` (ver [anexo de Miniconda](../anexos/instalar_miniconda.md), Paso 5).
- **Conexión SQLAlchemy** al cluster Aurora del Tema 01 — la misma que usaste en el Tema 04. Cada notebook re-crea el engine al inicio (auto-contenido).
- **Datasets:** `northwind_dwh` (las 5 dimensiones + `fact_sales` ya cargadas en el Tema 02) y `airbnb.listings` (bronze layer del Tema 01, columnas en `TEXT` que requieren casting).

## :dart: Objetivos

- Aplicar las cinco funciones agregadas estándar (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`) entendiendo cómo manejan NULL.
- Distinguir `COUNT(*)` de `COUNT(col)` de `COUNT(DISTINCT col)` y usar la correcta en cada caso.
- Diferenciar el filtrado pre-agregación (`WHERE`) del post-agregación (`HAVING`) y el orden de ejecución de una query.
- Limpiar y extraer información de columnas de texto sucias con `TRIM`, `SUBSTRING`, `SPLIT_PART`, `REGEXP_REPLACE`, `REGEXP_MATCH`.
- Manipular fechas con `DATE_TRUNC`, `EXTRACT`, aritmética con `INTERVAL`, `AGE`, `TO_CHAR` / `TO_DATE`.
- Combinar las tres familias de funciones para resolver ejercicios analíticos sobre el DWH y sobre Airbnb.

## :file_folder: Contenido

El tema se cubre en cuatro notebooks Jupyter, en orden:

<ins>1. Funciones agregadas</ins>

Las cinco agregadas básicas (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`). La distinción crítica entre `COUNT(*)`, `COUNT(col)` y `COUNT(DISTINCT col)`. **La trampa de los NULL** — todas las agregadas (excepto `COUNT(*)`) los ignoran silenciosamente, fuente común de bugs en reportes. Repaso de `GROUP BY` y la diferencia operativa entre `WHERE` y `HAVING`. Concatenación agregada con `STRING_AGG` y `ARRAY_AGG`. Cierre con casting para agregar Airbnb sucio.

[**`Notebook 01`**](01_funciones_agregadas.ipynb)

<ins>2. Funciones de strings</ins>

Capitalización (`UPPER`, `LOWER`, `INITCAP`), limpieza de bordes (`TRIM`, `LTRIM`, `RTRIM` con caracteres custom), búsqueda con `POSITION`, `LIKE` y `ILIKE` (case-sensitive vs insensitive), extracción con `SUBSTRING`, `LEFT`, `RIGHT`, `SPLIT_PART`, composición con `||` / `CONCAT` / `FORMAT` (con énfasis en cómo manejan NULL), primer encuentro con regex vía `REGEXP_REPLACE` y `REGEXP_MATCH`. Caso integrador: parsear `price`, `bathrooms_text` y `host_response_rate` de Airbnb.

[**`Notebook 02`**](02_funciones_de_strings.ipynb)

<ins>3. Funciones de fechas</ins>

Los cinco tipos de fecha de PostgreSQL (`DATE`, `TIME`, `TIMESTAMP`, `TIMESTAMPTZ`, `INTERVAL`) y cuándo usar cada uno. Funciones del *ahora* (`NOW`, `CURRENT_DATE`, `CURRENT_TIMESTAMP`, `LOCALTIMESTAMP`). `DATE_TRUNC` como herramienta #1 para agregar por período. `EXTRACT` para sacar componentes individuales. Aritmética con `INTERVAL`, diferencias con `AGE`, formateo y parseo con `TO_CHAR` / `TO_DATE`. Cierre con un análisis temporal escrito **con** vs **sin** `dim_date` — el contraste que refuerza Kimball.

[**`Notebook 03`**](03_funciones_de_fechas.ipynb)

<ins>4. Práctica</ins>

**15 ejercicios graduales** que combinan las tres familias de funciones. Estructurados en tres niveles: 5 fáciles (una sola familia a la vez), 5 medios (agregadas con strings o fechas), 5 difíciles (tres familias combinadas, `HAVING`, CTEs, `COUNT(*) FILTER`). Cada ejercicio trae el enunciado, una celda vacía para tu solución, y la solución oficial colapsable (`<details>`) para abrir solo cuando hayas intentado.

[**`Notebook 04`**](04_practica.ipynb)

## :books: Material

Los cuatro notebooks viven en este mismo directorio. Cada uno es **auto-contenido** — abre cualquiera y córrelo sin depender del estado de los anteriores. Solo asegúrate de tener el cluster Aurora del Tema 01 accesible (con `northwind_dwh` y `airbnb` ya cargados) y de reemplazar `AURORA_HOST` y `AURORA_PASSWORD` en la celda de Setup con los tuyos.

> :information_source: **JupySQL vs `pd.read_sql`** — en el Tema 04 ejecutabas SQL envolviéndolo en `pd.read_sql("...", engine)`. En este tema usamos JupySQL (`%%sql` magic) porque el contenido es 95% SQL y el envoltorio se volvía ruido visual. Las dos herramientas conviven sin problema: la misma conexión, los mismos engines, distinto azúcar sintáctico.

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="../Tema-06/Readme.md">Siguiente: Tema 06 →</a>
</p>
