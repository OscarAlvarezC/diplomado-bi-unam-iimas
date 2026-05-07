# Temario del Diplomado

Diplomado en Bases de Datos y Sistemas de Información — IIMAS, UNAM, en alianza con AWS Academy. **8 módulos, 250 horas en total.** Este repo cubre el **Módulo 4** (40 h).

> 📄 Documento oficial publicado por IIMAS: [TEMARIO.pdf](https://www.iimas.unam.mx/educacioncontinua/diplomado/TEMARIO.pdf). Lo de abajo es la transcripción a Markdown del Módulo 4 para lectura rápida desde GitHub; el detalle de los otros módulos está en el PDF.

| # | Módulo | Horas |
|---|---|---|
| 1 | Fundamentos de cómputo en la nube | 20 |
| 2 | Introducción a servicios de AWS | 20 |
| 3 | Sistemas transaccionales OLTP y SQL básico | 40 |
| **4** | **Inteligencia de negocios y SQL avanzado** ← este módulo | **40** |
| 5 | Fundamentos de NoSQL | 40 |
| 6 | Conceptos avanzados de bases de datos NoSQL | 40 |
| 7 | Convergencias entre SQL y NoSQL | 20 |
| 8 | Administración de bases de datos en AWS | 30 |

---

## Módulo 4: Inteligencia de negocios y SQL avanzado (40 h)

**Al finalizar el módulo, las personas participantes podrán:**

- Explicar las características de los sistemas OLAP y diseñar modelos multidimensionales aplicando hechos, dimensiones, esquemas estrella y copo de nieve.
- Aplicar procesos ETL (extracción, limpieza, transformación y carga) para integrar datos provenientes de fuentes heterogéneas, asegurando calidad y consistencia.
- Ejecutar consultas avanzadas en SQL y PL/pgSQL utilizando funciones agregadas, de carácter, de fecha, estructuras de control, cursores, procedimientos y funciones almacenadas.
- Implementar técnicas analíticas con SQL avanzado, incluyendo funciones de ventana, CTE, recursividad, uniones y análisis de datos jerárquicos.
- Gestionar datos semiestructurados en hstore, JSON y JSONB, aplicando operadores, funciones e indexación para optimizar consultas y rendimiento.
- Integrar los conceptos de OLAP, ETL y SQL avanzado en un caso práctico de inteligencia de negocios, generando reportes descriptivos y consultas analíticas de valor empresarial.

**Temas:**

1. **Características OLAP**
    1. Modelo multidimensional.
    2. Hechos y dimensiones.
    3. Esquema estrella.
    4. Esquema copo de nieve.
    5. Ejemplos y consultas en sistemas OLAP.
    6. Caso de estudio práctico.

2. **Componentes de inteligencia de negocios para analítica descriptiva (OLAP)**
    1. Introducción.
    2. Fuentes de información heterogéneas.
    3. Proceso ETL (extracción, limpieza, transformación, carga).
    4. Extracción.
    5. Limpieza (depuración, perfilado, corrección, estandarización, correspondencia de datos, consolidación).
    6. Transformación de acuerdo con las reglas de negocio, estándares, cambio de formato, sustitución de códigos, valores derivados y valores agregados, definición de nivel de detalle.
    7. Carga (integración, actualización).
    8. Herramientas ETL y OLAP.

3. **Structured Query Language avanzado y PL/pgSQL**
    1. Introducción.
    2. Funciones predefinidas en SQL:
        1. Funciones agregadas (`count`, `sum`, `avg`, `min`, `max`).
        2. Funciones para datos tipo carácter.
        3. Funciones para datos tipo fecha.
    3. Estructuras de control de flujo:
        1. `IF-THEN-ELSE-END IF`, `CASE`.
        2. Ciclo `FOR`.
        3. Ciclo `WHILE`.
    4. Cursores.
    5. Procedimientos almacenados:
        1. Declaración de variables.
        2. Creación de procedimientos.
        3. Ejecución de procedimientos.
        4. Eliminación de procedimientos.
    6. Funciones:
        1. Funciones de ventana (`row_number`, `rank`, `dense_rank`).
        2. Función `OVER`.
        3. Promedios móviles, sumas acumulativas, análisis lead.
    7. Common Table Expressions (CTE para datos jerárquicos):
        1. Recursión.
        2. `WITH`.
        3. `WITH RECURSIVE`.
        4. `UNION ALL`.
    8. Soporte a datos semiestructurados:
        1. Colecciones simples llave-valor, `hstore`.
        2. Tipos de datos que almacena `hstore`.
        3. Almacenamiento en una sola columna.
        4. Operadores y funciones de `hstore`: `->`, `->>`, `||`, `?`.
        5. Indexación y rendimiento en `hstore` (GIN).
        6. Colecciones jerárquicas llave-valor `JSON` y `JSONB`.
        7. Tipos de datos que almacenan JSON.
        8. Operadores JSON: `->`, `->>`, `#>>`, `@>`.
        9. Funciones `jsonb_array_elements()` y `jsonb_extract_path()`.
        10. Indexación (GIN, btree).

---

## Bibliografía

1. Bradshaw, S., Brazil, E. & Chodorow, K. (2020). *MongoDB. The Definitive Guide: Powerful and Scalable Data Storage*. Third Edition. O'Reilly Media.
2. O'Higgins, N. (2011). *MongoDB and Python. Patterns and Processes for the Popular Document-Oriented Database*. O'Reilly Media.
3. Perkins, L., Redmond, E. & Wilson, J. (2018). *Seven Databases in Seven Weeks. A Guide to Modern Databases and the NoSQL Movement*. Second Edition. Pragmatic Bookshelf.
4. Wittig, A. & Wittig, M. (2023). *Amazon Web Services in Action. An in-depth guide to AWS*. Third Edition. Manning.
5. Fregly, C. & Barth, A. (2021). *Data Science on AWS. Implementing End-to-End, Continuous AI and Machine Learning Pipelines*. O'Reilly Media.
6. Viescas, J. (2018). *SQL Queries for Mere Mortals*. Fourth Edition. Addison-Wesley Professional.
7. Beaulieu, A. (2020). *Learning SQL. Generate, Manipulate, and Retrieve Data*. Third Edition. O'Reilly Media.
8. Tanimura, C. (2021). *SQL for Data Analysis. Advanced Techniques for Transforming Data into Insights*. O'Reilly Media.
9. Sullivan, D. (2015). *NoSQL for Mere Mortals*. Addison-Wesley Professional.
10. Teate, R. (2021). *SQL for Data Scientists: A Beginner's Guide for Building Datasets for Analysis*. Wiley.
11. Vadlamani, V. (2024). *PostgreSQL Skills Development on Cloud. A Practical Guide to Database Management with AWS and Azure*. Apress.
12. Johnson, R. (2025). *The DynamoDB Handbook. Practical Solutions for Modern NoSQL Database Management*. HiTeX Press.

---

<p align="center">
<a href="../README.md">← Volver al inicio</a>
</p>
