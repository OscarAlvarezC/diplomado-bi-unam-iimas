# Sesión 01: Setup técnico — montar el entorno de trabajo

## :dart: Objetivos

- Aprovisionar un cluster Aurora PostgreSQL personal en el AWS Academy Learner Lab.
- Abrir una conexión validada al cluster en DBeaver.
- Cargar el dataset Northwind como sistema **OLTP** (`northwind_oltp`).
- Construir el **data warehouse** Northwind (`northwind_dwh`) ejecutando los scripts DDL y de población.
- Cargar el snapshot de Inside Airbnb CDMX en bronze (`airbnb`).
- Verificar con una query corta que los tres schemas están operativos.

## :file_folder: Contenido

<ins>Cluster Aurora PostgreSQL</ins>

Antes de escribir queries necesitamos un servidor de base de datos. Vamos a aprovisionar un cluster **Aurora PostgreSQL** dentro del AWS Academy Learner Lab — Aurora es la versión gestionada de PostgreSQL que ofrece AWS, con replicación, backups y monitoreo integrados. La configuración es mínima (`Provisioned`, `db.t3.medium`, una sola instancia, acceso público) por las restricciones del Learner Lab. Este cluster será el backend que ejecute las queries durante todo el módulo.

[**`Guía 01`**](../setup/01_cluster_aurora.md)

---

<ins>DBeaver Community y conexión al cluster</ins>

Para enviar consultas SQL al cluster necesitamos un cliente. Vamos a usar **DBeaver Community** — un IDE SQL gratuito y multiplataforma con autocompletado, diagramas ER e historial de queries. Antes de conectar abrimos el security group del cluster en el puerto **5432** a la IP pública de la laptop (regla "My IP"); esa regla es la pieza que controla quién puede llegarle al cluster desde fuera de AWS.

[**`Guía 02`**](../setup/02_dbeaver_conexion.md)

---

<ins>Cargar Northwind OLTP</ins>

**Northwind** es el dataset transaccional de ejemplo más conocido en la industria: una empresa ficticia de importación/exportación de alimentos con clientes, pedidos, productos, empleados y proveedores. Lo cargamos en el schema `northwind_oltp` desde un dump SQL — **14 tablas** y unas **3 200 filas**, chico pero realista. Va a hacer las veces de "sistema operacional fuente" para todo lo que sigue: el data warehouse, el ETL en Python y los ejercicios de SQL avanzado.

[**`Guía 03`**](../setup/03_northwind_oltp.md)

---

<ins>Construir el data warehouse</ins>

Sobre `northwind_oltp` construimos un **data warehouse** en el schema `northwind_dwh`: un esquema estrella con **5 dimensiones + 1 tabla de hechos** (`fact_sales`, 2 155 filas) siguiendo los patrones clásicos de Kimball. En esta sesión solamente ejecutamos los scripts (DDL + tres `INSERT…SELECT` de población). El análisis profundo de cada decisión de diseño — surrogate keys, role-playing dimensions, smart keys, generated columns, corrección REAL→NUMERIC — se hace en la **Sesión 04**.

[**`Guía 04`**](../setup/04_northwind_dwh.md)

---

<ins>Cargar Airbnb CDMX</ins>

**Inside Airbnb** es un proyecto independiente de transparencia urbana (no afiliado a Airbnb la empresa) que publica snapshots mensuales de los listings de Airbnb por ciudad bajo licencia CC0. Cargamos el snapshot de Ciudad de México (**27 051 listings × 79 columnas**) en el schema `airbnb` como capa **bronze**: todas las columnas TEXT, sin tipos ni constraints, fiel a la fuente. En las **Sesiones 14 y 15** vamos a usar estos datos para explotar columnas semi-estructuradas con `hstore` y `JSONB`.

[**`Guía 05`**](../setup/05_airbnb.md)

---

<ins>Smoke test</ins>

Para cerrar la sesión, una query analítica corta que toque los tres schemas a la vez (`northwind_oltp`, `northwind_dwh`, `airbnb`). Si devuelve resultados sin errores, el entorno está listo y a partir de la siguiente sesión todo el tiempo de clase queda libre para contenido analítico — sin volver a tocar `search_path`, security groups ni cargas de CSV.

## :books: Material

Las guías de [`../setup/`](../setup/) son el step-by-step que se sigue en clase. Quedan ahí como referencia para repetir el ejecrcicio o consultar los pasos posteriormente.

---

[← Volver al inicio](../README.md) | [Siguiente: Sesión 02 →](../Sesion-02/Readme.md)
