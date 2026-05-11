# 02 — Instalar DBeaver y conectar a tu Aurora

Ahora que tu cluster `aurora-mod4` ya está corriendo en AWS, vas a configurar el cliente SQL en tu laptop y abrir la primera conexión.

**Lo que tendrás al terminar:** DBeaver instalado, security group abierto a tu IP, conexión guardada y validada con `SELECT version()`.

## Prerequisitos

- ✅ Cluster `aurora-mod4` en estado `Available` (de la guía 01).
- ✅ Endpoint del cluster anotado (algo como `aurora-mod4.cluster-XXXXXX.us-east-1.rds.amazonaws.com`).
- ✅ Master password guardado en tu password manager.
- 1 GB libre en disco para DBeaver.

---

## Paso 1 — Instalar DBeaver Community

DBeaver es un cliente SQL gratuito y multiplataforma. Lo vamos a usar durante todo el módulo.

### Descarga

Ve a `https://dbeaver.io` → **Community Edition** → descarga el instalador para tu sistema operativo:

- **Windows:** `.exe` instalable.
- **macOS:** `.dmg` (arrastra a Applications).
- **Linux:** `.deb` (Ubuntu/Debian), `.rpm` (Fedora), o Snap/Flatpak desde el Software Manager.

### Instalación

Sigue el instalador estándar de tu OS. Al primer arranque, DBeaver te ofrecerá descargar drivers — **acepta** cuando llegue el momento de PostgreSQL (lo hará automáticamente al crear la conexión).

> ℹ️ DBeaver Community es **gratis y sin límites**. No es la versión de prueba — la "Pro" agrega features avanzadas que no necesitas para este módulo.

---

## Paso 2 — Abrir el security group de tu cluster en el puerto 5432

Por default, el cluster que creaste **no acepta conexiones de internet**, aunque tenga "Public access" activo. Hay que abrirle un agujero específico al puerto 5432 desde tu IP.

### 2.1 — Llegar al security group desde RDS

1. AWS Console → **RDS** → **Bases de datos** → click **`aurora-mod4-instance-1`** (la instancia, no el cluster).
2. Pestaña **Conectividad y seguridad**.
3. Sección **Seguridad** → click en el security group (suele aparecer como `default (sg-XXXXXXXX)`).
4. Esto te lleva a la consola de **EC2**, pero a una **vista filtrada de solo lectura** donde solo puedes ver las reglas existentes — todavía no las puedes editar desde aquí.

### 2.2 — Abrir la vista de detalle del grupo de seguridad (donde sí se edita)

1. En la tabla de **Grupos de seguridad** que aparece, click en el **ID del grupo de seguridad** (`sg-xxxxxxxxxxxxxxxxx`) en la columna izquierda. Eso abre la vista de detalle del grupo de seguridad.
2. Pestaña **Reglas de entrada** (Inbound rules) → botón **Editar reglas de entrada** (Edit inbound rules).

### 2.3 — Agregar (o actualizar) la regla del puerto 5432

Aquí hay dos casos:

**Caso A — ya existe una regla de PostgreSQL (puerto 5432) con una IP fija como origen** (por ejemplo, de una sesión anterior cuando estabas en otra red):

- Edita esa regla: en el campo **Origen** cambia el valor a **Mi IP** (My IP). AWS detecta tu IP pública actual y la rellena automáticamente.
- **Guardar reglas**.

**Caso B — no existe ninguna regla para 5432:**

1. Click **Agregar regla** (Add rule).
2. Configura:

| Campo | Valor |
|---|---|
| Tipo | **PostgreSQL** |
| Protocolo | TCP (autocompletado) |
| Intervalo de puertos | 5432 (autocompletado) |
| Origen | **Mi IP** ⚠️ esto es clave |
| Descripción | `DBeaver desde mi laptop` |

3. **Guardar reglas**.

![Pantalla "Editar reglas de entrada" con la regla PostgreSQL en 5432 y el dropdown "Origen" abierto en "Mi IP"](img/guia2_paso2.png)

> ⚠️ **"Mi IP" detecta automáticamente tu IP pública actual.** Cuando cambies de red (otro WiFi, el café, casa de un amigo, datos móviles) tu IP cambia y la regla deja de funcionar. Solución: vuelve a esta misma vista, **Editar reglas de entrada**, sobre la regla existente vuelve a seleccionar **Mi IP** en Origen, **Guardar reglas**. Toma ~30 segundos.

### 2.4 — Verifica tu IP pública (opcional)

Antes de seguir, confirma que la IP que se guardó sí es la tuya:

```bash
# Linux/macOS:
curl ifconfig.me

# Windows PowerShell:
(Invoke-WebRequest -Uri "https://ifconfig.me/ip").Content
```

Compara con el "Source" de la regla recién creada. Deben coincidir.

---

## Paso 3 — Crear la conexión en DBeaver

### 3.1 — Datos que vas a necesitar

| Dato | De dónde |
|---|---|
| Host | Endpoint Writer de tu cluster (anotado en guía 01). Algo como `aurora-mod4.cluster-XXXXX.us-east-1.rds.amazonaws.com` |
| Port | `5432` |
| Database | `northwind` (la creaste en la guía 01 con "Initial database name") |
| Username | `postgres` |
| Password | Tu master password (de tu password manager) |

