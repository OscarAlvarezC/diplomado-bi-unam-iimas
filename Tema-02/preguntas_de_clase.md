# Preguntas que surgieron en clase

Preguntas reales que hicieron alumnos durante las sesiones del Tema 02, con la respuesta que se discutió o se investigó después. Pensadas como complemento al material — si tienes la misma duda, busca aquí primero.

## Índice

1. [Al conectar la base de datos de Aurora a Power BI sale el error "El certificado remoto no es válido". ¿Cómo lo resuelvo?](#al-conectar-la-base-de-datos-de-aurora-a-power-bi-sale-el-error-el-certificado-remoto-no-es-válido-cómo-lo-resuelvo)
2. [En Power BI, ¿cuál es la diferencia entre agregar una columna en Power Query y agregarla en la vista de datos?](#en-power-bi-cuál-es-la-diferencia-entre-agregar-una-columna-en-power-query-y-agregarla-en-la-vista-de-datos)

---

## Al conectar la base de datos de Aurora a Power BI sale el error "El certificado remoto no es válido". ¿Cómo lo resuelvo?

El mensaje completo es:

```
No se puede conectar
Se encontró un error al intentar conectarse.
Detalles: "Se produjo un error al leer datos desde el proveedor:
'El certificado remoto no es válido según el procedimiento de validación.'"
```

Es un error de **validación del certificado SSL**, no de credenciales ni de red. El cluster sí está accesible — el problema es que Power BI no confía en el certificado que presenta Aurora.

### Primero: ¿qué es el cifrado SSL?

**SSL** (hoy técnicamente **TLS**) es el mecanismo que **cifra la comunicación entre dos máquinas en una red**. Cuando Power BI se conecta a Aurora, los datos viajan por internet atravesando routers intermedios; sin cifrado, cualquiera en el camino podría leer tu password, tus queries y los datos que regresan. SSL/TLS hace tres cosas:

- **Confidencialidad** — los datos viajan cifrados, ilegibles para terceros.
- **Integridad** — nadie puede alterar los datos sin que se detecte.
- **Autenticación** — verifica que de verdad hablas con Aurora y no con un impostor. Para esto, el servidor presenta un **certificado digital** firmado por una autoridad certificadora (CA) confiable, y el cliente verifica esa firma.

Es la "s" de `https://`. El error de este caso ocurre justo en la parte de **autenticación**: Aurora presenta un certificado válido, pero Power BI no reconoce a la CA que lo firmó.

### Causa

Power BI Desktop establece la conexión usando **cifrado SSL/TLS**. Aurora presenta un certificado firmado por la **CA de Amazon RDS** de la región del cluster, pero Windows no tiene esa CA en su almacén de confianza, así que rechaza el certificado.

> :warning: Las versiones recientes del conector PostgreSQL de Power BI **ya no tienen la casilla "Cifrar conexión"** para desactivar SSL — el conector moderno (basado en Npgsql) siempre cifra. Por eso la única solución estable es **hacer que Windows confíe en el certificado de Amazon**, que además es la solución correcta (mantiene el tráfico cifrado).

### Requisitos previos

- **Acceso de administrador local** en la máquina Windows.
- **Cluster Aurora accesible** desde tu red. Verifícalo en PowerShell:
  ```powershell
  Test-NetConnection <endpoint> -Port 5432
  ```
  Debe retornar `TcpTestSucceeded: True`.
- **Conocer la región AWS del cluster** — es visible en el endpoint. Ejemplo: en
  `aurora-mod4.cluster-xxxxx.us-east-1.rds.amazonaws.com` la región es `us-east-1`.

### Solución — instalar el certificado raíz de Amazon RDS de la región del cluster

#### :warning: Importante: usa el bundle REGIONAL, no el global

Amazon ofrece dos opciones:

- **Bundle global** (`global-bundle.pem`) — supuestamente incluye todas las regiones.
- **Bundle regional** (ej. `us-east-1-bundle.pem`) — solo la región específica.

**Usa el bundle regional de tu cluster.** En la práctica se observó que `Import-Certificate` con el bundle global **no siempre registra todos los certificados** del archivo en el almacén de Windows — puede importar solo uno, y frecuentemente no es el de la región que necesitas. Ir directo al bundle regional evita ese problema.

#### Paso 1 — Descargar el bundle regional

Para `us-east-1`:

<https://truststore.pki.rds.amazonaws.com/us-east-1/us-east-1-bundle.pem>

Para otras regiones, reemplaza `us-east-1` por la región de tu cluster. Guárdalo en una ubicación conocida (ej. `Downloads`).

#### Paso 2 — Abrir PowerShell como Administrador

1. Menú Inicio → escribe `PowerShell`.
2. Click derecho sobre **Windows PowerShell** → **Ejecutar como administrador**.
3. Acepta el aviso de UAC.
4. Verifica que la barra de título diga **"Administrador: Windows PowerShell"**.

#### Paso 3 — Importar el certificado al almacén raíz del equipo

```powershell
cd $HOME\Downloads
Import-Certificate -FilePath ".\us-east-1-bundle.pem" -CertStoreLocation Cert:\LocalMachine\Root
```

PowerShell debe responder listando los certificados importados con su `Thumbprint` y `Subject`.

#### Paso 4 — Verificar la instalación

```powershell
Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -like "*Amazon RDS*" } | Select-Object Subject
```

Debe aparecer al menos un certificado de Amazon RDS de la región del cluster (ej. `Amazon RDS us-east-1 Root CA RSA2048 G1`). **Si aparece una región distinta a la del cluster, ese es el problema** — hay que descargar el bundle regional correcto.

#### Paso 5 — Limpiar credenciales cacheadas en Power BI

Power BI recuerda el intento fallido; hay que limpiarlo antes de reconectar.

1. Cierra Power BI Desktop completamente (verifica la bandeja del sistema).
2. Abre Power BI Desktop.
3. **Archivo → Opciones y configuración → Configuración del origen de datos**.
4. Busca el servidor Aurora en la lista, selecciónalo y click en **Borrar permisos**.
5. Cierra esa ventana.

#### Paso 6 — Reconectar

1. **Inicio → Obtener datos → Más… → Base de datos → Base de datos PostgreSQL → Conectar**.
2. Llena:
   - **Servidor:** `<endpoint>.cluster-xxxxx.<región>.rds.amazonaws.com:5432`
   - **Base de datos:** `northwind`
   - **Modo de conectividad:** Importar
3. En la ventana de credenciales, selecciona **"Base de datos"** en el menú lateral.
4. Ingresa usuario (`postgres`) y contraseña.
5. Click **Conectar**.

La conexión debe establecerse correctamente con cifrado SSL activo.

### Notas

- Este procedimiento se hace **una sola vez por máquina**. Una vez instalada la CA de Amazon, cualquier conexión futura a Aurora (u otra base RDS de la misma región) desde Power BI, DBeaver u otra herramienta que use el almacén de Windows funcionará sin volver a tocar nada.
- Si tu cluster está en otra región, repite el procedimiento con el bundle regional correspondiente.

---

## En Power BI, ¿cuál es la diferencia entre agregar una columna en Power Query y agregarla en la vista de datos?

En Power BI hay **dos lugares** donde puedes crear una columna nueva, y aunque las dos quedan almacenadas en el modelo, se calculan en **momentos distintos del flujo** y con **lenguajes distintos**.

| | Power Query (Transformar datos) | Vista de datos ("Nueva columna") |
|---|---|---|
| **Lenguaje** | M | DAX |
| **Cuándo se calcula** | **Durante la carga** de datos (refresh) | **Después de cargar**, sobre el modelo ya armado |
| **Etapa del flujo** | Antes de que los datos entren al modelo | Una vez los datos ya están en el modelo |
| **Puede empujarse al origen** | Sí (*query folding*) | No — siempre la calcula Power BI |
| **Acceso a relaciones entre tablas** | No (opera sobre la tabla en transformación) | Sí (`RELATED`, `LOOKUPVALUE`, etc.) |

### La idea de fondo

```
Aurora ──→ [POWER QUERY] ──→ [MODELO DE DATOS] ──→ visualizaciones
              │                    │
        columna M aquí       columna DAX aquí
        (durante la carga)   (datos ya cargados)
```

- **Columna en Power Query** = parte del **proceso de carga**. Cuando los datos llegan al modelo, la columna ya viene incluida — es como limpiar o derivar datos *antes* de meterlos a la tabla. Power Query es, de hecho, la herramienta ETL de Power BI.
- **Columna en Vista de datos** = se agrega **encima del modelo ya cargado**. Los datos ya entraron, y DAX calcula la columna nueva usando lo que ya está ahí, incluyendo relaciones con otras tablas.

### ¿Qué es el *query folding*?

Es una optimización de Power Query: cuando tus transformaciones son lo suficientemente simples, Power Query **las traduce a una sola query SQL y se la manda al origen** (Aurora, en este caso) para que la base de datos haga el trabajo, en lugar de traer todos los datos crudos y transformarlos en tu laptop.

```
SIN query folding:
  Power Query trae las 2,155 filas crudas → tu laptop calcula precio*cantidad

CON query folding:
  Power Query traduce el paso a SQL:
    SELECT *, unit_price * quantity AS total FROM fact_sales
  → Aurora ejecuta esa query y devuelve el resultado YA calculado
```

¿Por qué importa?

- **Más rápido** — la base de datos está optimizada para esas operaciones y solo viaja por la red el resultado final, no los datos crudos.
- **Escala mejor** — con millones de filas, transformar en tu laptop es lento; en el motor de base de datos no.
- **Solo funciona con orígenes que "hablan SQL"** (bases de datos como Aurora). Si el origen es un archivo Excel o CSV, no hay a quién delegar y el folding no aplica.
- **Las transformaciones complejas rompen el folding**: si haces un paso que no se puede expresar en SQL, de ahí en adelante Power Query ya no puede delegar y procesa localmente.

Las columnas DAX (vista de datos) **nunca** tienen query folding — siempre las calcula Power BI después de cargar.

### ¿Cuál usar?

- **Power Query** — para columnas derivadas de datos de **la misma tabla** (`unit_price * quantity`, extraer el año de una fecha, limpiar texto). Es lo preferible: se calcula una vez en la carga y, si hay query folding, la base de datos hace el trabajo.
- **Vista de datos (DAX)** — cuando la columna **necesita datos de otra tabla relacionada** y traerlos en Power Query sería complicado.

Regla simple: **si puedes hacerla en Power Query, hazla ahí**; usa DAX solo cuando necesites las relaciones del modelo. Esto conecta con el bloque de **ETL** del módulo (Tema 05) — Power Query es un ETL visual: lo que en Python harías con pandas (`df['total'] = df['precio'] * df['cantidad']`), en Power BI lo haces en Power Query.

---

<p align="center">
<a href="Readme.md">← Volver al índice del Tema 02</a>
</p>
