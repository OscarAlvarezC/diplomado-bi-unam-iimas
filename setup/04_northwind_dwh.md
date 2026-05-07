# 04 — Construir el data warehouse de Northwind

Vas a construir un **data warehouse** sobre Northwind: una base optimizada para queries analíticas, no transaccionales. Implementarás el patrón **estrella (star schema)** clásico de Kimball — el estándar de la industria para BI desde los 90s y aún el modelo dominante.

**Lo que tendrás al terminar:** el schema `northwind_dwh` con 5 dimensiones y una tabla de hechos, **2 155 filas** en `fact_sales` que reflejan exactamente las ventas de `northwind_oltp` pero estructuradas para análisis.

## Prerequisitos

- ✅ `northwind_oltp` cargado y verificado (guía 03).
- ✅ Schema `northwind_dwh` creado (lo creaste en la guía 03 junto con el OLTP).

---

## Concepto previo: ¿por qué un data warehouse?

`northwind_oltp` está **normalizado en 3NF** — optimizado para *escrituras* sin redundancia. Para responder preguntas analíticas como *"ventas netas por categoría por trimestre por país"*, necesitas joins de 5 tablas y razonamiento sobre claves foráneas.

Un **star schema** invierte el trade-off: desnormaliza a propósito para optimizar *lecturas analíticas*. La misma pregunta se vuelve **un solo join** contra una tabla de hechos central rodeada de dimensiones planas. Pierdes algo de espacio en disco; ganas orden de magnitud en velocidad y legibilidad.

```
                  dim_employee
                       │
   dim_customer ── fact_sales ── dim_product
                       │
   dim_shipper      dim_date
                  (3 roles: order, required, shipped)
```

Patrones que vas a ver en los scripts (todos clásicos de Kimball):

| Patrón | Dónde aparece |
|---|---|
| **Surrogate keys** | Cada dim tiene `*_key` entero generado, además del `*_id` natural del OLTP. Desacopla el DW del sistema fuente. |
| **Smart key** | `dim_date.date_key = YYYYMMDD::INT` (ej. 19960704). Filtrable sin join. |
| **Degenerate dimension** | `order_id` vive en `fact_sales` sin tabla propia (sirve para `COUNT(DISTINCT)` pero no tiene atributos descriptivos). |
| **Role-playing** | Una sola `dim_date` con 3 FKs en la fact (order, required, shipped). Misma tabla, distintos roles. |
| **Generated columns** | `extended_price` y `line_total` calculadas automáticamente por PG (no se insertan). |

No hace falta entender todo esto a fondo ahora — los scripts están comentados. Va a quedar claro cuando los ejecutes.

---

## Paso 1 — Descargar los 4 scripts SQL

```bash
mkdir -p ~/diplomado-bi/scripts
cd ~/diplomado-bi/scripts

BASE="https://raw.githubusercontent.com/OscarAlvarezC/diplomado-bi-unam-iimas/main/scripts"

curl -L -O "$BASE/01_northwind_dwh_ddl.sql"
curl -L -O "$BASE/02_dim_date_populate.sql"
curl -L -O "$BASE/03_dims_populate.sql"
curl -L -O "$BASE/04_fact_populate.sql"

ls -la
```

Esperado: 4 archivos `.sql`, total ~30 KB.

---

## Paso 2 — Crear el DDL del star (script 01)

En DBeaver, en una pestaña SQL Editor de la conexión `aurora-mod4`:

1. **File → Open File** → selecciona `01_northwind_dwh_ddl.sql`.
2. Lee los comentarios al inicio del archivo (te explican qué crea y por qué).
3. Ejecuta todo el script con **Alt+X**.

El script crea **6 tablas** dentro del schema `northwind_dwh`:

```
dim_customer    91 filas (después de poblarla)
dim_product     77 filas
dim_employee    9 filas
dim_shipper     6 filas
dim_date        1 096 filas
fact_sales      2 155 filas
```

Por ahora todas están **vacías** — solo creamos la estructura.

### Verificar

