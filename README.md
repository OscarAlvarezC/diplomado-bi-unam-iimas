# Diplomado de Inteligencia de Negocios y SQL Avanzado — IIMAS / UNAM

Material de soporte para el **Módulo 4** del Diplomado en alianza con AWS Academy. Contiene los datasets congelados, los scripts SQL de construcción del data warehouse y las guías paso a paso para que cada alumno configure su entorno desde cero.

## Para empezar

Si eres alumno del módulo, abre **`setup/01_cluster_aurora.md`** y sigue las 5 guías en orden. En ~2 horas tendrás todo el entorno listo.

```
setup/
├── 01_cluster_aurora.md       Crear cluster Aurora PostgreSQL en Learner Lab
├── 02_dbeaver_conexion.md     Instalar DBeaver y conectar
├── 03_northwind_oltp.md       Cargar Northwind transaccional
├── 04_northwind_dwh.md        Construir el data warehouse (star schema)
└── 05_airbnb.md               Cargar Airbnb CDMX
```

## Contenido del repo

```
diplomado-bi-unam-iimas/
├── README.md                   ← este archivo
├── LICENSE                     ← MIT (código y guías)
│
├── setup/                      ← guías paso a paso para alumnos
│
├── datasets/                   ← snapshot congelado de los datos
│   ├── airbnb/                 (Inside Airbnb CDMX, snapshot 2025-09-27, CC0)
│   │   ├── listings.csv.gz
│   │   ├── neighbourhoods.csv
│   │   └── neighbourhoods.geojson
│   └── northwind/
│       └── northwind.sql       (Northwind PostgreSQL dump, dominio público)
│
└── scripts/                    ← SQL ejecutable, en orden
    ├── 01_northwind_dwh_ddl.sql       Crear el star schema (5 dims + fact)
    ├── 02_dim_date_populate.sql       Generar dim_date con generate_series
    ├── 03_dims_populate.sql           Poblar las 4 dims OLTP-derivadas
    ├── 04_fact_populate.sql           Poblar fact_sales (resolución de surrogate keys)
    └── 05_airbnb_ddl.sql              Crear schema y tablas para Airbnb CDMX
```

## Datos: orígenes y atribución

### Northwind

Dataset clásico de demostración de Microsoft (público, sin restricciones). Versión adaptada para PostgreSQL: [pthom/northwind_psql](https://github.com/pthom/northwind_psql).

### Airbnb CDMX

Snapshot del **27 de septiembre de 2025** publicado por [Inside Airbnb](http://insideairbnb.com/) — proyecto independiente de transparencia urbana, **no afiliado a Airbnb la empresa**. Datos liberados bajo **CC0** (dominio público). Inside Airbnb publica snapshots mensuales y borra los anteriores; este repo congela la versión usada en el módulo para reproducibilidad entre semestres.

Más información sobre Inside Airbnb: <http://insideairbnb.com/about/>.

## Licencia

- **Scripts SQL, guías de setup y código en general:** MIT (ver `LICENSE`).
- **Datasets:** licencias originales de cada fuente (CC0 para Inside Airbnb, dominio público para Northwind).

## Contexto académico

Curso impartido por **Oscar Alvarez** en el **Instituto de Investigaciones en Matemáticas Aplicadas y en Sistemas (IIMAS)** de la UNAM, en alianza con AWS Academy. Las decisiones técnicas (Aurora PostgreSQL Provisioned `db.t3.medium`, DBeaver Community, ETL en Python con SQLAlchemy + pandas) responden a las restricciones del Educator Learner Lab y a un enfoque pedagógico de profundidad sobre amplitud.

## Reportar problemas

Si encuentras errores en las guías, scripts o datos, abre un issue en este repo o avisa en clase.
