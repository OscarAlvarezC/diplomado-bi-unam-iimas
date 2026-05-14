# Plan B — Conexión al servidor de respaldo (NAS)

Si tu cluster Aurora del Learner Lab no está disponible (crédito agotado, problemas con AWS Academy, IP cambió y no puedes actualizar el Security Group, lab caído), tienes acceso a un **servidor PostgreSQL de respaldo** mantenido por el instructor en un NAS local, expuesto a internet vía DDNS.

> ⚠️ **El Plan B es complementario, no sustituto de Aurora.** Es **solo lectura** — sirve para consultar datos cuando no puedes operar tu Aurora, pero **no permite escribir** (no DDL, no INSERT, no UPDATE, no DELETE, no ETL, no procedures). Si tu ejercicio requiere modificar datos, necesitas Aurora.

## :white_check_mark: Qué puedes hacer con el Plan B

| Caso de uso | ¿Funciona con Plan B? |
|---|---|
| Consultar datos del data warehouse (`SELECT`, `JOIN`, agregaciones) | ✅ |
| Practicar SQL avanzado (window functions, CTE, JSONB) | ✅ |
| Conectar Python (`pandas.read_sql`) para análisis | ✅ |
| Conectar Power BI Desktop como fuente de datos | ✅ |
| Explorar el esquema con DBeaver | ✅ |
| Crear tablas (`CREATE TABLE`) | ❌ |
| Insertar / modificar / borrar datos | ❌ |
| Ejecutar el ETL en Python que escribe al DWH | ❌ |
| Crear procedimientos almacenados | ❌ |

Para los temas **02, 06, 08, 09, 10** (Fundamentos OLAP, SQL avanzado, Funciones de ventana, CTE, Datos semi-estructurados) el Plan B es perfectamente útil. Para los temas **01, 03, 04, 05, 07, 11** (Setup, Esquemas dimensionales, Implementación DW, ETL Python, PL/pgSQL, Caso integrador) necesitas tu Aurora propio.

## :inbox_tray: Datos de conexión

```
Host:     dsservice.ddns.net
Puerto:   25432
Base:     northwind
Usuario:  alumno
SSL/TLS:  no
Password: el instructor te lo comparte en clase — no se publica
```

## :books: Lo que vas a encontrar

La base `northwind` tiene **los mismos tres schemas que tu Aurora**:

| Schema | Tablas | Filas |
|---|---|---|
| `northwind_oltp` | 14 tablas (clientes, pedidos, productos, etc.) | ~3,200 |
| `northwind_dwh` | 5 dims + `fact_sales` | 2,155 fact + 1,279 en dims |
| `airbnb` | `listings`, `neighbourhoods` | 27,051 + 16 |

Las queries que escribes contra tu Aurora deberían funcionar idénticas contra el Plan B — mismo schema, misma data.

---

## :computer: Conectar desde DBeaver

Asume que ya tienes DBeaver instalado (de la guía 02 del setup). Es el mismo flujo que usas para Aurora, solo cambian los datos de conexión.

### Paso 1 — Nueva conexión

1. En DBeaver: **Database → New Database Connection**.
2. Selecciona **PostgreSQL** → **Next**.

### Paso 2 — Llenar el formulario

Pestaña **Main**:

| Campo | Valor |
|---|---|
| Host | `dsservice.ddns.net` |
| Port | `25432` |
| Database | `northwind` |
| Username | `alumno` |
| Password | *(el que te compartió el instructor)* |
| Save password locally | ✅ marcado (para no escribirlo cada vez) |

### Paso 3 — Probar y guardar

1. Click en **Test Connection** abajo a la izquierda.
2. Si te pide descargar el driver de PostgreSQL la primera vez, acepta.
3. Resultado esperado: **"Connected"** con la versión de PostgreSQL.
4. Click **Finish**.

DBeaver te genera la conexión con nombre `dsservice.ddns.net - northwind` (puedes renombrarla con click derecho → **Edit Connection** → Connection name → poner algo como `plan-b-nas`).

### Paso 4 — Verificar acceso

Abre un **SQL Editor** sobre la conexión nueva y ejecuta:

