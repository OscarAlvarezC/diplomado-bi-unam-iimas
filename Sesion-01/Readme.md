# Sesión 01: Setup técnico — montar el entorno de trabajo

## :dart: Objetivo

Al cierre de esta sesión cada alumno tiene su entorno completo operacional: cluster Aurora corriendo, DBeaver conectado, y los **tres schemas** del módulo (`northwind_oltp`, `northwind_dwh`, `airbnb`) cargados y verificados. Es la única sesión 100% operacional del módulo — a partir de la 02 todo es contenido analítico sobre estos datos ya disponibles.

## :clock1: Duración

2.5 horas.

## :pushpin: Pasos hands-on

Se siguen las guías de `setup/` en orden, con el instructor explicando lo crítico en vivo:

1. **Cluster Aurora PostgreSQL** en Learner Lab (~25 min) — [`../setup/01_cluster_aurora.md`](../setup/01_cluster_aurora.md).
2. **DBeaver Community** instalado, security group My IP abierto, conexión validada (~25 min) — [`../setup/02_dbeaver_conexion.md`](../setup/02_dbeaver_conexion.md).
3. **Cargar Northwind OLTP** desde el dump (~15 min) — [`../setup/03_northwind_oltp.md`](../setup/03_northwind_oltp.md).
4. **Construir el data warehouse:** ejecutar el DDL + los 3 scripts de populate (~30 min) — [`../setup/04_northwind_dwh.md`](../setup/04_northwind_dwh.md). El instructor explica brevemente cada script; el análisis profundo de patrones Kimball se hace en Sesión 04.
5. **Cargar Airbnb CDMX** vía DBeaver Import Wizard (~30 min) — [`../setup/05_airbnb.md`](../setup/05_airbnb.md).
6. **Smoke test** (~10 min): query analítica que toque los 3 schemas, para confirmar que toda la cadena funciona.

## :bulb: ¿Por qué consolidar todo en una sesión?

Eficiencia. Una sola sesión "operacional" libera las 15 sesiones siguientes para enfocarse al 100% en contenido analítico. Si el setup se distribuye, **cada sesión paga peaje de tiempo en SET search_path, conexiones, error handling**, y el flujo conceptual se rompe.

## :books: Material

Las guías de [`../setup/`](../setup/) son el step-by-step que se sigue en clase. Quedan ahí para que cada alumno pueda volver a ellas si necesita repetir o entender un paso fuera de horas.
