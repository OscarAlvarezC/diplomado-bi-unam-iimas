# Instalar Power BI Desktop

**Power BI Desktop** es la herramienta gratuita de Microsoft para construir modelos analíticos y dashboards. Usa el motor columnar VertiPaq por debajo, lo cual permite trabajar con datasets grandes en memoria. En este módulo lo usamos para visualizar los datos del data warehouse de Northwind y conectar lo que aprendiste de modelado dimensional con una herramienta industrial.

> ⚠️ **Importante:** Power BI Desktop es una aplicación **exclusiva de Windows**. Microsoft no ofrece versión nativa para Mac ni para Linux — quien trabaje en esos sistemas necesita correr Windows en una máquina virtual gratuita. Esta guía cubre **solo opciones gratuitas**; las soluciones comerciales (Parallels Desktop, CrossOver) se mencionan al margen pero no son requeridas.

---

## :computer: Windows (el caso simple)

Tienes dos opciones gratuitas. 

### Opción 1 — Microsoft Store (recomendado)

1. Abre **Microsoft Store** desde el menú Inicio.
2. En la barra de búsqueda escribe **`Power BI Desktop`**.
3. Selecciona la app oficial de **Microsoft Corporation** y click en **Obtener** / **Instalar**.
4. Espera a que termine la descarga (~500 MB).
5. Lanza la app desde el menú Inicio.

**Ventaja:** se actualiza automáticamente cuando Microsoft publica nuevas versiones (mensualmente).

### Opción 2 — Instalador `.exe` (alternativa)

Solo si no tienes acceso a Microsoft Store (ej. Windows Server o cuentas restringidas):

1. Ve a <https://powerbi.microsoft.com/desktop/>.
2. Click en **Descargar gratis** → elige tu idioma → **Descargar**.
3. Ejecuta el `.exe` y sigue el asistente (Next → Next → Install).

**Desventaja:** tienes que actualizar manualmente cada cierto tiempo.

### Requisitos mínimos

| Componente | Mínimo recomendado |
|---|---|
| Sistema | Windows 10 versión 1809 o superior, Windows 11 |
| RAM | 2 GB (4 GB+ recomendado) |
| Disco | 1 GB libre |
| Procesador | x86/x64 de 1 GHz mínimo |
| .NET | .NET Framework 4.7.2 (lo instala solo si falta) |

---

## :apple: Mac

**Power BI Desktop NO tiene versión nativa para macOS.** Necesitas correr Windows encima de tu Mac (vía hipervisor) y dentro de Windows instalar Power BI. Las opciones gratuitas, en orden de recomendación:

> 💡 **Antes de elegir:** si la facultad tiene laboratorio con PCs Windows, o si puedes pedir prestada una laptop Windows para las sesiones de Power BI, **esa es la solución más cómoda** — evita la fricción de virtualizar. Las opciones de abajo aplican si tienes que trabajar desde tu Mac.

### Opción A — VMware Fusion Pro + Windows 11 (recomendado, gratis desde 2024)

[**VMware Fusion Pro**](https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion) es un hipervisor profesional que **Broadcom liberó como gratuito para uso personal en mayo de 2024**. Funciona en Macs con Apple Silicon (M1/M2/M3/M4) y en Macs Intel, y ofrece el **mejor rendimiento gratuito** disponible (~90% del rendimiento nativo de Windows).

