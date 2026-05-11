# Lectura 01 — OLTP vs OLAP: dos cargas, dos diseños

Una empresa tiene dos funciones principales para sus bases de datos. 
- Operar: cobrar un pedido, registrar un alta, despachar un envío, actualizar un inventario.
- Analizar: ¿cómo va el trimestre?, ¿qué categorías crecieron?, ¿qué clientes están comprando menos?

Las dos funciones **demandan el diseño en direcciones opuestas**. Esta lectura explica esa tensión y por qué la solución estándar es tener **dos bases con propósitos distintos**, no una sola que intente servir a las dos.

---

## El nombre largo de cada acrónimo

| Sigla | Qué significa | Pregunta que contesta |
|---|---|---|
| **OLTP** | *Online Transaction Processing* | "¿Está esta operación registrada de forma íntegra?" |
| **OLAP** | *Online Analytical Processing*  | "¿Qué patrón hay en este conjunto de operaciones?" |

El adjetivo **online** no significa "en internet" — significa **en línea**, en oposición a **batch** (procesamiento por lotes). La palabra que cambia entre las dos siglas describe **el tipo de uso** que se le da al sistema:

- **Transaction**: cada operación es una **transacción** del negocio (registrar un pedido, cobrar, despachar). Unidades pequeñas, atómicas, frecuentes.
- **Analytical**: cada operación es una **pregunta analítica** (sumar, agrupar, comparar entre periodos). Unidades grandes, exploratorias, esporádicas.

Esa diferencia de uso basta para que el diseño técnico de cada uno tenga que ser distinto.

---

## OLTP — el sistema que opera

Una base **OLTP** es la que sostiene la operación diaria. Es lo que toca cuando agregas un producto al carrito, cuando confirmas un pedido, cuando el almacén marca el envío como despachado. En Northwind, el schema `northwind_oltp` cumple este rol — es **la estructura original** del dataset, tal como existiría en el sistema transaccional de la empresa (clientes, pedidos, líneas de pedido, productos, etc.).

### Patrones de uso

- **Muchas escrituras pequeñas y concurrentes.** Decenas, cientos o miles de transacciones por segundo, cada una afectando pocas filas.
- **Lecturas puntuales por clave primaria.** "Dame el pedido `10248`", "dame el cliente `ALFKI`". Se sirven en milisegundos con el índice de la llave primaria (PK).
- **Tiempo de respuesta crítico.** Un usuario está esperando del otro lado. Si la query tarda 2 segundos, el pedido se cae.
- **Datos siempre vivos.** Lo que veas tiene que ser lo último que escribió alguien hace medio segundo. Sin caché que retrase, sin réplica que se rezague.

### Consideraciones de diseño

Para sostener este patrón, el diseño hace tres cosas que ya viste en módulos previos del diplomado:

1. **Normaliza fuerte.** Cada hecho del negocio vive en una sola tabla, sin duplicación. La consecuencia: una venta no se registra en una sola fila — se registra en `orders`, `order_details` , referencia a `customers`, `products`, `employees`, `shippers`. Modificar el nombre de un cliente actualiza un solo lugar; lo demás sigue siendo correcto por los `JOIN`.
2. **Garantiza propiedades ACID.** Atomicidad, consistencia, aislamiento, durabilidad. Si el pedido se confirma, las cinco tablas que toca quedan coherentes; si algo falla a medio camino, la base revierte todo y ninguna tabla queda modificada. Las cuatro propiedades atacan problemas distintos:

    | Letra | Qué problema resuelve | Tipo de problema |
    |---|---|---|
    | **A** Atomicidad | Falla durante la transacción → rollback | Falla del sistema |
    | **C** Consistencia | Transacción que viola reglas (`FK`, `CHECK`, `NOT NULL`) → rechazo | Integridad declarativa |
    | **I** Aislamiento | Transacciones concurrentes interfiriendo entre sí | Concurrencia |
    | **D** Durabilidad | Falla después del commit → los datos confirmados sobreviven | Falla del sistema |

    > *Nota:* **I** y **D** las cumple el motor solo, sin que el diseñador haga nada. **A** y **C** requieren cooperación: el diseñador debe marcar qué operaciones forman una transacción y qué reglas debe hacer cumplir el motor.

