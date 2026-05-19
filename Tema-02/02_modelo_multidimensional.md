# Lectura 02 — Modelo multidimensional: grano, hechos, dimensiones

En la lectura anterior cerraste con la idea de que **OLAP necesita un diseño distinto al de OLTP**. Esta lectura le pone nombre a ese diseño. El modelo dominante en la industria desde los años 90 — formalizado por Ralph Kimball[^kimball] y aplicado en prácticamente todo data warehouse moderno — se llama **modelo multidimensional**. Tiene tres conceptos centrales: **grano**, **hechos** y **dimensiones**. Si dominas esos tres, puedes leer y diseñar cualquier warehouse.

---

## La intuición geométrica

Antes del vocabulario formal, una imagen. Imagínate un **cubo** de tres ejes:

- Un eje es **producto**.
- Otro eje es **fecha**.
- Otro eje es **cliente**.

Cada punto dentro del cubo es la intersección de un producto, una fecha y un cliente — y en ese punto vive un número: *cuánto se vendió de ese producto, en esa fecha, a ese cliente*. El cubo describe el comportamiento del negocio: si lo cortas por el eje de fecha y sumas, obtienes ventas por mes; si lo cortas por categoría de producto y promedias, obtienes ticket promedio por categoría; etc.

El modelo multidimensional es **la representación tabular de ese cubo** dentro de una base de datos relacional. Los ejes del cubo se vuelven **dimensiones** (tablas separadas con atributos descriptivos) y los puntos del cubo se vuelven **filas en una tabla de hechos**, cada una con valores numéricos y referencias a las dimensiones que la sitúan en el espacio.

Northwind tiene cinco ejes — producto, cliente, empleado, transportista, fecha — así que el cubo es de cinco dimensiones (no se puede dibujar, pero la idea es la misma).

> *Nota: el nombre "cubo" viene de extender visualmente las tablas pivote 2D (un rectángulo de filas × columnas) a un tercer eje. Edgar Codd acuñó **"OLAP cube"** en 1993 y la convención se mantuvo aunque el modelo se generalice a N dimensiones — técnicamente sería "hipercubo", pero todos siguen diciendo "cubo". Geométricamente otras formas también podrían representar los datos; el cubo se eligió por su intuición visual a partir de las pivot tables, no por elegancia matemática.*

---

## Grano: la decisión más importante del warehouse

> **"Declare the grain before anything else."**
> — Ralph Kimball

Antes de entrar al detalle de hechos y dimensiones, hay una decisión que precede a ambos: el **grano**. El grano de una tabla de hechos es **qué representa una fila** dentro de ella. Es **la primera decisión** que se toma al diseñar un warehouse — antes de las dimensiones, antes de las medidas, antes de cualquier DDL. Todo lo demás se deriva del grano elegido; por eso esta lectura lo trata primero.

Para Northwind hay tres granos posibles para una fact de ventas:

| Grano | Una fila representa | ¿Cuántas filas tendría? | ¿Qué se puede medir? |
|---|---|---|---|
| **Por pedido** | Un pedido completo | 830 | Total del pedido, freight |
| **Por orden y producto** | Una línea (`order_details`) | 2 155 | Cantidad por producto, descuento por producto, ticket promedio por línea |
| **Por unidad vendida** | Una unidad individual del producto | ~51 000 | Cualquier cosa, pero el dataset crece e inventas filas que el OLTP no separa |

El grano **por línea de pedido (orden y producto)** es la elección estándar para Northwind. Es el **dato atómico disponible** en el OLTP — `order_details` ya está ahí, no hay que inventar. Y es el más expresivo de los tres: te permite preguntar *"¿qué descuento promedio aplicó cada empleado?"* (no se puede a nivel pedido porque el descuento es por línea), pero también te permite re-agregar a nivel pedido si lo necesitas (`SUM(line_total) GROUP BY order_id`).

El grano "por unidad" se descarta porque (1) el OLTP no separa las unidades individuales — fragmentar es inventar datos, (2) no responde ninguna pregunta que el grano "por línea" no responda con SUM(quantity), y (3) multiplica el dataset por 24× sin aportar valor. Kimball: elige el grano más atómico que el dato realmente soporta, no más fino.

### ¿Por qué importa tanto?

El grano determina:

1. **Qué dimensiones aplican.** A nivel línea de pedido aplica `dim_product` (cada línea es de un producto). A nivel pedido completo NO aplica `dim_product` directamente — un pedido tiene varios productos, no uno.
2. **Qué medidas son aditivas.** `quantity` y `line_total` son sumables sin restricciones. `unit_price` es **promediable**, no sumable (sumar precios unitarios no significa nada). El grano fija qué operación tiene sentido sobre cada medida.
3. **Qué preguntas de negocio se pueden contestar.** Decisiones que ocurren a nivel pedido (la decisión de elegir transportista) pueden vivir en una fact de grano "pedido" pero quedan duplicadas en una de grano "línea". Decisiones que ocurren a nivel línea (el descuento por producto) no se pueden expresar en una fact de grano "pedido".