1. **Crea una cuenta Broadcom gratuita** en [support.broadcom.com](https://support.broadcom.com/).
2. **Descarga VMware Fusion Pro** desde el portal de Broadcom — busca "VMware Fusion Pro" y la versión para macOS.
3. **Descarga Windows 11**:
   - Para Mac Intel: ISO x64 desde [microsoft.com/software-download/windows11](https://www.microsoft.com/software-download/windows11).
   - Para Apple Silicon: ISO ARM64 — sigue las instrucciones de la [guía VMware para Windows ARM](https://docs.vmware.com/).
4. **Crea una nueva VM** en VMware Fusion apuntando a la ISO. Asigna **al menos 4 GB de RAM y 60 GB de disco**; idealmente 8 GB de RAM si vas a trabajar con datasets medianos.
5. **Instala Windows** en la VM (~30 min). Elige "no tengo clave de producto" — Windows funciona en modo evaluación indefinidamente con watermark, suficiente para el curso.
6. **Dentro de Windows**, instala Power BI Desktop con las instrucciones de la sección de Windows.

### Opción B — UTM + Windows 11 (alternativa, gratis)

[**UTM**](https://mac.getutm.app/) es un hipervisor gratuito y open-source basado en QEMU. Funciona en Apple Silicon y en Intel. Más fácil de instalar que VMware (no requiere cuenta Broadcom), pero el **rendimiento es notablemente menor** (~50-70% del rendimiento nativo Windows). Power BI Desktop sí funciona, pero las queries DAX pueden tardar 2-3× más que en Windows nativo y la UI puede sentirse "lenta".

1. **Descarga UTM gratis** desde [mac.getutm.app](https://mac.getutm.app/) (click en **Download** directo, no en el botón de Mac App Store que es donación opcional).
2. **Descarga Windows 11**:
   - Para Mac Intel: ISO x64 desde [microsoft.com/software-download/windows11](https://www.microsoft.com/software-download/windows11).
   - Para Apple Silicon: ISO ARM64. Sigue la [guía oficial de UTM para Windows](https://docs.getutm.app/guides/windows/).
3. **Crea una nueva VM** en UTM: New → Virtualize → Windows → selecciona la ISO descargada → asigna **al menos 4 GB de RAM y 40 GB de disco**.
4. **Instala Windows** y luego Power BI Desktop dentro, igual que en la Opción A.

**Cuándo elegir UTM en vez de VMware:** si no quieres crear cuenta Broadcom, o si tu uso de Power BI va a ser ligero (ejercicios con datasets de cientos/miles de filas, no millones).

### Opción C — VirtualBox + Windows (alternativa para Mac Intel)

[**VirtualBox**](https://www.virtualbox.org/) es la opción tradicional. En Mac Intel funciona bien; en Apple Silicon su soporte sigue siendo "developer preview" desde la versión 7.1 — funcional pero menos maduro que UTM o VMware Fusion.

| Tipo de Mac | VirtualBox |
|---|---|
| Mac Intel | ✅ Funciona bien, alternativa válida a VMware Fusion |
| Mac Apple Silicon | ⚠️ "Developer preview" desde 7.1 — usable pero menos pulido que UTM/VMware |

1. Descarga el `.dmg` para macOS desde [virtualbox.org/wiki/Downloads](https://www.virtualbox.org/wiki/Downloads).
2. Instala el `.dmg` (puede pedirte autorizar en *Configuración → Privacidad y seguridad*).
3. Descarga la ISO de Windows 11 (mismo link que en las opciones anteriores).
4. Crea una nueva VM en VirtualBox apuntando a la ISO, asigna **mínimo 4 GB de RAM y 40 GB de disco**.
5. Instala Windows y Power BI Desktop dentro.

### Opción D — Boot Camp (solo Macs Intel, gratis)

Si tu Mac es **Intel** (no M1/M2/M3/M4), puedes instalar Windows en una partición separada usando **Boot Camp Assistant** (incluido gratis en macOS). Requiere reiniciar para cambiar de SO. **No funciona en Apple Silicon.** Más rápido que una VM porque Windows corre nativo, pero menos cómodo (no puedes tener macOS y Windows abiertos a la vez).

### Tabla comparativa rápida — Mac

| Opción | Apple Silicon | Mac Intel | Performance vs Windows nativo | Costo |
|---|:---:|:---:|:---:|:---:|
| **VMware Fusion Pro** | ✅ | ✅ | ~90% | Gratis (desde 2024) |
| **UTM** | ✅ | ✅ | ~50-70% | Gratis |
| **VirtualBox** | ⚠️ preview | ✅ | ~40-70% | Gratis |
| **Boot Camp** | ❌ | ✅ | ~100% (nativo) | Gratis |

**Recomendación general:**

- **Apple Silicon** → VMware Fusion Pro (Opción A). Si no quieres crear cuenta Broadcom, UTM (Opción B).
- **Mac Intel** → VMware Fusion Pro, VirtualBox, o Boot Camp si necesitas máximo rendimiento.
- **No quieres lidiar con VMs** → pide prestada una laptop Windows o usa el laboratorio de la facultad.

---

## :penguin: Linux

**Power BI Desktop tampoco tiene versión nativa para Linux.** Las opciones gratuitas:

### Opción A — VirtualBox + Windows (recomendado, gratuito)

[**VirtualBox**](https://www.virtualbox.org/) es un hipervisor gratuito y open-source mantenido por Oracle. Funciona en Ubuntu, Fedora, Debian, Arch, etc.

1. **Instala VirtualBox** desde el gestor de paquetes de tu distro:
   - **Ubuntu/Debian:** `sudo apt install virtualbox`
   - **Fedora:** `sudo dnf install VirtualBox`
   - **Arch:** `sudo pacman -S virtualbox`
2. **Descarga Windows 11 ISO** desde [microsoft.com/software-download/windows11](https://www.microsoft.com/software-download/windows11). Es legalmente descargable de forma gratuita.
3. **Crea una nueva VM** en VirtualBox apuntando a la ISO. Asigna **mínimo 4 GB de RAM y 50 GB de disco** para que Power BI funcione cómodamente.
4. **Instala Windows en la VM** (~30 min). Cuando pida la clave de producto, elige "no tengo clave" — Windows funciona en modo evaluación indefinidamente con watermark, suficiente para el curso.
5. **Dentro de Windows**, instala Power BI Desktop siguiendo las instrucciones de la sección de Windows.

**Funciona en:** cualquier procesador x86/x64. Si tu Linux corre en ARM (Raspberry Pi, etc.), VirtualBox no soporta ese caso — tendrías que usar otro hipervisor como QEMU (Opción B) o pedir prestada una laptop Windows.

### Opción B — KVM/QEMU + Windows (avanzado, gratuito)

Si ya usas **KVM** o **QEMU** como tu hipervisor nativo de Linux, puedes crear una VM Windows exactamente igual que con VirtualBox pero con mejor rendimiento. Si nunca has tocado KVM/virt-manager, es más laborioso de configurar — quédate con VirtualBox.

```bash
# Ubuntu/Debian, ejemplo rápido:
sudo apt install qemu-kvm virt-manager
# Luego abre virt-manager → New VM → apunta a la ISO de Windows
```

> 💡 **Mención al margen:** [VMware Workstation Player](https://www.vmware.com/products/workstation-player.html) es gratis para uso personal/no comercial — alternativa válida a VirtualBox si te llevas mejor con su interfaz. [Wine](https://www.winehq.org/) ejecuta apps Windows sin VM, pero **Power BI Desktop no funciona bien en Wine** (reportes mixtos y falla en operaciones complejas) — no se recomienda.

---

## :white_check_mark: Verificación

Cuando lo tengas instalado (en Windows directamente o dentro de una VM), abre Power BI Desktop y verifica lo siguiente:

1. **La app abre sin errores** y muestra la pantalla de bienvenida.
2. **Click en `Obtener datos` → `Más…`** y verifica que aparece **PostgreSQL Database** en la lista de orígenes.
3. **No hace falta conectarse todavía** — solo confirma que el conector está disponible. Si está, vas a poder conectar tu Aurora más adelante.

Si todo lo anterior funciona, Power BI Desktop está listo para los ejercicios del módulo.

---

## :wrench: Errores comunes

<details>
<summary><strong>Microsoft Store no abre o aparece error al descargar</strong></summary>

Reinicia Microsoft Store: abre PowerShell como administrador y ejecuta:
```
wsreset.exe
```
Espera a que la Store se relance sola y vuelve a intentar.

Si persiste, usa la Opción 2 (instalador `.exe` directo).
</details>

<details>
<summary><strong>Power BI Desktop tarda mucho en abrir la primera vez</strong></summary>

Es normal. La primera apertura inicializa servicios internos (especialmente la VertiPaq engine) y puede tardar 1-2 minutos. Las aperturas siguientes son mucho más rápidas (~10 segundos).
</details>

<details>
<summary><strong>En una VM con Windows, Power BI corre muy lento</strong></summary>

Tres causas comunes:

1. **Poca RAM asignada a la VM.** Asigna al menos 4 GB; idealmente 6-8 GB. Power BI necesita memoria para la VertiPaq columnar.
2. **CPU mal configurada.** Asigna al menos 2 cores a la VM en la configuración del hipervisor.
3. **Disco lento.** Si tu Mac/Linux tiene SSD, asegúrate de que la VM esté en él (no en disco mecánico externo). El I/O de Power BI es intensivo al cargar `.pbix`.
</details>

<details>
<summary><strong>Power BI pide cuenta Microsoft al abrir</strong></summary>

**No es obligatorio** para usar Power BI Desktop. Puedes cerrar ese diálogo y trabajar localmente con archivos `.pbix`. La cuenta solo es necesaria si quieres publicar al Power BI Service (la versión web), lo cual no es requisito del módulo.
</details>

<details>
<summary><strong>La ISO de Windows pide clave de producto</strong></summary>

En la instalación, en la pantalla "Activar Windows", elige **"No tengo clave de producto"** (link pequeño abajo a la izquierda). Windows se instalará en **modo evaluación** — funciona indefinidamente, solo aparece un watermark en la esquina inferior derecha. Para uso educativo es suficiente y completamente legal.

Si después quieres activarlo gratis: muchas universidades (incluida la UNAM) ofrecen licencias de Windows gratuitas para estudiantes vía Microsoft Azure for Students. Pregunta a tu IT institucional.
</details>


<details>
<summary><strong>No tengo Windows ni puedo instalar una VM, ¿hay otra opción?</strong></summary>

Si no puedes instalar una VM en tu máquina, la alternativa más práctica es **pedir prestada una laptop Windows** o usar el **laboratorio de la facultad** durante las sesiones de Power BI.

Todas las opciones de virtualización mencionadas (VMware Fusion Pro, UTM, VirtualBox) son gratuitas y consumen recursos moderados — con 4 GB de RAM libre y un SSD razonable, funcionan. Si tu hardware no da para eso, la PC prestada es lo más realista.
</details>

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="README.md">Volver a anexos</a>
</p>
