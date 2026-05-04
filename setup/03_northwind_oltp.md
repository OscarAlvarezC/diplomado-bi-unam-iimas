# 03 — Cargar Northwind OLTP

Vas a cargar el dataset **Northwind**, el ejemplo clásico de un sistema transaccional (clientes, pedidos, productos, empleados). Este es el dataset que vas a usar durante todo el módulo para practicar SQL, modelado dimensional, ETL, funciones de ventana y CTEs.

**Tiempo estimado:** 15-20 minutos.
**Lo que tendrás al terminar:** los schemas `northwind_oltp` y `northwind_dwh` creados dentro de tu base `northwind`, y el dataset OLTP completamente cargado y verificado (14 tablas, ~3 200 filas).

## Prerequisitos

- ✅ DBeaver conectado a tu cluster `aurora-mod4` (de la guía 02).
- ✅ Cluster `Available` y regla SG My IP actualizada si tu IP cambió.
- ✅ Conocimiento básico de SQL (puedes ejecutar consultas en DBeaver).

---

## Concepto previo: schema dentro de la base

PostgreSQL tiene **tres niveles** de namespace, no dos:

```
cluster (instancia AWS)
└── database  (en nuestro caso: northwind)
    └── schema  (en nuestro caso: northwind_oltp y northwind_dwh)
        └── tabla  (orders, customers, products, ...)
```

Las **dos bases** del módulo son dos schemas dentro de **una sola base** `northwind`:

- **`northwind_oltp`** — datos transaccionales originales (esta guía).
- **`northwind_dwh`** — data warehouse en esquema estrella (siguiente guía).

> 💡 **Si vienes de MySQL:** ahí `CREATE SCHEMA` y `CREATE DATABASE` son sinónimos — MySQL no tiene este nivel intermedio. En PostgreSQL, una conexión apunta a una **base**; los **schemas son carpetas dentro de la base**. Ventaja: puedes hacer `JOIN` entre `northwind_oltp.customers` y `northwind_dwh.fact_sales` con una sola conexión.

---

## Paso 1 — Crear los dos schemas

En DBeaver SQL Editor (conexión `aurora-mod4`):

```sql
CREATE SCHEMA IF NOT EXISTS northwind_oltp;
CREATE SCHEMA IF NOT EXISTS northwind_dwh;
```

Click derecho → **Execute SQL Statement** (o `Ctrl+Enter`).

### Verificar

```sql
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name LIKE 'northwind%';
```

Debe devolver **2 filas**: `northwind_oltp` y `northwind_dwh`.

Refresca el árbol del **Database Navigator** (F5 sobre la base `northwind`) — los dos schemas aparecen bajo `Schemas`.

---

## Paso 2 — Descargar el dump de Northwind

Tienes dos opciones, cualquiera funciona:

### Opción A — Desde el repo de la clase (recomendado)

```bash
# Linux/macOS:
mkdir -p ~/diplomado-bi/datasets
curl -L -o ~/diplomado-bi/datasets/northwind.sql \
  https://raw.githubusercontent.com/OscarAlvarezC/diplomado-bi-unam/main/datasets/northwind/northwind.sql

# Windows PowerShell:
mkdir -p ~/diplomado-bi/datasets
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OscarAlvarezC/diplomado-bi-unam/main/datasets/northwind/northwind.sql" -OutFile "~/diplomado-bi/datasets/northwind.sql"
```

### Opción B — Desde la fuente original (pthom/northwind_psql)

```bash
curl -L -o ~/diplomado-bi/datasets/northwind.sql \
  https://raw.githubusercontent.com/pthom/northwind_psql/master/northwind.sql
```

### Verificar la descarga

```bash
ls -lh ~/diplomado-bi/datasets/northwind.sql
# Esperado: archivo de ~340 KB
```

---

## Paso 3 — Cargar el dump en `northwind_oltp`

El dump contiene sentencias `CREATE TABLE customers (...)` **sin prefijo de schema**. Para que las tablas se creen dentro de `northwind_oltp` y no en el schema default `public`, usamos un truco: cambiar el `search_path` de la sesión antes de ejecutar el dump.

### `search_path` en una línea

Es la variable que le dice a PostgreSQL dónde buscar tablas cuando escribes nombres sin prefijo. Análogo al `PATH` de Bash, pero para schemas SQL.

> ⚠️ **Cuidado:** `SET search_path TO northwind_oltp;` **NO falla** aunque el schema no exista. Si te equivocas en el nombre, las tablas del dump caen silenciosamente en `public`. Por eso el Paso 1 (crear schemas) tiene que ir **antes**.

### 3.1 — Fija el search_path

En el SQL Editor de DBeaver, **en la misma pestaña/sesión** donde vas a cargar el dump, ejecuta primero:

```sql
SET search_path TO northwind_oltp;

-- Confirma que quedó bien:
SELECT current_database(), current_schema();
-- Esperado:  northwind  |  northwind_oltp
```

Si `current_schema` te devuelve **NULL** o `public`, **no avances** — vuelve al Paso 1, el schema no existe.

### 3.2 — Ejecuta el dump