```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'northwind_dwh'
ORDER BY table_name;
-- Esperado: 6 filas (dim_customer, dim_date, dim_employee, dim_product, dim_shipper, fact_sales)
```

---

## Paso 3 — Generar `dim_date` (script 02)

`dim_date` es **especial**: no se carga del OLTP. Se construye desde cero con `generate_series` cubriendo el rango de fechas del dataset (1996-01-01 a 1998-12-31, 1 096 días).

1. Abre `02_dim_date_populate.sql` en DBeaver.
2. Ejecuta con **Alt+X**.

Tarda menos de 1 segundo.

### Verificar

```sql
SELECT count(*) FROM northwind_dwh.dim_date;
-- Esperado: 1096

SELECT * FROM northwind_dwh.dim_date ORDER BY date_key LIMIT 7;
-- Verifica visualmente:
-- - 1996-01-01 fue lunes (day_of_week_number=1, day_of_week_name='lunes')
-- - month_name='enero' para enero
-- - is_weekend=true para sábado y domingo
```

---

## Paso 4 — Poblar las 4 dims OLTP-derivadas (script 03)

Carga `dim_customer`, `dim_product`, `dim_employee`, `dim_shipper` desde `northwind_oltp` con `INSERT … SELECT … JOIN`. Es el **ETL hecho a mano en SQL puro** — el patrón que vas a reimplementar con Python en el Bloque 3.

1. Abre `03_dims_populate.sql`.
2. Ejecuta con **Alt+X**.

Tarda <1 segundo.

### Verificar

```sql
SELECT 'dim_customer' AS dim, count(*) FROM northwind_dwh.dim_customer
UNION ALL SELECT 'dim_product',  count(*) FROM northwind_dwh.dim_product
UNION ALL SELECT 'dim_employee', count(*) FROM northwind_dwh.dim_employee
UNION ALL SELECT 'dim_shipper',  count(*) FROM northwind_dwh.dim_shipper;
-- Esperado: 91 / 77 / 9 / 6
```

```sql
-- El CEO de Northwind no tiene jefe (Andrew Fuller)
SELECT employee_id, full_name, reports_to_name
FROM northwind_dwh.dim_employee
WHERE reports_to_name IS NULL;
-- Esperado: 1 fila
```

---

## Paso 5 — Poblar `fact_sales` (script 04)

Es el paso central: para cada línea de pedido en `order_details`, crea una fila en `fact_sales` que **resuelve cada natural key del OLTP a su surrogate key del DW** vía joins con cada dim. Aquí ves cómo se conecta toda la estrella.

1. Abre `04_fact_populate.sql`.
2. Ejecuta con **Alt+X**.

Tarda 1-2 segundos.

### Verificar

```sql
SELECT count(*) FROM northwind_dwh.fact_sales;
-- Esperado: 2155 (= total de order_details)
```

```sql
-- SUM(quantity) debe coincidir entre OLTP y DWH
SELECT
  (SELECT SUM(quantity) FROM northwind_oltp.order_details) AS oltp,
  (SELECT SUM(quantity) FROM northwind_dwh.fact_sales)     AS dwh;
-- Esperado: 51317 / 51317
```

```sql
-- Cross-check end-to-end con un análisis típico
SELECT dp.category_name, count(*) AS lineas, ROUND(SUM(fs.line_total), 2) AS ventas_netas
FROM northwind_dwh.fact_sales fs
JOIN northwind_dwh.dim_product dp USING (product_key)
GROUP BY dp.category_name
ORDER BY ventas_netas DESC;
-- Esperado: 8 filas, "Beverages" típicamente lidera ventas netas
```

Si la última query te devuelve 8 categorías con números coherentes, **toda la cadena de joins funciona** y tu DWH está completo.

---

## Errores comunes

### `ERROR: relation "northwind_dwh.dim_xxx" does not exist`

Te saltaste el script 01. Corre `01_northwind_dwh_ddl.sql` primero.

### `ERROR: insert or update on table "fact_sales" violates foreign key constraint`

