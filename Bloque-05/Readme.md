# Bloque 05: Funciones de ventana y CTE

## :dart: Objetivo

Implementar técnicas analíticas con SQL avanzado, incluyendo funciones de ventana, CTE, recursividad, uniones y análisis de datos jerárquicos.

## :clock1: Duración

7 horas.

## :pushpin: Temas

- **Funciones de ventana (window functions):**
  - Cláusula `OVER`.
  - `PARTITION BY` y `ORDER BY` dentro de la ventana.
  - Funciones de ranking: `ROW_NUMBER`, `RANK`, `DENSE_RANK`.
  - Funciones de desplazamiento: `LEAD`, `LAG`.
  - Promedios móviles, sumas acumulativas, análisis lead.
- **Common Table Expressions (CTE):**
  - Sintaxis `WITH`.
  - CTE simples: legibilidad y reutilización dentro de una query.
  - **`WITH RECURSIVE`** para datos jerárquicos.
  - Análisis de la jerarquía empleado → jefe en Northwind como caso de uso ideal.
- **Uniones avanzadas:**
  - `UNION ALL` para combinar facts de distintos granos.
  - Self-joins.

## :books: Material

> Por publicar.

Ejercicios de práctica usando la fact `northwind_dwh.fact_sales` con su `dim_date` (1996-1998): rolling sums por mes, top-N productos por categoría, comparativas YoY/MoM, análisis lead de ventas.
