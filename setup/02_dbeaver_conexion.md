# 02 — Instalar DBeaver y conectar a tu Aurora

Ahora que tu cluster `aurora-mod4` ya está corriendo en AWS, vas a configurar el cliente SQL en tu laptop y abrir la primera conexión.

**Tiempo estimado:** 20-30 minutos (la mayoría descargando DBeaver).
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

### 2.1 — Llegar al security group

1. AWS Console → **RDS** → **Databases** → click **`aurora-mod4-instance-1`** (la instancia, no el cluster).
2. Pestaña **Connectivity & security**.
3. Sección **Security** → click el security group (suele decir `default (sg-XXXXXXXX)`).
4. Esto abre la consola de **EC2** filtrando ese SG.

### 2.2 — Agregar la regla inbound

1. Tab **Inbound rules** → botón **Edit inbound rules** → **Add rule**.
2. Configura:

| Campo | Valor |
|---|---|
| Type | **PostgreSQL** |
| Protocol | TCP (autollenado) |
| Port range | 5432 (autollenado) |
| Source | **My IP** ⚠️ esto es clave |
| Description | `DBeaver desde mi laptop` |

3. **Save rules**.

> ⚠️ **"My IP" detecta automáticamente tu IP pública actual.** Cuando cambies de red (otro WiFi, el café, casa de un amigo, datos móviles) tu IP cambia y la regla deja de funcionar. Solución: vuelve aquí, click **Edit inbound rules**, en la regla existente click el botón **My IP** otra vez, Save. Toma ~30 segundos.

### 2.3 — Verifica tu IP pública

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

## Errores comunes

### `Connection timed out` / `Connection refused`

Lo más probable: el security group no permite tu IP en 5432.

**Diagnóstico:**
- Verifica que `curl ifconfig.me` te devuelve la misma IP que la regla "My IP" del SG.
- Si no coinciden, edita la regla y vuelve a hacer click en "My IP" → Save.

Otras causas menos comunes:
- Tu cluster está `Stopped` — RDS → Start.
- Public access del cluster está en No — RDS → Modify → Public access: Yes → Apply.

### `FATAL: password authentication failed for user "postgres"`

Password incorrecto. Tres opciones:
1. Re-verifica el password en tu password manager.
2. Si lo perdiste: RDS → tu cluster → **Modify** → **New master password** → escribe uno nuevo → **Apply immediately** → espera ~3 min.
3. Pega el password directamente desde el password manager (sin retypear) — los caracteres especiales se escapan a veces mal al teclear.

### `FATAL: database "northwind" does not exist`

Verifica el nombre exacto. La base se llama `northwind` (todo en minúsculas, sin espacios). Si no la creaste con ese nombre en la guía 01, conéctate a la base default (`postgres`) y créala:

```sql
CREATE DATABASE northwind;
```

Después reconecta la conexión de DBeaver apuntando a `northwind`.

### `Unknown host` / `nslookup failed`

Hostname mal copiado. Causas típicas:
- Espacio o salto de línea oculto al copiar.
- Te perdiste algún caracter.

Solución: vuelve a RDS → cluster → **Connectivity & security** → endpoints → usa el botón de copiar (ícono al lado del endpoint).

### DBeaver pide instalar drivers cada vez

Si DBeaver no recuerda los drivers descargados, abre **Database** → **Driver Manager** → busca PostgreSQL → verifica que dice "Default driver" en verde. Si no, click → **Edit Driver** → **Download / Update** → confirma.

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
