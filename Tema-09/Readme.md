# Tema 09: Datos semiestructurados — hstore y JSONB

PostgreSQL soporta datos cuyo schema **no es fijo a nivel de columna**: una sola columna puede contener pares clave-valor (`hstore`) o estructuras JSON anidadas (`JSONB`). Esto resuelve un problema clásico — entidades heterogéneas con atributos distintos por instancia (productos con propiedades específicas por categoría, eventos con payloads variables, etc.). Este tema cubre los dos tipos: cuándo usar cada uno, sus operadores y funciones, y cómo indexarlos con GIN para que las queries sobre ellos sean rápidas.

## :dart: Objetivos

- Distinguir cuándo conviene una columna semi-estructurada vs un schema relacional clásico.
- Modelar atributos clave-valor planos con **`hstore`**.
- Modelar atributos jerárquicos con **`JSONB`**.
- Dominar los operadores de acceso (`->`, `->>`, `#>>`), existencia (`?`) y containment (`@>`).
- Usar `jsonb_array_elements()` para convertir un array JSON en filas, y `jsonb_extract_path()` para acceso por path.
- Indexar con **GIN** y medir el impacto en queries reales sobre el dataset Airbnb CDMX.

## :file_folder: Contenido

<ins>1. Por qué datos semi-estructurados</ins>

El problema: schemas que cambian por entidad. Productos heterogéneos donde cada categoría tiene atributos distintos (un libro tiene `paginas` y `autor`, una camiseta tiene `talla` y `color`); atributos de usuarios opcionales y variables; payloads de eventos donde la estructura depende del tipo. Las dos respuestas tradicionales — una tabla por tipo de entidad, o una tabla EAV — tienen problemas. PostgreSQL ofrece una tercera vía: **una columna que contiene la estructura variable**.

<ins>2. hstore — colecciones planas clave-valor</ins>

Habilitación de la extensión `hstore`. Sintaxis literal y almacenamiento en una sola columna. **Operadores:** `->` (acceso al valor — ya como texto), `||` (merge), `?` (existencia de key). **Limitación clave:** hstore es **plano** — no soporta jerarquías ni arrays anidados. Para eso, JSONB.

<ins>3. JSONB — colecciones jerárquicas</ins>

**`JSON` vs `JSONB`:** almacenamiento (texto vs binario) y cuándo usar cada uno (regla rápida: `JSONB` salvo que necesites preservar el formato textual exacto). **Operadores de acceso:** `->` (devuelve `JSONB`), `->>` (devuelve texto), `#>>` (acceso por path como texto). **Operador de containment** `@>` — clave para queries con índices. **Funciones:** `jsonb_array_elements()` (explotar arrays a filas) y `jsonb_extract_path()` (acceso por path en forma de función).

<ins>4. Indexación GIN — cómo y cuándo</ins>

Por qué GIN funciona bien para semi-estructurados (índice invertido sobre los elementos internos) y cómo verlo con `EXPLAIN`. Trade-off: lectura más rápida, escrituras más caras y más espacio. Mención de índices **btree** sobre expresiones (`(data->>'campo')`) cuando solo filtras por un campo escalar específico.

<ins>5. Práctica sobre Airbnb CDMX</ins>

Aplicación a la columna **`amenities`** de `airbnb.listings` — un array JSON guardado como texto, casteable a `jsonb`. Queries: contar listings que ofrecen una amenity (`@>`), explotar el array a filas con `jsonb_array_elements_text()` para rankear las amenities más comunes, e indexar con GIN.

## :books: Material

[**`Notebook 01 — Datos semiestructurados`**](https://colab.research.google.com/github/OscarAlvarezC/diplomado-bi-unam-iimas/blob/main/Tema-09/01_semiestructurados.ipynb)

Cubre lo explícito del temario: `hstore` (`->`, `||`, `?`, GIN) y `JSONB` (`->`, `->>`, `#>>`, `@>`, `jsonb_array_elements()`, `jsonb_extract_path()`, GIN/btree).

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="../anexos/rubrica_proyecto_final.md">Siguiente: Proyecto final →</a>
</p>