### 3.2 — Pasos en DBeaver

1. Menu **Database** → **New Database Connection**.
2. Selecciona **PostgreSQL** (no Aurora — DBeaver usa el driver de PostgreSQL para conectar a Aurora) → **Next**.
3. Pestaña **Main**:
   - **Connect by:** Host (no JDBC URL).
   - **Host:** pega tu endpoint completo.
   - **Port:** `5432`.
   - **Database:** `northwind`.
   - **Authentication:** Database Native.
   - **Username:** `postgres`.
   - **Password:** tu master password.
   - Marca **Save password locally**.
4. Click **Test Connection** abajo a la izquierda.
5. La primera vez te pedirá descargar el driver JDBC de PostgreSQL → **Download**.
6. Si ves "Connected" en verde → click **Finish**. Conexión guardada.

> 💡 **Nombre de la conexión:** en el campo arriba puedes ponerle un alias amigable como `aurora-mod4`. Aparece en el panel izquierdo y no afecta nada técnico.

### 3.3 — Verificar que funciona

En el panel izquierdo, expande tu conexión → **Databases** → **northwind**. Deberías poder navegar el árbol.

Click derecho en la conexión → **SQL Editor** → **Open SQL Editor**. Pega y ejecuta (Ctrl+Enter):

```sql
SELECT version();
SELECT current_database();
SELECT current_user;
```

Resultados esperados:
- `PostgreSQL 17.x ... on x86_64-pc-linux-gnu, ...`
- `northwind`
- `postgres`

Si los tres responden, **la conexión está completa**.

---

<details>
<summary><strong>Errores comunes</strong></summary>

<details>
<summary><code>Connection timed out</code> / <code>Connection refused</code></summary>

Lo más probable: el grupo de seguridad no permite tu IP en 5432.

**Diagnóstico:**
- Verifica que `curl ifconfig.me` te devuelve la misma IP que la regla "My IP" del grupo de seguridad.
- Si no coinciden, edita la regla y vuelve a hacer click en "My IP" → Save.

Otras causas menos comunes:
- Tu cluster está `Detenido` — RDS → Iniciar.
- Acceso público del cluster está en No — RDS → Modify → Public access: Yes → Apply.

</details>

<details>
<summary><code>FATAL: password authentication failed for user "postgres"</code></summary>

Password incorrecto. Tres opciones:
1. Re-verifica el password en tu password manager.
2. Si lo perdiste: RDS → tu cluster → **Modify** → **New master password** → escribe uno nuevo → **Apply immediately** → espera ~3 min.
3. Pega el password directamente desde el password manager (sin retypear) — los caracteres especiales se escapan a veces mal al teclear.

</details>

<details>
<summary><code>FATAL: database "northwind" does not exist</code></summary>

Verifica el nombre exacto. La base se llama `northwind` (todo en minúsculas, sin espacios). Si no la creaste con ese nombre en la guía 01, conéctate a la base default (`postgres`) y créala:

```sql
CREATE DATABASE northwind;
```

Después reconecta la conexión de DBeaver apuntando a `northwind`.

</details>

<details>
<summary><code>Unknown host</code> / <code>nslookup failed</code></summary>

Hostname mal copiado. Causas típicas:
- Espacio o salto de línea oculto al copiar.
- Te perdiste algún caracter.

Solución: vuelve a RDS → cluster → **Conectividad y seguridad** → endpoints → usa el botón de copiar (ícono al lado del endpoint).

</details>

<details>
<summary>DBeaver pide instalar drivers cada vez</summary>

Si DBeaver no recuerda los drivers descargados, abre **Database** → **Driver Manager** → busca PostgreSQL → verifica que dice "Default driver" en verde. Si no, click → **Edit Driver** → **Download / Update** → confirma.

</details>

</details>

---

## Flujo de trabajo cada sesión

A partir de ahora, el ciclo de inicio y cierre se ve así:

### Iniciar sesión

1. **Canvas** → AWS Academy Learner Lab → **Start Lab** → espera verde.
2. **AWS Console** → RDS → **Start** tu cluster si está `Stopped` → espera `Available` (~3-5 min).
3. **Verificar tu IP** — `curl ifconfig.me`. Si cambió desde la última sesión: EC2 → Security Groups → editar regla 5432 → My IP → Save.
4. **DBeaver** → click en tu conexión `aurora-mod4` → conecta.

### Cerrar sesión

1. **DBeaver** → desconecta la conexión (click derecho → Disconnect) o cierra DBeaver.
2. **AWS Console** → RDS → **Stop temporarily** tu cluster.
3. (Opcional) Canvas → **End Lab**.

> 🔴 **No olvides Stop temporarily.** Es lo más fácil de pasar por alto y lo más caro de pasar por alto. Tu cluster cobra mientras esté `Available`. Stop = ~$0/h.

---

## Siguiente paso

Continúa con **`03_northwind_oltp.md`** — vas a cargar el dataset Northwind (datos transaccionales clásicos: clientes, pedidos, productos) en un schema dentro de tu base `northwind`. Es la primera fuente de datos que vas a explorar con SQL.

---

<p align="center">
<a href="../Tema-01/Readme.md">← Volver al índice del Tema 01</a> | <a href="03_northwind_oltp.md">Siguiente: 03 — Northwind OLTP →</a>
</p>
