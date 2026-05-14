# Anexos

Material de referencia transversal al módulo — no pertenece a un tema específico, pero se consulta a lo largo del curso.

## Contenido

- [**`glosario_aws.md`**](glosario_aws.md) — Glosario corto de los 11 servicios AWS que se mencionan a lo largo del módulo (S3, RDS, Aurora, DynamoDB, Redshift, Athena, QuickSight, EC2, Lambda, SageMaker, IAM). Cada entrada responde *¿qué es?*, *¿para qué sirve?* y *¿cuándo lo usarías?*.
- [**`instalar_power_bi.md`**](instalar_power_bi.md) — Guía de instalación de Power BI Desktop con **solo opciones gratuitas**: Windows (Microsoft Store), Mac (VMware Fusion Pro gratis desde 2024, UTM, VirtualBox, Boot Camp), Linux (VirtualBox, KVM/QEMU). Incluye tabla comparativa de rendimiento por opción.
- [**`rubrica_proyecto_final.md`**](rubrica_proyecto_final.md) — Rúbrica del proyecto final: criterios de evaluación, niveles de desempeño (1-4), pesos ponderados, entregables esperados, sugerencias de datasets y calendario de hitos.
- [**`conexion_plan_b_nas.md`**](conexion_plan_b_nas.md) — Cómo conectarse al **servidor PostgreSQL de respaldo** (Plan B) cuando tu Aurora del Learner Lab no está disponible. Acceso read-only a los mismos 3 schemas (`northwind_oltp`, `northwind_dwh`, `airbnb`). Instrucciones para DBeaver, terminal (`psql`), Python y Power BI.
- [**`explorar_schemas_y_tablas.md`**](explorar_schemas_y_tablas.md) — Cómo navegar la estructura de una base PostgreSQL: listar schemas, listar tablas, ver columnas y tipos, sondear datos. Tres formas: comandos `\` de `psql`, queries SQL contra `information_schema`/`pg_catalog`, y navegador visual de DBeaver. Aplica a Aurora, Plan B o cualquier otra base PostgreSQL.

---

<p align="center">
<a href="../README.md">← Volver al inicio</a>
</p>
