# Rúbrica del proyecto final

El proyecto final del módulo consiste en entregar una **solución analítica completa** sobre un problema de tu elección. Integra todas las técnicas vistas en el curso: modelado dimensional, infraestructura en AWS, ETL en Python, SQL avanzado y visualización. La idea es que apliques el flujo de un proyecto de BI real, desde la pregunta de negocio hasta el dashboard.

> :bulb: **¿Necesitas un ejemplo?** Revisa [`ejemplo_proyecto_final/`](ejemplo_proyecto_final/README.md) — un proyecto completo sobre la calidad del aire en CDMX (SIMAT 2023) que cubre los siete criterios de esta rúbrica con su informe, scripts SQL, ETL Python y dashboard Streamlit.

## :dart: Objetivo

Demostrar capacidad para:

- Plantear una pregunta analítica de valor sobre un dominio que te interese.
- Diseñar un modelo dimensional (estrella) adecuado a esa pregunta.
- Implementar la infraestructura en AWS (Aurora PostgreSQL).
- Construir un proceso ETL en Python que transforme datos crudos en el modelo dimensional.
- Aplicar SQL avanzado en alguna parte del flujo (ETL o consultas analíticas).
- Comunicar los hallazgos en un dashboard interactivo.

## :file_folder: Componentes obligatorios

| # | Componente | Qué debe contener |
|---|---|---|
| 1 | **Problema y dataset** | Pregunta analítica clara + dataset elegido (público o propio), con justificación de por qué el dataset permite responder la pregunta |
| 2 | **Modelo dimensional** | Diagrama del esquema estrella con hechos, dimensiones y grano explícito + DDL de las tablas |
| 3 | **Implementación AWS** | Cluster Aurora con el modelo cargado y accesible (puede ser el mismo `aurora-mod4` del módulo o uno nuevo) |
| 4 | **ETL en Python** | Script `etl_pipeline.py` ejecutable de extremo a extremo (Extract → Transform → Load) con `pandas` + `SQLAlchemy` |
| 5 | **SQL avanzado** | Uso real de al menos **dos** de las técnicas vistas: funciones de ventana, CTE (simples o recursivas), funciones predefinidas no triviales, procedimientos/funciones, datos semi-estructurados con JSONB. Pueden estar dentro del ETL o en las consultas analíticas del dashboard |
| 6 | **Dashboard** | Mínimo **tres visualizaciones** que respondan la pregunta analítica. Herramienta libre: Power BI Desktop, Excel, Python (Streamlit/Dash/Plotly), R (Shiny), Tableau, etc. |
| 7 | **Documentación** | `README.md` que explique el problema, el modelo, cómo ejecutar el ETL, y cómo abrir el dashboard. Incluir un breve análisis de los hallazgos (1-2 párrafos) |

## :package: Entregables

Repositorio (GitHub, GitLab o ZIP entregado por correo) con la siguiente estructura sugerida:

```
proyecto-final/
├── README.md                    ← problema, modelo, cómo ejecutar, hallazgos
├── datasets/                    ← datos crudos (o link de descarga si son grandes)
├── scripts/
│   ├── 01_schema_ddl.sql        ← creación del modelo dimensional
│   └── etl_pipeline.py          ← script ETL completo
├── dashboard/                   ← archivo del dashboard (.pbix, .twbx, .py, .R, .xlsx)
└── docs/
    └── diagrama_modelo.png      ← diagrama del esquema estrella
```

## :clipboard: Rúbrica de evaluación

Siete criterios, **todos con el mismo peso** (1/7 cada uno). Cada criterio se califica en escala de **1 a 4** según los descriptores de cada nivel. La calificación final es el promedio simple de los siete criterios.

### Criterio 1 — Problema y dataset

| Nivel | Descriptor |
|---|---|
| **Excelente (4)** | Pregunta analítica de negocio bien planteada, accionable, con relevancia clara. Dataset apropiado en tamaño (~10k filas o más) y permite responder la pregunta. Justificación sólida del por qué |
| **Bueno (3)** | Pregunta clara y dataset razonable, aunque la pregunta podría ser más específica o el dataset un poco chico |
| **Suficiente (2)** | Pregunta entendible pero genérica; dataset funciona pero está sub-utilizado |
| **Insuficiente (1)** | Pregunta vaga o trivial ("¿cuántas filas hay?"), dataset inadecuado o demasiado simple |

