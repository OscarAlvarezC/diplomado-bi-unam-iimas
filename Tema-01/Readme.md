# Tema 01: Setup técnico — montar el entorno de trabajo

En la práctica del análisis de datos, lo más común es recibir la información en alguno de dos formatos: un **dump SQL** (`.sql`, generalmente exportado desde otra base de datos con `CREATE TABLE` + `INSERT` ya listos) o un **archivo CSV** (`.csv`, planilla cruda sin tipos ni schema)[^1]. En esta sesión cargamos los dos: **Northwind** como dump SQL y el snapshot de **Inside Airbnb CDMX** como CSV. Son los dos métodos que vas a usar para incorporar cualquier dataset durante el resto del módulo.

Lo que hacemos hoy es un **ETL básico**. ETL son las tres fases típicas para mover datos de una fuente a un destino: **Extract** (leer del origen — archivo, otra base, API), **Transform** (limpiar, convertir tipos, aplicar reglas de negocio) y **Load** (escribir al destino). Hoy aplicamos *Extract* y *Load* en su forma más simple. Las tres fases se profundizan más adelante: en el **Tema 02** se analiza la transformación SQL hacia el data warehouse, y en el **Tema 04** se construye un ETL completo en Python (`pandas` + `SQLAlchemy`) — extracción desde la base, perfilado, limpieza, transformaciones según reglas de negocio y estrategias de carga.

## :dart: Objetivos

- Aprovisionar un cluster Aurora PostgreSQL personal en el AWS Academy Learner Lab.
- Abrir una conexión validada al cluster en DBeaver.
- Cargar el dataset Northwind como sistema **OLTP** (`northwind_oltp`).
- Construir el **data warehouse** Northwind (`northwind_dwh`) ejecutando los scripts DDL y de población.
- Cargar el snapshot de Inside Airbnb CDMX en el schema `airbnb`.
- Verificar con una query corta que los tres schemas están operativos.

## :file_folder: Contenido

<ins>Antes de empezar: descargar el repo</ins>

Se recomienda descargar el **ZIP del repo completo** y descomprimirlo en una carpeta de trabajo. Las guías siguientes asumen que tienes los archivos localmente, con rutas como `datasets/...` y `scripts/...`.

- **Navegador:** <https://github.com/OscarAlvarezC/diplomado-bi-unam-iimas> → botón verde **Code** → **Download ZIP** → descomprime en `~/diplomado-bi/` (o donde prefieras).
- **Terminal:** `git clone https://github.com/OscarAlvarezC/diplomado-bi-unam-iimas.git ~/diplomado-bi`

---

<ins>Cluster Aurora PostgreSQL</ins>

Antes de escribir queries necesitamos un servidor de base de datos. Vamos a aprovisionar un cluster **Aurora PostgreSQL** dentro del AWS Academy Learner Lab. Aurora es uno de los motores que ofrece **RDS** (Relational Database Service, el servicio gestionado de bases relacionales de AWS) — es API-compatible con PostgreSQL estándar, pero con un storage distribuido propio que mejora el rendimiento y la resiliencia. La configuración es mínima (`Provisioned`, `db.t3.medium`, una sola instancia, acceso público) por las restricciones del Learner Lab. Este cluster será el backend que ejecute las queries durante todo el módulo.

[**`Guía 01`**](../setup/01_cluster_aurora.md)

---

<ins>DBeaver Community y conexión al cluster</ins>

Para enviar consultas SQL al cluster necesitamos un cliente. Vamos a usar **DBeaver Community** — un IDE SQL gratuito y multiplataforma con autocompletado, diagramas ER e historial de queries. Antes de conectar abrimos el security group del cluster en el puerto **5432** a la IP pública de la laptop (regla "My IP"); esa regla es la pieza que controla quién puede llegarle al cluster desde fuera de AWS.

[**`Guía 02`**](../setup/02_dbeaver_conexion.md)

---

<ins>Cargar Northwind OLTP</ins>

**Northwind** es el dataset transaccional de ejemplo más conocido en la industria: una empresa ficticia de importación/exportación de alimentos con clientes, pedidos, productos, empleados y proveedores. Lo cargamos en el schema `northwind_oltp` desde un dump SQL — **14 tablas** y unas **3 200 filas**, chico pero realista. Actuará como **fuente operacional** para todo lo que sigue: el data warehouse, el ETL en Python y los ejercicios de SQL avanzado.

[**`Guía 03`**](../setup/03_northwind_oltp.md)

---

<ins>Construir el data warehouse</ins>

Sobre `northwind_oltp` construimos un **data warehouse** en el schema `northwind_dwh`: un esquema estrella con **5 dimensiones + 1 tabla de hechos** (`fact_sales`, 2 155 filas) siguiendo los patrones clásicos de Kimball. En esta sesión solamente ejecutamos los scripts (DDL + tres `INSERT…SELECT` de población). El análisis profundo de cada decisión de diseño — surrogate keys, role-playing dimensions, smart keys, generated columns, corrección REAL→NUMERIC — se hace en el **Tema 02**.

[**`Guía 04`**](../setup/04_northwind_dwh.md)

---

<ins>Cargar Airbnb CDMX</ins>

**Inside Airbnb** es un proyecto independiente de transparencia urbana (no afiliado a Airbnb la empresa) que publica snapshots mensuales de los listings de Airbnb por ciudad bajo licencia CC0. Cargamos el snapshot de Ciudad de México (**27 051 listings × 79 columnas**) en el schema `airbnb` con todas las columnas TEXT, sin tipos ni constraints, fiel a la fuente. En el **Tema 09** (datos semiestructurados) vamos a usar estos datos para explotar columnas semi-estructuradas con `hstore` y `JSONB`.

[**`Guía 05`**](../setup/05_airbnb.md)

---

<ins>Smoke test</ins>

Para cerrar la sesión hacemos un **smoke test**. El término viene de la electrónica: la primera vez que enciendes un circuito nuevo, "le buscas el humo" — si sale, algo está mal y hay que apagar; si no sale, al menos lo básico funciona. En software se adopta la misma idea: una prueba mínima que no valida todo, solo confirma que las piezas esenciales arrancan.

Aquí basta con una query corta que toque los tres schemas a la vez:

```sql
SELECT 'OLTP'    AS origen, count(*) AS filas FROM northwind_oltp.customers
UNION ALL
SELECT 'DWH',              count(*)         FROM northwind_dwh.fact_sales
UNION ALL
SELECT 'AIRBNB',           count(*)         FROM airbnb.listings;
-- Esperado: 91 / 2155 / 27051
```

Si devuelve los tres conteos sin errores, el entorno está listo y a partir de la siguiente sesión todo el tiempo de clase queda libre para contenido analítico — sin volver a tocar `search_path`, security groups ni cargas de CSV.

## :books: Material

Las guías de [`../setup/`](../setup/) son el step-by-step que se sigue en clase. Quedan ahí como referencia para repetir el ejercicio o consultar los pasos posteriormente.

## :grey_question: Preguntas de clase

Preguntas reales que han hecho alumnos durante este tema, con las respuestas que demandaron investigación en profundidad después de clase: [**`preguntas_de_clase.md`**](preguntas_de_clase.md).

[^1]: La [documentación oficial de PostgreSQL](https://www.postgresql.org/docs/current/populate.html) reconoce ambos como métodos primarios de carga (`COPY` para CSV y `pg_restore` para dumps SQL).

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="../Tema-02/Readme.md">Siguiente: Tema 02 →</a>
</p>