### Regla de oro

**El grano es uniforme dentro de una fact.** No mezclas filas de granos distintos. Si necesitas analizar a dos granos diferentes (por línea y por pedido), tendrás dos facts separadas — `fact_sales` (por línea) y `fact_orders` (por pedido) — compartiendo dimensiones. Esa configuración se llama **fact constellation** y la verás en el **Tema 03**.

---

## Tabla de hechos

Con el grano ya decidido — una fila por línea de pedido — toca ver **qué columnas** lleva esa fila. Una **tabla de hechos** registra **eventos que ocurren en el negocio** — cada fila es una vez que el evento sucedió, acompañada de las **cifras numéricas que lo cuantifican**. En Northwind, el evento es **una línea de pedido**: alguien compró tantas unidades de tal producto, en tal pedido, con tal descuento — y esas cantidades (unidades, precio, descuento) son justamente las cifras que la fact guarda. La tabla `fact_sales` tiene una fila por cada línea de pedido (2 155 filas en total).

Las columnas de una fact pertenecen a tres familias:

### 1. Medidas (las cifras del negocio)

Son los **valores numéricos** que se van a sumar, promediar, contar. En `fact_sales`:

```
quantity         SMALLINT       -- cuántas unidades
unit_price       NUMERIC(10,2)  -- precio por unidad al momento del pedido
discount         NUMERIC(4,2)   -- descuento aplicado (0.00 a 0.25)
extended_price   NUMERIC(12,2)  -- quantity * unit_price (calculado)
line_total       NUMERIC(12,2)  -- quantity * unit_price * (1 - discount) (calculado)
```

Las dos últimas son **columnas calculadas** (`GENERATED ALWAYS AS … STORED`). PostgreSQL las mantiene automáticamente: cualquier `INSERT` o `UPDATE` recalcula el valor. Como están materializadas en disco, sumarlas es tan barato como sumar cualquier otra columna numérica.

> **¿Por qué pre-calcularlas?** Porque la fórmula `quantity * unit_price * (1 - discount)` se va a aplicar **en cada query analítica** que pregunte por ventas netas. Calcularla una vez al cargar y guardar el resultado es más rápido y menos propenso a errores que escribirla a mano cada vez.

### 2. Foreign keys hacia las dimensiones (el contexto)

Son las **referencias** a las tablas que describen el evento. En `fact_sales`:

```
customer_key      INT  → dim_customer
product_key       INT  → dim_product
employee_key      INT  → dim_employee
shipper_key       INT  → dim_shipper       (puede ser NULL)
order_date_key    INT  → dim_date
required_date_key INT  → dim_date          (misma dim_date, otro rol)
shipped_date_key  INT  → dim_date          (misma dim_date, otro rol — puede ser NULL)
```

Estas FKs **no almacenan los atributos descriptivos** (nombre del cliente, ciudad, teléfono) — solo apuntan a la dimensión donde esos atributos viven. La fact se mantiene angosta y enfocada en métricas; el contexto descriptivo está aparte.

### 3. Degenerate dimensions (identificadores sin tabla)

A veces hay un identificador del evento original que conviene preservar pero **no merece tabla propia** porque no tiene atributos descriptivos asociados. En `fact_sales` ese papel lo juega `order_id`:

```
order_id  SMALLINT  -- identificador del pedido en el OLTP
```

Sirve para responder *"¿cuántos pedidos distintos cerró esta categoría?"* (`COUNT(DISTINCT order_id)`), pero no tiene atributos propios — todo lo que sabes del pedido vive en sus líneas o en las dimensiones referenciadas. Por eso Kimball lo llama **dimensión degenerada**: no tiene tabla, vive directamente en la fact.

### Anatomía completa de `fact_sales`

| Columna | Familia | Para qué sirve |
|---|---|---|
| `sale_key` | Surrogate PK | Identificar la fila |
| `order_id` | Degenerate dim | `COUNT(DISTINCT)` por pedido |
| `customer_key` … `shipped_date_key` | FKs a dims | Contexto descriptivo |
| `quantity`, `unit_price`, `discount` | Medidas base | Lo que el OLTP registró |
| `extended_price`, `line_total` | Medidas calculadas | Pre-agregaciones útiles |

---

## Dimensiones

Las **dimensiones** describen el **contexto** de cada hecho. Si la fact dice "tantas unidades por tantos pesos", las dimensiones contestan al **quién**, **qué**, **cuándo**, **dónde**, **cómo** de esa cifra. Cada dimensión es una tabla con:

