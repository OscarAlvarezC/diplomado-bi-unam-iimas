# Módulo 4: Inteligencia de Negocios y SQL Avanzado

Diplomado **IIMAS – UNAM** en alianza con **AWS Academy**.

## :wave: Bienvenid@s

Al finalizar el módulo podrás diseñar e implementar un **data warehouse** sobre PostgreSQL, ejecutar **procesos ETL** en Python para integrar datos de fuentes heterogéneas, escribir **consultas analíticas avanzadas** con funciones de ventana, CTE recursivas y procedimientos almacenados, y **gestionar datos semiestructurados** con JSONB. Saldrás con habilidades transferibles a cualquier stack moderno de inteligencia de negocios y data engineering.

## :dart: Objetivo

Integrar los conceptos de OLAP, ETL y SQL avanzado en un caso práctico de inteligencia de negocios, generando reportes descriptivos y consultas analíticas de valor empresarial sobre Aurora PostgreSQL.

## ⚙ Requisitos

**Cero pre-trabajo.** Llegas a clase con tu laptop e internet, todo lo demás se monta en vivo durante las sesiones correspondientes.

Material de referencia que se usa en clase (no se requiere leerlo antes):

- [`Temario del diplomado`](./temario/README.md) — los 8 módulos del diplomado completo (este repo cubre el Módulo 4).
- [`Guías de setup técnico`](./setup/README.md) — 5 guías paso a paso que el instructor sigue contigo durante las sesiones 01, 02, 05 y 14.
- [`Datasets congelados`](./datasets/README.md) — Northwind y snapshot 2025-09-27 de Inside Airbnb CDMX.
- [`Scripts SQL`](./scripts/README.md) — DDL del star schema y poblado de dimensiones/hechos.
- [`Anexos`](./anexos/README.md) — material de referencia transversal: glosario de servicios AWS, etc.

**Lo único que necesitas antes del primer día:**
- Cuenta de **AWS Academy Learner Lab** activa (la asigna IIMAS / coordinación del diplomado).
- Laptop con **conexión a internet** y permisos para instalar software.

## :bookmark_tabs: Temas

11 temas que cubren las 40 horas del módulo. **El ritmo es adaptativo** — cada tema se cubre en el tiempo que el grupo necesite, sin atadura 1:1 a una sesión de clase.

- [`Tema-01:` Setup técnico — montar el entorno de trabajo](./Tema-01/Readme.md)
- [`Tema-02:` Fundamentos OLAP — OLTP vs OLAP y modelo multidimensional](./Tema-02/Readme.md)
- [`Tema-03:` Esquemas dimensionales — estrella, copo de nieve, galaxy](./Tema-03/Readme.md)
- [`Tema-04:` Implementación del DW — análisis del DDL y la transformación SQL](./Tema-04/Readme.md)
- [`Tema-05:` ETL con Python — extracción, perfilado, limpieza, transformación, carga](./Tema-05/Readme.md)
- [`Tema-06:` SQL avanzado — funciones predefinidas](./Tema-06/Readme.md)
- [`Tema-07:` PL/pgSQL — control de flujo, cursores, procedimientos y funciones](./Tema-07/Readme.md)
- [`Tema-08:` Funciones de ventana](./Tema-08/Readme.md)
- [`Tema-09:` Common Table Expressions y análisis jerárquico](./Tema-09/Readme.md)
- [`Tema-10:` Datos semiestructurados — hstore y JSONB](./Tema-10/Readme.md)
- [`Tema-11:` Caso integrador](./Tema-11/Readme.md)

> **Tema 01 es 100% operacional**: cluster Aurora + DBeaver + carga de los 3 schemas (Northwind OLTP, DWH, Airbnb). A partir del Tema 02 todo es contenido analítico sobre datos ya disponibles.

## :bar_chart: Datos: orígenes y atribución

### Northwind

Dataset clásico de demostración de Microsoft (público, sin restricciones). Versión adaptada para PostgreSQL: [pthom/northwind_psql](https://github.com/pthom/northwind_psql).

### Airbnb CDMX

Snapshot del **27 de septiembre de 2025** publicado por [Inside Airbnb](http://insideairbnb.com/) — proyecto independiente de transparencia urbana, **no afiliado a Airbnb la empresa**. Datos liberados bajo **CC0** (dominio público). Inside Airbnb publica snapshots mensuales y borra los anteriores; este repo congela la versión usada en el módulo para reproducibilidad entre semestres.

Más información: <http://insideairbnb.com/about/>.

## :scroll: Licencia

- **Scripts SQL, guías de setup, contenido por bloque y código en general:** MIT (ver `LICENSE`).
- **Datasets:** licencias originales de cada fuente (CC0 para Inside Airbnb, dominio público para Northwind).

## :wrench: Reportar problemas

Si encuentras errores en las guías, scripts o datos, abre un issue en este repo o avisa en clase.
