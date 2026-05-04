# Sesión 07: ETL con Python III — Transformación según reglas de negocio

## :dart: Objetivo

Transformar DataFrames limpios aplicando reglas de negocio: cálculos derivados, joins, generación de la dimensión de tiempo, y construcción de las dimensiones y la tabla de hechos en memoria.

## :clock1: Duración

2.5 horas.

## :pushpin: Temas

- **Cálculo de valores derivados** (márgenes, totales, ratios) con operaciones vectorizadas de pandas.
- **Joins entre DataFrames** con `merge`: how='inner'/'left'/'outer', múltiples keys.
- **Generación de `dim_date`** en pandas con `pd.date_range` + atributos calendáricos derivados.
- **Construcción de las dimensiones desnormalizadas** en pandas — el equivalente a los `INSERT…SELECT…JOIN` que vimos en Sesión 04, ahora en código Python.
- **Construcción de la tabla de hechos** con resolución de surrogate keys vía merge sucesivo.
- Estrategias para garantizar **integridad referencial** antes de la carga.

## :books: Material

> Por publicar.
