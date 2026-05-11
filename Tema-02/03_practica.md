# Práctica 01 — La misma pregunta sobre OLTP y sobre DWH

Esta práctica cierra la sesión con la **prueba empírica** de las dos lecturas anteriores. Vas a contestar **una sola pregunta de negocio** primero contra `northwind_oltp` (3NF, normalizado) y luego contra `northwind_dwh` (esquema estrella, dimensional). El objetivo no es la respuesta — la respuesta es la misma — sino **leer la diferencia entre las dos queries**: cuántas tablas tocan, qué cálculos requieren, qué tan rápido se entiende qué intentan responder.

## Pregunta de negocio

> *"¿Cuáles fueron las **ventas netas por categoría de producto y por mes** durante el año 1997?"*

"Ventas netas" significa contemplar el descuento aplicado a cada línea: `quantity * unit_price * (1 - discount)`.

## Prerequisitos

- ✅ DBeaver conectado al cluster `aurora-mod4` (Tema 01).
- ✅ Schemas `northwind_oltp` y `northwind_dwh` cargados (Tema 01).
- ✅ Repo descargado localmente para abrir los `.sql` desde DBeaver.

---

## Paso 1 — Query sobre el OLTP

Abre el archivo [`scripts/tema02/01_oltp_ventas_categoria_mes.sql`](../scripts/tema02/01_oltp_ventas_categoria_mes.sql) en DBeaver y ejecútalo (**Alt+X**).

```sql
SELECT
    c.category_name,
    EXTRACT(MONTH FROM o.order_date)::INT                                         AS mes,
    ROUND(SUM(od.unit_price::NUMERIC * od.quantity * (1 - od.discount::NUMERIC)),
          2)                                                                      AS ventas_netas
FROM northwind_oltp.order_details od
JOIN northwind_oltp.orders        o ON o.order_id    = od.order_id
JOIN northwind_oltp.products      p ON p.product_id  = od.product_id
JOIN northwind_oltp.categories    c ON c.category_id = p.category_id
WHERE EXTRACT(YEAR FROM o.order_date) = 1997
GROUP BY c.category_name, EXTRACT(MONTH FROM o.order_date)
ORDER BY c.category_name, mes;
```

Observa el resultado: 96 filas, ocho categorías × doce meses. Pero antes de pasar a la siguiente query, **vuelve al texto de la query** y cuenta:

- **Tablas que aparecen en el `FROM` y los `JOIN`:** `order_details`, `orders`, `products`, `categories`. **Cuatro tablas.**
- **Joins explícitos:** tres.
- **Cálculo manual de la métrica:** `od.unit_price * od.quantity * (1 - od.discount)` — la fórmula de venta neta, escrita a mano dentro del `SUM`.
- **Casts y funciones de corrección:** `::NUMERIC` para convertir REAL a decimal exacto, `ROUND(…, 2)` para presentar pesos con dos decimales.
- **Funciones para extraer parte de la fecha:** `EXTRACT(YEAR FROM …)` para filtrar el año, `EXTRACT(MONTH FROM …)` para agrupar por mes.

Y la pregunta importante: **si alguien nuevo lee esta query, ¿qué tan rápido entiende qué se está preguntando?** El intento ("ventas netas por categoría y mes") está distribuido en seis decisiones técnicas distintas. Hay que descifrar la fórmula y los casts antes de ver la intención.

---

## Paso 2 — Query sobre el DWH

Abre [`scripts/tema02/02_dwh_ventas_categoria_mes.sql`](../scripts/tema02/02_dwh_ventas_categoria_mes.sql) y ejecútalo.

```sql
SELECT
    p.category_name,
    d.month_number          AS mes,
    SUM(f.line_total)       AS ventas_netas
FROM northwind_dwh.fact_sales  f
JOIN northwind_dwh.dim_product p ON p.product_key  = f.product_key
JOIN northwind_dwh.dim_date    d ON d.date_key     = f.order_date_key
WHERE d.year = 1997
GROUP BY p.category_name, d.month_number
ORDER BY p.category_name, mes;
```

Mismo resultado: 96 filas, ocho categorías × doce meses. Vuelve a contar:

- **Tablas:** `fact_sales`, `dim_product`, `dim_date`. **Tres.**
- **Joins:** dos.
- **Cálculo manual:** ninguno. `line_total` ya viene calculado y en `NUMERIC`.
- **Casts y funciones de corrección:** ninguno.
- **Funciones para extraer fecha:** ninguna. `year` y `month_number` ya son columnas de `dim_date`.

La intención ("ventas netas por categoría y mes durante 1997") **se lee directo del texto de la query**: `SUM(line_total)`, agrupado por `category_name` y `month_number`, filtrado por `year = 1997`. Sin ruido técnico encima.

---

## Paso 3 — Comparación lado a lado

