# Tema 08: Common Table Expressions y análisis jerárquico

## :dart: Objetivo

Usar CTEs (Common Table Expressions) para escribir queries complejas legibles, y resolver problemas de jerarquías y datos recursivos con `WITH RECURSIVE`.

## :pushpin: Temas

- **`UNION` y `UNION ALL`** — apilar resultados de varios `SELECT`: `UNION ALL` conserva duplicados (y es la pieza de la recursión), `UNION` (sin `ALL`) los elimina. La variante `UNION` no está en el temario, pero se incluye como introducción para distinguirla bien.
- **CTEs simples (`WITH`):** sintaxis, semántica y CTEs encadenadas (legibilidad y reutilización dentro de la query).
- **CTEs recursivas (`WITH RECURSIVE`):** estructura caso base + `UNION ALL` + caso recursivo, y cómo PostgreSQL las evalúa (incluye un primer ejemplo que genera una serie de fechas).
- **Análisis jerárquico** (jerarquía empleado → jefe en Northwind):
  - Recorrido descendente con cálculo del nivel.
  - Recorrido ascendente (cadena de mando).

## :books: Material

[**`Notebook 01 — Common Table Expressions`**](https://colab.research.google.com/github/OscarAlvarezC/diplomado-bi-unam-iimas/blob/main/Tema-08/01_cte.ipynb)

Cubre lo explícito del temario: `WITH` simple y encadenadas, `WITH RECURSIVE` (jerarquía empleado→jefe, descendente y ascendente) y `UNION ALL`. Añade además una introducción a `UNION` (sin `ALL`) y su diferencia con `UNION ALL` —no contemplada en el temario, pero útil para elegir bien.

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="../Tema-09/Readme.md">Siguiente: Tema 09 →</a>
</p>
