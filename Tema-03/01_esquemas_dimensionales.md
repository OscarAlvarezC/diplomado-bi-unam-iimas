# Lectura 01 — Esquemas dimensionales: estrella, copo de nieve, galaxy

En el Tema 02 aprendiste el **vocabulario** del modelo multidimensional — grano, hechos, dimensiones — y viste que `northwind_dwh` organiza los datos como un cubo. Esta lectura le pone nombre a la **forma** que toma ese cubo cuando se aterriza en tablas. Hay tres patrones: **estrella**, **copo de nieve** y **galaxy** (constelación). No son tres tecnologías distintas — son tres maneras de acomodar las mismas tablas de hechos y dimensiones, cada una con un trade-off.

---

## El punto de partida: una fact rodeada de dimensiones

Recuerda la estructura de `northwind_dwh`: una tabla de hechos (`fact_sales`) en el centro, con foreign keys que apuntan a cinco dimensiones (`dim_customer`, `dim_product`, `dim_employee`, `dim_shipper`, `dim_date`). Esa disposición — **un hecho central + dimensiones alrededor** — es la base de todos los esquemas dimensionales. Lo que cambia entre estrella, copo de nieve y galaxy es **cuántas facts hay** y **qué tan normalizadas están las dimensiones**.

---

## Esquema estrella (star schema)

El **esquema estrella** es el patrón canónico de Kimball y el que usa `northwind_dwh`. Su definición:

> Una tabla de hechos en el centro, conectada directamente a un conjunto de dimensiones **planas** (desnormalizadas). Cada dimensión es **una sola tabla**.

```
              dim_date
                  │
   dim_customer ──┼── dim_product
                  │
            fact_sales
                  │
   dim_employee ──┴── dim_shipper
```

Si lo dibujas, el hecho queda en el centro y las dimensiones irradian como las **puntas de una estrella** — de ahí el nombre.

### La clave: dimensiones planas

"Plana" significa que **toda la información descriptiva de la dimensión vive en una sola tabla**, aunque eso implique duplicar valores. En `dim_product` lo viste en el Tema 02: la categoría y el proveedor están **aplanados** como columnas (`category_name`, `supplier_name`, `supplier_country`), no en tablas aparte.

```
dim_product
─────────────────────────────────────────────
  product_key      (surrogate)
  product_id       (natural)
  product_name
  category_name    ← "Beverages" se repite en cada bebida
  supplier_name    ← el nombre del proveedor se repite
  supplier_country
  discontinued
```

`"Beverages"` aparece duplicado en cada producto que sea bebida. En un esquema estrella eso es **deliberado y correcto**.

### Por qué la estrella es el patrón preferido

- **Queries simples.** Para "ventas por categoría" haces un solo `JOIN` (`fact_sales` → `dim_product`). La categoría ya está ahí.
- **Pocos joins = más rápido.** El motor une la fact con cada dimensión una sola vez. Menos joins, menos trabajo, planes de ejecución más predecibles.
- **Fácil de entender.** Un analista ve el esquema y de inmediato sabe qué dimensiones tiene disponibles.
- **La duplicación no duele.** Las dimensiones son chicas (77 productos, 91 clientes) y solo se reescriben vía ETL — la redundancia no genera riesgo de inconsistencia.

Es el patrón por defecto. Mientras no tengas una razón fuerte para hacer otra cosa, **diseña en estrella**.

---

## Esquema copo de nieve (snowflake schema)

El **copo de nieve** toma el esquema estrella y **normaliza las dimensiones** — las parte en sub-tablas para eliminar la duplicación.

Imagina que en vez de aplanar la categoría dentro de `dim_product`, la sacáramos a su propia tabla:

```
                          fact_sales
                              │
                          dim_product
                          ────────────
                            product_key
                            product_name
                            category_key  ──→  dim_category
                            supplier_key  ──→  dim_supplier      ────────────         ────────────
                                                                  category_key         supplier_key
                                                                  category_name        supplier_name
                                                                  category_desc        supplier_country
```

Ahora `dim_product` ya no tiene `category_name` — tiene un `category_key` que apunta a una tabla `dim_category` separada. La categoría se guarda **una sola vez**. Lo mismo con el proveedor.

