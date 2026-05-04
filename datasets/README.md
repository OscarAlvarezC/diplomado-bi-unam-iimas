# Datasets

Snapshot congelado de los datos usados en el Módulo 4. Estos archivos son **inmutables** entre semestres — congelar la versión exacta garantiza reproducibilidad de los ejercicios y resultados.

## `airbnb/`

| Archivo | Tamaño | Filas | Descripción |
|---|---|---|---|
| `listings.csv.gz` | 14 MB (59 MB descomprimido) | 27 051 | Listings detallados: name, host, location, amenidades, precio, reseñas. 79 columnas. |
| `neighbourhoods.csv` | 275 B | 16 | Las 16 alcaldías de Ciudad de México. |
| `neighbourhoods.geojson` | 335 KB | 16 | Polígonos GIS de cada alcaldía. Para Bloque 6 (JSONB). |

**Fuente:** [Inside Airbnb](http://insideairbnb.com/) — proyecto independiente de transparencia urbana.
**Snapshot:** 27 de septiembre de 2025.
**Licencia:** CC0 (dominio público).
**Importante:** Inside Airbnb publica snapshots mensuales y borra los anteriores. El snapshot de este repo es la versión canónica del módulo y no se actualiza para mantener consistencia entre semestres.

### Descomprimir el listings

```bash
gunzip -k listings.csv.gz   # -k mantiene el .gz original
```

## `northwind/`

| Archivo | Tamaño | Descripción |
|---|---|---|
| `northwind.sql` | 343 KB | Dump SQL completo de Northwind: 14 tablas, ~3 200 filas. Incluye DDL + DML. |

**Fuente:** [pthom/northwind_psql](https://github.com/pthom/northwind_psql) — adaptación a PostgreSQL del dataset clásico de Microsoft.
**Licencia:** dominio público.

### Cargar en PostgreSQL

Ver `setup/03_northwind_oltp.md` para el procedimiento completo. Resumen:

```sql
CREATE SCHEMA IF NOT EXISTS northwind_oltp;
SET search_path TO northwind_oltp;
-- ejecutar todo northwind.sql en la misma sesión
```
