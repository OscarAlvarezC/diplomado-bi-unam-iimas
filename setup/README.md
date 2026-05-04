# Setup paso a paso

5 guías secuenciales para configurar tu entorno desde cero. Sigue las 5 en orden — cada una asume que la anterior está completa.

| # | Guía | Tiempo | Resultado |
|---|---|---|---|
| 01 | [`01_cluster_aurora.md`](01_cluster_aurora.md) | ~30 min | Cluster Aurora PostgreSQL `aurora-mod4` corriendo en tu Learner Lab |
| 02 | [`02_dbeaver_conexion.md`](02_dbeaver_conexion.md) | ~25 min | DBeaver Community instalado, security group abierto, conexión validada |
| 03 | [`03_northwind_oltp.md`](03_northwind_oltp.md) | ~20 min | Schema `northwind_oltp` con 14 tablas, dataset transaccional cargado |
| 04 | [`04_northwind_dwh.md`](04_northwind_dwh.md) | ~40 min | Schema `northwind_dwh` con star schema completo (5 dims + fact, 2 155 filas) |
| 05 | [`05_airbnb.md`](05_airbnb.md) | ~30 min | Schema `airbnb` con 27 051 listings de CDMX |
| | **Total** | **~2.5 h** | Entorno completo, listo para los 7 bloques del módulo |

## Si algo falla

Cada guía tiene una sección **"Errores comunes"** al final con causas y fixes concretos. Revísala antes de pedir ayuda — la mayoría de problemas (IP cambió, password mal copiado, schema en `public` por error) están cubiertos.

## Recordatorios operativos

- 🔴 **Pausa el cluster** cuando termines de trabajar — RDS → Stop temporarily. Cuesta ~$0.08 USD/h encendido.
- 🟢 **Reanuda + refresca SG My IP** al empezar la siguiente sesión.
- 💰 Tu crédito Learner Lab es ~$100 USD. Olvidar pausar una semana cuesta ~$13 USD.
