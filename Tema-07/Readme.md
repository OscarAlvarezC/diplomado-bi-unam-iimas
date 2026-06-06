# Tema 07: Funciones de ventana

## :dart: Objetivo

Resolver problemas analíticos clásicos (rankings, comparativas con valores adyacentes, agregados móviles) usando funciones de ventana, sin recurrir a self-joins ni subconsultas correlacionadas.

## :pushpin: Temas

- **La cláusula `OVER`:** introducción al concepto de "ventana" sobre el resultado.
- **`PARTITION BY`** y **`ORDER BY`** dentro de la ventana — qué hacen y cuándo se usan.
- **Funciones de ranking:**
  - `ROW_NUMBER` — fila secuencial.
  - `RANK` — con huecos.
  - `DENSE_RANK` — sin huecos.
- **Función de desplazamiento `LEAD`** — valor de la fila siguiente (análisis de tendencia). Su gemela `LAG` se menciona de pasada.
- **Frames de ventana** (`ROWS BETWEEN`) — lo necesario para los agregados móviles.
- **Agregados móviles:**
  - Sumas acumulativas (running totals).
  - Promedios móviles (rolling averages).

Práctica sobre `fact_sales` × `dim_date` y `dim_product`: top-N productos por categoría, acumulados y promedios móviles mensuales, variación mes contra mes.

## :books: Material

[**`Notebook 01 — Funciones de ventana`**](https://colab.research.google.com/github/OscarAlvarezC/diplomado-bi-unam-iimas/blob/main/Tema-07/01_funciones_de_ventana.ipynb)

Cubre exactamente lo explícito del temario: `OVER`, `PARTITION BY`, ranking (`ROW_NUMBER`/`RANK`/`DENSE_RANK`), top-N por grupo, agregados móviles y `LEAD`.

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="../Tema-08/Readme.md">Siguiente: Tema 08 →</a>
</p>
