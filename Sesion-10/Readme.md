# Sesión 10: SQL avanzado II — Estructuras de control y cursores

## :dart: Objetivo

Escribir lógica procedural en PL/pgSQL usando estructuras de control de flujo, y entender cuándo los cursores son la herramienta correcta vs cuándo conviene quedarse en SQL set-based.

## :clock1: Duración

2.5 horas.

## :pushpin: Temas

- Introducción a **PL/pgSQL** como lenguaje procedural de PostgreSQL.
- Bloques anónimos (`DO $$ ... $$`).
- **Estructuras de control:**
  - `IF-THEN-ELSE-END IF`.
  - `CASE` (expresión y sentencia).
  - Ciclos `FOR` (sobre rangos, queries, arrays).
  - Ciclos `WHILE`.
- **Cursores:**
  - Declaración con `DECLARE`.
  - `OPEN`, `FETCH`, `CLOSE`.
  - Cursores explícitos vs `FOR` loops sobre queries (implícitos).
  - **Cuándo usar cursores:** procesamiento fila por fila con efectos secundarios (raro).
  - **Cuándo evitar cursores:** transformaciones que se pueden hacer con `UPDATE/INSERT … SELECT` (lo común).

## :books: Material

> Por publicar.
