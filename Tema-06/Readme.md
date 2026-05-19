# Tema 06: PL/pgSQL — lógica procedural en el servidor

PostgreSQL incluye **PL/pgSQL**, su lenguaje procedural que vive dentro del motor. Te permite escribir lógica de control (`IF`, `CASE`, `FOR`, `WHILE`), declarar variables, manipular cursores, y empaquetar todo en **funciones definidas por el usuario** y **procedimientos almacenados** que se invocan desde queries normales. Este tema cubre el lenguaje completo y cuándo (y cuándo no) conviene usarlo en lugar de SQL set-based.

## :dart: Objetivos

- Escribir bloques PL/pgSQL anónimos para lógica ad-hoc.
- Usar las estructuras de control de flujo (`IF`, `CASE`, `FOR`, `WHILE`) de PL/pgSQL.
- Manejar cursores explícitos y entender cuándo aportan vs cuándo son innecesarios.
- Crear, ejecutar y eliminar **procedimientos almacenados**.
- Crear funciones definidas por el usuario que devuelven escalares o tablas.
- Distinguir cuándo conviene una función, un procedimiento, o quedarse en SQL plano.

## :file_folder: Contenido

<ins>1. Introducción a PL/pgSQL y bloques anónimos</ins>

PL/pgSQL como lenguaje procedural integrado al motor PostgreSQL. Sintaxis básica: bloque `DO $$ ... $$;` para ejecución ad-hoc sin guardar el código. Variables locales con `DECLARE`. Asignación con `:=`. Mensajes con `RAISE NOTICE`.

<ins>2. Estructuras de control de flujo</ins>

- **`IF-THEN-ELSIF-ELSE-END IF`** — condicionales clásicas.
- **`CASE`** — variantes de expresión y de sentencia.
- **Ciclos `FOR`** — sobre rangos numéricos, sobre filas de queries, sobre elementos de arrays.
- **Ciclos `WHILE`** — para condiciones de salida no determinadas por iteración.
- **`EXIT`** y **`CONTINUE`** dentro de loops.

<ins>3. Cursores</ins>

Declaración con `DECLARE`. Operaciones: `OPEN`, `FETCH`, `CLOSE`. Cursores explícitos vs `FOR` loops sobre queries (que crean cursores implícitos por debajo). **Cuándo usar cursores:** procesamiento fila por fila con efectos secundarios (raro). **Cuándo evitar cursores:** transformaciones que se pueden hacer con `UPDATE/INSERT … SELECT` (lo común y lo eficiente).

<ins>4. Procedimientos almacenados</ins>

`CREATE PROCEDURE`, parámetros `IN`, `OUT`, `INOUT`. Ejecución con `CALL`. Eliminación con `DROP PROCEDURE`. Casos de uso típicos: efectos secundarios, control explícito de transacciones (un procedimiento puede hacer `COMMIT` y `ROLLBACK` internamente — una función no puede).

<ins>5. Funciones definidas por el usuario</ins>

`CREATE FUNCTION` con `RETURNS`. Funciones que devuelven escalares (`RETURNS NUMERIC`, etc.). Funciones que devuelven sets (`RETURNS TABLE`, `RETURNS SETOF`). **Categorías de volatilidad:** `IMMUTABLE` (no toca DB, mismo input → mismo output), `STABLE` (toca DB pero no escribe), `VOLATILE` (puede escribir o cambiar entre llamadas) — el optimizador las usa para decidir si cachear.

<ins>6. Procedimiento vs función — cuándo elegir cada uno</ins>

- **Funciones:** cómputo determinista, **usables dentro de `SELECT`**, pueden formar parte de queries, pueden indexarse (si `IMMUTABLE`).
- **Procedimientos:** efectos secundarios, control explícito de transacciones, **no usables en queries**, se invocan con `CALL`.

Casos prácticos sobre el DW: función para calcular ventas netas por categoría/periodo, procedimiento para refrescar agregados pre-calculados, función `IMMUTABLE` para un cálculo que se reutiliza en muchas queries.

## :books: Material

> Por publicar.

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="../Tema-07/Readme.md">Siguiente: Tema 07 →</a>
</p>
