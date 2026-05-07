# Sesión 12: Funciones de ventana

## :dart: Objetivo

Resolver problemas analíticos clásicos (rankings, comparativas con valores adyacentes, agregados móviles) usando funciones de ventana, sin recurrir a self-joins ni subconsultas correlacionadas.

## :pushpin: Temas

- **La cláusula `OVER`:** introducción al concepto de "ventana" sobre el resultado.
- **`PARTITION BY`** y **`ORDER BY`** dentro de la ventana — qué hacen y cuándo se usan.
- **Funciones de ranking:**
  - `ROW_NUMBER` — fila secuencial.
  - `RANK` — con huecos.
  - `DENSE_RANK` — sin huecos.
- **Funciones de desplazamiento:**
  - `LEAD` — valor de la fila siguiente.
  - `LAG` — valor de la fila anterior.
- **Frames de ventana:** `ROWS BETWEEN`, `RANGE BETWEEN`.
- **Agregados móviles:**
  - Promedios móviles (rolling averages).
  - Sumas acumulativas (running totals).
  - Análisis lead (predicción de tendencias simples).

Práctica intensiva sobre `fact_sales` × `dim_date`: top-N productos por mes, comparativas año-contra-año, rolling 30 días.

## :books: Material

> Por publicar.

---

[← Volver al inicio](../README.md) | [Siguiente: Sesión 13 →](../Sesion-13/Readme.md)