1. **File → Open File** en DBeaver → selecciona `~/diplomado-bi/datasets/northwind.sql`.
2. **Importante:** DBeaver puede abrir el archivo en una pestaña nueva. Si pasa, **el `SET search_path` del paso 3.1 NO aplica** (otra sesión = otro path). Tienes dos opciones:
   - **Opción 1 (más simple):** copia/pega el contenido del archivo en la pestaña donde corriste `SET search_path`.
   - **Opción 2:** en la nueva pestaña, agrega `SET search_path TO northwind_oltp;` como primera línea antes de ejecutar.
3. Ejecuta **todo el script** con `Alt+X` (botón "Execute SQL Script") — **NO** uses `Ctrl+Enter`, eso solo ejecuta la sentencia bajo el cursor.

El dump tarda 5-15 segundos. Vas a ver muchos mensajes de `CREATE TABLE`, `ALTER TABLE`, `INSERT`, etc.

---

## Paso 4 — Verificar la carga

### 4.1 — Conteo de tablas

```sql
SELECT count(*)
FROM information_schema.tables
WHERE table_schema = 'northwind_oltp';
-- Esperado: 14
```

### 4.2 — Conteos por tabla (opcional pero recomendado)

```sql
SELECT 'orders'        AS tabla, count(*) FROM northwind_oltp.orders
UNION ALL SELECT 'order_details',   count(*) FROM northwind_oltp.order_details
UNION ALL SELECT 'customers',       count(*) FROM northwind_oltp.customers
UNION ALL SELECT 'products',        count(*) FROM northwind_oltp.products
UNION ALL SELECT 'employees',       count(*) FROM northwind_oltp.employees
UNION ALL SELECT 'categories',      count(*) FROM northwind_oltp.categories
UNION ALL SELECT 'shippers',        count(*) FROM northwind_oltp.shippers
UNION ALL SELECT 'suppliers',       count(*) FROM northwind_oltp.suppliers;
```

| Tabla | Filas esperadas |
|---|---|
| orders | 830 |
| order_details | 2155 |
| customers | 91 |
| products | 77 |
| employees | 9 |
| categories | 8 |
| shippers | 6 |
| suppliers | 29 |

### 4.3 — Tu primera query analítica

Comprueba que las tablas se relacionan bien:

```sql
SELECT c.category_name, count(*) AS productos
FROM northwind_oltp.products p
JOIN northwind_oltp.categories c USING (category_id)
GROUP BY c.category_name
ORDER BY productos DESC;
```

Debe devolver 8 categorías con sus conteos. Si responde, **el OLTP está completamente funcional**.

---

## Errores comunes

### Las tablas terminaron en `public`, no en `northwind_oltp`

Pasa cuando el `SET search_path` no aplicó a la sesión donde se cargó el dump. Diagnóstico:

```sql
SELECT table_schema, count(*) AS n
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog','information_schema')
GROUP BY table_schema;
```

Si ves ~14 tablas en `public` y 0 en `northwind_oltp`, el fix es **mover las tablas** sin re-cargar:

```sql
CREATE SCHEMA IF NOT EXISTS northwind_oltp;

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
    EXECUTE format('ALTER TABLE public.%I SET SCHEMA northwind_oltp', r.tablename);
  END LOOP;
END$$;
```

Las FKs y constraints viajan automáticamente con `ALTER TABLE ... SET SCHEMA`. Verifica:

```sql
SELECT table_schema, count(*) FROM information_schema.tables
WHERE table_name IN ('orders','customers','products')
GROUP BY table_schema;
-- Esperado: northwind_oltp | 3
```

### `ERROR: schema "northwind_oltp" does not exist`

Aparece si intentas hacer `CREATE TABLE northwind_oltp.foo (...)` sin haber creado el schema. Vuelve al Paso 1.

### `current_schema()` devuelve NULL

El schema no existe pero `SET search_path` no falla — apunta al vacío. Vuelve al Paso 1, crea el schema, luego repite Paso 3.

### DBeaver se congela ejecutando el dump

Northwind es pequeño y no debería colgar. Si pasa:
- Cierra DBeaver, reábrelo, conéctate de nuevo.
- En el SQL Editor, en lugar de cargar el archivo entero, **divídelo**: ejecuta primero todos los `CREATE TABLE` (parte de arriba del archivo), luego los `INSERT`.

### `Connection lost` durante el dump

Tu cluster pudo haberse pausado o tu IP cambió. Verifica:
- RDS → cluster `Available`.
- SG → My IP actual.

Reconecta DBeaver y vuelve a empezar — los `CREATE TABLE` del Paso 3 son idempotentes con `IF NOT EXISTS`, pero los `INSERT` del dump no. Si hubo carga parcial, lo más limpio es:

```sql
DROP SCHEMA northwind_oltp CASCADE;
CREATE SCHEMA northwind_oltp;
SET search_path TO northwind_oltp;
-- Re-ejecuta el dump
```

---

## Siguiente paso

Continúa con **`04_northwind_dwh.md`** — vas a construir un **data warehouse** sobre el OLTP que acabas de cargar. Diseñarás un esquema estrella con dimensiones y una tabla de hechos, y lo poblarás con SQL puro a partir de las tablas de `northwind_oltp`. Es el corazón del módulo.