```sql
-- Confirmar que entraste
SELECT current_database(), current_user, version();
-- Esperado: northwind | alumno | PostgreSQL 17.x ...

-- Listar los schemas disponibles
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name NOT IN ('pg_catalog','information_schema','pg_toast');
-- Esperado: northwind_oltp, northwind_dwh, airbnb, public

-- Smoke test: contar filas en los 3 schemas
SELECT 'OLTP'   AS origen, count(*) AS filas FROM northwind_oltp.customers
UNION ALL
SELECT 'DWH',             count(*)         FROM northwind_dwh.fact_sales
UNION ALL
SELECT 'AIRBNB',          count(*)         FROM airbnb.listings;
-- Esperado: 91 / 2155 / 27051
```

Si los tres conteos salen correctos, la conexión está lista.

---

## :computer: Conectar desde terminal con `psql`

`psql` es el cliente oficial de línea de comandos de PostgreSQL. Útil cuando quieres iterar queries rápido sin abrir DBeaver, o automatizar consultas en un script de shell.

> :information_source: **`psql` NO viene incluido con DBeaver.** DBeaver es una app Java con su propio driver JDBC empaquetado; `psql` es un cliente C separado que se distribuye con el paquete cliente oficial de PostgreSQL. Son herramientas independientes que conectan al mismo motor.

### Paso 1 — Instalar `psql`