- Una **surrogate key** (entero autogenerado, PK, sin significado de negocio).
- Una **natural key** (el ID del sistema fuente, el que existe en el OLTP).
- **Atributos descriptivos** (texto, fechas, banderas) que describen al miembro de la dimensión.

### `dim_customer` — el quién

```
customer_key   INT       -- surrogate
customer_id    CHAR(5)   -- natural ('ALFKI', 'BERGS', …)
company_name   VARCHAR(40)
contact_name   VARCHAR(30)
contact_title  VARCHAR(30)
city           VARCHAR(15)
region         VARCHAR(15)
postal_code    VARCHAR(10)
country        VARCHAR(15)
```

91 filas, una por cliente. Cuando preguntas *"¿cuáles son mis 10 clientes con más ventas?"*, la fact te da `SUM(line_total)` agrupado por `customer_key`, y `dim_customer` te da el `company_name` para que el reporte sea legible.

### `dim_product` — el qué

```
product_key       INT       -- surrogate
product_id        SMALLINT  -- natural
product_name      VARCHAR(40)
category_id       SMALLINT
category_name     VARCHAR(15)   -- ← aplanado desde la tabla `categories` del OLTP
category_desc     TEXT          -- ← aplanado
supplier_id       SMALLINT
supplier_name     VARCHAR(40)   -- ← aplanado desde la tabla `suppliers` del OLTP
supplier_country  VARCHAR(15)   -- ← aplanado
supplier_city     VARCHAR(15)   -- ← aplanado
discontinued      BOOLEAN
```

77 filas, una por producto. Fíjate en lo importante: en el OLTP las categorías están en una tabla `categories` aparte y los proveedores están en `suppliers` aparte — siguiendo 3NF. En el DWH **se aplanaron como atributos de `dim_product`**. Esto duplica el `category_name` "Beverages" en cada producto que sea bebida, sí — y eso es **deliberado**:

- Para una query analítica, agrupar por `category_name` ya no requiere `JOIN` adicional.
- El gasto en almacenamiento es marginal (77 filas, no 77 millones).
- Como la dim solo se reescribe vía ETL, la duplicación no introduce riesgo de inconsistencia.

A esta operación de **traer atributos de tablas relacionadas y aplanarlos en la dimensión** se le llama **desnormalización** y es la decisión central del modelado dimensional.

### `dim_employee` — el quién (interno)

Empleado que tomó el pedido. 9 filas. Caso interesante: en el OLTP `employees` tiene una self-FK (`reports_to`) que apunta al jefe del empleado. En la dim ese vínculo se **aplana** a una columna de texto `reports_to_name` con el nombre del jefe — así una query analítica no necesita un self-join para mostrar la jerarquía.

### `dim_shipper` — el cómo

Transportista. 6 filas. La dimensión más simple del modelo.

### `dim_date` — el cuándo

Caso especial, lo suficientemente importante para tratarlo aparte.

```
date_key            INT         PRIMARY KEY    -- smart key: YYYYMMDD
full_date           DATE        UNIQUE
year                SMALLINT
quarter             SMALLINT
month_number        SMALLINT
month_name          VARCHAR(10)                -- "enero", "febrero", …
week_of_year        SMALLINT
day_of_month        SMALLINT
day_of_week_number  SMALLINT                   -- ISO: lunes=1
day_of_week_name    VARCHAR(10)
is_weekend          BOOLEAN
```

1 096 filas (una por cada día calendario entre 1996-01-01 y 1998-12-31). Tres rasgos a notar:

1. **Smart key.** El PK es `YYYYMMDD` como entero (`19970315` para el 15 de marzo de 1997). No es un surrogate auto-generado — es un valor con significado, **filtrable sin join**: `WHERE order_date_key BETWEEN 19970101 AND 19971231`.
2. **Atributos pre-calculados.** Año, trimestre, mes, semana, día, día de la semana, nombre en español, bandera de fin de semana. Todo lo que normalmente extraerías de una fecha con `EXTRACT()` está ya como columna lista para `WHERE` y `GROUP BY`.
3. **Tabla densa (recomendación fuerte de Kimball).** Una fila por día existió o no haya pasado nada ese día. La densidad permite hacer joins externos cuando quieres ver "ventas por día incluyendo días sin venta", lo cual no podrías con una fact donde solo aparecen días con actividad. Otras razones son: time series, detección de gaps y filtros calendarios.

### Role-playing — una dimensión usada con varios roles

Una pregunta natural: **un pedido tiene tres fechas relevantes** — fecha del pedido, fecha requerida de entrega y fecha real de envío. ¿Necesitamos tres dimensiones de fecha?

