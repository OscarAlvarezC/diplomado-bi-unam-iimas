# Tema 06: PL/pgSQL — lógica procedural en el servidor

PostgreSQL incluye **PL/pgSQL**, su lenguaje procedural que vive dentro del motor. Te permite escribir lógica de control (`IF`, `CASE`, `FOR`, `WHILE`), declarar variables, manipular cursores, y empaquetar todo en **funciones definidas por el usuario** y **procedimientos almacenados** que se invocan desde queries normales. Este tema cubre el lenguaje completo y cuándo (y cuándo no) conviene usarlo en lugar de SQL set-based.

## :wrench: Setup técnico inicial

- **JupySQL** — mismo magic `%%sql` que en Tema-05. La celda de Setup de cada notebook detecta si JupySQL ya está instalado y, si no, lo instala (útil en Colab que trae ipython-sql pre-cargado).
- **Conexión SQLAlchemy** al cluster Aurora del Tema 01 — `northwind_oltp` y `northwind_dwh` ya cargados.
- **Dataset:** todos los ejemplos y ejercicios usan Northwind (OLTP y DWH).

## :dart: Objetivos

- Escribir bloques PL/pgSQL anónimos (`DO $$ ... $$;`) para lógica ad-hoc.
- Usar las estructuras de control de flujo (`IF`, `CASE`, `FOR`, `WHILE`).
- Manejar cursores explícitos y entender cuándo aportan vs cuándo son innecesarios.
- Crear, ejecutar y eliminar **procedimientos almacenados** con `CALL`.
- Crear funciones definidas por el usuario que devuelvan escalares, `SETOF`, o `TABLE`.
- Distinguir cuándo conviene una función, un procedimiento, o quedarse en SQL plano.

## :file_folder: Contenido

El tema se cubre en cinco notebooks Jupyter, en orden:

<ins>1. Introducción a PL/pgSQL y bloques anónimos</ins>

PL/pgSQL como lenguaje procedural integrado al motor. Sintaxis `DO $$ ... $$;` para ejecución ad-hoc. Variables con `DECLARE`. Asignación con `:=`. Mensajes con `RAISE NOTICE`/`WARNING`/`EXCEPTION`. Asignación desde queries con `SELECT INTO` y verificación con `FOUND`. `PERFORM` para ejecutar sin guardar resultado. Bloques anidados y scope. Manejo básico de excepciones con `BEGIN ... EXCEPTION ... END`.

[**`Notebook 01`**](https://colab.research.google.com/github/OscarAlvarezC/diplomado-bi-unam-iimas/blob/main/Tema-06/01_introduccion_y_bloques.ipynb)

<ins>2. Estructuras de control de flujo</ins>

`IF`-`ELSIF`-`ELSE`-`END IF`. `CASE` como expresión vs como sentencia. `LOOP` básico con `EXIT WHEN`. Los tres tipos de `FOR`: sobre rangos numéricos, sobre filas de query (el patrón más útil), sobre arrays con `FOREACH`. `WHILE` para condiciones de salida no determinadas. `CONTINUE` y loops etiquetados `<<nombre>>` para control en loops anidados.

[**`Notebook 02`**](https://colab.research.google.com/github/OscarAlvarezC/diplomado-bi-unam-iimas/blob/main/Tema-06/02_control_de_flujo.ipynb)

<ins>3. Funciones definidas por el usuario</ins>

`CREATE FUNCTION` con parámetros y `RETURNS`. Defaults en parámetros. Diferencia entre `LANGUAGE plpgsql` (procedural) y `LANGUAGE sql` (inline-able, más rápido cuando aplica). Retornos: escalar, `SETOF`, `TABLE(...)` con `RETURN NEXT` y `RETURN QUERY`. Categorías de **volatilidad** (`IMMUTABLE`/`STABLE`/`VOLATILE`) y por qué importan al optimizador. `OR REPLACE`, `DROP FUNCTION` con firma, overloading. Caso práctico sobre Northwind DWH.

[**`Notebook 03`**](https://colab.research.google.com/github/OscarAlvarezC/diplomado-bi-unam-iimas/blob/main/Tema-06/03_funciones.ipynb)

<ins>4. Procedimientos almacenados y cursores</ins>

Diferencia entre función y procedimiento (cómo se invocan, qué pueden hacer, control de transacciones). `CREATE PROCEDURE` + `CALL`. Parámetros con dirección `IN`/`OUT`/`INOUT`. Control de transacciones con `COMMIT`/`ROLLBACK` dentro del procedimiento. Cursores explícitos: `DECLARE`-`OPEN`-`FETCH`-`CLOSE`. Comparación con `FOR ... IN SELECT` (cursores implícitos). Tabla de decisión final: cuándo usar procedimiento, función, o SQL puro.

[**`Notebook 04`**](https://colab.research.google.com/github/OscarAlvarezC/diplomado-bi-unam-iimas/blob/main/Tema-06/04_procedimientos_y_cursores.ipynb)

<ins>5. Práctica</ins>

**12 ejercicios graduales** que combinan las cuatro lecturas anteriores sobre Northwind. Estructurados en tres niveles: 4 fáciles (bloques anónimos con `IF`/`FOR`/`SELECT INTO`), 4 medios (funciones con parámetros, `RETURNS TABLE`, manejo de excepciones), 4 difíciles (procedimientos, validaciones de invariantes, decidir entre función/procedimiento/SQL puro). Cada ejercicio tiene enunciado + celda vacía + solución colapsable.

[**`Notebook 05`**](https://colab.research.google.com/github/OscarAlvarezC/diplomado-bi-unam-iimas/blob/main/Tema-06/05_practica.ipynb)

## :books: Material

Los cinco notebooks viven en este mismo directorio. Cada uno es **auto-contenido** — abre cualquiera y córrelo sin depender del estado de los anteriores. Solo asegúrate de tener el cluster Aurora del Tema 01 accesible (con `northwind_oltp` y `northwind_dwh` ya cargados) y de reemplazar `AURORA_HOST` y `AURORA_PASSWORD` en la celda de Setup con los tuyos.

> :information_source: **Las funciones y procedimientos que crees viven en la base.** Si quieres mantener el schema limpio, ejecuta los `DROP FUNCTION IF EXISTS ...` que aparecen al final de cada notebook (o en cualquier momento desde DBeaver).

> :warning: **Cuidado con la "trampa del bucle" en PL/pgSQL.** En este tema vas a ver muchos ejemplos con `FOR ... IN SELECT ... LOOP`. Antes de copiar ese patrón a tu código, **pregúntate si la misma transformación se puede hacer con SQL set-based** (`UPDATE`, `INSERT INTO ... SELECT`, etc.). En la mayoría de los casos, sí — y será 10-100× más rápido. PL/pgSQL es para cuando SQL puro **no alcanza**, no para reemplazarlo.

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="../Tema-07/Readme.md">Siguiente: Tema 07 →</a>
</p>