| Sistema | Comando |
|---|---|
| Ubuntu / Debian | `sudo apt install postgresql-client` |
| Fedora / RHEL | `sudo dnf install postgresql` |
| Arch | `sudo pacman -S postgresql-libs` |
| macOS (Homebrew) | `brew install libpq && brew link --force libpq` |
| Windows | Viene con [PostgreSQL installer](https://www.postgresql.org/download/windows/) (marca "Command Line Tools" en la instalación) |

> :warning: En Ubuntu, si te aparece la sugerencia automática `sudo apt install postgresql-client-common`, **ignórala** — ese paquete solo trae scripts auxiliares, no el binario `psql`. Usa `postgresql-client` (sin sufijo), que es el meta-paquete correcto.

Verifica la instalación:

```bash
psql --version
# Esperado: psql (PostgreSQL) 17.x  (o similar)
```

### Paso 2 — Conectar

```bash
psql -h dsservice.ddns.net -p 25432 -U alumno -d northwind
```

Te pedirá el password (no se muestra al teclear). Si todo va bien, entras al prompt:

```
northwind=>
```

### Paso 3 — Evitar escribir el password cada vez (opcional)

Si te molesta escribir el password cada conexión, configúralo en `~/.pgpass`:

```bash
echo 'dsservice.ddns.net:25432:northwind:alumno:<EL_PASSWORD>' >> ~/.pgpass
chmod 600 ~/.pgpass   # crítico — psql ignora el archivo si no es 600
```

A partir de aquí, `psql -h dsservice.ddns.net -p 25432 -U alumno -d northwind` entra directo sin preguntar password.

### Comandos útiles dentro de `psql`

| Comando | Para qué |
|---|---|
| `\l` | Listar bases de datos |
| `\dn` | Listar schemas |
| `\dt northwind_oltp.*` | Listar tablas del schema `northwind_oltp` |
| `\d northwind_dwh.fact_sales` | Ver columnas y tipos de una tabla |
| `\timing` | Activar / desactivar medición de tiempo de cada query |
| `\x` | Toggle modo "expanded" (filas verticales, útil para tablas anchas) |
| `\q` | Salir |

### Ejecutar queries sin entrar al prompt

Una sola query inline:

```bash
psql -h dsservice.ddns.net -p 25432 -U alumno -d northwind \
  -c "SELECT count(*) FROM northwind_dwh.fact_sales;"
```

Un archivo `.sql` completo:

```bash
psql -h dsservice.ddns.net -p 25432 -U alumno -d northwind \
  -f mi_query.sql
```

Salida como CSV (útil para procesar con `awk`, `cut` o redirigir a archivo):

```bash
psql -h dsservice.ddns.net -p 25432 -U alumno -d northwind --csv \
  -c "SELECT * FROM northwind_dwh.dim_product LIMIT 5;" > productos.csv
```

### Salir de `psql`

Cualquiera de estas cuatro opciones cierra la sesión y te regresa al shell:

| Comando | Notas |
|---|---|
| `\q` | El más usado, sintaxis estilo `psql` |
| `\quit` | Equivalente, más explícito |
| `exit` | Funciona desde PostgreSQL 11+ |
| `Ctrl+D` | Atajo estándar de Unix para "fin de input" — funciona también en bash, python REPL, etc. |

---

## :snake: Conectar desde Python

Para los temas de análisis donde uses pandas:

```python
from sqlalchemy import create_engine
import pandas as pd

# Reemplaza <PASSWORD> con el password que te compartió el instructor
URL = "postgresql+psycopg2://alumno:<PASSWORD>@dsservice.ddns.net:25432/northwind"

engine = create_engine(URL)

# Ejemplo: traer ventas por categoría desde el DWH
df = pd.read_sql("""
    SELECT p.category_name, SUM(f.line_total) AS ventas
    FROM   northwind_dwh.fact_sales  f
    JOIN   northwind_dwh.dim_product p ON p.product_key = f.product_key
    GROUP BY p.category_name
    ORDER BY ventas DESC
""", engine)

print(df)
```

> :warning: **No subas tu script con el password a GitHub.** Para mantenerlo fuera del código:
>
> ```python
> import os
> URL = f"postgresql+psycopg2://alumno:{os.environ['PLAN_B_PASSWORD']}@dsservice.ddns.net:25432/northwind"
> ```
> Y exporta la variable en tu shell antes de correr: `export PLAN_B_PASSWORD='...'`

---

## :chart_with_upwards_trend: Conectar desde Power BI Desktop

1. **Get Data → More → PostgreSQL Database**.
2. **Server**: `dsservice.ddns.net:25432`
3. **Database**: `northwind`
4. **Data Connectivity mode**: **Import** (recomendado) o **DirectQuery**.
5. **OK** → ingresa username `alumno` y el password compartido.
6. Power BI lista los schemas; expande y selecciona las tablas que quieras importar.

---

## :wrench: Errores comunes

<details>
<summary><strong>"Connection refused" o timeout al conectar</strong></summary>

Posibles causas:

1. **Tu red bloquea puertos no estándar.** Algunas redes corporativas o universitarias bloquean tráfico saliente a puertos como el `25432`. Prueba desde otra red (datos móviles, casa).
2. **El DDNS no resuelve.** Verifica que `nslookup dsservice.ddns.net` te devuelva una IP. Si falla, hay problema con tu DNS o el DDNS del instructor.
3. **El NAS del instructor está apagado.** Reporta el problema en Moodle/Classroom — el instructor confirmará.
</details>

<details>
<summary><strong>"FATAL: no pg_hba.conf entry for host" o "authentication failed"</strong></summary>

Tu role `alumno` está pidiendo conectar a una base distinta a `northwind`, o estás escribiendo mal el password. Verifica:

1. **Database = `northwind`** exactamente (sin mayúsculas, sin espacios).
2. **Username = `alumno`** (no `student`, no `alumno1`, etc.).
3. **Password** copiado tal cual (cuidado con espacios al inicio/fin si haces copy-paste).

Si todo es correcto y sigue fallando, el password puede haber sido rotado por el instructor — consulta Moodle/Classroom por la versión actual.
</details>

<details>
<summary><strong>"permission denied for table X" al intentar SELECT</strong></summary>

El role `alumno` solo tiene SELECT sobre los schemas `northwind_oltp`, `northwind_dwh` y `airbnb`. Si estás haciendo SELECT a alguna tabla fuera de esos schemas (por ejemplo, una tabla que creaste en `public`), recibirás este error porque `alumno` no tiene permisos en `public`.

Solución: solo consulta tablas dentro de los 3 schemas autorizados.
</details>

<details>
<summary><strong>"permission denied" al intentar CREATE TABLE, INSERT, UPDATE, etc.</strong></summary>

Esto es **comportamiento esperado**. El role `alumno` es **read-only** (solo SELECT). Si necesitas crear/modificar datos, debes usar tu Aurora del Learner Lab. El Plan B no sustituye a Aurora — solo lo complementa para consulta de datos cuando Aurora está caído.
</details>

<details>
<summary><strong>El password se filtró en mi repo de GitHub</strong></summary>

Si subiste accidentalmente el password a un repo público:

1. **Avisa de inmediato** al instructor (Moodle, Classroom, correo).
2. **No intentes "borrar el commit"** — la información ya está en el historial público de GitHub y posiblemente en caches.
3. El instructor rotará el password y lo distribuirá nuevamente.

Para evitar esto, **siempre** mantén el password fuera del código (variables de entorno, archivo `.env` en `.gitignore`, etc.).
</details>

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="README.md">Volver a anexos</a>
</p>
