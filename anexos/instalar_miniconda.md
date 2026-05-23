# Instalar Miniconda

Guía para instalar **Miniconda** — el gestor de ambientes y paquetes que vamos a usar en el módulo para correr Python y Jupyter Lab. Aplica al **Tema 04 (ETL con Python)** en adelante.

## ¿Qué es Miniconda y por qué Miniconda en vez de Anaconda?

**Miniconda** es la versión mínima del ecosistema de Anaconda: solo trae `conda` (el gestor de paquetes), Python, y unas pocas librerías base. Anaconda completa, en cambio, trae **más de 250 paquetes científicos preinstalados** — la mayoría no los usarás nunca.

| | Miniconda | Anaconda completa |
|---|---|---|
| Tamaño del instalador | **~50 MB** | ~700 MB |
| Espacio en disco tras instalar | **~400 MB** | ~3 GB |
| Librerías preinstaladas | Mínimas (conda + Python) | 250+ científicas (NumPy, SciPy, pandas, scikit-learn, etc.) |
| Tiempo de instalación | **~2 minutos** | ~15 minutos |
| Filosofía | Tú instalas lo que necesitas | Todo incluido |

**Para este módulo conviene Miniconda:** instalas solo las 4 librerías que vamos a usar (`pandas`, `sqlalchemy`, `psycopg2-binary`, `jupyterlab`) y mantienes tu sistema ligero. Si después quieres más, las agregas con `conda install`.

> :information_source: **¿Por qué conda y no pip directamente?** Conda crea **ambientes aislados** — un ambiente por proyecto, con su propia versión de Python y sus propias librerías. Así no rompes tu Python del sistema, ni mezclas dependencias de proyectos distintos. Es el equivalente a `venv` + `pip`, pero más robusto para Windows y para librerías con dependencias en C (como `psycopg2`).

---

## Paso 1 — Descargar el instalador

