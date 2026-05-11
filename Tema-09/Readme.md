# Tema 09: Common Table Expressions y análisis jerárquico

## :dart: Objetivo

Usar CTEs (Common Table Expressions) para escribir queries complejas legibles, y resolver problemas de jerarquías y datos recursivos con `WITH RECURSIVE`.

## :pushpin: Temas

- **CTEs simples (`WITH`):**
  - Sintaxis y semántica.
  - Diferencias frente a subqueries y vistas.
  - Cuándo aportan: legibilidad, reutilización dentro de la query, debugging.
- **CTEs recursivas (`WITH RECURSIVE`):**
  - Estructura: caso base + caso recursivo + UNION ALL.
  - Cómo PostgreSQL las evalúa.
- **Análisis jerárquico:**
  - Caso clásico: la jerarquía empleado → manager en Northwind.
  - Recorrido descendente (todos los subordinados de un manager).
  - Recorrido ascendente (cadena de mando completa).
  - Cálculo del nivel jerárquico.
- **Otros casos de uso recursivo:**
  - Generación de secuencias (alternativa a `generate_series`).
  - Bill-of-materials, redes, grafos.
- **`UNION ALL`** como herramienta para combinar facts de distintos granos.

## :books: Material

> Por publicar.

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="../Tema-10/Readme.md">Siguiente: Tema 10 →</a>
</p>
