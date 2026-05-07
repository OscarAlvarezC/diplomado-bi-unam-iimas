# 05 — Cargar Airbnb CDMX

Última guía del setup. Vas a cargar el snapshot de **Inside Airbnb** para Ciudad de México: 27 051 listings reales con sus alcaldías, descripciones, amenidades, precios y reseñas. Es el dataset que usarás en el Bloque 6 para explorar **datos semi-estructurados** con `JSONB`.

**Lo que tendrás al terminar:** schema `airbnb` con dos tablas — `listings` (27 051 filas × 79 columnas) y `neighbourhoods` (16 alcaldías).

## Prerequisitos

- ✅ DBeaver conectado a `aurora-mod4`.
- ✅ Cluster `Disponible` y regla My IP del grupo de seguridad actualizada.
- ✅ ~80 MB libres en disco para los archivos descomprimidos.

---

## Concepto previo: el dataset y su contexto

[Inside Airbnb](http://insideairbnb.com/) **NO es Airbnb la empresa** — es un proyecto independiente de transparencia que rasca datos públicos del sitio de Airbnb y los publica como CSVs descargables, organizados por ciudad.

**Características del dataset:**

- **Real** — listings actuales en barrios reconocibles (Roma, Condesa, Coyoacán, Centro Histórico).
- **Snapshot mensual** — Inside Airbnb publica una versión nueva cada mes y **borra la anterior**. Por eso este repo congela la versión **2025-09-27** que vamos a usar todo el módulo.
- **Schema descubierto** — las columnas son lo que la página de Airbnb muestra, no un schema diseñado. Esto explica que tenga campos JSON (`amenities`), listas (`host_verifications`) y texto libre (`bathrooms_text`) — perfecto para Bloque 6.
- **Licencia CC0** (dominio público) — uso libre para análisis y enseñanza.

### Estructura del dataset

```
schema airbnb
├── listings        (27 051 filas, 79 columnas TEXT crudas)
└── neighbourhoods  (16 alcaldías de CDMX)
```

Las 79 columnas de `listings` se cargan **todas como TEXT**, sin tipos ni constraints. Esa es la "capa bronze" o "landing" del ETL: preservar el origen tal cual antes de transformarlo. En el Bloque 6 verás cómo extraer datos tipados (numéricos, booleanos, JSONB) desde estas columnas.

---

## Paso 1 — Descargar archivos

```bash
mkdir -p ~/diplomado-bi/datasets/airbnb
cd ~/diplomado-bi/datasets/airbnb

BASE="https://raw.githubusercontent.com/OscarAlvarezC/diplomado-bi-unam-iimas/main/datasets/airbnb"

# Listings comprimido (14 MB, snapshot CDMX 2025-09-27)
curl -L -O "$BASE/listings.csv.gz"

# Lista de las 16 alcaldías
curl -L -O "$BASE/neighbourhoods.csv"

# (Opcional, para Bloque 6) Polígonos GeoJSON de las alcaldías
curl -L -O "$BASE/neighbourhoods.geojson"

ls -lh
```

Esperado:
- `listings.csv.gz` ~14 MB
- `neighbourhoods.csv` 275 B
- `neighbourhoods.geojson` ~335 KB

### Descomprimir el listings

DBeaver Import Wizard no lee `.gz` directo, hay que descomprimir:

```bash
# Linux/macOS:
gunzip -k listings.csv.gz   # -k mantiene el .gz original

# Windows (PowerShell):
# Necesitas 7-Zip o el cmdlet Expand-Archive con un workaround
# Más fácil: descarga listings.csv directo si está disponible, o usa 7-Zip
```

Esperado: `listings.csv` ~59 MB sin comprimir.

---

## Paso 2 — Crear schema y tablas (script DDL)

```bash
cd ~/diplomado-bi/scripts

curl -L -O "https://raw.githubusercontent.com/OscarAlvarezC/diplomado-bi-unam-iimas/main/scripts/05_airbnb_ddl.sql"
```

En DBeaver, conexión `aurora-mod4`:

1. **File → Open File** → `05_airbnb_ddl.sql`.
2. Lee los comentarios al inicio del archivo.
3. Ejecuta todo con **Alt+X**.

Crea:
- Schema `airbnb`.
- Tabla `airbnb.listings` (79 columnas TEXT, sin PK ni constraints).
- Tabla `airbnb.neighbourhoods` (2 columnas, PK sobre `neighbourhood`).

### Verificar

```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'airbnb' ORDER BY table_name;
-- Esperado: listings, neighbourhoods

SELECT count(*) AS columnas FROM information_schema.columns
WHERE table_schema = 'airbnb' AND table_name = 'listings';
-- Esperado: 79
```

---

## Paso 3 — Cargar `listings.csv` con DBeaver Import Wizard

### 3.1 — Abrir el wizard

1. En el **Database Navigator** (sidebar izquierdo), expande:
   `aurora-mod4 → northwind → Schemas → airbnb → Tables`.
2. **Click derecho** sobre `listings` → **Import Data**.
3. **Source:** CSV → Next.
4. **Input file:** selecciona `~/diplomado-bi/datasets/airbnb/listings.csv` → Next.

### 3.2 — Importer settings (críticos)

| Campo | Valor |
|---|---|
| **Header position** | `1` |
| **Encoding** | `UTF-8` |
| **Delimiter** | `,` (coma) |
| **Quote char** | `"` (comilla doble) |
| **Escape char** | `\` (default, no cambiar) |
| **Empty string is null** | **NO marcar** ⚠️ |

> ⚠️ **No marques "Empty string is null"** — quieres preservar las celdas vacías como string vacío, no convertirlas a NULL. Es purismo de "bronze layer": el origen 1:1.

### 3.3 — Mapping

DBeaver auto-mapea las 79 columnas por nombre. **Verifica visualmente:**

- Las 79 columnas tienen flecha verde (mapeadas).
- El target dice `airbnb.listings` (no propone "Create new table" — si lo propone, **cancela**, vuelve al árbol y haz click derecho directamente sobre `listings`).

### 3.4 — Advanced settings

| Campo | Valor |
|---|---|
| Use multi-row insert | ✅ |
| Batch size | `1000` |

### 3.5 — Ejecutar

**Proceed** → **Start**. La carga toma **1-3 minutos** dependiendo de tu CPU. No la canceles aunque parezca colgada — son 27 000 filas × 79 columnas = ~2.1 millones de celdas.

---

## Paso 4 — Cargar `neighbourhoods.csv`

Mismo flujo, pero más rápido:

1. Click derecho en `airbnb.neighbourhoods` → **Import Data** → CSV.
2. Archivo: `~/diplomado-bi/datasets/airbnb/neighbourhoods.csv`.
3. Mismas settings que el paso 3.2 — pero esta vez **SÍ marca "Empty string is null"** (la columna `neighbourhood_group` viene vacía en CDMX y queremos que sea NULL).
4. Mapeo: 2 columnas a 2 columnas, trivial.
5. Proceed. Termina en segundos.

---

## Paso 5 — Verificación

### 5.1 — Conteos

```sql
SELECT 'listings'        AS tabla, count(*) FROM airbnb.listings
UNION ALL
SELECT 'neighbourhoods', count(*) FROM airbnb.neighbourhoods;
-- Esperado: 27051 / 16
```

### 5.2 — Sanity check de parsing

Las descripciones contienen saltos de línea. Verifica que el parser CSV los manejó bien (no las trató como fila nueva):

```sql
SELECT count(*) FROM airbnb.listings;
-- Esperado: 27051

SELECT max(length(description)) FROM airbnb.listings;
-- Esperado: 1000 (cap natural del campo en Airbnb, no truncamiento)
```

> 💡 Si te da `count(*) = 48 965` o algo claramente más alto, el wizard interpretó cada `\n` como nueva fila. Truncar (`TRUNCATE airbnb.listings;`) y re-cargar revisando que **Quote char = `"`**.

### 5.3 — Distribución por alcaldía

```sql
SELECT n.neighbourhood, count(l.id) AS listings
FROM airbnb.neighbourhoods n
LEFT JOIN airbnb.listings l ON l.neighbourhood_cleansed = n.neighbourhood
GROUP BY n.neighbourhood
ORDER BY listings DESC;
```

Esperado: 16 alcaldías. **Cuauhtémoc** lidera con ~12 500, **Miguel Hidalgo** y **Benito Juárez** después. Las 13 periféricas reparten el resto. Es la geografía real de la concentración turística en CDMX.

### 5.4 — Inspección de campos semi-estructurados

```sql
-- amenities es un JSON array (lo verás en Bloque 6)
SELECT id, name, amenities
FROM airbnb.listings
WHERE name IS NOT NULL
LIMIT 3;
```

Verás algo como `["Wifi", "Kitchen", "Free parking", ...]` — un JSON array serializado como texto. En el Bloque 6 vas a aprender a parsearlo como JSONB.

---

<details>
<summary><strong>Errores comunes</strong></summary>

<details>
<summary><code>count(*) = 48 965</code> en lugar de 27 051</summary>

El parser CSV trató los `\n` dentro de descripciones como saltos de fila. Causa: encoding incorrecto, quote char mal configurado, o archivo corrupto.

```sql
TRUNCATE airbnb.listings;
```

Re-carga revisando: encoding=UTF-8, quote char=`"`, escape char=`\`.

</details>

<details>
<summary>"The separator, quote, and escape characters must be different!"</summary>

Cambiaste el escape char a `"` pensando en RFC 4180. **Devuélvelo a `\`**. PostgreSQL maneja automáticamente el `""` doblado de RFC 4180 cuando quote char es `"` — el escape char es para una convención distinta (backslash). Con `\` el wizard funciona.

</details>

<details>
<summary>El wizard propone "Create new table"</summary>

Te perdiste el paso de seleccionar la tabla destino. Cancela. En el árbol del Database Navigator, **expande hasta `listings`** y haz click derecho directamente sobre la tabla. Vuelve a empezar.

</details>

<details>
<summary>Carga muy lenta</summary>

27 051 × 79 = ~2.1 millones de celdas. En máquinas modestas tarda 1-3 minutos. Si pasa de 5 min sin progreso, cancela e intenta con batch size mayor (5000).

</details>

<details>
<summary>"Empty string is null" — me equivoqué</summary>

Si la marcaste y querías no marcarla (o viceversa), `TRUNCATE TABLE airbnb.listings` y re-carga con la configuración correcta. `TRUNCATE` solo borra filas — la estructura, los índices, etc. quedan intactos.

</details>

</details>

---

## Lo que acabas de cargar

Tu base `northwind` ahora tiene **3 schemas operativos**:

```
northwind
├── northwind_oltp   ← OLTP transaccional clásico (14 tablas)
├── northwind_dwh    ← star schema (5 dims + fact)
└── airbnb           ← semi-estructurado (2 tablas, listings 27k filas)
```

Todo lo necesario para los 7 bloques del módulo está en su lugar.

---

## Siguiente paso

**Setup completo.** Ya estás listo para el primer día de clase.

Si tu cluster Aurora llega a fallar en algún momento durante el semestre, hay un servidor de respaldo de **solo lectura** disponible — ve a `plan-b/README.md` para el connection string y los caveats.

Recuerda:
- 🔴 **Pausa el cluster** (Stop temporarily) al terminar cada sesión de trabajo.
- 🟢 **Reanuda y refresca la regla My IP del grupo de seguridad** al empezar la siguiente.
- 💰 Tu crédito Learner Lab es ~$50 USD. El cluster cuesta ~$2/día encendido.

---

<p align="center">
<a href="../Sesion-01/Readme.md">← Volver al índice de la sesión 1</a>
</p>