### Criterio 2 — Modelo dimensional

| Nivel | Descriptor |
|---|---|
| **Excelente (4)** | Esquema estrella correcto con grano declarado, fact con FKs y medidas bien elegidas, dimensiones con surrogate + natural keys y atributos relevantes. Decisiones de diseño documentadas (por qué este grano, qué desnormalizaciones se hicieron, etc.) |
| **Bueno (3)** | Estrella correcta pero con decisiones poco fundamentadas o alguna dimensión sub-explotada |
| **Suficiente (2)** | Modelo funciona pero tiene problemas: grano ambiguo, FKs faltantes, atributos sin valor analítico |
| **Insuficiente (1)** | No es esquema estrella (queda en 3NF o caos); o no hay separación fact/dim |

### Criterio 3 — Implementación AWS

| Nivel | Descriptor |
|---|---|
| **Excelente (4)** | Cluster Aurora corriendo, modelo cargado, esquema separado del OLTP si aplica, acceso documentado. Buenas prácticas de naming y conectividad |
| **Bueno (3)** | Cluster + modelo cargados; algún detalle de conectividad o naming descuidado |
| **Suficiente (2)** | El modelo está en AWS pero con problemas operativos (sin acceso reproducible, credenciales en código, etc.) |
| **Insuficiente (1)** | No hay implementación en AWS; modelo solo local |

### Criterio 4 — ETL en Python

| Nivel | Descriptor |
|---|---|
| **Excelente (4)** | Pipeline modular con funciones separadas para Extract/Transform/Load, `main()` orquestador, logging básico, manejo de errores, validaciones post-carga (conteos vs origen, integridad referencial). Idempotente (se puede re-correr sin duplicar datos) |
| **Bueno (3)** | Pipeline estructurado y funcional, pero sin logging o sin validaciones post-carga |
| **Suficiente (2)** | Script funciona end-to-end pero es monolítico, sin separación clara de fases ni manejo de errores |
| **Insuficiente (1)** | El ETL no corre completo o tiene errores que el alumno no detectó; pasos manuales no documentados |

### Criterio 5 — SQL avanzado

| Nivel | Descriptor |
|---|---|
| **Excelente (4)** | Uso pertinente de **tres o más** técnicas (window functions, CTE, funciones predefinidas no triviales, JSONB, procedimientos). Las queries resuelven preguntas reales del problema, no son ejercicios sintéticos |
| **Bueno (3)** | Dos técnicas bien aplicadas; alguna podría ser más profunda |
| **Suficiente (2)** | Dos técnicas, pero al menos una se siente forzada o decorativa |
| **Insuficiente (1)** | Una sola técnica o ninguna; queries básicas que pudieron haberse hecho en pandas |

### Criterio 6 — Dashboard

| Nivel | Descriptor |
|---|---|
| **Excelente (4)** | Mínimo 3 visualizaciones bien elegidas para la pregunta analítica, interactivas (filtros, drill-down, slicers), narrativa coherente, diseño limpio. El dashboard "cuenta una historia" |
| **Bueno (3)** | 3 visualizaciones correctas pero faltó pulir interactividad o narrativa |
| **Suficiente (2)** | Cumple el mínimo de 3 viz, pero son básicas o no aprovechan el modelo dimensional |
| **Insuficiente (1)** | Menos de 3 viz, o viz que no responden la pregunta planteada |

### Criterio 7 — Documentación

| Nivel | Descriptor |
|---|---|
| **Excelente (4)** | `README.md` claro: planteamiento, diagrama del modelo, pasos de ejecución, hallazgos. Código comentado donde el contexto lo amerita. Cualquier persona puede reproducir el proyecto |
| **Bueno (3)** | `README.md` cubre lo esencial pero le falta algún paso o claridad |
| **Suficiente (2)** | Documentación mínima, hay que adivinar pasos |
| **Insuficiente (1)** | Sin documentación o con instrucciones que no funcionan |

