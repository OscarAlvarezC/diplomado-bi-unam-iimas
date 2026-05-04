# Módulo 4: Inteligencia de Negocios y SQL Avanzado

Diplomado **IIMAS – UNAM** en alianza con **AWS Academy**.

## :wave: Bienvenid@s

Al finalizar el módulo podrás diseñar e implementar un **data warehouse** sobre PostgreSQL, ejecutar **procesos ETL** en Python para integrar datos de fuentes heterogéneas, escribir **consultas analíticas avanzadas** con funciones de ventana, CTE recursivas y procedimientos almacenados, y **gestionar datos semiestructurados** con JSONB. Saldrás con habilidades transferibles a cualquier stack moderno de inteligencia de negocios y data engineering.

## :dart: Objetivo

Integrar los conceptos de OLAP, ETL y SQL avanzado en un caso práctico de inteligencia de negocios, generando reportes descriptivos y consultas analíticas de valor empresarial sobre Aurora PostgreSQL.

## ⚙ Requisitos

Antes de la primera sesión:

- [`Configuración del entorno`](./setup/README.md) — 5 guías paso a paso (~2.5 h totales): cluster Aurora, DBeaver, Northwind OLTP, data warehouse, Airbnb CDMX.
- [`Datasets congelados`](./datasets/README.md) — Northwind y snapshot 2025-09-27 de Inside Airbnb CDMX.
- [`Scripts SQL`](./scripts/README.md) — DDL del star schema y poblado de dimensiones/hechos.

> :bulb: **Tip:** completa los 5 documentos de `setup/` **antes** del primer día de clase. La primera sesión arranca asumiendo que ya tienes el entorno listo.

## :bookmark_tabs: Bloques

- [`Bloque-01:` Fundamentos OLAP](./Bloque-01/Readme.md) — 5 h
- [`Bloque-02:` Implementación del warehouse](./Bloque-02/Readme.md) — 6 h
- [`Bloque-03:` ETL con Python](./Bloque-03/Readme.md) — 8 h (4 subsesiones de 2 h)
- [`Bloque-04:` SQL avanzado y PL/pgSQL](./Bloque-04/Readme.md) — 7 h
- [`Bloque-05:` Funciones de ventana y CTE](./Bloque-05/Readme.md) — 7 h
- [`Bloque-06:` Datos semiestructurados (hstore, JSONB)](./Bloque-06/Readme.md) — 4.5 h
- [`Bloque-07:` Caso integrador](./Bloque-07/Readme.md) — 2.5 h

**Total:** 40 horas.

## :bar_chart: Datos: orígenes y atribución

### Northwind

Dataset clásico de demostración de Microsoft (público, sin restricciones). Versión adaptada para PostgreSQL: [pthom/northwind_psql](https://github.com/pthom/northwind_psql).

### Airbnb CDMX

Snapshot del **27 de septiembre de 2025** publicado por [Inside Airbnb](http://insideairbnb.com/) — proyecto independiente de transparencia urbana, **no afiliado a Airbnb la empresa**. Datos liberados bajo **CC0** (dominio público). Inside Airbnb publica snapshots mensuales y borra los anteriores; este repo congela la versión usada en el módulo para reproducibilidad entre semestres.

Más información: <http://insideairbnb.com/about/>.

## :scroll: Licencia

- **Scripts SQL, guías de setup, contenido por bloque y código en general:** MIT (ver `LICENSE`).
- **Datasets:** licencias originales de cada fuente (CC0 para Inside Airbnb, dominio público para Northwind).

## :school: Contexto académico

Curso impartido por **Oscar Alvarez** en el **Instituto de Investigaciones en Matemáticas Aplicadas y en Sistemas (IIMAS)** de la UNAM, en alianza con AWS Academy. Las decisiones técnicas (Aurora PostgreSQL Provisioned `db.t3.medium`, DBeaver Community, ETL en Python con SQLAlchemy + pandas) responden a las restricciones del Educator Learner Lab y a un enfoque pedagógico de profundidad sobre amplitud — pocas herramientas dominadas a fondo, alta transferibilidad de habilidades.

## :wrench: Reportar problemas

Si encuentras errores en las guías, scripts o datos, abre un issue en este repo o avisa en clase.
