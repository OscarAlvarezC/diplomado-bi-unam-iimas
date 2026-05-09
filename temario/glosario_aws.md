# Glosario de servicios AWS

Glosario corto de los 11 servicios AWS que se mencionan a lo largo del módulo. No pretende ser exhaustivo — para la lista completa de servicios consulta el [glosario oficial](https://docs.aws.amazon.com/general/latest/gr/glos-chap.html).

Cada entrada responde tres preguntas: **qué es**, **para qué sirve** y **cuándo lo usarías**.

---

## Almacenamiento

### S3 — Simple Storage Service

**¿Qué es?** Almacenamiento de **objetos** (archivos) escalable a petabytes. Los archivos viven en *buckets*, cada uno con un nombre globalmente único. No es un sistema de archivos tradicional (no hay carpetas reales) — es un mapa de claves a bytes.

**¿Para qué sirve?** Guardar cualquier archivo: respaldos, datasets crudos, imágenes, logs, snapshots de bases de datos, código compilado.

**¿Cuándo lo usarías?** Es la base de cualquier datalake en AWS. En este módulo, S3 sería donde vivirían los CSVs de Inside Airbnb si hubiéramos podido crear buckets públicos en el Learner Lab (no se pudo, por restricciones del entorno educativo).

---

## Bases de datos transaccionales (OLTP)

### RDS — Relational Database Service

**¿Qué es?** Servicio paraguas de bases de datos relacionales gestionadas. Soporta varios motores: **PostgreSQL, MySQL, MariaDB, Oracle Database, SQL Server** y **Aurora** (motor propio de AWS, ver entrada siguiente). Tú no administras el sistema operativo, los backups ni las actualizaciones.

**¿Para qué sirve?** Tener una base relacional confiable sin operar un servidor.

**¿Cuándo lo usarías?** Cualquier app web que necesite una base SQL "estándar" sin complicaciones operativas.

### Aurora

**¿Qué es?** **Una de las opciones de motor dentro de RDS** — específicamente, el motor propio de AWS, **API-compatible con PostgreSQL y MySQL** pero con storage distribuido propio (replicado en 6 lugares en 3 zonas de disponibilidad). Tu app no nota diferencia respecto a PostgreSQL/MySQL estándar, pero por debajo es más rápida y más resiliente.

Administrativamente Aurora vive en la consola de RDS (la creas, monitoreas y respaldas con la misma interfaz que cualquier otra base RDS), pero AWS la presenta a veces como producto separado en su marketing por las diferencias de arquitectura.

**¿Para qué sirve?** Lo mismo que RDS PostgreSQL/MySQL, pero con mejor performance, replicación más rápida y failover en ~30 segundos sin pérdida de datos.

**¿Cuándo lo usarías?** Producción seria que necesite las garantías ACID de PostgreSQL/MySQL con el rendimiento y la resiliencia que Aurora agrega. **Es lo que estamos usando en este módulo** (Aurora PostgreSQL `db.t3.medium`).

### DynamoDB

**¿Qué es?** Base **NoSQL** de tipo *key-value* y *document store*. Latencia en milisegundos a cualquier escala. No tiene `JOIN`, ni transacciones complejas, ni schemas rígidos.

**¿Para qué sirve?** Workloads que requieren lectura/escritura puntual masivamente concurrente, sin necesidad de queries analíticas.

**¿Cuándo lo usarías?** Sesiones de usuarios, carritos de compras, IoT con millones de eventos por segundo, perfiles de jugadores en videojuegos. **No** es un reemplazo de una base relacional para reportes — es complementaria.

---

## Bases de datos analíticas (OLAP)

### Redshift

**¿Qué es?** **Data warehouse columnar MPP** (Massively Parallel Processing) basado en un fork modificado de PostgreSQL. Cluster con un *leader node* y varios *compute nodes* que procesan queries en paralelo.

**¿Para qué sirve?** Queries analíticas sobre tablas de millones o miles de millones de filas. Optimizado para `SUM`, `GROUP BY`, agregaciones masivas.

**¿Cuándo lo usarías?** Cuando tu data warehouse rebasa lo que un PostgreSQL/Aurora puede manejar cómodamente (decenas de millones de filas y arriba). En este módulo no lo usamos por el costo y porque el dataset Northwind es muy chico para justificarlo.

### Athena

**¿Qué es?** Motor SQL **serverless** que ejecuta queries directamente sobre archivos en S3 (Parquet, CSV, JSON, ORC). Basado en **Trino/Presto**. No requiere cluster encendido — provisiona compute al vuelo y se apaga cuando termina.

**¿Para qué sirve?** Consultar datasets que viven en S3 sin cargarlos a una base. Pay-per-query: cobra por TB escaneado.

**¿Cuándo lo usarías?** Análisis ad-hoc sobre logs históricos, exploración de un dataset nuevo, datalake con datos heterogéneos. Si vas a correr cientos de queries por hora sobre los mismos datos, Redshift sale más económico; si es uso esporádico, Athena gana.

---

## Visualización / BI

### QuickSight

**¿Qué es?** Herramienta de **dashboards y visualización** estilo Tableau o Power BI, gestionada por AWS. Se conecta a Redshift, RDS, Aurora, Athena, S3 y otras fuentes para construir reportes interactivos.

**¿Para qué sirve?** Que usuarios de negocio (no técnicos) exploren datos sin escribir SQL.

**¿Cuándo lo usarías?** Dashboards corporativos, reportes ejecutivos, exploración visual de KPIs. En este módulo lo mencionamos como *capa final de BI*, pero no construimos dashboards directamente — el módulo se queda en SQL avanzado y modelado dimensional.

---

## Compute

### EC2 — Elastic Compute Cloud

**¿Qué es?** **Máquinas virtuales** en la nube. Eliges tipo de instancia (CPU, RAM, disco), sistema operativo y arrancas un servidor. Tú administras todo lo de adentro: SO, parches, software.

**¿Para qué sirve?** Correr cualquier cosa que normalmente correrías en un servidor — bases de datos auto-gestionadas, servidores web, jobs de procesamiento.

**¿Cuándo lo usarías?** Cuando necesitas control total sobre el SO o software. En la práctica moderna, muchas tareas que antes eran EC2 ahora son Lambda, ECS o servicios gestionados.

### Lambda

**¿Qué es?** **Funciones serverless**. Subes un fragmento de código (Python, Node, Java, Go, etc.), defines un evento que la dispara, y AWS la ejecuta cuando ocurre el evento. Pagas solo por el tiempo de ejecución.

**¿Para qué sirve?** Lógica corta dirigida por eventos: procesar un archivo cuando aparece en S3, transformar un mensaje de cola, responder un webhook.

**¿Cuándo lo usarías?** Cualquier tarea < 15 min que se ejecuta esporádicamente y no justifica mantener un servidor encendido. Es el caballito de batalla de las arquitecturas event-driven.

### SageMaker

**¿Qué es?** Plataforma completa de **machine learning**: notebooks Jupyter gestionados, entrenamiento distribuido de modelos, deployment de endpoints, orquestación de pipelines de ML.

**¿Para qué sirve?** Todo el ciclo de vida del ML: experimentar, entrenar, evaluar, desplegar y monitorear modelos.

**¿Cuándo lo usarías?** Cualquier proyecto serio de ML/AI dentro de AWS que necesite escalar más allá de un notebook local. No lo tocamos en este módulo (el ML está fuera del alcance del Módulo 4).

---

## Identidad

### IAM — Identity and Access Management

**¿Qué es?** Servicio de **identidad y permisos**. Define usuarios, grupos, roles y políticas que determinan **quién puede hacer qué** sobre los recursos AWS.

**¿Para qué sirve?** Es la base de seguridad de toda la cuenta. Sin IAM correctamente configurado, cualquier servicio queda expuesto o inaccesible.

**¿Cuándo lo usarías?** Siempre — IAM no es opcional. En este módulo el Learner Lab pre-configura un rol con permisos limitados (`LabRole`); los alumnos no crean políticas propias pero sí las heredan al lanzar recursos.

---

## Resumen rápido

| Servicio | Categoría | Uso típico |
|---|---|---|
| **S3** | Storage | Archivos, datalake |
| **RDS** | OLTP | Bases relacionales gestionadas |
| **Aurora** | OLTP | PostgreSQL/MySQL mejorado por AWS |
| **DynamoDB** | NoSQL | Key-value de baja latencia |
| **Redshift** | OLAP | Data warehouse a escala |
| **Athena** | OLAP | SQL serverless sobre S3 |
| **QuickSight** | BI | Dashboards |
| **EC2** | Compute | Máquinas virtuales |
| **Lambda** | Compute | Funciones serverless |
| **SageMaker** | ML | Plataforma de machine learning |
| **IAM** | Identidad | Permisos y roles |

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="README.md">Volver al temario</a>
</p>
