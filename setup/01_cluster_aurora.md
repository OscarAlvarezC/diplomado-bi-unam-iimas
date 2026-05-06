# 01 — Crear tu cluster Aurora PostgreSQL en el Learner Lab

Esta es la primera guía del setup. Al terminarla tendrás un servidor PostgreSQL corriendo en la nube de AWS, listo para conectar desde tu laptop con DBeaver (siguiente guía).


## Prerequisitos

- Cuenta de **AWS Academy Learner Lab** activa.
- Conexión a internet estable.

---

## Paso 1 — Iniciar tu Learner Lab y abrir la consola AWS

1. Entra a `https://awsacademy.instructure.com` con tu cuenta de estudiante.
2. Abre el curso del diplomado.
3. Localiza el módulo de tu **AWS Academy Learner Lab** (suele aparecer como tarjeta o módulo en el dashboard del curso).
4. Click en **Start Lab**. El indicador en la esquina pasará a verde en ~1-2 minutos.
5. Una vez verde, click en **AWS** (logo arriba). Se abrirá la consola de AWS en una pestaña nueva, ya autenticado.

> ⚠️ **No cierres la pestaña de Learner Lab.** Si la cierras, AWS termina la sesión y pierdes acceso a la consola hasta volver a hacer Start Lab. Cada Start Lab consume parte de tus 4 horas máximas continuas.

**Verifica:** la consola debe abrir en la región **us-east-1 (N. Virginia)**. Esquina superior derecha — confirma que dice "N. Virginia". Si no, **cámbiala** desde el dropdown.

---

## Paso 2 — Crear el cluster Aurora PostgreSQL

### 2.1 — Navegar al servicio RDS

En la barra de búsqueda superior de la consola AWS, escribe **RDS** y selecciónalo. Una vez en RDS:

- Sidebar izquierdo → **Bases de datos** (Databases).
- Botón naranja arriba a la derecha → **Crear base de datos** (Create database).

### 2.2 — Configuración del cluster

Llena el formulario con estos valores. Los que **no menciono explícitamente** déjalos en su valor default.

![Vista general del formulario de creación](img/paso2_2.png)

#### Método de creación

- **Configuración estándar** (NO Easy Create).

#### Engine options

| Campo | Valor |
|---|---|
| Tipo de motor | **Aurora (PostgreSQL Compatible)** |
| Versión del motor | **Aurora PostgreSQL 17.7** (la más reciente que aparezca) |

#### Templates

- **Desarrollo y prueba** (Dev/Test).

#### Cluster scalability

- **Aprovisionado** (Provisioned).

#### Configuration

| Campo | Valor |
|---|---|
| DB cluster identifier | `aurora-mod4` (o el nombre que prefieras, todo en minúsculas y con guiones, sin espacios) |
| Master username | `postgres` |
| Credentials management | **Self managed** (autogestionado) |
| Master password | Genera un password fuerte y **guárdalo** ya en tu password manager — lo necesitarás cada vez que conectes. Sugerencia: usa `openssl rand -base64 24` en una terminal para generar uno bueno |
| Confirm password | (el mismo) |

![Tipo de escalabilidad, versión del motor, identifier y master username](img/paso2_2_1.png)

> ℹ️ La captura muestra `instructor-aurora` porque es del cluster del instructor. Tú usa **`aurora-mod4`** como identifier (o el nombre que prefieras).

#### Instance configuration

| Campo | Valor |
|---|---|
| Clase de instancia | **db.t3.medium** |

#### Disponibilidad

- **No crear una réplica de Aurora.** (El Learner Lab no soporta multi-AZ; intentar agregar réplica falla.)

![Password, autenticación y opciones de almacenamiento](img/paso2_2_2.png)

#### Connectivity

| Campo | Valor |
|---|---|
| Compute resource | **No conectarse a un recurso de cómputo de EC2** |
| Tipo de red | **IPv4** |
| Virtual Private Cloud (VPC) | **Default VPC** |
| DB subnet group | default |
| **Public access** | **Sí** ⚠️ esto es **crítico** — sin esto no podrás conectar desde DBeaver de tu laptop |
| VPC security group | **default** (la que ya existe) |
| Disponibility Zone | Sin preferencia |
| RDS Proxy | desmarcado |
| Certificate authority | `rds-ca-rsa2048-g1` (default) |

![Conectividad: compute, tipo de red, VPC](img/paso2_2_3.png)

![Public access, security group y certificate authority](img/paso2_2_4.png)

> ⚠️ **Public access** debe estar marcado. Si lo dejas en No, tu cluster queda solo accesible desde dentro de la VPC de AWS — y desde tu laptop no podrás llegar. Lo arreglas después editando el cluster, pero es más fácil ponerlo bien ahora.

#### Database authentication

- **Password authentication** marcado (default). NO marques IAM ni Kerberos.

#### Monitoring

- **Database Insights:** Estándar (default).
- **Performance Insights:** desactivado.
- **Enhanced Monitoring:** desactivado (no soportado en Learner Lab).

![Puerto, etiquetas y supervisión Database Insights](img/paso2_2_5.png)

#### Configuración adicional