3. **Indexa para búsquedas por clave.** Índice por la PK de cada tabla, índices por las FK más usadas. No hay índice "por el campo que sumarías" — la base no espera ese tipo de consulta.

### Cómo se ve en `northwind_oltp`

Catorce tablas. La PK de `orders` es `order_id`, la PK de `order_details` es la pareja `(order_id, product_id)`. La fecha del pedido vive una sola vez en `orders.order_date`. La categoría de un producto está a dos `JOIN`s de distancia: `order_details → products → categories`. Para registrar una venta, perfecto: tres `INSERT` y todo el contexto queda referenciado. Para preguntar "*¿cuánto vendí por categoría en 1997?*"... ya no es perfecto. Esa es la siguiente parte.

---

## OLAP — el sistema que se pregunta qué pasó

Una base **OLAP** existe para que la empresa **observe agregados** y **detecte patrones**. Es lo que toca un analista, un dashboard, un reporte ejecutivo. En Northwind, el schema `northwind_dwh` cumple este rol — y a diferencia del OLTP, **no estaba en el dump original**: lo construimos nosotros con los scripts del Tema 01, reorganizando los datos del OLTP en una estructura distinta diseñada para análisis.

### Patrones de uso

- **Pocas escrituras grandes en lotes.** Una vez al día, una vez por hora — un proceso ETL inserta miles o millones de filas de un jalón. Entre cargas, casi pura lectura.
- **Lecturas masivas con agregación.** "Dame `SUM(ventas)` agrupado por categoría y mes durante todo 1997." La query no toca una fila — toca todas las filas del año filtradas y las pliega.
- **Tiempo de respuesta tolerante (relativamente).** El analista sí espera 2-30 segundos; lo que no quiere es 10 minutos.
- **Datos casi vivos, no instantáneos.** Una latencia de minutos u horas suele ser aceptable. El reporte ejecutivo del trimestre no necesita las ventas del último segundo, necesita las del último cierre.

### Consideraciones de diseño

Las decisiones se invierten:

1. **Desnormaliza con cuidado.** En vez de seguir cuatro saltos de FK, se aplanan las relaciones que las queries analíticas usarán siempre (la categoría siempre acompaña al producto, el mes siempre acompaña a la fecha). La categoría del producto queda **como atributo** dentro de la dimensión de productos. La fecha se descompone en año/trimestre/mes/día como columnas listas para filtrar y agrupar.
2. **Sin transacciones complejas, sin locks largos.** Las escrituras vienen del ETL, no de usuarios concurrentes. No hay decenas de procesos peleando por la misma fila.
3. **Indexa para agregación y para join entre tabla de hechos y dimensiones.** La PK de cada dimensión, las FK desde el fact, ocasionalmente índices columnares en motores especializados.
4. **Tipos de datos correctos para análisis.** Los precios viven en `NUMERIC` exacto, no en `REAL` aproximado — sumar un millón de filas con error binario no da el mismo total que sumar un millón de filas con decimales exactos.

### Cómo se ve en `northwind_dwh`

Seis tablas. Una **tabla de hechos** (`fact_sales`, 2 155 filas — una por línea de pedido) y cinco **dimensiones** (`dim_customer`, `dim_product`, `dim_employee`, `dim_shipper`, `dim_date`). La categoría del producto está aplanada dentro de `dim_product` como columna `category_name`. El año y el mes están aplanados dentro de `dim_date` como columnas `year` y `month_number`. La venta neta de cada línea está pre-calculada como columna `line_total`. Para preguntar *"¿cuánto vendí por categoría en 1997?"*, el join cruza tres tablas y la suma se resuelve en una línea.

---

## Por qué la normalización 3NF estorba para análisis

Un repaso rápido de **tercera forma normal** desde la óptica analítica: **3NF prohíbe duplicar atributos**. Si la categoría de un producto vive en una tabla, no puede vivir también en otra. Eso es genial cuando estás escribiendo — actualizas un lugar y la verdad queda intacta. Pero al leer agregaciones tienes que **reconstituir** el contexto cada vez que preguntas, mediante `JOIN`s.

