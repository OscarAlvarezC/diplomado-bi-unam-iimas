# Explorar schemas y tablas en PostgreSQL

Cómo navegar la estructura de una base PostgreSQL desde cero: qué schemas hay, qué tablas en cada schema, qué columnas tiene cada tabla, y echar un vistazo a los datos. Aplica a tu cluster Aurora del Learner Lab, al servidor del Plan B (NAS), o a cualquier otra base PostgreSQL a la que te conectes.

Cubre tres formas: comandos meta de `psql` (lo más rápido en terminal), queries SQL contra el catálogo del sistema (funciona en cualquier cliente) y el navegador visual de DBeaver (el más amigable para empezar).

---

## :mag: Con comandos `\` de `psql`

`psql` tiene un conjunto de **comandos meta** (los que empiezan con `\`) que no son SQL pero sirven para inspeccionar la base. Son la forma más rápida de explorar una vez conectado.

```sql
-- Listar schemas disponibles
\dn

-- Listar todas las tablas de un schema específico
\dt northwind_dwh.*

-- Listar todas las tablas de los tres schemas del módulo
\dt northwind_oltp.*
\dt northwind_dwh.*
\dt airbnb.*

-- Describir una tabla (columnas, tipos, índices, foreign keys)
\d northwind_dwh.fact_sales

-- Descripción detallada (agrega tamaño en disco, comentarios)
\d+ northwind_dwh.fact_sales

-- Listar vistas (views)
\dv northwind_dwh.*

-- Listar funciones disponibles
\df *
```

Ejemplo de output de `\dt northwind_dwh.*`:

```
              List of relations
    Schema     |    Name      | Type  | Owner
---------------+--------------+-------+----------
 northwind_dwh | dim_customer | table | postgres
 northwind_dwh | dim_date     | table | postgres
 northwind_dwh | dim_employee | table | postgres
 northwind_dwh | dim_product  | table | postgres
 northwind_dwh | dim_shipper  | table | postgres
 northwind_dwh | fact_sales   | table | postgres
```

Y `\d northwind_dwh.fact_sales` muestra todas las columnas con sus tipos, las foreign keys y los índices definidos.

### Salir de `psql`

Cualquiera de estas cuatro opciones cierra la sesión y te regresa al shell:

| Comando | Notas |
|---|---|
| `\q` | El más usado, sintaxis estilo `psql` |
| `\quit` | Equivalente, más explícito |
| `exit` | Funciona desde PostgreSQL 11+ |
| `Ctrl+D` | Atajo estándar de Unix para "fin de input" — funciona también en bash, python REPL, etc. |

---

## :scroll: Con queries SQL (funciona en cualquier cliente)

Si estás en DBeaver, Power BI, Python o cualquier herramienta que no soporta `\` de psql, puedes consultar el **catálogo del sistema** directamente. PostgreSQL expone dos vistas estándar para esto: **`information_schema`** (estándar SQL, portable entre motores) y **`pg_catalog`** (específico de PostgreSQL, más detallado).

```sql
-- Todos los schemas
SELECT schema_name
FROM   information_schema.schemata
WHERE  schema_name NOT IN ('pg_catalog','information_schema','pg_toast')
ORDER  BY schema_name;

-- Tablas de un schema con número de columnas
SELECT t.table_name,
       count(c.column_name) AS num_cols
FROM   information_schema.tables  t
JOIN   information_schema.columns c
       ON c.table_schema = t.table_schema
      AND c.table_name   = t.table_name
WHERE  t.table_schema = 'northwind_dwh'
GROUP  BY t.table_name
ORDER  BY t.table_name;

-- Columnas de una tabla con tipos y nullability
SELECT column_name, data_type, is_nullable, column_default
FROM   information_schema.columns
WHERE  table_schema = 'northwind_dwh'
  AND  table_name   = 'fact_sales'
ORDER  BY ordinal_position;

-- Tablas más grandes (por número de filas estimado)
SELECT schemaname, relname, n_live_tup AS filas_estimadas
FROM   pg_stat_user_tables
WHERE  schemaname IN ('northwind_oltp','northwind_dwh','airbnb')
ORDER  BY n_live_tup DESC;

-- Tamaño en disco por tabla
SELECT schemaname,
       relname,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||relname)) AS tamaño
FROM   pg_stat_user_tables
WHERE  schemaname IN ('northwind_oltp','northwind_dwh','airbnb')
ORDER  BY pg_total_relation_size(schemaname||'.'||relname) DESC;

-- Foreign keys de una tabla (qué referencias salen de fact_sales)
SELECT tc.constraint_name,
       kcu.column_name        AS columna_origen,
       ccu.table_schema || '.' || ccu.table_name AS tabla_destino,
       ccu.column_name        AS columna_destino
