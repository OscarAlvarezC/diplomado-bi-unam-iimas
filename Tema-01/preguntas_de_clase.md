# Preguntas que surgieron en clase

Preguntas reales que hicieron alumnos durante las sesiones del Tema 01, con la respuesta que se discutió o se investigó después. Pensadas como complemento al material — si tienes la misma duda al seguir las guías, busca aquí primero.

---

## ¿En "Configuración express" AWS dice "Cree y consulte una base de datos sin servidor de Aurora PostgreSQL" — a qué se refiere con "sin servidor"?

"Sin servidor" es una mala traducción de **serverless**. **Sí hay servidores** — lo que cambia es que tú no los administras: AWS los provisiona, escala y libera automáticamente según la demanda real, y te cobra por uso (no por hora encendida).

En Aurora esto se llama **Aurora Serverless v2**. Las diferencias clave contra el modo **Aprovisionado** (el que usamos en este módulo):

| Aspecto | Aprovisionado | Serverless v2 |
|---|---|---|
| Tamaño | Eliges una clase de instancia (`db.t3.medium`, etc.) | No eliges tamaño — solo un rango mínimo y máximo en **ACUs** |
| Billing | Pagas por hora encendida, uses o no | Pagas por **ACUs consumidas por segundo** |
| Capacidad | Fija | Auto-escala con la carga (sube en picos, baja en valles) |
| Visibilidad | Hay una "instancia" visible en la consola | Solo el cluster; AWS multiplexa servidores internos |

Una **ACU** (Aurora Capacity Unit) es una unidad sintética que combina **~2 GB de RAM con CPU y red proporcionales** (aproximadamente 0.5 vCPU por ACU). Al subir o bajar ACUs, las tres dimensiones escalan juntas. Cuesta ~$0.12 USD/hora; si el cluster está en mínimo (0.5 ACU) sin tráfico paga ~$0.06/hora, y si recibe un pico que sube a 4 ACUs por 10 min paga eso solo por esos 10 min.

**Cuándo conviene cada uno:**

- **Serverless** — cargas erráticas (picos + valles), dev/test esporádico, demos y POCs, multi-tenant SaaS.
- **Aprovisionado** — producción 24/7 con tráfico predecible (más barato a uso constante), entornos donde quieres costo fijo predecible.

**¿Por qué no usamos Serverless en este módulo?** El AWS Academy Learner Lab **bloquea Aurora Serverless v2** por política. En producción real fuera del Learner Lab sí podrías elegirlo libremente. Esa restricción está documentada en el `<details>` "¿Aprovisionado vs Serverless?" dentro de [`setup/01_cluster_aurora.md`](../setup/01_cluster_aurora.md).

**Analogía:** Aprovisionado es como **rentar un coche fijo todo el año** — siempre disponible, siempre te cuesta. Serverless es como **usar Uber/Didi cuando lo necesitas** — pides cuando hace falta, pagas el viaje. Los autos siguen existiendo; cambia tu relación con ellos.

---

## ¿Después de crear el cluster salió un error sobre `ram:GetResourceShares` — qué significa? ¿Rompió algo?

**No rompió nada.** Es un warning cosmético del Learner Lab. El cluster se creó correctamente si pasó a estado *Disponible*. Pero entender el mensaje vale la pena.

### El mensaje

```
User: arn:aws:sts::...:assumed-role/voclabs/user...=Tu_Nombre
is not authorized to perform: ram:GetResourceShares
on resource: arn:aws:ram:us-east-1:...:resource-share/*
because no identity-based policy allows the ram:GetResourceShares action
```

Decodificándolo:

| Pieza | Qué significa |
|---|---|
| `assumed-role/voclabs/...` | Tu identidad temporal. **`voclabs`** es el rol IAM que usa AWS Academy / Vocareum. No eres un usuario IAM permanente, eres una **sesión efímera** con credenciales prestadas. |
| `ram:GetResourceShares` | La acción intentada. **`ram`** es **AWS Resource Access Manager**, el servicio que permite **compartir recursos entre cuentas AWS** dentro de una organización. `GetResourceShares` lista esos recursos compartidos. |
| `no identity-based policy allows...` | Tu rol simplemente **no tiene esa permission**. AWS Academy mantiene el rol con privilegios mínimos. |

### ¿Por qué la consola RDS intenta llamar a Resource Access Manager?

Cuando creas el cluster, RDS quiere ofrecerte **todas las subnets disponibles** para colocar tu instancia — incluyendo subnets que pudieran estar compartidas desde **otras cuentas AWS** vía RAM. Es un patrón común en empresas con muchas cuentas: una cuenta central crea la VPC y comparte subnets con las demás.

### ¿Por qué falla el llamado?

El rol `voclabs` del Learner Lab **no tiene permiso para usar el servicio RAM en absoluto** — no es que falten permisos sobre la VPC, ni que esté bloqueada una acción específica. Es que **todo el namespace `ram:*` está fuera del whitelist** del rol educativo:

| Servicio | ¿Tu rol tiene permiso? |
|---|---|
| **VPC** (crear/modificar tu red privada, subnets, route tables, security groups) | ✅ Sí, dentro del scope del Lab |
| **RDS / Aurora** (crear bases de datos) | ✅ Sí (con restricciones: solo burstable, sin Serverless) |
| **EC2** (máquinas virtuales) | ✅ Sí, con restricciones |
| **RAM** (Resource Access Manager — compartir recursos entre cuentas) | ❌ **Bloqueado completamente** — ninguna acción de `ram:*` |
| **AWS Organizations** | ❌ Bloqueado |

VPC y RAM **son servicios distintos**. La consola necesita llamar a los dos para construir la lista completa de subnets (propias + compartidas). La llamada a VPC/EC2 (`ec2:DescribeSubnets`) sí pasa; la llamada a RAM (`ram:GetResourceShares`) no.

AWS Academy bloquea RAM por tres razones:

1. **No tienes otras cuentas AWS** con las que compartir. RAM solo tiene sentido en una AWS Organization multi-cuenta, lo cual no aplica al Learner Lab.
2. **No formas parte de una AWS Organization.** El Lab es una cuenta huérfana.
3. **Principio de mínimo privilegio.** AWS Academy solo te da los permisos que necesitas para el contenido del curso. RAM no está en ningún temario del diplomado, así que el rol no lo incluye.

### ¿Por qué no rompe nada?

Cuando el call a RAM falla, la consola **cae al comportamiento por defecto**: muestra solo las subnets **propias de tu cuenta** (las de la VPC default). Como no tienes otras cuentas conectadas vía RAM (eres una cuenta educativa aislada), esa lista habría estado vacía de todos modos.

### Qué hacer al verlo

**Ignorarlo.** Si el cluster está *Disponible* y puedes conectarte por DBeaver, todo funcionó. El error es ruido visual del Learner Lab — aparece porque el rol educativo está restringido a propósito (principio de mínimo privilegio).

---

## ¿Qué son las subnets?

Una **subnet** es una **subdivisión lógica de una red más grande**. En AWS son las divisiones internas que tiene una VPC.

### La jerarquía: VPC → subnets

Recuerda que una **VPC** es tu red privada en AWS, con un rango de IPs propio (ej. `172.31.0.0/16`, ~65,000 IPs). Una sola red plana de tantas IPs sería difícil de operar, así que se **subdivide en subnets** más pequeñas:

```
VPC default:         172.31.0.0/16   (~65,000 IPs)
│
├── Subnet A:        172.31.16.0/20  (~4,000 IPs) → en zona us-east-1a
├── Subnet B:        172.31.32.0/20  (~4,000 IPs) → en zona us-east-1b
└── Subnet C:        172.31.48.0/20  (~4,000 IPs) → en zona us-east-1c
```

