# Tema 02: Fundamentos OLAP — OLTP vs OLAP y modelo multidimensional

En el Tema 01 cargamos dos representaciones de Northwind: una transaccional en `northwind_oltp` y una analítica en `northwind_dwh`. Hoy explicamos **por qué** existen las dos. La razón corta: una base optimizada para registrar miles de pedidos por segundo no es la misma base optimizada para responder _"¿cuánto vendimos por categoría y mes durante 1997?"_ sin que la pregunta tarde minutos. Esta sesión es la justificación intelectual del modelado dimensional — el _qué_ (esquemas estrella, copo de nieve, constelación) lo vemos en el **Tema 03**, y el _cómo_ (DDL + carga end-to-end) en el **Tema 04**.

## :dart: Objetivos

- Distinguir cargas **OLTP** y **OLAP** por sus patrones de uso, propósito y restricciones de diseño.
- Argumentar por qué una base normalizada en 3NF es ideal para escrituras y limitante para análisis.
- Manejar el vocabulario fundamental del modelo multidimensional: **hechos**, **dimensiones**, **grano**.
- Reconocer cuándo una métrica entra en una tabla de hechos y cuándo es atributo de una dimensión.
- Conocer las operaciones OLAP (drill-down, roll-up, slice, dice, pivot) para navegar un cubo de datos.
- Comparar la misma pregunta de negocio respondida sobre `northwind_oltp` vs `northwind_dwh` y leer la diferencia.

## :file_folder: Contenido

<ins>OLTP vs OLAP — dos cargas de trabajo, dos diseños</ins>

Las bases transaccionales (**OLTP**, _Online Transaction Processing_) se diseñan para que la empresa siga operando: cobrar un pedido, registrar un alta, despachar un envío. Lo importante es que cada operación sea **rápida, atómica y nunca pierda datos**. Las bases analíticas (**OLAP**, _Online Analytical Processing_) se diseñan para que la empresa **se pregunte qué está pasando**: tendencias, comparativos, agregados sobre millones de filas. Estos dos objetivos jalan el diseño en direcciones opuestas — distinta normalización, distintos índices, distinto tamaño esperado, distinta latencia tolerable. Reconocer estas diferencias es lo primero que hay que hacer antes de modelar cualquier warehouse.

[**`Lectura 01`**](01_oltp_vs_olap.md)

---

<ins>Modelo multidimensional — hechos, dimensiones, grano</ins>

El modelado multidimensional es la geometría de los datos analíticos. Una **tabla de hechos** registra eventos medibles del negocio (una venta, un click, una llamada) — sus columnas son métricas numéricas y referencias al contexto. Las **dimensiones** son ese contexto: el **quién** (cliente), el **qué** (producto), el **cuándo** (fecha), el **dónde** (geografía). La pregunta más importante a hacer antes de construir cualquier warehouse es la del **grano** de la tabla de hechos: ¿una fila por pedido completo, por línea de pedido, por unidad vendida? La respuesta determina todo lo demás — qué dimensiones aplican, qué métricas se pueden agregar, qué preguntas se pueden contestar.

[**`Lectura 02`**](02_modelo_multidimensional.md)

---

<ins>Operaciones OLAP — cómo se explora el cubo</ins>

El modelo dimensional es la **estructura**; las operaciones OLAP son lo que **haces** con ella. Drill-down, roll-up, slice, dice y pivot son los movimientos estándar para navegar un cubo de datos — los mismos en Power BI, Tableau, Excel o cualquier herramienta de BI. Una lectura corta para nombrar formalmente lo que un analista hace todo el día frente a un dashboard.

[**`Lectura 03`**](03_operaciones_olap.md)

---

<ins>Práctica — la misma pregunta sobre OLTP y sobre DWH</ins>

Cerramos con la prueba empírica de lo discutido. Tomamos una pregunta de negocio simple — _"ventas netas por categoría de producto y por mes en 1997"_ — y la respondemos primero contra `northwind_oltp` (que requiere joins de tres o cuatro tablas, agregaciones manuales y `EXTRACT` sobre fechas) y luego contra `northwind_dwh` (un join sencillo a `dim_product` y `dim_date`, `SUM` directo sobre `fact_sales`). La diferencia en complejidad de la query, claridad de la intención y volumen de filas tocadas **es** la justificación del modelado dimensional en una imagen.

[**`Práctica 01`**](04_practica.md)

## :books: Material

Las lecturas y la práctica viven en este mismo directorio. Las queries comparativas están en [`scripts/tema02/`](../scripts/tema02/) y se pueden ejecutar tal cual desde DBeaver con la conexión `aurora-mod4` ya configurada en el Tema 01.

## :grey_question: Preguntas de clase

Preguntas reales que han hecho alumnos durante este tema, con la respuesta que demandó investigación en profundidad después de clase: [**`preguntas_de_clase.md`**](preguntas_de_clase.md).

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="../Tema-03/Readme.md">Siguiente: Tema 03 →</a>
</p>