No. La estructura de fechas (año, mes, día, etc.) **es la misma**. Lo que cambia es el rol. La fact incluye **tres FKs distintas hacia la misma `dim_date`**:

```
order_date_key      → dim_date
required_date_key   → dim_date
shipped_date_key    → dim_date
```

En las queries se usa **alias** para distinguir:

```sql
JOIN dim_date d_ord ON d_ord.date_key = f.order_date_key
JOIN dim_date d_shp ON d_shp.date_key = f.shipped_date_key
```

Eso es **role-playing**: una sola dimensión, varios usos contextuales.

---

## ¿Cuándo una métrica entra en hecho vs atributo de dimensión?

Una de las decisiones recurrentes al diseñar es: *"este número, ¿va en la fact o en una dimensión?"* La regla rápida:

> Va en la **fact** si **cambia con cada evento** medido y **se va a sumar/promediar**.
> Va en la **dimensión** si **es estable para el miembro (fila de una tabla de dimensión)** y **describe**, no se agrega.

Aplicado a Northwind:

| Atributo | ¿Dónde? | Por qué |
|---|---|---|
| `quantity` (cantidad vendida) | **Fact** | Cambia en cada línea, se suma. |
| `unit_price` aplicado a la venta | **Fact** | Cambia con el momento de venta — si el producto subió de precio, queda registrado el precio del momento. |
| `unit_price` "de catálogo" del producto en el catálogo | **Dimensión** | Atributo descriptivo del producto en el momento de cargar. Si el producto sube de precio mañana, se actualizará la dim — pero la fact ya guardó el precio histórico. |
| `discount` aplicado a la línea | **Fact** | Decisión por línea, varía. |
| `category_name` del producto | **Dimensión** | Descriptivo del producto, no varía con cada venta. |
| `country` del cliente | **Dimensión** | Descriptivo del cliente. |
| `is_weekend` para una fecha | **Dimensión** (`dim_date`) | Descriptivo del miembro "fecha". |

---

## Lo que llevas hasta aquí

| Concepto | Qué es | Dónde lo tocas en Northwind |
|---|---|---|
| **Tabla de hechos** | Eventos medibles, una fila por evento | `fact_sales` (2 155 filas) |
| **Medidas** | Columnas numéricas agregables | `quantity`, `unit_price`, `line_total` |
| **Foreign keys de la fact** | Apuntan a las dimensiones | `customer_key`, `product_key`, … |
| **Degenerate dimension** | ID sin tabla propia | `order_id` |
| **Dimensión** | Tabla con atributos descriptivos | `dim_customer`, `dim_product`, … |
| **Surrogate key** | PK autogenerada en la dim | `customer_key`, `product_key` |
| **Natural key** | ID del sistema fuente | `customer_id`, `product_id` |
| **Role-playing** | Una dim usada con varios roles | `dim_date` × 3 en `fact_sales` |
| **Smart key** | PK con significado, filtrable directo | `dim_date.date_key` (`YYYYMMDD`) |
| **Grano** | Qué representa una fila de la fact | "Una línea de pedido" en Northwind |
| **Desnormalización deliberada** | Aplanar relaciones para evitar joins en queries | `category_name` dentro de `dim_product` |

Lo que **no** has visto todavía y se trata en temas siguientes:

- **Esquema estrella, copo de nieve, constellation** → Tema 03.
- **El proceso ETL en Python que pobló estas tablas** → Tema 04.

---

## Lo que sigue

Ya tienes la **estructura** — el modelo dimensional. Lo siguiente es aprender a **navegarla**: la **Lectura 03** cubre las operaciones OLAP (drill-down, roll-up, slice, dice, pivot), los movimientos estándar para explorar el cubo en cualquier herramienta de BI.

---

[^kimball]: **Ralph Kimball** (n. 1944) — consultor y autor estadounidense, una de las figuras fundadoras del *data warehousing*. Es el creador del **enfoque dimensional** (también llamado "metodología Kimball"). Su libro **_The Data Warehouse Toolkit_** (1996, con ediciones posteriores) es la referencia estándar de la disciplina y la fuente de prácticamente todo el vocabulario de esta lectura. Su nombre aparece varias veces aquí porque son ideas suyas: la cita *"declara el grano antes que nada"* (sección **Grano**), el principio de elegir el grano más atómico disponible, la **dimensión degenerada** (sección Tabla de hechos), y la recomendación de mantener `dim_date` **densamente poblada** (sección Dimensiones) — todas forman parte de su metodología.

<p align="center">
<a href="01_oltp_vs_olap.md">← Anterior: Lectura 01</a> | <a href="Readme.md">Volver al índice</a> | <a href="03_operaciones_olap.md">Siguiente: Lectura 03 — Operaciones OLAP →</a>
</p>