Si lo dibujas, las dimensiones se ramifican en sub-dimensiones, y sub-sub-dimensiones — la figura recuerda los brazos fractales de un **copo de nieve**. De ahí el nombre.

### El trade-off

| Aspecto | Estrella | Copo de nieve |
|---|---|---|
| Duplicación de datos | Sí (tolerada) | No (normalizado) |
| Espacio en disco | Un poco más | Un poco menos |
| Joins por query | Menos | **Más** (hay que cruzar las sub-tablas) |
| Complejidad de la query | Baja | Mayor |
| Facilidad para el analista | Alta | Menor |

El copo de nieve **ahorra espacio** y **elimina la redundancia** — gana en pureza de diseño. Pero **paga con más joins** en cada query analítica, que es exactamente lo que un DWH quiere evitar.

### Por qué Kimball lo desaconseja

Kimball es explícito: **para la mayoría de los casos, no uses copo de nieve.** Su razonamiento:

1. **El ahorro de espacio es marginal.** Las dimensiones son chicas comparadas con la fact. Normalizar `dim_product` de 77 filas ahorra kilobytes — irrelevante cuando la fact tiene millones de filas.
2. **El costo en queries es real.** Cada sub-tabla es un join extra que se paga en **cada** consulta analítica, para siempre.
3. **Complica la herramienta de BI.** Power BI, Tableau y compañía están optimizados para esquemas estrella. Un copo de nieve confunde el modelo y la auto-detección de relaciones.

Es el mismo argumento que viste en el Tema 02 sobre por qué el DWH desnormaliza: en analítica, **la velocidad de lectura vale más que la pureza del diseño**.

### Cuándo el copo de nieve sí tiene sentido

No es un patrón "prohibido" — tiene casos legítimos:

- **Dimensiones enormes con mucha repetición.** Si una dimensión tiene millones de filas y un atributo larguísimo (un texto de varios KB) que se repite, normalizarlo sí ahorra espacio significativo.
- **Atributos compartidos por varias dimensiones.** Si "país" lo usan `dim_customer`, `dim_supplier` y `dim_employee`, una tabla `dim_country` central evita mantener la lista de países en tres lugares.
- **Jerarquías que cambian de forma independiente.** Cuando una sub-dimensión se actualiza por su cuenta con frecuencia.

Pero son la excepción. El default sigue siendo estrella.

---

## Esquema galaxy (fact constellation)

Los dos esquemas anteriores tienen **una sola tabla de hechos**. El **galaxy** — también llamado **fact constellation** o esquema de constelación — es lo que pasa cuando el DWH tiene **varias tablas de hechos que comparten dimensiones**.

Recuerda del Tema 02: una fact tiene **un grano uniforme**. Si necesitas analizar el negocio a dos granos distintos, no mezclas filas en una sola fact — creas **dos facts**. Por ejemplo, para Northwind:

```
              dim_date          dim_customer          dim_employee
                 │                   │                     │
        ┌────────┼─────────┐         │          ┌──────────┼─────────┐
        ▼        ▼         ▼         ▼          ▼          ▼         ▼
   fact_sales (grano: línea de pedido)   fact_orders (grano: pedido completo)
        ▲        ▲                                   ▲          ▲
        │        │                                   │          │
   dim_product  dim_shipper                      dim_shipper   dim_date
```

- **`fact_sales`** — una fila por línea de pedido. Mide `quantity`, `line_total`.
- **`fact_orders`** — una fila por pedido completo. Mide `freight` (el flete, que se cobra por pedido, no por línea).

Las dos comparten `dim_date`, `dim_customer`, `dim_employee`, `dim_shipper`. Cada fact es una estrella; **juntas forman una "constelación" de estrellas** — de ahí el nombre galaxy.

### Conformed dimensions — la pieza clave

Para que un galaxy funcione, las dimensiones compartidas deben ser **conformed dimensions** (dimensiones conformadas): **exactamente la misma tabla**, usada por ambas facts, con el mismo significado y las mismas llaves.

Esto importa porque permite **comparar métricas entre facts**. Si `fact_sales` y `fact_orders` usan la misma `dim_date`, puedes preguntar *"por mes, ¿cuánto vendí (de fact_sales) y cuánto pagué de flete (de fact_orders)?"* — alineando ambas por la dimensión común. Eso es el **drill-across** que viste en la Lectura 03 del Tema 02.

