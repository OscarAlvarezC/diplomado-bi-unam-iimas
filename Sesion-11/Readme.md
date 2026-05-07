# Sesión 11: PL/pgSQL — Procedimientos almacenados y funciones definidas

## :dart: Objetivo

Crear, ejecutar y gestionar procedimientos almacenados y funciones definidas por el usuario en PostgreSQL, entendiendo las diferencias prácticas entre ambos.

## :pushpin: Temas

- **Procedimientos almacenados:**
  - `CREATE PROCEDURE`.
  - Parámetros `IN`, `OUT`, `INOUT`.
  - Ejecución con `CALL`.
  - Eliminación con `DROP PROCEDURE`.
  - Casos de uso: efectos secundarios, transacciones explícitas.
- **Funciones definidas por el usuario:**
  - `CREATE FUNCTION` con `RETURNS`.
  - Funciones que devuelven escalares (`RETURNS NUMERIC`, etc.).
  - Funciones que devuelven sets (`RETURNS TABLE`, `RETURNS SETOF`).
  - Volatilidad: `IMMUTABLE`, `STABLE`, `VOLATILE`.
- **Procedimiento vs función — cuándo elegir cada uno:**
  - Funciones: cómputo determinista, usables en `SELECT`, pueden formar parte de queries.
  - Procedimientos: efectos secundarios, control de transacciones, no usables en queries.
- Casos prácticos sobre el DW: función para calcular ventas netas por categoría/periodo, procedimiento para refrescar agregados, etc.

## :books: Material

> Por publicar.

---

[← Volver al inicio](../README.md) | [Siguiente: Sesión 12 →](../Sesion-12/Readme.md)