FROM   information_schema.table_constraints       tc
JOIN   information_schema.key_column_usage        kcu
       ON tc.constraint_name = kcu.constraint_name
JOIN   information_schema.constraint_column_usage ccu
       ON ccu.constraint_name = tc.constraint_name
WHERE  tc.constraint_type = 'FOREIGN KEY'
  AND  tc.table_schema    = 'northwind_dwh'
  AND  tc.table_name      = 'fact_sales';
```

---

## :eyes: Ver datos de ejemplo

Para echar un vistazo rápido a las primeras filas:

```sql
-- Primeras 5 filas
SELECT * FROM northwind_dwh.fact_sales LIMIT 5;

-- Filas aleatorias (no garantiza distribución pareja pero sirve para sondeo)
SELECT * FROM northwind_dwh.fact_sales ORDER BY random() LIMIT 5;

-- Estadísticas básicas de una columna numérica
SELECT count(*), min(line_total), avg(line_total), max(line_total)
FROM   northwind_dwh.fact_sales;

-- Distribución de valores únicos
SELECT category_name, count(*) AS productos
FROM   northwind_dwh.dim_product
GROUP  BY category_name
ORDER  BY productos DESC;
```

### Modo "expanded" para tablas anchas

Si una tabla tiene muchas columnas (como `airbnb.listings` con 79), la salida tabular se corta. Activa el modo expandido en `psql` para ver las filas verticalmente, una columna por línea:

```sql
\x
SELECT * FROM airbnb.listings LIMIT 3;
\x   -- volver a modo normal
```

---

## :compass: Trabajar con un schema (`search_path`)

El **`search_path`** es una **variable de sesión** que le dice a PostgreSQL **en qué schemas buscar (y en qué orden)** cuando referencias una tabla sin prefijo. Es análogo al `PATH` de Bash: una lista ordenada donde el motor recorre los schemas hasta encontrar la tabla que mencionaste. También afecta dónde se crean tablas nuevas al hacer `CREATE TABLE` sin prefijo — caen en el primer schema del `search_path` donde tu role tenga permisos.

Por defecto, si tu tabla vive en un schema distinto a `public`, **tienes que prefijar siempre**:

```sql
SELECT * FROM northwind_dwh.fact_sales;
SELECT count(*) FROM northwind_dwh.dim_customer;
```

Esto es seguro pero verboso si vas a hacer 50 queries sobre el mismo schema. La alternativa es configurar el **`search_path`** — la lista de schemas donde PostgreSQL busca tablas cuando no las prefijas.

### Cambiar `search_path` para la sesión actual

```sql
SET search_path TO northwind_dwh;
-- A partir de aquí:
SELECT * FROM fact_sales;          -- ya no necesita prefijo
SELECT count(*) FROM dim_customer; -- tampoco
```

Esto solo afecta a **tu sesión actual** — al cerrar `psql`/DBeaver vuelve al default. Si quieres acceso simultáneo a varios schemas en orden de prioridad:

```sql
SET search_path TO northwind_dwh, northwind_oltp, airbnb, public;
```

### Verificar y resetear

```sql
SHOW search_path;            -- ver el valor actual
SET search_path TO DEFAULT;  -- resetear ('"$user", public')
```

### Hacerlo persistente (solo si eres admin)

Si quieres que cada nueva sesión empiece con un `search_path` específico:

```sql
-- Solo si tienes permisos sobre tu propio role:
ALTER ROLE alumno SET search_path TO northwind_dwh, northwind_oltp, public;
```

En el **Plan B (NAS)** no tienes permiso para esto — eres `alumno`, no admin. Usa `SET search_path` por sesión. En tu **Aurora propia** sí puedes hacerlo (eres `postgres`).

### En DBeaver

Click derecho sobre tu conexión → **Edit Connection** → busca el campo **"Default schema"** o **"Active Schema"** → pon el schema deseado. También hay un dropdown en la barra superior del SQL Editor para cambiarlo al vuelo.

### Qué pasa si hay tablas con el mismo nombre en varios schemas

PostgreSQL aplica una regla simple: **usa la primera tabla que encuentre siguiendo el orden del `search_path`**, sin avisar. Es "first match wins."

```sql
SET search_path TO northwind_dwh, northwind_oltp, airbnb, public;

SELECT * FROM mi_tabla;
                ↓
PostgreSQL busca en orden:
  1. ¿Existe northwind_dwh.mi_tabla?   → si sí, usa esa y termina.
  2. ¿Existe northwind_oltp.mi_tabla?  → solo si no apareció en (1).
  3. ¿Existe airbnb.mi_tabla?          → solo si no apareció en (1) ni (2).
  4. ¿Existe public.mi_tabla?          → último recurso.
