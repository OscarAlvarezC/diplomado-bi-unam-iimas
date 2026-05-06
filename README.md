# Módulo 4: Inteligencia de Negocios y SQL Avanzado

Diplomado **IIMAS – UNAM** en alianza con **AWS Academy**.

## :wave: Bienvenid@s

Al finalizar el módulo podrás diseñar e implementar un **data warehouse** sobre PostgreSQL, ejecutar **procesos ETL** en Python para integrar datos de fuentes heterogéneas, escribir **consultas analíticas avanzadas** con funciones de ventana, CTE recursivas y procedimientos almacenados, y **gestionar datos semiestructurados** con JSONB. Saldrás con habilidades transferibles a cualquier stack moderno de inteligencia de negocios y data engineering.

## :dart: Objetivo

Integrar los conceptos de OLAP, ETL y SQL avanzado en un caso práctico de inteligencia de negocios, generando reportes descriptivos y consultas analíticas de valor empresarial sobre Aurora PostgreSQL.

## ⚙ Requisitos

**Cero pre-trabajo.** Llegas a clase con tu laptop e internet, todo lo demás se monta en vivo durante las sesiones correspondientes.

Material de referencia que se usa en clase (no se requiere leerlo antes):

- [`Guías de setup técnico`](./setup/README.md) — 5 guías paso a paso que el instructor sigue contigo durante las sesiones 01, 02, 05 y 14.
- [`Datasets congelados`](./datasets/README.md) — Northwind y snapshot 2025-09-27 de Inside Airbnb CDMX.
- [`Scripts SQL`](./scripts/README.md) — DDL del star schema y poblado de dimensiones/hechos.

**Lo único que necesitas antes del primer día:**
- Cuenta de **AWS Academy Learner Lab** activa (la asigna IIMAS / coordinación del diplomado).
- Laptop con **conexión a internet** y permisos para instalar software.

## :bookmark_tabs: Sesiones

16 sesiones, 40 horas en total.

- [`Sesion-01:` Setup técnico — montar el entorno de trabajo](./Sesion-01/Readme.md)
- [`Sesion-02:` Fundamentos OLAP — OLTP vs OLAP y modelo multidimensional](./Sesion-02/Readme.md)
- [`Sesion-03:` Esquemas dimensionales — estrella, copo de nieve, galaxy](./Sesion-03/Readme.md)
- [`Sesion-04:` Implementación del DW — análisis del DDL y la transformación SQL](./Sesion-04/Readme.md)
- [`Sesion-05:` ETL con Python I — Fundamentos y extracción](./Sesion-05/Readme.md)
- [`Sesion-06:` ETL con Python II — Limpieza y perfilado](./Sesion-06/Readme.md)
- [`Sesion-07:` ETL con Python III — Transformación según reglas de negocio](./Sesion-07/Readme.md)
- [`Sesion-08:` ETL con Python IV — Carga, orquestación y buenas prácticas](./Sesion-08/Readme.md)
- [`Sesion-09:` SQL avanzado I — Funciones predefinidas](./Sesion-09/Readme.md)
- [`Sesion-10:` SQL avanzado II — Estructuras de control y cursores](./Sesion-10/Readme.md)
- [`Sesion-11:` PL/pgSQL — Procedimientos almacenados y funciones definidas](./Sesion-11/Readme.md)
- [`Sesion-12:` Funciones de ventana](./Sesion-12/Readme.md)
- [`Sesion-13:` Common Table Expressions y análisis jerárquico](./Sesion-13/Readme.md)
- [`Sesion-14:` Datos semiestructurados I — hstore](./Sesion-14/Readme.md)
- [`Sesion-15:` Datos semiestructurados II — JSONB](./Sesion-15/Readme.md)
- [`Sesion-16:` Caso integrador](./Sesion-16/Readme.md)

> **Sesión 01 es 100% operacional**: cluster Aurora + DBeaver + carga de los 3 schemas (Northwind OLTP, DWH, Airbnb). A partir de Sesión 02 todo es contenido analítico sobre datos ya disponibles.

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
