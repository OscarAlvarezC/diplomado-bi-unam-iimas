# Lectura 03 — Operaciones OLAP: cómo se explora el cubo

En la Lectura 02 viste que los datos analíticos se modelan como un **cubo** — ejes (dimensiones) y valores en las celdas (medidas). Pero tener un cubo no sirve de nada si no sabes **moverte** dentro de él. Esta lectura corta cubre las **operaciones OLAP**: el conjunto estándar de "movimientos" para navegar un cubo de datos.

Toda herramienta de BI — Power BI, Tableau, las tablas dinámicas de Excel, QuickSight — implementa estas mismas operaciones, solo con interfaces distintas. Aprender los verbos una vez te deja usar cualquier herramienta.

> Los nombres de estas operaciones son **geométricos a propósito**: describen movimientos físicos sobre un cubo (rebanarlo, rotarlo, profundizar en él). Es otra razón por la que la metáfora del cubo, y no otra forma, se volvió el estándar de la industria.

---

## Las cinco operaciones principales

### Drill-down — profundizar

Bajar de un nivel de agregación a uno **más detallado**, siguiendo una jerarquía.

```
Ventas por AÑO  →  drill-down  →  por TRIMESTRE  →  por MES  →  por DÍA
```

Ejemplo: ves "ventas de 1997 = $617 085" y haces drill-down — la cifra se abre en los 12 meses que la componen. Y de un mes puedes seguir bajando a los días.

Requiere que la dimensión tenga una **jerarquía** definida. En `dim_date` la jerarquía natural es `año › trimestre › mes › día`; en una dimensión geográfica sería `región › país › estado › ciudad`.

### Roll-up — resumir

Lo contrario de drill-down: subir a un nivel **más agregado**.

```
Ventas por CIUDAD  →  roll-up  →  por PAÍS  →  por REGIÓN
```

Es "alejarse" para ver el panorama general. Drill-down y roll-up son **el mismo eje recorrido en direcciones opuestas** — bajas para ver el detalle, subes para ver el resumen.

### Slice — rebanar

**Fijar un valor de una dimensión** y observar el resto del cubo. Reduce el cubo en una dimensión — te quedas con una "rebanada" plana.

```
Cubo completo  →  slice (year = 1997)  →  solo el corte de 1997
```

Antes tenías el cubo de 5 dimensiones; tras el slice por `year = 1997`, esa dimensión queda fija y analizas las otras cuatro dentro de ese corte. Es exactamente lo que hace un **slicer** en Power BI: eliges "1997" y todo el reporte se restringe a ese año.

### Dice — cortar en dados

Como slice, pero filtrando **varias dimensiones a la vez** — te quedas con un sub-cubo más pequeño.

```
dice:  year ∈ {1997, 1998}  Y  category = 'Beverages'  Y  country = 'México'
```

La diferencia con slice: slice fija **un** valor de **una** dimensión (queda una rebanada plana); dice filtra **rangos o conjuntos de valores** en **varias** dimensiones (el resultado sigue siendo un cubo, solo más chico).

### Pivot — rotar

**Reorientar** el cubo: intercambiar qué dimensión va en las filas y cuál en las columnas, para verlo desde otro ángulo.

```
Filas = categoría, Columnas = mes   →  pivot  →  Filas = mes, Columnas = categoría
```

Los datos son los mismos — solo cambia la perspectiva desde la que los lees. Es lo que hace una **tabla dinámica** (de ahí el nombre "pivot table" de Excel): arrastras un campo de filas a columnas y el cubo se reorganiza.

---

## Operaciones relacionadas

| Operación | ¿Qué hace? |
|---|---|
| **Drill-through** | Saltar de un dato agregado a las **filas de detalle individuales** que lo componen. Distinto de drill-down: drill-down baja de nivel pero el dato sigue agregado; drill-through te lleva al renglón crudo (a las filas de `fact_sales` que sumaron esa cifra). |
| **Drill-across** | Cruzar entre dos tablas de hechos distintas que comparten dimensiones — ej. combinar `fact_sales` con una hipotética `fact_inventory` (ambas conectadas a `dim_date` y `dim_product`) para responder _"por producto y mes, ¿cuántas unidades vendí vs cuál fue mi stock promedio?"_. |
| **Filter** | Restringir qué datos se muestran sin cambiar el nivel de agregación ni la orientación. |

---

## ¿Cómo se ven en Power BI?

El producto de visualización del módulo implementa todas las operaciones — solo cambia el nombre del control:

| Operación OLAP | En Power BI |
|---|---|
| Drill-down / roll-up | Botones de flecha (↓ ↑) en las visualizaciones con jerarquía |
| Slice | **Slicers** — los controles de filtro de la página |
| Dice | Varios slicers combinados + el panel de Filtros |
| Pivot | El visual **Matriz** — arrastras campos entre las áreas Filas y Columnas |
| Drill-through | Configuración "Drill-through" que salta a otra página del reporte con el detalle |

Tableau, Excel y QuickSight tienen equivalentes — los nombres de los botones cambian, las operaciones de fondo son las mismas.

---

## ¿Por qué importa?

El modelo dimensional (Lectura 02) y las operaciones OLAP (esta lectura) son **dos caras de lo mismo**:

- El **modelo dimensional** organiza los datos como un cubo — esa es la *estructura*.
- Las **operaciones OLAP** son lo que *haces* con esa estructura — la *interacción*.

Un buen diseño dimensional es el que hace que estas operaciones sean **rápidas y naturales**. Por eso `dim_date` tiene año, trimestre, mes y día como columnas separadas: para que el drill-down sea inmediato. Por eso las dimensiones se aplanan: para que slice y dice no requieran joins. La estructura del Tema 02 existe **para servir a estas operaciones**.

A este conjunto de movimientos se le llama **navegación OLAP** o **análisis multidimensional interactivo**. Es vocabulario universal de BI — los cinco verbos (drill-down, roll-up, slice, dice, pivot) más drill-through son lo que un analista hace todo el día frente a un dashboard.

---

## Y ahora, la prueba empírica

Con el modelo dimensional entendido (Lectura 02) y las operaciones para navegarlo (esta lectura), el tema cierra con la **Práctica 01**: la misma pregunta de negocio respondida sobre `northwind_oltp` y sobre `northwind_dwh`, para ver en una imagen por qué el modelado dimensional vale la pena.

---

<p align="center">
<a href="02_modelo_multidimensional.md">← Anterior: Lectura 02</a> | <a href="Readme.md">Volver al índice</a> | <a href="04_practica.md">Siguiente: Práctica 01 →</a>
</p>
