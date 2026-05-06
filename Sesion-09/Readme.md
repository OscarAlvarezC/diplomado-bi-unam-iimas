# Sesión 09: SQL avanzado I — Funciones predefinidas

## :dart: Objetivo

Dominar las funciones predefinidas de PostgreSQL más usadas en queries analíticas: agregadas, de manipulación de strings y de fechas.

## :pushpin: Temas

- **Funciones agregadas:**
  - `count`, `sum`, `avg`, `min`, `max`.
  - `count(*)` vs `count(columna)` vs `count(DISTINCT columna)`.
  - `string_agg`, `array_agg` para concatenación.
- **Funciones para datos tipo carácter:**
  - Manipulación: `upper`, `lower`, `initcap`, `trim`, `ltrim`, `rtrim`.
  - Búsqueda: `position`, `strpos`, `like` / `ilike`.
  - Extracción: `substring`, `left`, `right`, `split_part`.
  - Concatenación: `concat`, `||`, `format`.
- **Funciones para datos tipo fecha:**
  - `now`, `current_date`, `current_timestamp`.
  - `date_trunc` (truncar a mes, trimestre, año, etc.).
  - `extract` (sacar componentes: año, mes, día de la semana).
  - Aritmética con `interval`.
  - `age`, diferencias entre fechas.

Práctica sobre el data warehouse de Northwind y el dataset Airbnb.

## :books: Material

> Por publicar.
