# Anexos

Material de referencia transversal al módulo — no pertenece a un tema específico, pero se consulta a lo largo del curso.

## Contenido

- [**`glosario_aws.md`**](glosario_aws.md) — Glosario corto de los 11 servicios AWS que se mencionan a lo largo del módulo (S3, RDS, Aurora, DynamoDB, Redshift, Athena, QuickSight, EC2, Lambda, SageMaker, IAM). Cada entrada responde *¿qué es?*, *¿para qué sirve?* y *¿cuándo lo usarías?*.
- [**`glosario_bi_y_sql.md`**](glosario_bi_y_sql.md) — Glosario de términos técnicos del módulo: SQL, normalización, modelado dimensional, ETL, PostgreSQL, ACID, Aurora/clusters. Organizado por categoría temática para ver términos relacionados juntos.
- [**`instalar_power_bi.md`**](instalar_power_bi.md) — Guía de instalación de Power BI Desktop con **solo opciones gratuitas**: Windows (Microsoft Store), Mac (VMware Fusion Pro gratis desde 2024, UTM, VirtualBox, Boot Camp), Linux (VirtualBox, KVM/QEMU). Incluye tabla comparativa de rendimiento por opción.
- [**`instalar_miniconda.md`**](instalar_miniconda.md) — Guía de instalación de **Miniconda** (la versión ligera de Anaconda) para preparar el entorno Python del Tema 04. Por SO (Windows, macOS Intel/Apple Silicon, Linux), creación del ambiente `bi-unam`, instalación de `pandas`/`sqlalchemy`/`psycopg2`/`jupyterlab`, lanzamiento de Jupyter Lab, y errores comunes.
- [**`rubrica_proyecto_final.md`**](rubrica_proyecto_final.md) — Rúbrica del proyecto final: criterios de evaluación, niveles de desempeño (1-4), pesos ponderados, entregables esperados, sugerencias de datasets y calendario de hitos.
- [**`conexion_plan_b_nas.md`**](conexion_plan_b_nas.md) — Cómo conectarse al **servidor PostgreSQL de respaldo** (Plan B) cuando tu Aurora del Learner Lab no está disponible. Acceso read-only a los mismos 3 schemas (`northwind_oltp`, `northwind_dwh`, `airbnb`). Instrucciones para DBeaver, terminal (`psql`), Python y Power BI.
- [**`explorar_schemas_y_tablas.md`**](explorar_schemas_y_tablas.md) — Cómo navegar la estructura de una base PostgreSQL: listar schemas, listar tablas, ver columnas y tipos, sondear datos. Tres formas: comandos `\` de `psql`, queries SQL contra `information_schema`/`pg_catalog`, y navegador visual de DBeaver. Aplica a Aurora, Plan B o cualquier otra base PostgreSQL.
- [**`diagramas_er.md`**](diagramas_er.md) — Diagramas entidad-relación de los 3 schemas (`northwind_oltp`, `northwind_dwh`, `airbnb`) en Mermaid (GitHub los renderiza nativamente). Cubre tablas, columnas clave, FKs, y notas sobre patrones aplicados (3NF en OLTP, Kimball en DWH, bronze sin constraints en Airbnb).

---

<p align="center">
<a href="../README.md">← Volver al inicio</a>
</p>
