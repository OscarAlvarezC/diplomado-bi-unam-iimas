# 03 — Cargar Northwind OLTP

Vas a cargar el dataset **Northwind**, el sistema transaccional de ejemplo (clientes, pedidos, productos, empleados). Actuará como **fuente operacional** para el resto del módulo: data warehouse, ETL en Python, SQL avanzado y funciones de ventana.

**Lo que tendrás al terminar:** schema `northwind_oltp` con 14 tablas y ~3 200 filas dentro de la base `northwind`.

## Prerequisitos

- ✅ DBeaver conectado a tu cluster `aurora-mod4` (de la guía 02).
- ✅ Cluster `Disponible` y regla My IP del grupo de seguridad actualizada si tu IP cambió.

---

## Concepto previo: schemas dentro de la base

El módulo organiza sus datasets como **schemas** dentro de **una sola base** `northwind`:

- **`northwind_oltp`** — datos transaccionales originales (esta guía).
- **`northwind_dwh`** — data warehouse en esquema estrella (siguiente guía).
- **`airbnb`** — dataset semi-estructurado (guía 05).

> 💡 **Si vienes de MySQL:** ahí `CREATE SCHEMA` y `CREATE DATABASE` son sinónimos. En PostgreSQL son cosas distintas: una conexión apunta a una **base**; los schemas son carpetas dentro de la base.
>
> - **Ventaja:** puedes hacer `JOIN` entre `northwind_oltp.customers` y `northwind_dwh.fact_sales` con una sola conexión.
> - **Desventaja:** dos schemas pueden tener tablas con el mismo nombre — sin prefijar el schema dependes del `search_path` y es fácil leer de la equivocada.

---

## Paso 1 — Descargar el dump

Cualquiera de las dos opciones funciona. El archivo es ~340 KB y crea el schema `northwind_oltp` y carga las 14 tablas en una sola pasada — no hay que hacer nada más.

### Opción A — Navegador

1. Abre <https://github.com/OscarAlvarezC/diplomado-bi-unam-iimas/blob/main/datasets/northwind/northwind.sql> en tu navegador.
2. Click en el botón **Download raw file** (ícono de flecha hacia abajo, arriba a la derecha del visor de código).
3. Guarda el archivo como `northwind.sql` en una carpeta que recuerdes (e.g., `~/diplomado-bi/datasets/`).

### Opción B — Terminal

```bash
mkdir -p ~/diplomado-bi/datasets
curl -L -o ~/diplomado-bi/datasets/northwind.sql \
  https://raw.githubusercontent.com/OscarAlvarezC/diplomado-bi-unam-iimas/main/datasets/northwind/northwind.sql
```

---

## Paso 2 — Ejecutar el script en DBeaver

1. **File → Open File** → selecciona `~/diplomado-bi/datasets/northwind.sql`.
2. Ejecuta todo el script con **Alt+X** ("Execute SQL Script").

Vas a ver muchos `CREATE TABLE`, `ALTER TABLE` e `INSERT` en la consola — es normal. El dump tiene ~3 400 inserciones que se ejecutan una a una, así que **suele tardar entre 5 y 6 minutos** dependiendo de tu latencia a la región `us-east-1`. No canceles aunque parezca lento.

---

## Paso 3 — Verificar la carga

```sql
SELECT count(*) AS total_tablas
FROM information_schema.tables
WHERE table_schema = 'northwind_oltp';
-- Esperado: 14
```

Si responde 14, el OLTP está listo y puedes pasar a la siguiente guía.

---

## Siguiente paso

Continúa con **`04_northwind_dwh.md`** — vas a construir un **data warehouse** sobre el OLTP que acabas de cargar. Ese es el corazón del módulo.

---

<p align="center">
<a href="../Sesion-01/Readme.md">← Volver al índice de la sesión 1</a> | <a href="04_northwind_dwh.md">Siguiente: 04 — Data warehouse →</a>
</p>
