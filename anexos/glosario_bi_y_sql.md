# Glosario de BI y SQL

Términos que aparecen recurrentemente en el módulo. Organizados por categoría temática, no alfabéticamente — para que veas términos relacionados juntos. Si buscas algo específico, usa `Ctrl+F` / `Cmd+F`.

Si buscas términos de **AWS** (servicios, infraestructura), ese glosario está en [`glosario_aws.md`](glosario_aws.md).

---

## :file_folder: Estructura de la base de datos

### Base de datos (database)
Contenedor lógico de schemas, tablas, índices, etc. En PostgreSQL una conexión apunta a una base; dentro hay schemas. **No** es lo mismo que en MySQL (donde "database" y "schema" son sinónimos).

### Schema
Espacio de nombres dentro de una base de datos. Agrupa tablas, vistas y funciones relacionadas. En este módulo: `northwind_oltp`, `northwind_dwh`, `airbnb`.

### Tabla
Estructura de filas y columnas que almacena datos relacionados. Cada fila es una entidad; cada columna un atributo de esa entidad.

### Vista (view)
Query SQL guardada que se comporta como una tabla virtual. Se actualiza dinámicamente cuando consultas la vista — refleja el estado actual de las tablas subyacentes.

### Materialized view
Como una vista pero **almacena el resultado en disco**. Más rápida de leer, pero requiere refresh manual o programado para actualizarse.

### Schema vs Base vs Tabla — jerarquía PostgreSQL
```
Cluster → Database → Schema → Table → Column → Row → Value
```
Tres niveles entre cluster y tabla; MySQL solo tiene dos (cluster → database/schema → table).

---

## :key: Claves (keys) y constraints

### Primary Key (PK)
Columna(s) que **identifica unívocamente** cada fila de una tabla. Implica `NOT NULL` + `UNIQUE`. Una tabla tiene exactamente una PK.

### Foreign Key (FK)
Columna que **apunta a la PK de otra tabla** (o a la misma tabla si es self-FK). Garantiza integridad referencial: el valor debe existir como PK en la tabla referenciada.

### Composite key (PK compuesta)
Clave primaria formada por **dos o más columnas** combinadas. Ej. `order_details(order_id, product_id)`: la pareja identifica la línea, no cada columna por separado.

### Surrogate key
Clave artificial generada por el sistema (típicamente entero auto-incremental). **No tiene significado de negocio.** Ej. `customer_key` en `dim_customer`.

### Natural key
Clave que **viene del dominio del negocio** y tiene significado por sí misma. Ej. `customer_id = 'ALFKI'` en `customers`. En el DWH se conserva como atributo además de la surrogate key.

### Self-FK (clave foránea recursiva)
FK que apunta a la **misma tabla** donde vive. Ej. `employees.reports_to` apunta a `employees.employee_id`. Permite jerarquías en una sola tabla.

### Smart key
PK con **significado interpretable directamente**. Ej. `dim_date.date_key = 19970315` (YYYYMMDD como entero) — filtrable sin join: `WHERE date_key BETWEEN 19970101 AND 19971231`.

### Degenerate dimension
Identificador del evento original que **vive en la fact table sin tabla propia**. Ej. `order_id` en `fact_sales` — sirve para `COUNT(DISTINCT)` pero no tiene atributos descriptivos propios.

### Constraint
Regla declarativa que el motor hace cumplir. Tipos: `PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE`, `NOT NULL`, `CHECK`.

### CHECK constraint
Expresión booleana que debe cumplir cada fila. Ej. `CHECK (unit_price >= 0)` impide precios negativos.

---

## :triangular_ruler: Normalización

### Atributo descriptivo
Cualquier columna que **describe** una entidad sin ser PK. Si la PK es `product_id`, todo lo demás (`product_name`, `unit_price`, `category_id`, etc.) son atributos descriptivos.

### Dependencia funcional
"Si A → B" = "saber A me dice B automáticamente". Ej. `product_id → product_name` (saber el ID del producto te da su nombre). 3NF restringe qué dependencias se permiten dentro de una tabla.

### 1NF (Primera Forma Normal)
Cada celda contiene **un solo valor atómico** — no listas dentro de una columna.

### 2NF (Segunda Forma Normal)
Si la PK es compuesta, cada atributo no-clave depende de **toda** la PK, no de parte de ella. Raramente relevante con surrogate keys.

### 3NF (Tercera Forma Normal)
Cada atributo descriptivo depende **solo de la PK de su tabla**, no de otros atributos. Es la forma normal "estándar" en sistemas transaccionales.

### Desnormalización deliberada
Romper 3NF **a propósito** para optimizar lecturas. En DWH se aplanan dimensiones (ej. `category_name` se copia en `dim_product` aunque dependa de `category_id`).

---

## :books: SQL básico

### SELECT
Lee datos de una o más tablas. Es el verbo más común en SQL analítico.

### JOIN
Combina filas de dos tablas según una condición de relación. Tipos: `INNER` (solo filas con match), `LEFT/RIGHT` (todas de un lado), `FULL OUTER` (todas de ambos), `CROSS` (producto cartesiano).