Cada subnet es un bloque contiguo de IPs dentro de la VPC. Cuando lanzas un recurso (Aurora, EC2, etc.) **vive dentro de una subnet específica** — no flotando en la VPC en abstracto.

### Analogía

La **VPC** es un edificio de oficinas con dirección postal única. Las **subnets** son los pisos del edificio. Cada piso tiene su rango de oficinas (IPs), su propia entrada (route table), su propio guardia (NACL). Cuando rentas una oficina (lanzas un recurso) siempre es en un piso específico — no "en el edificio" en abstracto. Los pisos públicos los entra cualquiera desde la calle; los privados, solo desde dentro del edificio; los aislados son cuartos cerrados.

---

## ¿El profesor de AWS Academy puede modificar los roles IAM para habilitar RAM (o cualquier otro servicio bloqueado)?

**No.** El rol `voclabs` está blindado por AWS Academy / Vocareum y ni siquiera la cuenta del profesor tiene permisos para modificarlo.

### Por qué no se puede

1. **El rol lo gestiona Vocareum centralmente**, no la institución educativa. Su política IAM está definida en los servidores de Vocareum y se aplica idéntica a **todos los Learner Labs del mundo** que usen ese módulo. Permitir modificación rompería la consistencia global del programa.
2. **El rol del profesor (Educator Lab) tampoco tiene `iam:AttachRolePolicy` ni `iam:PutRolePolicy`** sobre `voclabs`. Es un rol paralelo, no un super-admin.
3. **Las credenciales son STS temporales** (de ahí el `assumed-role/voclabs/...` del error). Aunque se lograra un workaround, expira al cerrar el Lab y no persiste entre sesiones.

### Qué SÍ puede hacer el profesor

| Acción | Disponible |
|---|---|
| Ver progreso y consumo de crédito de los alumnos | ✅ |
| Reiniciar el Lab de un alumno atorado | ✅ |
| Personalizar el material introductorio del Lab | ✅ (vía Vocareum) |
| Demostrar features en su propio Educator Lab | ✅ |
| Modificar la política IAM de `voclabs` | ❌ |
| Habilitar un servicio bloqueado (RAM, Organizations, etc.) | ❌ |
| Cambiar el límite de crédito de los alumnos | ❌ (lo define AWS Academy) |

### Alternativas si hace falta cubrir un servicio bloqueado

1. **Solicitarlo formalmente a AWS Academy** vía portal de educadores o Academy Champion. Proceso largo, raramente aprobado para un curso.
2. **Usar la cuenta personal de AWS** del profesor para la demo. El profesor graba o presenta en vivo desde su cuenta (donde sí tiene admin); los alumnos solo ven, no replican.
3. **Adaptar el curriculum** para trabajar dentro de las restricciones del Lab (es lo que se hace en este módulo — RAM no es central al temario).

### Por qué AWS Academy mantiene esta restricción

Es por tres garantías que el programa ofrece a las universidades:

1. **Costo controlado.** Cada alumno tiene crédito limitado (~$50 USD). Permisos amplios podrían consumir miles de dólares accidentalmente.
2. **Seguridad consistente.** Los alumnos no pueden causar daño operativo aunque quisieran.
3. **Reproducibilidad global.** Todo el contenido funciona igual en cualquier institución del mundo.

Es un trade-off explícito: **más restricción → menos riesgo pero menos flexibilidad**. Para el Módulo 4 (BI, ETL, SQL avanzado, OLAP) las restricciones no afectan los temas centrales — solo bloquean detalles enterprise (RAM, Organizations, Direct Connect, etc.) que no son curriculares.

---

## En RDS PostgreSQL estándar solo se creaba una instancia, pero al crear una Aurora PostgreSQL aparecen **un cluster y una instancia**. ¿Qué cambió?

En el formulario de creación de RDS, lo único que cambió fue una sola opción:

| Campo | Antes (RDS estándar) | Ahora (Aurora) |
|---|---|---|
| Tipo de motor | "PostgreSQL" | "**Aurora (compatible con PostgreSQL)**" |
| Resultado en la consola | 1 entidad (instance) | **2 entidades** (cluster + instance) |

### ¿Qué es un cluster y una instancia?

**Instancia (instance)** = un **servidor de base de datos corriendo**. Es una máquina virtual gestionada por AWS con CPU, RAM, red y el motor PostgreSQL ejecutándose. Cuando elegiste `db.t3.medium`, decidiste el tamaño de esa máquina (2 vCPU + 4 GB RAM). Una instancia atiende conexiones SQL, ejecuta queries, mantiene caché en memoria. Si la apagas, las queries dejan de responder.

**Cluster** = un **grupo de componentes que cooperan y se presentan como un solo sistema lógico**. En el contexto de bases de datos, un cluster típicamente agrupa: una capa de almacenamiento compartida + una o más instancias de cómputo + endpoints DNS + configuración común (backups, parámetros, seguridad). El cluster es la **unidad administrativa**; las instancias son sus componentes activos.

En RDS estándar **estos dos conceptos colapsan en uno**: la instancia ES la base, con su propio disco adjunto, sin nada más alrededor. En Aurora **se separan**: el cluster contiene el almacenamiento y las instancias son piezas de cómputo intercambiables dentro de él.

### La diferencia arquitectónica de fondo

Aurora introduce una **separación arquitectónica fundamental** que el PostgreSQL estándar de RDS no tiene: **el almacenamiento vive separado del cómputo**. Por eso ves dos entidades en la consola — el cluster es el almacenamiento, la instancia es el cómputo.

### RDS PostgreSQL estándar — almacenamiento y cómputo acoplados

```
┌──────────────────────────────────────┐
│  RDS PostgreSQL instance             │
│  ┌────────────────────────────────┐  │
│  │  PostgreSQL engine (CPU + RAM) │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │  EBS volume (disco)            │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
     ↑
     una sola entidad: "la instancia"
     (cómputo y almacenamiento juntos)
```

La instancia es una máquina virtual con PostgreSQL corriendo y un disco EBS adjunto. Inseparables — exactamente como un servidor físico tradicional. Si quieres una réplica, AWS levanta **otra instancia idéntica con su propio disco** y configura streaming replication entre ambas.

### Aurora PostgreSQL — almacenamiento y cómputo separados

```
┌─── Aurora Cluster ─────────────────────────────────┐
│                                                    │
│  ┌───────────────┐  ┌───────────────┐              │
│  │   Instance 1  │  │   Instance 2  │  (opcional)  │
│  │  (CPU + RAM)  │  │  (CPU + RAM)  │              │
│  └───────┬───────┘  └───────┬───────┘              │
│          │                  │                      │
│          └──────────┬───────┘                      │
│                     ▼                              │
│  ┌──────────────────────────────────────────────┐  │
│  │  Storage compartido (distribuido en 3 AZs,   │  │
│  │  replicado 6 veces, gestionado por AWS)      │  │
│  └──────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────┘
```

Aurora tiene **dos entidades separadas**:

- **Cluster** — posee el almacenamiento. Sistema de discos distribuidos propietario de AWS, replicado automáticamente 6 veces en 3 zonas de disponibilidad. **Es persistente; los datos viven aquí aunque no haya ninguna instancia encendida.**
- **Instances** — solo aportan cómputo (CPU + RAM). **No tienen disco propio**; se conectan al storage compartido del cluster. Puedes tener 1, 15 o 0 instancias — el cluster y los datos siguen ahí.

### Por qué tener cluster con UNA sola instancia sigue valiendo la pena

Aunque en este módulo solo tenemos 1 instancia en el cluster `aurora-mod4`, las **garantías estructurales** del cluster ya te benefician:

- Si tu única instancia falla, el cluster levanta otra y la conecta al storage existente automáticamente.
- Si el día de mañana necesitas agregar una réplica para Power BI sin afectar la operativa, lo haces en segundos.
- Tu cómputo es elástico: cambiar el tamaño de instancia (más CPU/RAM) o agregar réplicas con tamaños distintos toma minutos, no horas — porque los datos no se mueven, solo se reconfigura qué máquina está adelante.

> *En RDS PostgreSQL estándar, la instancia incluye el almacenamiento — son la misma cosa. En Aurora, AWS separó el almacenamiento (que vive en el cluster) del cómputo (que vive en las instancias). Por eso ves un cluster aunque solo crees una instancia: el cluster es donde realmente viven los datos.*

---

## Cuando te conectas al cluster, ¿trabajan las dos instancias para el procesamiento? ¿Se pueden tener dos instancias con motores diferentes en el mismo cluster?

Dos respuestas cortas: **no, las instancias no colaboran en una sola query**, y **no, todas las instancias del cluster comparten el mismo motor y versión**.

### ¿Las instancias trabajan juntas para procesar mi query?

**Aurora no es un motor MPP** (Massively Parallel Processing). Cada query individual la ejecuta **una sola instancia**, de principio a fin. Las otras instancias del cluster pueden estar atendiendo otras queries en paralelo, pero **no colaboran** en la tuya.

Lo que sí hacen varias instancias es **repartirse la carga de trabajo** (no la query):

```
Carga del día:
  ├── 1,000 escrituras       → writer (instance-1)
  ├── 5,000 reads de la app  → reader endpoint balancea entre instance-2 e instance-3
  └── 100 queries Power BI   → reader endpoint balancea entre instance-2 e instance-3
```

Si una query analítica pesada llega a `instance-2`, **`instance-2` la resuelve sola** con su CPU y RAM. Las otras instancias hacen otras cosas para otros clientes en paralelo, pero no aportan al cómputo de esa query.

Comparativa con motores que sí son MPP:

| Sistema | ¿Una query individual se divide entre múltiples nodos? |
|---|---|
| **Aurora PostgreSQL** | ❌ No. Una query = una instancia |
| **RDS PostgreSQL** | ❌ No |
| **Redshift** | ✅ Sí — distribuida entre todos los compute nodes |
| **Snowflake** | ✅ Sí — distribuida en el warehouse activo |
| **BigQuery** | ✅ Sí — dispatch dinámico de slots |

Aurora con múltiples instancias **escala la concurrencia** (muchas queries chicas en paralelo, típico de BI), no **la velocidad de una query individual**. Si necesitas velocidad masiva en una sola query gigante, el camino es Redshift / Snowflake / BigQuery, no Aurora con muchas instancias.

### ¿Puedo mezclar motores diferentes en el mismo cluster?

**No.** El motor (engine) y la versión major son **propiedades del cluster, no de las instancias**. Todas las instancias del cluster corren el mismo motor y la misma versión.

```
aurora-mod4 (cluster)
  ├── Engine:          Aurora PostgreSQL     ← UN motor para todo el cluster
  ├── Engine version:  16.4                  ← UNA versión major para todo
  │
  ├── instance-1 (writer)  → mismo motor, misma versión, db.r5.xlarge
  ├── instance-2 (reader)  → mismo motor, misma versión, db.r5.large
  └── instance-3 (reader)  → mismo motor, misma versión, db.t3.medium
```

**¿Por qué?** Porque el formato físico de los datos en el storage es específico del motor. Aurora PostgreSQL escribe páginas con el formato binario de PostgreSQL; Aurora MySQL escribe con el formato de InnoDB. Como el storage es compartido entre todas las instancias del cluster, **todas tienen que hablar el mismo "idioma binario"** — lo cual fuerza un motor único por cluster.

---

<p align="center">
<a href="Readme.md">← Volver al índice del Tema 01</a>
</p>