Las dims no están pobladas. La fact tiene FKs a las 5 dims — necesita que dim_date, dim_customer, dim_product, dim_employee, dim_shipper tengan datos antes. Vuelve a correr scripts 02 y 03.

### `ERROR: duplicate key value violates unique constraint`

Re-ejecutaste un script que ya había corrido. Las natural keys (`customer_id`, `product_id`, etc.) tienen UNIQUE constraint. Para reiniciar limpio:

```sql
TRUNCATE TABLE northwind_dwh.fact_sales,
               northwind_dwh.dim_customer,
               northwind_dwh.dim_product,
               northwind_dwh.dim_employee,
               northwind_dwh.dim_shipper,
               northwind_dwh.dim_date
RESTART IDENTITY CASCADE;
```

Después corre los scripts 02, 03, 04 de nuevo en orden.

### Conteo de `fact_sales` no es 2155

Pierdes filas si las dims tienen huecos. Diagnóstico:

```sql
-- ¿Hay productos en order_details que no estén en dim_product?
SELECT count(*) FROM northwind_oltp.order_details od
LEFT JOIN northwind_dwh.dim_product dp ON dp.product_id = od.product_id
WHERE dp.product_key IS NULL;
-- Esperado: 0
```

Si te da > 0, falta poblar `dim_product`. Re-corre script 03.

### `SUM(line_total)` difiere ligeramente del cálculo OLTP

**Esto es esperado y correcto.** El OLTP usa `REAL` (float) para precios — guarda 19.99 como 19.989999771... aproximadamente. El DWH usa `NUMERIC` exacto y el script 04 redondea a 2 decimales (`ROUND(unit_price::NUMERIC, 2)`). La diferencia entre los dos `SUM` es de centavos y refleja que el DW **corrigió la imprecisión del origen**. No es bug, es feature.

---

## Lo que acabas de construir

```
northwind_dwh.fact_sales  (2 155 filas)
  ├── customer_key       → dim_customer    (91 filas)
  ├── product_key        → dim_product     (77 filas)
  ├── employee_key       → dim_employee    (9 filas)
  ├── shipper_key        → dim_shipper     (6 filas)  ← nullable
  ├── order_date_key     → dim_date        (1 096 filas)  ┐
  ├── required_date_key  → dim_date                       ├─ role-playing
  ├── shipped_date_key   → dim_date                       ┘  (3 FKs a la misma tabla)
  ├── order_id           (degenerate dimension)
  └── medidas: quantity, unit_price, discount, extended_price, line_total
```

A partir de ahora, las queries analíticas son **legibles y rápidas**. Compara:

```sql
-- Mismo análisis (ventas netas por categoría) en OLTP vs DWH:

-- OLTP: 3 joins, hay que conocer el grafo de FKs
SELECT c.category_name, ROUND(SUM(od.quantity*od.unit_price*(1-od.discount))::NUMERIC, 2)
FROM northwind_oltp.order_details od
JOIN northwind_oltp.products p ON p.product_id = od.product_id
JOIN northwind_oltp.categories c ON c.category_id = p.category_id
GROUP BY c.category_name;

-- DWH: 1 join, jerarquía aplanada en la dim
SELECT dp.category_name, ROUND(SUM(fs.line_total), 2)
FROM northwind_dwh.fact_sales fs
JOIN northwind_dwh.dim_product dp USING (product_key)
GROUP BY dp.category_name;
```

Misma respuesta, distinto costo cognitivo. **Esa es la justificación del star schema en una imagen.**

---

## Siguiente paso

Continúa con **`05_airbnb.md`** — vas a cargar el dataset **Airbnb CDMX** (snapshot de Inside Airbnb), que tiene columnas semi-estructuradas (JSON arrays, listas) que vas a explorar en el Bloque 6 con `JSONB` y operadores específicos de PostgreSQL.

---

[← Volver al índice de la sesión 1](../Sesion-01/Readme.md) | [Siguiente: 05 — Airbnb →](05_airbnb.md)