Si cada fact tuviera su propia tabla de fechas, distinta, no podrías cruzarlas — los meses no se alinearían. Las conformed dimensions son el "pegamento" del galaxy.

### Cuándo aparece un galaxy

Naturalmente, cuando el negocio tiene **varios procesos medibles** que comparten contexto:

- **Ventas + inventario** — `fact_sales` y `fact_inventory`, ambas con `dim_product` y `dim_date`.
- **Ventas + metas** — `fact_sales` y `fact_targets`, comparando real vs objetivo.
- **Pedidos + devoluciones + envíos** — cada proceso su fact, todas compartiendo cliente y fecha.

Casi todo DWH empresarial real es un galaxy — un solo proceso de negocio es raro. Northwind con su única `fact_sales` es un esquema estrella simple, justo porque es un dataset didáctico chico.

---

## Los tres, lado a lado

| | Estrella | Copo de nieve | Galaxy |
|---|---|---|---|
| **Tablas de hechos** | 1 | 1 | **Varias** |
| **Dimensiones** | Planas (desnormalizadas) | Normalizadas en sub-tablas | Planas, **compartidas** entre facts |
| **Joins por query** | Mínimos | Más (sub-tablas) | Mínimos dentro de cada fact |
| **Cuándo se usa** | El default | Excepción (dims enormes, atributos compartidos) | Cuando hay varios procesos de negocio |
| **Ejemplo Northwind** | `northwind_dwh` actual | Si `dim_category` se separara de `dim_product` | `fact_sales` + `fact_orders` |

Una forma de verlo: **el galaxy es "varias estrellas conectadas"**, y **el copo de nieve es "una estrella con las dimensiones partidas"**. La estrella es la unidad base; las otras dos son lo que pasa al escalar (galaxy) o al normalizar (copo de nieve).

---

## El trade-off de fondo: espacio vs velocidad de lectura

Los tres esquemas son variaciones sobre una misma tensión, la misma que viste en el Tema 02 entre OLTP y OLAP:

- **Normalizar** (copo de nieve, y el OLTP en 3NF) → menos duplicación, menos espacio, pero **más joins**.
- **Desnormalizar** (estrella) → algo de duplicación, algo más de espacio, pero **menos joins y lecturas más rápidas**.

En un sistema analítico la balanza se inclina **siempre hacia la velocidad de lectura**, porque:

1. El espacio en disco es barato; el tiempo del analista esperando una query, no.
2. Las dimensiones son chicas — la duplicación cuesta poco.
3. Las dimensiones solo se reescriben vía ETL controlado — la redundancia no genera inconsistencias.

Por eso **el esquema estrella es el patrón por defecto** del modelado dimensional, y por eso `northwind_dwh` está diseñado así.

---

## Para pensar — diseñar una estrella desde cero

Una buena forma de fijar estos conceptos es diseñar un esquema estrella para **un dominio distinto a Northwind**. Toma un negocio que conozcas — una **biblioteca**, un **hospital**, una **plataforma de streaming**, una **tienda en línea** — y plantéate:

1. **¿Cuál es el proceso de negocio y su grano?** (ej. en una biblioteca: ¿un préstamo de un libro? ¿una fila por libro prestado?)
2. **¿Qué métricas tiene la fact?** (días prestado, multa generada, número de renovaciones...)
3. **¿Qué dimensiones dan contexto?** (libro, socio, fecha, sucursal...)
4. **¿Habría más de una fact?** (préstamos + adquisiciones de libros = un galaxy con `dim_libro` y `dim_fecha` conformadas)
5. **¿Alguna dimensión ameritaría copo de nieve?** Probablemente no — recuerda el default.

No hay que entregar nada; es un ejercicio mental para comprobar que puedes aplicar el patrón fuera del ejemplo conocido. El modelado dimensional es una habilidad de **diseño** — se aprende diseñando, no solo leyendo.

---

## Lo que sigue

Con los tres esquemas claros, el **Tema 04** te lleva al ETL en Python: el proceso que **construye y puebla** un esquema estrella tomando datos de un sistema OLTP. Vas a implementar en código lo que hasta ahora solo has leído.

---

<p align="center">
<a href="Readme.md">← Volver al índice del Tema 03</a> | <a href="../Tema-04/Readme.md">Siguiente: Tema 04 →</a>
</p>