## :triangular_ruler: Cálculo de la calificación final

Cada criterio se califica en escala de **1 a 4**. La calificación final es el promedio simple de los siete criterios, escalado a base 100:

$$\text{Calificación} = \frac{\sum_{i=1}^{7} \text{nivel}_i}{7} \times 25$$

Por ejemplo, si obtuviste niveles `[4, 3, 3, 4, 3, 4, 3]`, la calificación es `(24 / 7) × 25 ≈ 85.7`.

| Resultado | Interpretación |
|---|---|
| 90 - 100 | Sobresaliente — listo para portafolio profesional |
| 80 - 89 | Muy bueno — domina la metodología |
| 70 - 79 | Aprobado — cumple los objetivos con áreas de mejora |
| < 70 | Insuficiente — revisar y reentregar |

## :bulb: Sugerencias de problemas / datasets

Si no tienes idea sobre qué construir, aquí van detonadores. **No son obligatorios** — lo importante es que el dataset te interese:

| Dominio | Ejemplos de pregunta | Dataset sugerido |
|---|---|---|
| **Movilidad CDMX** | ¿Cómo varía la disponibilidad de Ecobici por hora y alcaldía? | API de Ecobici / Datos Abiertos CDMX |
| **Spotify personal** | ¿Cómo evolucionó mi gusto musical en los últimos 3 años? | Extended streaming history de Spotify (descargas tu data) |
| **Sismicidad** | ¿Qué patrones temporales hay en los sismos de México? | Catálogo del Servicio Sismológico Nacional |
| **Calidad del aire** | ¿Qué contaminantes correlacionan con clima en CDMX? | Datos Abiertos CDMX (RAMA) |
| **Películas / series** | ¿Qué predice un rating alto en IMDb? | IMDb datasets públicos |
| **Cripto / finanzas** | Patrones de volumen vs precio en BTC/ETH | API de Binance o Yahoo Finance |
| **Ventas tu negocio** | Si tienes acceso a datos reales de un negocio propio o familiar | Datos anonimizados |
| **Datos open gov** | Gasto público, contrataciones, programas sociales | datos.gob.mx |
| **Salud pública** | COVID, vacunación, mortalidad por estado | INEGI, DGE |

La regla: **dataset con al menos ~10,000 filas, que tenga al menos una dimensión temporal** (para que SQL avanzado de ventana tenga sentido), y que la pregunta sea **descriptiva o exploratoria** (no predictiva — eso es otro curso).

## :calendar: Calendario sugerido

Para evitar dejar el proyecto al final, organiza tus entregables como hitos parciales. Sugerencia (ajustable a las fechas reales del módulo):

| Hito | Cuándo | Qué entregas |
|---|---|---|
| **Propuesta** | A mitad del módulo | Pregunta + dataset elegido + diagrama del modelo dimensional preliminar |
| **Avance ETL** | 2 semanas antes del cierre | Pipeline corriendo end-to-end con datos cargados a AWS |
| **Entrega final** | Fecha de cierre | Todo el repo + dashboard + presentación de 5-10 min |

## :memo: Notas finales

- **No copies un proyecto de internet.** El valor del ejercicio es pasar por todas las decisiones de diseño tú mismo. Inspirarte sí, copiar no.
- **El dataset no necesita ser exótico.** Un análisis claro y bien hecho sobre Northwind (extendiendo lo que ya hicimos en clase) puede ser excelente. Lo que se evalúa es el dominio de la metodología, no la originalidad del dataset.
- **Si el dataset es pesado**, no lo subas al repo — pon un script que lo descargue de la fuente original.
- **El dashboard puede ser sencillo visualmente**, lo que se evalúa es que las visualizaciones respondan la pregunta planteada y aprovechen el modelo dimensional (ej. usar las dimensiones como filtros, las medidas como ejes Y).

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="README.md">Volver a anexos</a>
</p>