Ve a la [página oficial de Miniconda](https://docs.anaconda.com/miniconda/) y descarga el instalador para tu sistema operativo.

| Sistema | Instalador |
|---|---|
| **Windows 64-bit** | `Miniconda3-latest-Windows-x86_64.exe` |
| **macOS Intel** | `Miniconda3-latest-MacOSX-x86_64.pkg` |
| **macOS Apple Silicon (M1/M2/M3/M4)** | `Miniconda3-latest-MacOSX-arm64.pkg` |
| **Linux 64-bit** | `Miniconda3-latest-Linux-x86_64.sh` |

> :warning: En **macOS** asegúrate de elegir el instalador correcto según tu chip. Para saberlo: menú Apple → Acerca de este Mac → si dice "Apple M…" usa **arm64**, si dice "Intel" usa **x86_64**.

---

## Paso 2 — Instalar

### Windows

1. Doble click en el `.exe` descargado.
2. **Install for: Just Me** (recomendado — no requiere admin).
3. Ruta de instalación: dejar la default (`C:\Users\<tu_usuario>\miniconda3`).
4. **Advanced Options:**
   - ✅ Marcar **"Add Miniconda3 to my PATH environment variable"** (técnicamente Anaconda lo desaconseja, pero simplifica mucho la vida en el módulo).
   - ✅ Marcar **"Register Miniconda3 as my default Python"**.
5. **Install** → esperar ~2 minutos → **Finish**.

### macOS

1. Doble click en el `.pkg` descargado.
2. Seguir el asistente con todos los defaults (siguiente → siguiente → instalar).
3. El instalador edita tu `~/.zshrc` para agregar `conda` al PATH.
4. **Reinicia tu Terminal** para que los cambios surtan efecto.

### Linux

```bash
bash ~/Downloads/Miniconda3-latest-Linux-x86_64.sh
```

1. Acepta la licencia con `yes`.
2. Ruta de instalación: dejar la default (`~/miniconda3`).
3. Al final pregunta *"Do you wish the installer to initialize Miniconda3 by running conda init?"* — responde **`yes`**.
4. **Reinicia tu terminal** (o `source ~/.bashrc`).

---

## Paso 3 — Verificar la instalación

Abre una terminal nueva (en Windows: **Anaconda Prompt (miniconda3)** desde el menú Inicio, o PowerShell si marcaste "Add to PATH"). Verifica:

```bash
conda --version
# Esperado: conda 24.x.x

python --version
# Esperado: Python 3.12.x
```

Si los dos responden con sus versiones, la instalación está bien.

---

## Paso 4 — Crear un ambiente para el módulo

Un ambiente es una carpeta aislada con su propio Python y sus propias librerías. Creamos uno para este módulo llamado `bi-unam`:

```bash
conda create -n bi-unam python=3.12 -y
```

`-n bi-unam` nombra el ambiente; `python=3.12` fija la versión de Python; `-y` salta la confirmación interactiva.

Activa el ambiente:

```bash
conda activate bi-unam
```

Verás que el prompt de la terminal cambia para mostrar `(bi-unam)` al inicio — eso indica que el ambiente está activo. Cualquier `python`, `pip` o `conda install` que ejecutes ahora aplicará solo dentro de este ambiente.

> :information_source: **Cada vez que abras una terminal nueva**, tienes que volver a ejecutar `conda activate bi-unam` para activarlo. No es automático.

---

## Paso 5 — Instalar las librerías del módulo

Con el ambiente activo:

```bash
conda install -y pandas sqlalchemy psycopg2 jupyterlab
```

Esto instala:

- **`pandas`** — manipulación de DataFrames.
- **`sqlalchemy`** — capa de abstracción sobre el driver de PostgreSQL.
- **`psycopg2`** — driver concreto de PostgreSQL.
- **`jupyterlab`** — entorno para correr los notebooks del módulo.

> :information_source: Si conda no encuentra `psycopg2`, prueba con: `pip install psycopg2-binary`. La versión `-binary` evita compilar desde C y suele funcionar mejor cross-platform.

---

## Paso 6 — Lanzar Jupyter Lab

Con el ambiente `bi-unam` activo, ejecuta:

```bash
jupyter lab
```

Se abrirá una pestaña en tu navegador con la interfaz de Jupyter Lab. Desde ahí puedes abrir los notebooks `.ipynb` del módulo (los del Tema 04, por ejemplo) y ejecutarlos celda por celda.

Para cerrar Jupyter Lab: ve a la terminal donde lo lanzaste y presiona **Ctrl+C** dos veces.

---

## Comandos útiles de conda

| Comando | Para qué |
|---|---|
| `conda activate bi-unam` | Activar el ambiente del módulo |
| `conda deactivate` | Desactivar el ambiente actual y volver al `base` |
| `conda env list` | Listar todos los ambientes que tienes |
| `conda list` | Listar paquetes instalados en el ambiente activo |
| `conda install <paquete>` | Instalar un paquete nuevo en el ambiente activo |
| `conda env remove -n bi-unam` | Borrar el ambiente (útil si quieres empezar de cero) |

---

## Errores comunes

<details>
<summary><strong>"conda: command not found" después de instalar</strong></summary>

Casi siempre es que el instalador no actualizó tu PATH o no reiniciaste la terminal.

- **Windows:** abre **Anaconda Prompt (miniconda3)** desde el menú Inicio en vez de PowerShell.
- **macOS / Linux:** reinicia la terminal completamente (cierra la ventana y abre una nueva). Si sigue sin funcionar, ejecuta `source ~/.bashrc` (Linux) o `source ~/.zshrc` (macOS).
</details>

<details>
<summary><strong>El prompt no muestra <code>(bi-unam)</code> después de activar</strong></summary>

Algunos terminales personalizados (Oh My Zsh, Powerlevel10k, Starship) ocultan el indicador de ambiente conda. Para verificar que sí está activo:

```bash
conda info --envs
# La línea con * indica el ambiente activo
```
</details>

<details>
<summary><strong>"psycopg2 fails to build wheel" al instalar</strong></summary>

Pasa cuando conda intenta compilar `psycopg2` desde C y falta el compilador. Solución: usar la versión binaria precompilada:

```bash
conda install -y pandas sqlalchemy jupyterlab
pip install psycopg2-binary
```
</details>

<details>
<summary><strong>Jupyter Lab abre pero no encuentra las librerías del ambiente</strong></summary>

Probablemente lanzaste `jupyter lab` desde **otra** instalación de Python (la del sistema, o el `base` de conda). Verifica:

1. Que el ambiente `bi-unam` esté activo: `conda activate bi-unam`.
2. Que estés usando el Jupyter del ambiente: `which jupyter` (macOS/Linux) o `where jupyter` (Windows) — debe apuntar a una ruta dentro de `~/miniconda3/envs/bi-unam/`.
3. Si no, reinstala Jupyter en el ambiente: `conda install -n bi-unam jupyterlab`.
</details>

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="README.md">Volver a anexos</a>
</p>