| Aspecto | OLTP | DWH |
|---|---|---|
| Tablas | 4 | 3 |
| Joins | 3 | 2 |
| Cálculo manual de la métrica | Sí (`qty × price × (1-discount)`) | No (`line_total` ya calculado) |
| Cast `::NUMERIC` para corrección de tipo | Sí | No (la dim ya está en NUMERIC) |
| `EXTRACT(YEAR …)`, `EXTRACT(MONTH …)` | Sí | No (columnas explícitas en `dim_date`) |
| Líneas significativas de query | ~9 | ~6 |
| Legibilidad de la intención | Difusa | Directa |

Compara también los totales. Las dos queries deberían producir cifras prácticamente idénticas, con **diferencias de centavos** entre ambas — esas diferencias son el efecto de la corrección **REAL → NUMERIC** que hizo el ETL al cargar la fact. El OLTP suma `REAL` (binario aproximado), el DWH suma `NUMERIC` (decimal exacto).

---

## Paso 4 — Pregúntate qué pasa cuando escalas

Northwind tiene 2 155 líneas de pedido. Ambas queries se ejecutan en milisegundos sobre el cluster `db.t3.medium` — la diferencia entre ellas, en este dataset, es **estética**.

Imagínate ahora un escenario de empresa real:

- 50 millones de líneas de pedido al año.
- 5 años de historia.
- 250 millones de filas en la tabla equivalente a `order_details`.

Sobre ese volumen:

- La query OLTP recorre **cuatro tablas grandes**, hace `JOIN` por `order_id` (que es el grano natural pero no necesariamente el más selectivo para análisis), aplica `EXTRACT(YEAR …)` a 250 M filas para descartar las que no son de 1997 (sin poder usar índice sobre la columna derivada — la función envuelve la columna y mata el índice), y multiplica tres columnas para cada fila sobreviviente.
- La query DWH recorre **tres tablas**, hace `JOIN` por surrogate keys (índices muy selectivos), filtra por `dim_date.year = 1997` (que toca primero la dim chica de 1 096 filas y propaga el filtro a la fact por la FK), y suma una columna ya calculada.

La diferencia deja de ser estética. Una corre en segundos; la otra puede tardar minutos o no terminar.

Y eso es **antes** de hablar de:

- Concurrencia: la query OLAP sobre el OLTP bloquea las ventas en tiempo real.
- Modelado: agregar tres dimensiones más (canal de venta, campaña, sucursal) duplica los joins en el OLTP y solo agrega una columna FK en la fact.

---

## Paso 5 — Variantes para practicar

Sobre el DWH (porque son más cómodas), intenta responder estas preguntas escribiéndolas tú. No hace falta entregar nada — son para que sientas cómo "girar el cubo" desde la misma fact.

1. **Top 10 de productos por venta neta en 1997.**
   *Hint:* `SUM(line_total)` agrupado por `dim_product.product_name`, ordenado descendente, `LIMIT 10`.

2. **Ventas netas por país del cliente y trimestre, en 1997.**
   *Hint:* tres joins (fact + `dim_customer` + `dim_date`), agrupar por `country` y `quarter`.

3. **Ventas netas por empleado en pedidos despachados en fin de semana.**
   *Hint:* esta es la prueba del role-playing — necesitas join a `dim_date` por **`shipped_date_key`** (no por `order_date_key`) y filtrar `is_weekend = TRUE`.

4. **¿Cuántos pedidos distintos cerró cada categoría?**
   *Hint:* esta es la prueba de la dimensión degenerada — `COUNT(DISTINCT order_id)` agrupado por `category_name`.

5. **Compara las mismas variantes contra el OLTP.** Para cada una, pregúntate qué tablas adicionales tendrías que tocar y qué cálculos manuales agregar. La pregunta 3 sobre el OLTP requiere convertir `shipped_date` a "es fin de semana" — algo que en el DWH es una columna directa.

---

## Cierre

Lo que acabas de comprobar es que **el modelo dimensional cambia el costo de las preguntas analíticas** — no porque el motor sea distinto (es el mismo Aurora PostgreSQL ejecutando las dos queries), sino porque la **organización de los datos** está pensada para ese tipo de consultas. Esa es la justificación del trabajo que viene en las siguientes sesiones:

- **Tema 03** explora **qué patrones** de organización dimensional existen (estrella, copo de nieve, constellation) y cuándo elegir uno sobre otro.
- **Tema 04** te lleva por el **DDL completo y la transformación** SQL paso a paso del DWH que ya tienes cargado.
- El **Tema 05** construye el **proceso ETL en Python** que automatiza esa transformación.

---

<p align="center">
<a href="02_modelo_multidimensional.md">← Anterior: Lectura 02</a> | <a href="Readme.md">Volver al índice del Tema 02</a> | <a href="../Tema-03/Readme.md">Siguiente: Tema 03 →</a>
</p>
