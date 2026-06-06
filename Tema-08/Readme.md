# Tema 08: Common Table Expressions y análisis jerárquico

## :dart: Objetivo

Usar CTEs (Common Table Expressions) para escribir queries complejas legibles, y resolver problemas de jerarquías y datos recursivos con `WITH RECURSIVE`.

## :pushpin: Temas

- **CTEs simples (`WITH`):** sintaxis, semántica y CTEs encadenadas (legibilidad y reutilización dentro de la query).
- **CTEs recursivas (`WITH RECURSIVE`):** estructura caso base + `UNION ALL` + caso recursivo, y cómo PostgreSQL las evalúa.
- **Análisis jerárquico** (jerarquía empleado → jefe en Northwind):
  - Recorrido descendente con cálculo del nivel (organigrama).
  - Recorrido ascendente (cadena de mando).
- **`UNION ALL`** — apilar resultados (y su papel en la recursión).

## :books: Material

[**`Notebook 01 — Common Table Expressions`**](https://colab.research.google.com/github/OscarAlvarezC/diplomado-bi-unam-iimas/blob/main/Tema-08/01_cte.ipynb)

Cubre lo explícito del temario: `WITH` simple y encadenadas, `WITH RECURSIVE` (jerarquía empleado→jefe, descendente y ascendente) y `UNION ALL`.

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="../Tema-09/Readme.md">Siguiente: Tema 09 →</a>
</p>