### WHERE
Filtra filas según una condición. Se evalúa **antes** de las agregaciones.

### GROUP BY
Agrupa filas que comparten valor en una o más columnas. Necesario para usar funciones agregadas (`SUM`, `COUNT`, `AVG`, etc.) sobre grupos en lugar de toda la tabla.

### HAVING
Filtra **grupos** después del `GROUP BY`. Ej. `HAVING SUM(line_total) > 1000` — solo grupos con ventas mayores a 1000.

### ORDER BY
Ordena el resultado final por una o más columnas, ascendente (`ASC`) o descendente (`DESC`).

### LIMIT
Restringe cuántas filas devuelve la query. Ej. `LIMIT 10` para top-10.

### Funciones agregadas
`COUNT(*)`, `SUM(col)`, `AVG(col)`, `MIN(col)`, `MAX(col)`. Operan sobre grupos de filas y producen un solo valor por grupo.

### CTE (Common Table Expression)
Sub-query nombrada usando `WITH` que se puede referenciar en la query principal. Mejora legibilidad para queries complejas. Si lleva `RECURSIVE` permite jerarquías.

### Window function
Función que opera sobre un subconjunto ("ventana") de filas relacionadas a la fila actual, sin colapsar el resultado como hace `GROUP BY`. Ej. `RANK() OVER (PARTITION BY category ORDER BY ventas DESC)`.

---

## :department_store: Modelado dimensional / OLAP

### OLTP (Online Transaction Processing)
Sistema diseñado para **operar el negocio**: muchas escrituras pequeñas concurrentes con baja latencia. Normalizado en 3NF.

### OLAP (Online Analytical Processing)
Sistema diseñado para **entender el negocio**: lecturas masivas con agregación, latencia tolerable. Desnormalizado en estrella o copo.

### Data warehouse (DWH)
Base de datos optimizada para análisis. Recibe datos del OLTP vía ETL. En Northwind: `northwind_dwh` (esquema estrella con 5 dims + 1 fact).

### Modelo multidimensional
Marco conceptual donde los datos se representan como un cubo: ejes (dimensiones) + valores en las celdas (medidas). Formalizado por Ralph Kimball.

### Tabla de hechos (fact table)
Tabla central del modelo dimensional. Registra **eventos medibles** del negocio (una venta, un click, una llamada). Sus columnas son medidas numéricas + FKs a dimensiones.

### Dimensión
Tabla que describe el **contexto** de los hechos (quién, qué, cuándo, dónde, cómo). En Northwind: `dim_customer`, `dim_product`, `dim_employee`, `dim_shipper`, `dim_date`.

### Miembro (member)
Una fila individual de una dimensión. Ej. `dim_customer` tiene 91 miembros (uno por cliente). El cubo "se mueve" entre miembros de cada dimensión.

### Grano (grain)
**Lo que representa una fila** en la tabla de hechos. Primera decisión al diseñar un DWH. En Northwind: "una línea de pedido" (`fact_sales` tiene 2,155 filas).

### Esquema estrella (star schema)
Una fact en el centro + dimensiones desnormalizadas a su alrededor. Cada dim es **una sola tabla** plana. Es el patrón canónico de Kimball.

### Esquema copo de nieve (snowflake)
Variante del estrella donde las dimensiones están **normalizadas** en sub-tablas. Más limpio teóricamente pero requiere más joins en queries — Kimball lo desaconseja.

### Constelación / galaxy
Múltiples tablas de hechos **compartiendo dimensiones**. Ej. `fact_sales` (por línea) + `fact_orders` (por pedido completo) compartiendo `dim_customer`, `dim_date`, etc.

### Role-playing dimension
Una sola dimensión usada **con varios roles** en la fact. Ej. `dim_date` referenciada tres veces en `fact_sales` (order_date, required_date, shipped_date) — misma tabla, distintos significados.

### Slowly Changing Dimension (SCD)
Patrón para manejar **atributos de dimensión que cambian con el tiempo**. Tipos: SCD1 (sobreescribir), SCD2 (versionar con fechas), SCD3 (guardar anterior + actual).

### Medida (measure / metric)
Valor numérico de una fact table. Se clasifica por agregabilidad: **aditiva** (suma siempre tiene sentido: `quantity`), **semi-aditiva** (suma en algunas dimensiones, no en otras), **no-aditiva** (solo promedia: `unit_price`).

### MPP (Massively Parallel Processing)
Arquitectura donde **una sola query se distribuye entre múltiples nodos de cómputo**. Ej. Redshift, Snowflake, BigQuery. Aurora **no es MPP** — cada query corre en una sola instancia.

---

## :arrows_counterclockwise: ETL

### ETL (Extract, Transform, Load)
Proceso de mover datos de fuentes (OLTP, archivos, APIs) a un destino (DWH). Tres fases: extraer, transformar, cargar.

