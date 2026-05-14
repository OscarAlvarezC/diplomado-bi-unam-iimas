# Diagramas entidad-relación de los tres schemas

Visión rápida de la estructura de los tres schemas que viven en la base `northwind`. Los diagramas usan **Mermaid** y GitHub los renderiza directamente en el navegador — si tu visor local no soporta Mermaid, ve [esta versión en GitHub](https://github.com/OscarAlvarezC/diplomado-bi-unam-iimas/blob/main/anexos/diagramas_er.md) o usa [mermaid.live](https://mermaid.live) pegando el código.

---

## :package: `northwind_oltp` — sistema transaccional (3NF)

Datos originales de la empresa ficticia Northwind. 14 tablas normalizadas en 3NF. Cada hecho del negocio vive en una sola tabla; las relaciones se reconstituyen vía `JOIN`.

```mermaid
erDiagram
    customers {
        string customer_id PK
        string company_name
        string country
        string city
    }
    orders {
        int order_id PK
        string customer_id FK
        int employee_id FK
        int ship_via FK
        date order_date
        date required_date
        date shipped_date
        numeric freight
    }
    order_details {
        int order_id PK, FK
        int product_id PK, FK
        real unit_price
        smallint quantity
        real discount
    }
    products {
        int product_id PK
        string product_name
        int category_id FK
        int supplier_id FK
        real unit_price
        boolean discontinued
    }
    categories {
        int category_id PK
        string category_name
        text description
    }
    suppliers {
        int supplier_id PK
        string company_name
        string country
        string city
    }
    employees {
        int employee_id PK
        string first_name
        string last_name
        string title
        int reports_to FK
    }
    shippers {
        int shipper_id PK
        string company_name
        string phone
    }

    customers   ||--o{ orders        : "places"
    employees   ||--o{ orders        : "processes"
    shippers    ||--o{ orders        : "ships via"
    orders      ||--|{ order_details : "contains"
    products    ||--o{ order_details : "appears in"
    categories  ||--o{ products      : "categorizes"
    suppliers   ||--o{ products      : "supplies"
    employees   ||--o{ employees     : "reports to"
```

> **Tablas secundarias** que no aparecen en el diagrama por claridad: `region`, `territories`, `employee_territories`, `customer_demographics`, `customer_customer_demo`, `us_states`. Son tablas de catálogo auxiliar que prácticamente no se usan en queries analíticas.

### Patrones a notar

- **`order_details` tiene PK compuesta** `(order_id, product_id)` — una fila por cada producto en cada pedido (grano "por línea de pedido").
- **`employees.reports_to`** es self-FK que apunta al jefe del empleado — jerarquía de empleados en una sola tabla. El CEO (Andrew Fuller, `employee_id = 2`) tiene `reports_to = NULL`.
- **3NF estricta**: categorías y proveedores viven en tablas aparte, no como atributos de `products`. Para reportes "ventas por categoría" hay que cruzar 4 tablas.

---

## :star: `northwind_dwh` — data warehouse (esquema estrella)

Reorganización de los mismos datos para análisis. Una **tabla de hechos** (`fact_sales`) en el centro + **cinco dimensiones** alrededor. Sigue el patrón Kimball.

```mermaid
erDiagram
    fact_sales {
        int sale_key PK
        smallint order_id "degenerate dim"
        int customer_key FK
        int product_key FK
        int employee_key FK
        int shipper_key FK
        int order_date_key FK
        int required_date_key FK
        int shipped_date_key FK
        smallint quantity
        numeric unit_price
        numeric discount
        numeric extended_price "generated"
        numeric line_total "generated"
    }
    dim_customer {
        int customer_key PK
        char customer_id "natural"
        string company_name
        string country
        string city
    }
    dim_product {
        int product_key PK
        smallint product_id "natural"
        string product_name
        string category_name "flattened"
        string supplier_name "flattened"
        string supplier_country "flattened"
        boolean discontinued
    }
    dim_employee {
        int employee_key PK
        smallint employee_id "natural"
        string full_name
        string title
        string reports_to_name "flattened"
    }
    dim_shipper {
        int shipper_key PK
        smallint shipper_id "natural"
        string company_name
    }
    dim_date {
        int date_key PK "YYYYMMDD smart key"
        date full_date
        smallint year
        smallint quarter
        smallint month_number
        string month_name
        boolean is_weekend
    }

    dim_customer ||--o{ fact_sales : ""
    dim_product  ||--o{ fact_sales : ""
    dim_employee ||--o{ fact_sales : ""
    dim_shipper  |o--o{ fact_sales : "nullable"
    dim_date     ||--o{ fact_sales : "order_date"
    dim_date     ||--o{ fact_sales : "required_date"
    dim_date     ||--o{ fact_sales : "shipped_date"
```

### Patrones Kimball aplicados

- **Surrogate keys** (`customer_key`, `product_key`, etc.) en todas las dims — desacoplan el DWH de los IDs del sistema fuente. La natural key (`customer_id`, `product_id`) queda como atributo descriptivo.
- **Smart key** en `dim_date`: `date_key` es `YYYYMMDD` como entero. Filtrable directo (`WHERE order_date_key BETWEEN 19970101 AND 19971231`) sin join.
- **Role-playing**: una sola `dim_date` con **tres FKs distintas** en `fact_sales` (order_date, required_date, shipped_date). Misma tabla, tres roles.
- **Degenerate dimension**: `order_id` vive en la fact sin tabla propia. Sirve para `COUNT(DISTINCT order_id)` por categoría/cliente/etc.
- **Aplanamiento (denormalización deliberada)**: `category_name` y `supplier_name` viven en `dim_product` como atributos, no en tablas aparte. Esto duplica strings pero elimina joins en queries analíticas.
- **Generated columns**: `extended_price` y `line_total` los calcula PostgreSQL automáticamente con `GENERATED ALWAYS AS … STORED`.
- **`shipper_key` nullable**: porque un pedido puede no haberse despachado todavía (lifecycle de atributos).

---

## :house: `airbnb` — datos semi-estructurados (bronze)

Snapshot mensual de Inside Airbnb para CDMX (septiembre 2025). Solo dos tablas, prácticamente sin estructura relacional — todo en formato "bronze" (TEXT crudo, fiel a la fuente).

```mermaid
erDiagram
    listings {
        text id
        text name
        text host_id
        text host_name
        text neighbourhood
        text room_type
        text price
        text amenities "JSON array"
        text host_verifications "Python list"
        text latitude
        text longitude
        text minimum_nights
        text number_of_reviews
        text review_scores_rating
    }
    neighbourhoods {
        text neighbourhood PK
        text neighbourhood_group
    }
```

> **No hay FK formal** entre `listings` y `neighbourhoods` en el bronze. La conexión es por nombre de texto (`listings.neighbourhood = neighbourhoods.neighbourhood`) pero sin constraint declarado — son datos crudos.

### Por qué bronze sin tipos ni constraints

- **Fidelidad al origen**: cargar los CSV de Inside Airbnb tal cual, sin pretender que la fuente sea limpia. Si un campo tiene `"N/A"` literal en lugar de `NULL`, lo guardamos así.
- **Sin PK en `listings`** porque hay `id`s que podrían tener problemas de unicidad en el origen — la carga no debe fallar por eso.
- **79 columnas TEXT**: el casting a tipos correctos (NUMERIC para precios, BOOLEAN, DATE) se hace en la capa "silver" del ETL, que está fuera del alcance del módulo.
- **`amenities` es un JSON array válido** — usable directo con `JSONB` en el Tema 10 (datos semi-estructurados).
- **`host_verifications` es lista Python** (con comillas simples) — necesita transformación a JSON antes de cargar a `JSONB`. Es ejemplo típico de "dato sucio que parece JSON pero no lo es".

### Mostradas solo algunas columnas

`listings` tiene **79 columnas** en total — el diagrama solo muestra las más relevantes para análisis. El resto incluye campos como descripciones HTML largas, fechas de scraping, URLs de imágenes, etc.

---

## :left_right_arrow: Relación entre los tres schemas

Los tres viven en la misma base `northwind` pero **son lógicamente independientes**:

- `northwind_oltp` y `northwind_dwh` representan los mismos datos en estructuras distintas — el DWH se popula desde el OLTP vía ETL (Temas 04 y 05). **Sin FKs entre schemas.**
- `airbnb` es completamente independiente — distinto dominio de datos. Convive en la misma base por conveniencia operativa.

Esto significa que puedes hacer joins **dentro de un schema** sin problema, pero joins **entre `northwind_oltp` y `northwind_dwh`** solo tienen sentido para validar el ETL (cross-check de totales OLTP vs DWH), no para análisis productivo.

---

## :hammer_and_wrench: Generar tus propios diagramas

Si quieres exportar estos diagramas como PNG/SVG para ponerlos en una presentación o reporte:

1. Copia el código Mermaid del bloque que te interese.
2. Pégalo en [mermaid.live](https://mermaid.live).
3. **Actions → PNG / SVG / Markdown** según el formato que necesites.

Alternativa con `mermaid-cli` desde terminal:

```bash
npm install -g @mermaid-js/mermaid-cli
mmdc -i diagrama.mmd -o diagrama.png
```

DBeaver también puede generar diagramas ER directamente (click derecho sobre el schema → **View Diagram**) sin escribir Mermaid — útil para schemas que no están en este documento.

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="README.md">Volver a anexos</a>
</p>
