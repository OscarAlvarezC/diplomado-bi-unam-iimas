# Sesión 01: Fundamentos OLAP — OLTP vs OLAP y modelo multidimensional

## :dart: Objetivo

Reconocer las diferencias entre sistemas transaccionales (OLTP) y analíticos (OLAP), entender por qué el análisis de negocios requiere un modelado distinto de los datos, y dominar el vocabulario fundamental del modelo multidimensional. **Al cierre de la sesión cada alumno tiene su entorno técnico operacional** (cluster Aurora corriendo y DBeaver conectado).

## :clock1: Duración

2.5 horas.

## :wrench: Setup técnico en vivo (~60 min)

Primera mitad de la sesión, se hace en vivo siguiendo las guías:

- [`../setup/01_cluster_aurora.md`](../setup/01_cluster_aurora.md) — crear cluster Aurora PostgreSQL en el Learner Lab personal.
- [`../setup/02_dbeaver_conexion.md`](../setup/02_dbeaver_conexion.md) — instalar DBeaver, abrir security group "My IP", conectar.

## :pushpin: Temas (~90 min)

- Diferencias OLTP vs OLAP: carga de trabajo, schema, propósito.
- Por qué la normalización en 3NF es ideal para escrituras pero limitante para análisis.
- Modelo multidimensional: la geometría de los datos analíticos.
- Hechos: eventos medibles del negocio.
- Dimensiones: contexto descriptivo (quién, qué, cuándo, dónde).
- Concepto de **grano** y por qué es la primera decisión a tomar.

## :books: Material

> Por publicar.
