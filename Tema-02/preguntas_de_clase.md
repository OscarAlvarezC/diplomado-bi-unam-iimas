# Preguntas que surgieron en clase

Preguntas reales que hicieron alumnos durante las sesiones del Tema 02, con la respuesta que se discutió o se investigó después. Pensadas como complemento al material — si tienes la misma duda, busca aquí primero.

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

<p align="center">
<a href="Readme.md">← Volver al índice del Tema 02</a>
</p>
