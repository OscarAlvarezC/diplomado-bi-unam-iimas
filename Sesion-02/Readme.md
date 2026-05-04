# Sesión 02: Esquemas dimensionales — estrella, copo de nieve, galaxy

## :dart: Objetivo

Diferenciar los tres patrones de modelado dimensional, entender los trade-offs entre normalización y desnormalización en un contexto analítico, y aplicar el patrón estrella al diseño en papel del data warehouse de Northwind. **Al cierre cada alumno tiene Northwind OLTP cargado** y listo para construir el DW en la siguiente sesión.

## :clock1: Duración

2.5 horas.

## :wrench: Setup técnico en vivo (~30 min)

Primera media hora, hands-on en clase:

- [`../setup/03_northwind_oltp.md`](../setup/03_northwind_oltp.md) — descargar el dump y cargar Northwind OLTP (14 tablas) usando `SET search_path` para dirigir al schema correcto.

## :pushpin: Temas (~120 min)

- **Esquema estrella (star schema)** — el patrón canónico de Kimball: hecho central + dimensiones planas.
- **Esquema copo de nieve (snowflake)** — variante normalizada y por qué Kimball lo desaconseja.
- **Constelación / galaxy** — múltiples tablas de hechos compartiendo dimensiones.
- Trade-off **espacio vs velocidad de lectura** en analítica.
- **Caso de estudio práctico:** diseñar en papel el star schema de Northwind antes de implementarlo en SQL en la siguiente sesión.

## :books: Material

> Por publicar.
