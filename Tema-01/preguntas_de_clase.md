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





<p align="center">
<a href="Readme.md">← Volver al índice del Tema 01</a>
</p>
