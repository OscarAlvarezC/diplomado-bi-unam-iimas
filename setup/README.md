# Guías de setup técnico

5 guías paso a paso que **se siguen durante las sesiones del módulo**, no como pre-trabajo. El instructor te lleva por cada una en su sesión correspondiente. Quedan acá como referencia para que las consultes durante o después de la clase.

**Las 5 guías se siguen consecutivamente durante la Sesión 01** (única sesión 100% operacional del módulo).

| # | Guía | Tiempo en clase | Resultado |
|---|---|---|---|
| 01 | [`01_cluster_aurora.md`](01_cluster_aurora.md) | ~25 min | Cluster Aurora PostgreSQL `aurora-mod4` corriendo en tu Learner Lab |
| 02 | [`02_dbeaver_conexion.md`](02_dbeaver_conexion.md) | ~25 min | DBeaver Community instalado, security group abierto, conexión validada |
| 03 | [`03_northwind_oltp.md`](03_northwind_oltp.md) | ~15 min | Schema `northwind_oltp` con 14 tablas, dataset transaccional cargado |
| 04 | [`04_northwind_dwh.md`](04_northwind_dwh.md) | ~30 min | Schema `northwind_dwh` con star schema completo (5 dims + fact, 2 155 filas) |
| 05 | [`05_airbnb.md`](05_airbnb.md) | ~30 min | Schema `airbnb` con 27 051 listings de CDMX |
| | **Total Sesión 01** | **~125 min** | Entorno completo, listo para los 15 sesiones restantes |

## Si te quedaste atrás de algún tema

Si te perdiste una sesión o se te trabó algo durante la clase, las guías son **autocontenidas** — puedes seguirlas solo en tu tiempo y emparejarte. Cada una tiene una sección **"Errores comunes"** al final que cubre los problemas más frecuentes (IP cambió, password mal copiado, etc.).

## Recordatorios operativos

- 🔴 **Pausa el cluster** cuando termines de trabajar — RDS → Stop temporarily. Cuesta ~$0.08 USD/h encendido.
- 🟢 **Reanuda + refresca SG My IP** al empezar la siguiente sesión.
- 💰 Tu crédito Learner Lab es ~$100 USD. Olvidar pausar una semana cuesta ~$13 USD.