```

**El peligro:** si hay dos tablas con el mismo nombre en schemas distintos, la query devuelve resultados **del primero que encuentre, sin error y sin warning**. Cambiar el orden del `search_path` cambiaría el resultado de la misma query. Por eso prefijar es más seguro en scripts.

Para saber qué tabla está resolviendo PostgreSQL en este momento:

```sql
SELECT (regclass 'mi_tabla')::text;
-- Devuelve: "northwind_dwh.mi_tabla"  ← te dice exactamente cuál ganó
```

Y siempre puedes acceder a la tabla "escondida" prefijando explícitamente:

```sql
-- Aunque northwind_dwh esté antes en search_path, esto funciona:
SELECT count(*) FROM northwind_oltp.customers;
```

### ¿Hay colisiones en Northwind?

**No.** El DWH usa prefijos `dim_` y `fact_` por convención Kimball, así que ningún nombre se repite entre los tres schemas:

| OLTP | DWH | Airbnb |
|---|---|---|
| `customers` | `dim_customer` | `listings` |
| `products` | `dim_product` | `neighbourhoods` |
| `orders` | `fact_sales` | — |
| `employees` | `dim_employee` | — |

Por eso `SET search_path TO northwind_dwh, northwind_oltp, airbnb, public;` es seguro en este módulo — no hay ambigüedades.

### Patrón recomendado

| Para... | Mejor patrón |
|---|---|
| Exploración interactiva en `psql`/DBeaver | `SET search_path TO ...` — más cómodo, bajo riesgo si conoces tus schemas |
| Scripts SQL que se guardan o comparten | **Prefijar siempre** — explícito y portable |
| Definición de tablas (`CREATE TABLE`) | **Prefijar siempre** — para que la tabla quede donde tú quieres |
| Cuando hay colisiones de nombre conocidas | **Prefijar siempre** — el `search_path` te miente silenciosamente |

> :information_source: **Si vienes de MySQL:** allá usas `USE schema;` para cambiar la base activa. En PostgreSQL no existe `USE` — `\c base` (en `psql`) cambia de **base de datos**, y `SET search_path` cambia de **schema** dentro de la base. La distinción schema vs database es una de las diferencias clave entre los dos motores.

---

## :cyclone: Tips de presentación en `psql`

Si la salida se ve desordenada por defecto, hay cuatro ajustes que la mejoran mucho:

```sql
\timing                  -- muestra el tiempo de cada query
\pset format wrapped     -- envuelve columnas largas en vez de cortarlas
\pset null '∅'           -- marca los NULLs con un símbolo (en vez de espacio vacío)
\x auto                  -- modo expandido automático cuando la fila no cabe en pantalla
```

Puedes hacerlos permanentes guardándolos en `~/.psqlrc` para que se apliquen cada vez que abras `psql`:

```bash
cat > ~/.psqlrc << 'EOF'
\timing
\pset format wrapped
\pset null '∅'
\x auto
\set COMP_KEYWORD_CASE upper
EOF
```

La última línea (`COMP_KEYWORD_CASE upper`) hace que el autocompletado con Tab use MAYÚSCULAS para palabras reservadas (`SELECT`, `FROM`, etc.) — mejora la legibilidad del SQL.

---

## :computer: Explorar en DBeaver (alternativa visual)

Si prefieres una interfaz gráfica:

1. **Database Navigator** (panel izquierdo) → expande tu conexión.
2. Bajo **Databases → northwind → Schemas**, expande el schema que te interese (`northwind_dwh`, por ejemplo).
3. Cada tabla muestra sub-nodos: **Columns**, **Constraints**, **Foreign Keys**, **Indexes**, **References**.
4. Click derecho en una tabla → **View Data** para ver el contenido sin escribir SQL.
5. Click derecho en una tabla → **View Diagram** para ver el modelo ER con las foreign keys dibujadas.

DBeaver tiene además la pestaña **ER Diagram** (botón en la barra superior cuando estás en una tabla) que genera un diagrama del star schema completo automáticamente — útil para entender la relación entre `fact_sales` y las dimensiones de un vistazo.

---

## :triangular_flag_on_post: Cuándo usar qué

| Situación | Mejor herramienta |
|---|---|
| Exploración rápida desde terminal | `\` de `psql` |
| Necesitas la consulta en un script o automatización | SQL contra `information_schema` |
| Quieres ver el diagrama ER visualmente | DBeaver |
| Estás en otra herramienta (Power BI, Python) | SQL contra `information_schema` |
| Buscar todas las tablas que contienen una columna específica | SQL contra `information_schema.columns` con `WHERE column_name = ...` |

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="README.md">Volver a anexos</a>
</p>