### ELT (Extract, Load, Transform)
Variante moderna: cargar datos crudos al destino primero, transformar después con SQL ahí mismo. Habilitada por DWHs columnares (Snowflake, BigQuery).

### Idempotencia
Propiedad de un proceso ETL: **correrlo dos veces produce el mismo resultado**. Importante para tolerancia a fallos — si el ETL falla y reintentas, no obtienes duplicados.

### Capa bronze / silver / gold (medallion architecture)
Jerga moderna para etapas de transformación. **Bronze** = datos crudos tal cual (texto plano, sin tipos). **Silver** = limpios y tipados. **Gold** = agregados listos para consumo. `airbnb.listings` está en bronze.

### CDC (Change Data Capture)
Técnica de ETL **continuo**: capturar cambios del OLTP en tiempo real y propagarlos al DWH. Herramientas: Debezium, AWS DMS.

---

## :elephant: PostgreSQL

### psql
Cliente de línea de comandos oficial de PostgreSQL. Tiene comandos meta que empiezan con `\` (`\l`, `\dn`, `\dt`, `\d`, `\q`).

### search_path
Variable de sesión que lista **schemas donde PostgreSQL busca tablas sin prefijar**. Análogo al `PATH` de Bash. Default: `"$user", public`. Se cambia con `SET search_path TO ...`.

### pg_catalog
Schema especial que contiene **los catálogos del sistema** de PostgreSQL. Siempre está implícitamente al inicio del `search_path`.

### information_schema
Vistas estándar SQL que exponen metadata (`tables`, `columns`, `schemata`). Portable entre motores. Equivalente más limitado a `pg_catalog`.

### Generated column
Columna calculada automáticamente desde otras. Sintaxis: `GENERATED ALWAYS AS (formula) STORED`. Ej. `line_total` en `fact_sales`.

### WAL (Write-Ahead Log)
Log secuencial donde PostgreSQL escribe cada cambio **antes** de modificar las tablas reales. Garantiza durabilidad (la D de ACID) y permite recovery tras fallas.

### MVCC (Multi-Version Concurrency Control)
Estrategia de PostgreSQL para que lectores y escritores **no se bloqueen entre sí**. Cada transacción ve una "foto" consistente del estado en el momento que empezó.

### VACUUM
Operación de mantenimiento que recupera espacio de filas obsoletas (residuo de MVCC) y actualiza estadísticas del planner. Auto-ejecutado por `autovacuum`.

### Extension
Funcionalidad opcional que se carga con `CREATE EXTENSION`. Ej. `hstore` (clave-valor), `pg_trgm` (búsqueda fuzzy), `postgis` (datos geoespaciales).

---

## :lock: ACID y transacciones

### Transacción
Secuencia de operaciones SQL agrupadas que se ejecutan como una unidad. Delimitada por `BEGIN` y `COMMIT` (o `ROLLBACK`).

### ACID
Cuatro propiedades garantizadas por motores transaccionales:
- **A**tomicity: la transacción es todo-o-nada (todo se aplica o nada).
- **C**onsistency: la transacción no viola constraints declarados.
- **I**solation: transacciones concurrentes no se ven entre sí (a medias).
- **D**urability: lo confirmado sobrevive a caídas del sistema.

### Commit
Confirmar permanentemente los cambios de una transacción. Tras un commit exitoso, los cambios son durables.

### Rollback
Revertir los cambios de una transacción en curso. Deja la base como estaba antes del `BEGIN`.

### Isolation level
Configuración de qué tan estrictamente se aíslan transacciones concurrentes. Niveles SQL estándar: `READ UNCOMMITTED`, `READ COMMITTED` (default PG), `REPEATABLE READ`, `SERIALIZABLE`.

---

## :star: Aurora y clusters

### Cluster (Aurora)
Agrupación lógica de **una capa de almacenamiento compartida** + **una o más instancias de cómputo** + endpoints + configuración común.

### Instancia
Servidor de base de datos corriendo. CPU + RAM + motor PostgreSQL. En Aurora son piezas intercambiables del cluster (puedes agregar/quitar sin tocar el storage).

### Writer endpoint
DNS estable que **siempre apunta a la instancia primaria** (writer). Si hay failover, el endpoint sigue funcionando — solo cambia a qué instancia apunta.

### Reader endpoint
DNS que **balancea entre las réplicas de lectura** del cluster. Cada conexión nueva va a una réplica distinta (round-robin).

### Failover
Cuando la instancia primaria falla, el cluster **promueve una réplica** a primaria automáticamente. En Aurora toma ~30 segundos porque el storage se preserva.

### Aurora Serverless v2
Modelo de Aurora donde **no eliges tamaño de instancia** — AWS escala CPU y memoria automáticamente según la carga, medido en **ACUs**. Pagas por consumo, no por hora encendida.

### ACU (Aurora Capacity Unit)
Unidad sintética en Aurora Serverless v2 que combina **~2 GB de RAM + CPU y red proporcionales** (~0.5 vCPU por ACU). Pagas por ACU-segundo consumido.

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="README.md">Volver a anexos</a>
</p>
