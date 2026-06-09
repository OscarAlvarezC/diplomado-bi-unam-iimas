# Preguntas que surgieron en clase

Preguntas reales que hicieron alumnos durante las sesiones del Tema 05, con la respuesta que se discutió o se investigó después. Pensadas como complemento al material — si tienes la misma duda, busca aquí primero.

## Índice

1. [¿Por qué `CURRENT_DATE - hire_date` y `AGE(CURRENT_DATE, hire_date)` me dan valores distintos si miden "lo mismo"?](#por-qué-current_date---hire_date-y-agecurrent_date-hire_date-me-dan-valores-distintos-si-miden-lo-mismo)
2. [Con `%config SqlMagic.autopandas = True`, la columna de `AGE` cambia de número. ¿Por qué?](#con-config-sqlmagicautopandas--true-la-columna-de-age-cambia-de-número-por-qué)

---

## ¿Por qué `CURRENT_DATE - hire_date` y `AGE(CURRENT_DATE, hire_date)` me dan valores distintos si miden "lo mismo"?

La query que disparó la duda:

```sql
%%sql
SELECT
    full_name,
    hire_date,
    CURRENT_DATE - hire_date     AS dias_en_empresa,
    AGE(CURRENT_DATE, hire_date) AS dias_en_empresa_v2
FROM     northwind_dwh.dim_employee
ORDER BY hire_date;
```

Resultado (fila de Janet Leverling, contratada el `1992-04-01`):

| `dias_en_empresa` | `dias_en_empresa_v2` |
|---|---|
| `12487` | `34 years 2 mons 8 days` |

No es un error: **cada expresión devuelve un tipo de dato distinto**, y por eso "no se parecen".

### `CURRENT_DATE - hire_date` → un entero de días

Restar dos `date` en PostgreSQL devuelve un **`integer`**: el número **total de días corridos** entre ambas fechas. El alias `dias_en_empresa` aquí sí es correcto — son días.

### `AGE(CURRENT_DATE, hire_date)` → un `interval`

`AGE` devuelve un **`interval`** simbólico, descompuesto en **años, meses y días**, tal como lo leería un humano (`34 years 2 mons 8 days`). Tiene en cuenta la longitud real de cada mes y los años bisiestos para dar una antigüedad "de calendario". Por eso el alias `..._v2` es engañoso: **no son días**, es un intervalo año/mes/día.

### Son el mismo lapso, en unidades distintas

| Expresión | Tipo | Ejemplo | Significa |
|---|---|---|---|
| `CURRENT_DATE - hire_date` | `integer` | `12487` | días totales |
| `AGE(...)` | `interval` | `34 years 2 mons 8 days` | años + meses + días |

Verificación rápida: `12487 / 365.25 ≈ 34.2 años`, que coincide con el `34 years 2 mons` de `AGE`. No hay contradicción — es la misma antigüedad expresada de dos maneras.

### Si quieres que ambas sean comparables

```sql
SELECT
    full_name,
    hire_date,
    CURRENT_DATE - hire_date                          AS dias_en_empresa,   -- días exactos
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date))   AS anios_completos,    -- años enteros
    ROUND((CURRENT_DATE - hire_date) / 365.25, 1)     AS anios_aprox         -- años con decimales
FROM northwind_dwh.dim_employee
ORDER BY hire_date;
```

> :warning: **No confundas** `AGE(...)::DAYS` — **el tipo `DAYS` no existe** en PostgreSQL y la query falla con `ERROR: type "days" does not exist`. Solo puedes castear a tipos reales (`TEXT`, `INTEGER`, `INTERVAL`, …).

---

## Con `%config SqlMagic.autopandas = True`, la columna de `AGE` cambia de número. ¿Por qué?

Esta es la más sutil. La misma query, **solo** que ahora con autopandas activado:

```sql
%%sql
SELECT
    full_name,
    hire_date,
    CURRENT_DATE - hire_date           AS dias_en_empresa,
    AGE(CURRENT_DATE, hire_date)       AS dias_en_empresa_v2,
    AGE(CURRENT_DATE, hire_date)::TEXT AS dias_en_empresa_v3
FROM     northwind_dwh.dim_employee
ORDER BY hire_date;
```

Resultado (fila de Janet) — **tres valores distintos** donde antes había "lo mismo":

| columna | valor | tipo en pandas |
|---|---|---|
| `dias_en_empresa` | `12487` | `int64` |
| `dias_en_empresa_v2` | `12478 days` | `timedelta64` |
| `dias_en_empresa_v3` | `34 years 2 mons 8 days` | `str` |

Fíjate en lo importante: con autopandas, `v2` **ya no dice "34 años…"** sino `12478 days` — y además `12478 ≠ 12487`. Eso es lo que confunde.

### ¿Qué hace `autopandas`?

Sin autopandas, ves el **texto crudo** que manda PostgreSQL. Con `autopandas = True`, JupySQL convierte el resultado en un **DataFrame de pandas**, y el resultado pasa por `psycopg2` → `pandas`, donde **cada tipo de PostgreSQL se mapea a un tipo de Python**. La conversión clave es la del `interval`:

- **`v2` (`AGE(...)`)** → el `interval` se convierte a un `datetime.timedelta` de Python, que pandas guarda como `timedelta64`. Pero **un `timedelta` no puede guardar meses ni años**, solo días/segundos. Así que `psycopg2` lo **aplasta con factores fijos**:

  > **1 año = 365 días, 1 mes = 30 días** (¡sin bisiestos!)

  ```
  34×365 + 2×30 + 8  =  12410 + 60 + 8  =  12478 days
  ```

- **`dias_en_empresa` (`date - date`)** → llega como entero `int64`. Cuenta los **días reales del calendario**, con bisiestos. → `12487`.

- **`v3` (`AGE(...)::TEXT`)** → como lo casteaste a texto **dentro de SQL**, llega a pandas ya como string. Pandas no lo toca y conserva el formato calendario `"34 years 2 mons 8 days"`.

### ¿Por qué difieren exactamente en 9 días?

```
 12487   (días reales, con bisiestos)
−12478   (interval con año=365, mes=30)
──────
     9   días  ←  los 29-feb entre 1992 y 2026 (1992, 1996, 2000, … 2024)
```

La conversión a `timedelta` ignora los años bisiestos; la resta de fechas no. Esos 9 días bisiestos son toda la diferencia.

### La moraleja

`autopandas` no solo cambia **cómo se ve** el interval — **cambia el número**, porque psycopg2 lo fuerza a `timedelta` con años de 365 días planos. Para días exactos en un DataFrame, usa siempre la **resta de fechas** (`date - date` → `int64`). Reserva `AGE` para mostrar antigüedad en formato "años/meses/días", y en ese caso **castea a `::TEXT`** para que pandas no lo convierta en `timedelta` y altere el valor.

---

<p align="center">
<a href="Readme.md">← Volver al índice del Tema 05</a>
</p>
