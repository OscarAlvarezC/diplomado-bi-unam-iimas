# Preguntas que surgieron en clase

Preguntas reales que hicieron alumnos durante las sesiones del Tema 01, con la respuesta que se discutió o se investigó después. Pensadas como complemento al material — si tienes la misma duda al seguir las guías, busca aquí primero.

---

## ¿En "Configuración express" AWS dice "Cree y consulte una base de datos sin servidor de Aurora PostgreSQL" — a qué se refiere con "sin servidor"?

"Sin servidor" es la traducción literal de **serverless**. **Sí hay servidores** — lo que cambia es que tú no los administras: AWS los provisiona, escala y libera automáticamente según la demanda real, y te cobra por uso (no por hora encendida).

En Aurora esto se llama **Aurora Serverless v2**. Las diferencias clave contra el modo **Aprovisionado** (el que usamos en este módulo):

| Aspecto | Aprovisionado | Serverless v2 |
|---|---|---|
| Tamaño | Eliges una clase de instancia (`db.t3.medium`, etc.) | No eliges tamaño — solo un rango mínimo y máximo en **ACUs** |
| Billing | Pagas por hora encendida, uses o no | Pagas por **ACUs consumidas por segundo** |
| Capacidad | Fija | Auto-escala con la carga (sube en picos, baja en valles) |
| Visibilidad | Hay una "instancia" visible en la consola | Solo el cluster; AWS multiplexa servidores internos |

Una **ACU** (Aurora Capacity Unit) equivale a ~2 GB de RAM + CPU proporcional, y cuesta ~$0.12 USD/hora. Si el cluster está en mínimo (0.5 ACU) sin tráfico, paga ~$0.06/hora; si recibe un pico que sube a 4 ACUs por 10 min, paga eso solo por esos 10 min.

**Cuándo conviene cada uno:**

- **Serverless** — cargas erráticas (picos + valles), dev/test esporádico, demos y POCs, multi-tenant SaaS.
- **Aprovisionado** — producción 24/7 con tráfico predecible (más barato a uso constante), entornos donde quieres costo fijo predecible.

**¿Por qué no usamos Serverless en este módulo?** El AWS Academy Learner Lab **bloquea Aurora Serverless v2** por política. En producción real fuera del Learner Lab sí podrías elegirlo libremente. Esa restricción está documentada en el `<details>` "¿Aprovisionado vs Serverless?" dentro de [`setup/01_cluster_aurora.md`](../setup/01_cluster_aurora.md).

**Analogía:** Aprovisionado es como **rentar un coche fijo todo el año** — siempre disponible, siempre te cuesta. Serverless es como **usar Uber/Didi cuando lo necesitas** — pides cuando hace falta, pagas el viaje. Los autos siguen existiendo; cambia tu relación con ellos.

---

<p align="center">
<a href="Readme.md">← Volver al índice del Tema 01</a>
</p>