| Campo | Valor |
|---|---|
| Initial database name | `northwind` |
| DB cluster parameter group | default (default.aurora-postgresql17) |
| DB parameter group | default |
| Failover priority | Sin preferencia |
| Backup retention period | 1 día |
| Backup window | Sin preferencia |
| Encryption | habilitado (default), AWS owned key |
| Auto minor version upgrade | habilitado |
| Maintenance window | Sin preferencia |
| Deletion protection | **desactivado** (importante para poder eliminar el cluster sin trámite) |

![Initial database name (`northwind`) y parameter groups](img/paso2_2_6.png)

![Backup, cifrado, mantenimiento y deletion protection](img/paso2_2_7.png)

### 2.3 — Crear

Click en **Crear base de datos** abajo a la derecha. AWS empieza a aprovisionar el cluster.

> 💰 **AWS te muestra una estimación de costo** antes de confirmar. Para `db.t3.medium` debe estar alrededor de $0.082/hora. Confirma que la estimación es razonable antes de seguir.

---

## Paso 3 — Esperar a que el cluster esté Available

Vuelve a **RDS → Bases de datos**. Verás dos elementos relacionados:

```
aurora-mod4              (el cluster — capa de almacenamiento)
aurora-mod4-instance-1   (la instancia — capa de cómputo)
```

Ambos pasarán por estos estados:
- `Creating` → `Backing up` → `Available` ✅

**Tarda 5-10 minutos.** No tiene caso refrescar cada 30 segundos — toma agua y vuelve.

Cuando ambos digan `Available`, el cluster está listo.

### Anotar el endpoint

Click en el cluster (`aurora-mod4`). En la pestaña **Connectivity & security** verás:

```
Endpoint:  aurora-mod4.cluster-XXXXXXXX.us-east-1.rds.amazonaws.com
Port:      5432
```

**Cópialo y guárdalo** junto con tu password — los necesitarás en la siguiente guía cuando configures DBeaver.

---

## Paso 4 — Verificación rápida

Antes de cerrar esta guía, confirma que todo está bien:

| Check | Cómo verificar |
|---|---|
| ✅ Cluster `Available` | RDS → Databases — estado verde |
| ✅ Endpoint anotado | Lo guardaste junto con el password |
| ✅ Public access habilitado | Configuration tab del cluster → "Publicly accessible: Yes" |
| ✅ DB inicial `northwind` creada | Configuration → "Initial database name: northwind" |
| ✅ Tu password lo tienes guardado | Password manager o nota local segura |

---

## Operativa importante

### 🔴 Pausar el cluster al terminar cada sesión

Tu crédito del Learner Lab es limitado. Mientras el cluster esté `Available`, **gasta**.

Al terminar de trabajar:

1. RDS → Databases → click en tu cluster.
2. **Actions** → **Stop temporarily**.
3. Confirma. El cluster pasa a `Stopped`.

> ℹ️ AWS **auto-reanuda** el cluster a los 7 días aunque sigas con Stop. Si trabajas con varios días de pausa, necesitas volver a hacer Stop. El propósito de auto-resume es que la BD no se quede dormida indefinidamente y los datos se compacten / mantengan.

### 🟢 Reanudar para la siguiente sesión

1. RDS → Databases → cluster.
2. **Actions** → **Start**.
3. Espera 3-5 minutos hasta que diga `Available`.

### Costos aproximados

| Tiempo encendido | Costo |
|---|---|
| 1 hora | ~$0.08 USD |
| 1 día completo (24h) | ~$2 USD |
| 1 semana ininterrumpida | ~$13 USD |
| 1 mes ininterrumpido | ~$58 USD |

El crédito típico de Learner Lab es ~$100 USD, así que olvidar pausar **una noche o un fin de semana** no es desastre. Olvidarlo **una semana o más** sí empieza a doler.

---

## Errores comunes

### "Cannot create db.serverless"

Estás eligiendo Aurora Serverless v2. **Pivota a Provisioned** (Cluster scalability → Aprovisionado).

### "User is not authorized to perform: rds:CreateDBInstance"

Probablemente elegiste una clase de instancia más grande que `medium`. El Learner Lab solo permite hasta `db.t3.medium`. Vuelve y selecciona esa clase.

### "Database creation failed"

Causas comunes:
- Master password no cumple los requisitos (mínimo 8 chars, sin caracteres prohibidos como `/`, `"`, `@`, espacio).
- Identifier del cluster ya existe en tu cuenta — usa otro nombre.
- DB inicial name con caracteres no permitidos — usa solo letras, números, underscore.

### El cluster nunca pasa de `Creating`

Después de 15 minutos sin progreso, lo más práctico es **eliminarlo y crearlo de nuevo**. Click → Actions → Delete → desmarca "create final snapshot" → confirma. Después vuelves al Paso 2.

### No veo la opción de "Public access"

Estás en la sección equivocada del formulario. Está dentro de **Connectivity** → expandir la sección si está colapsada.

---

## Siguiente paso

Continúa con **`02_dbeaver_conexion.md`** — vas a instalar DBeaver Community en tu laptop, configurar el security group del cluster para permitir conexiones desde tu IP, y conectar al servidor que acabas de crear.
