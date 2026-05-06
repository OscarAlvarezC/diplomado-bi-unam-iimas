# Sesión 06: ETL con Python II — Limpieza y perfilado

## :dart: Objetivo

Aplicar técnicas de perfilado y limpieza a un dataset extraído, identificar problemas de calidad de datos, y normalizar tipos y formatos para la siguiente etapa de transformación.

## :pushpin: Temas

- **Perfilado del DataFrame:**
  - `df.info()` — tipos y nullable.
  - `df.describe()` — estadísticas por columna numérica.
  - `df.isna().sum()` — conteo de nulos por columna.
  - `df.value_counts()` — distribución de valores categóricos.
- **Limpieza:**
  - Manejo de nulos: drop, fillna, indicadores.
  - Deduplicación con `drop_duplicates`.
  - Normalización de strings (`str.strip`, `str.lower`, regex).
- **Conversión de tipos:**
  - `astype` para tipos numéricos y categóricos.
  - Parseo de fechas con `pd.to_datetime`.
- **Estandarización:**
  - Catálogos de valores aceptados.
  - Unificación de formatos (e.g., teléfonos, códigos postales).

## :books: Material

> Por publicar.