Veamos las dos versiones de la pregunta *"ventas netas por categoría y mes en 1997"* — sin escribir las queries todavía, solo contando saltos:

| Query sobre... | Tablas tocadas | Operaciones |
|---|---|---|
| `northwind_oltp` | `order_details`, `orders`, `products`, `categories` | 4 tablas, 3 joins, `SUM(qty * price * (1-discount))` con la métrica calculada a mano, `EXTRACT(YEAR …)` y `EXTRACT(MONTH …)`, corregir tipo `REAL → NUMERIC`, agrupar por categoría y mes |
| `northwind_dwh` | `fact_sales`, `dim_product`, `dim_date` | 3 tablas, 2 joins, `SUM(line_total)`, filtro `year = 1997`, agrupar por `month_number` |

No es una diferencia abismal con un dataset de 2 000 filas. Multiplica por mil — fact con 2 millones de filas, OLTP con 100 millones — y la diferencia deja de ser estética y se vuelve **operativa**: la query del OLTP se vuelve impráctica, la del DWH sigue siendo razonable.

Las queries concretas las verás en la **Práctica 01** de esta misma sesión.

---

## Tabla comparativa

| Dimensión | OLTP | OLAP |
|---|---|---|
| **Propósito** | Operar el negocio | Entender el negocio |
| **Carga de escritura** | Muchas, pequeñas, concurrentes | Pocas, grandes, en lotes |
| **Carga de lectura** | Puntual por PK | Masiva con agregación |
| **Volumen típico de fila tocada por query** | 1-50 filas | Miles a millones |
| **Modelo de datos** | Normalizado (3NF) | Dimensional (estrella, copo de nieve) |
| **Duplicación de atributos** | Prohibida | Tolerada y deliberada |
| **Frescura del dato** | Instantánea | Hasta el último ETL (minutos a un día) |
| **Consumidor** | Aplicación / sitio web / API | Analista / dashboard / reporte |

---

## Por qué se separan en dos sistemas

Aún si una sola base soportara las dos cargas técnicamente, la separación se justifica por al menos cuatro razones independientes:

1. **Contención de recursos.** Una query OLAP que agrega un millón de filas usa CPU y memoria en una escala que ralentiza al OLTP concurrente. Si el reporte ejecutivo bloquea las ventas en línea, la operación pierde dinero. **Aislar las cargas en bases separadas elimina la contención.**
2. **Locks y aislamiento.** El OLAP necesita una "foto estable" del estado durante minutos para escanear millones de filas; el OLTP necesita seguir cambiando ese estado cada milisegundo. Las dos políticas chocan — una de las dos cosas tiene que ceder, y siempre cuesta caro.
3. **Modelos optimizados para cada caso.** El OLTP en 3NF y el DWH en estrella son **dos formas de organizar la misma información** para servir a dos preguntas distintas.
4. **Independencia de cambios.** El equipo de operaciones puede evolucionar el OLTP (agregar columnas, refactorizar, particionar) sin romper a los analistas, porque los analistas no consultan el OLTP — consultan el DWH, que el ETL alimenta y aísla del cambio aguas arriba.

A esa separación se le llama **arquitectura de dos capas**: capa transaccional y capa analítica, conectadas por un **proceso ETL** que extrae del OLTP, transforma a la forma dimensional y carga al DWH. El bloque ETL del módulo (Tema 05) construye exactamente ese proceso en Python.

---

## En resumen

OLTP y OLAP son **dos cargas de trabajo que jalan el diseño en direcciones opuestas**. Una optimiza por escrituras pequeñas concurrentes con integridad transaccional; la otra optimiza por lecturas masivas con agregación. La 3NF protege la primera y estorba la segunda. La solución estándar es tener dos sistemas, uno por cada carga, conectados por un proceso ETL. Lo que sigue en esta sesión es darle nombre formal al diseño que adopta el OLAP: **el modelo multidimensional** — hechos, dimensiones, grano. Esa es la **Lectura 02**.

---

<p align="center">
<a href="Readme.md">← Volver al índice del Tema 02</a> | <a href="02_modelo_multidimensional.md">Siguiente: Lectura 02 — Modelo multidimensional →</a>
</p>
