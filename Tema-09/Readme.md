# Tema 09: Datos semiestructurados — hstore y JSONB

PostgreSQL soporta datos cuyo schema **no es fijo a nivel de columna**: una sola columna puede contener pares clave-valor (`hstore`) o estructuras JSON anidadas (`JSONB`). Esto resuelve un problema clásico — entidades heterogéneas con atributos distintos por instancia (productos con propiedades específicas por categoría, eventos con payloads variables, etc.). Este tema cubre los dos tipos: cuándo usar cada uno, sus operadores y funciones, y cómo indexarlos con GIN para que las queries sobre ellos sean rápidas.

## :dart: Objetivos

- Distinguir cuándo conviene una columna semi-estructurada vs un schema relacional clásico.
- Modelar atributos clave-valor planos con **`hstore`**.
- Modelar atributos jerárquicos con **`JSONB`**.
- Dominar los operadores de acceso (`->`, `->>`, `#>`, `#>>`), existencia (`?`, `?&`, `?|`) y containment (`@>`).
- Usar funciones de explosión (`jsonb_array_elements`, `jsonb_each`) para convertir JSON en filas.
- Indexar con **GIN** y medir el impacto en queries reales sobre el dataset Airbnb CDMX.

## :file_folder: Contenido

<ins>1. Por qué datos semi-estructurados</ins>

El problema: schemas que cambian por entidad. Productos heterogéneos donde cada categoría tiene atributos distintos (un libro tiene `paginas` y `autor`, una camiseta tiene `talla` y `color`); atributos de usuarios opcionales y variables; payloads de eventos donde la estructura depende del tipo. Las dos respuestas tradicionales — una tabla por tipo de entidad, o una tabla EAV — tienen problemas. PostgreSQL ofrece una tercera vía: **una columna que contiene la estructura variable**.

<ins>2. hstore — colecciones planas clave-valor</ins>

Habilitación de la extensión `hstore`. Sintaxis literal y parsing del tipo. Almacenamiento en una sola columna vs columnas separadas — trade-offs. **Operadores:** `->` (acceso a valor), `->>` (acceso como texto), `||` (merge), `?` (existencia de key), `?&` y `?|` (existencia de múltiples keys). **Funciones útiles:** `hstore_to_array`, `each`, `keys`, `values`. **Limitación clave:** hstore es **plano** — no soporta jerarquías ni arrays anidados. Para eso, JSONB.

<ins>3. JSONB — colecciones jerárquicas</ins>

**`JSON` vs `JSONB`:** diferencias de almacenamiento (texto vs binario), performance, cuándo usar cada uno (regla rápida: `JSONB` salvo que necesites preservar formato textual exacto). **Operadores de acceso:** `->` (devuelve `JSONB`), `->>` (devuelve texto), `#>` y `#>>` (acceso por path para jerarquías profundas). **Operador de containment** `@>` — clave para queries con índices. **Operadores de existencia:** `?`, `?&`, `?|`. **Funciones:** `jsonb_array_elements()` (explotar arrays a filas), `jsonb_extract_path()`, `jsonb_object_keys()`, `jsonb_each()`.

<ins>4. Indexación GIN — cómo y cuándo</ins>

Por qué GIN funciona bien para semi-estructurados (índice invertido sobre los elementos internos). Comparación de plan de query con y sin índice GIN. Trade-off: lectura más rápida pero escrituras más caras y más espacio. **Operator class** `jsonb_path_ops` vs `jsonb_ops` — la primera es más chica y más rápida pero solo soporta `@>`. Mención de índices btree sobre expresiones (`(data->>'campo')`) cuando solo accedes a un campo específico.

<ins>5. Práctica sobre Airbnb CDMX</ins>

Aplicación a las columnas semi-estructuradas reales del dataset (decisiones documentadas en el setup):

- **`amenities`** — JSON array válido en el origen, cargable directo a JSONB. Queries: contar listings con piscina, filtrar por combinación de amenities.
- **`host_verifications`** — lista Python con comillas simples, requiere transformación previa. Caso de "limpieza antes de cargar".
- **`bathrooms_text`** — texto libre, ejemplo de cuándo regex es mejor que JSONB.
- **`price`, `host_response_rate`** — ejemplos de campos que parecen JSON pero son textos sucios que necesitan parseo.

## :books: Material

> Por publicar.

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="../anexos/rubrica_proyecto_final.md">Siguiente: Proyecto final →</a>
</p>
