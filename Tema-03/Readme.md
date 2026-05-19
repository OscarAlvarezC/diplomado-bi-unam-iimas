# Tema 03: Esquemas dimensionales — estrella, copo de nieve, galaxy

En el Tema 02 aprendiste el vocabulario del modelo multidimensional (grano, hechos, dimensiones) y las operaciones para navegar el cubo. Este tema le pone nombre a la **forma** que toma ese cubo cuando se aterriza en tablas. Hay tres patrones — **estrella**, **copo de nieve** y **galaxy** — y entender cuándo usar cada uno es la diferencia entre un data warehouse que vuela y uno que arrastra cada query.

## :dart: Objetivos

- Diferenciar los tres patrones de modelado dimensional: estrella, copo de nieve y galaxy.
- Reconocer que `northwind_dwh` es un esquema estrella y explicar por qué.
- Entender el trade-off entre normalización y desnormalización en un contexto analítico.
- Argumentar por qué Kimball desaconseja el copo de nieve y cuándo sí tiene sentido.
- Identificar cuándo un DWH necesita varias tablas de hechos (galaxy) y qué son las *conformed dimensions*.

## :file_folder: Contenido

<ins>Estrella, copo de nieve y galaxy — los tres patrones</ins>

El **esquema estrella** es el patrón canónico: una tabla de hechos central rodeada de dimensiones planas, el que usa `northwind_dwh`. El **copo de nieve** normaliza esas dimensiones en sub-tablas — ahorra espacio pero agrega joins, y Kimball lo desaconseja salvo casos puntuales. El **galaxy** (constelación) aparece cuando el DWH tiene varias tablas de hechos compartiendo dimensiones, conectadas por *conformed dimensions*. Los tres son variaciones sobre una misma tensión: espacio en disco vs velocidad de lectura — y en analítica la balanza siempre se inclina hacia la lectura.

[**`Lectura 01`**](01_esquemas_dimensionales.md)

## :books: Material

La lectura vive en este mismo directorio. El Tema 03 es conceptual — no requiere ejecutar nada en el cluster; el `northwind_dwh` ya cargado sirve como ejemplo vivo del esquema estrella mientras lees.

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="../Tema-04/Readme.md">Siguiente: Tema 04 →</a>
</p>
