# Sesión 14: Datos semiestructurados I — hstore

## :dart: Objetivo

Modelar y consultar datos clave-valor planos con la extensión `hstore` de PostgreSQL, y aplicar indexación GIN para optimizar queries sobre estos datos.

## :pushpin: Temas

- **Por qué datos semi-estructurados:** el problema de schemas que cambian por entidad (e.g., propiedades de productos heterogéneos, atributos de usuarios).
- **Habilitación de la extensión** `hstore`.
- **Tipo de datos `hstore`:** sintaxis literal, parsing.
- **Almacenamiento en una sola columna** vs columnas separadas — trade-offs.
- **Operadores y funciones:**
  - `->` (acceso a valor).
  - `->>` (acceso como texto).
  - `||` (concatenación / merge).
  - `?` (existencia de key).
  - `?&`, `?|` (existencia de múltiples keys).
- **Funciones útiles:** `hstore_to_array`, `each`, `keys`, `values`.
- **Indexación con GIN:** cómo funciona, cuándo aporta, costo de mantenimiento.

## :books: Material

> Por publicar.

---

<p align="center">
<a href="../README.md">← Volver al inicio</a> | <a href="../Sesion-15/Readme.md">Siguiente: Sesión 15 →</a>
</p>
