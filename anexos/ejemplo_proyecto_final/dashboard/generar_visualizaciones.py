"""
Genera las 4 visualizaciones del proyecto como PNG estáticas con matplotlib.

Si la variable de entorno AURORA_HOST está definida, ejecuta las queries reales
contra el cluster. Si no, usa datos sintéticos coherentes con los patrones
documentados del SIMAT — útil para previsualizar el resultado sin necesidad
de conexión a Aurora.

Uso:
    export AURORA_HOST=aurora-mod4.cluster-XXX.us-east-1.rds.amazonaws.com
    export AURORA_PASSWORD=tu_password
    python generar_visualizaciones.py

Salida: dashboard/img/{01_mapa, 02_serie_mensual, 03_top_estaciones, 04_heatmap}.png
"""

import os
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

OUT = Path(__file__).parent / "img"
OUT.mkdir(exist_ok=True)

# =============================================================================
# Datos: o desde Aurora, o sintéticos
# =============================================================================

USE_AURORA = bool(os.environ.get("AURORA_HOST"))

ESTACIONES = [
    ("ACO", "Acolman",                 19.635,  -98.912),
    ("AJM", "Ajusco Medio",            19.272,  -99.207),
    ("BJU", "Benito Juárez",           19.371,  -99.158),
    ("CAM", "Camarones",               19.468,  -99.169),
    ("CCA", "Centro Ciencias Atm",     19.326,  -99.176),
    ("CHO", "Chalco",                  19.266,  -98.886),
    ("COY", "Coyoacán",                19.350,  -99.158),
    ("CUA", "Cuajimalpa",              19.365,  -99.293),
    ("FAC", "FES Acatlán",             19.483,  -99.244),
    ("GAM", "Gustavo A. Madero",       19.491,  -99.094),
    ("HGM", "Hospital General",        19.412,  -99.152),
    ("IZT", "Iztacalco",               19.384,  -99.117),
    ("MER", "Merced",                  19.424,  -99.119),
    ("MGH", "Miguel Hidalgo",          19.404,  -99.202),
    ("NEZ", "Nezahualcóyotl",          19.395,  -99.028),
    ("PED", "Pedregal",                19.325,  -99.204),
    ("SAG", "San Agustín",             19.532,  -99.030),
    ("SFE", "Santa Fe",                19.357,  -99.262),
    ("TLA", "Tlalnepantla",            19.529,  -99.205),
    ("UAX", "UAM Xochimilco",          19.305,  -99.103),
    ("UIZ", "UAM Iztapalapa",          19.360,  -99.074),
    ("XAL", "Xalostoc",                19.526,  -99.082),
]

WHO_LIMIT_PM25 = 15.0


def generar_sintetico():
    """Datos sintéticos coherentes con patrones documentados del SIMAT 2023."""
    rng = np.random.default_rng(seed=42)

    # Promedio anual por estación — sesgo elevado en el norte/poniente
    base_pm25 = {}
    for code, name, lat, _lon in ESTACIONES:
        zona_norte_poniente = (lat > 19.45) or (code in ("CUA", "SFE", "MGH"))
        media = 21.5 if zona_norte_poniente else 14.5
        base_pm25[code] = max(8.0, rng.normal(media, 2.5))

    mapa = pd.DataFrame([
        {
            "station_code": code, "station_name": name,
            "latitude": lat, "longitude": lon,
            "promedio": base_pm25[code],
            "lecturas": int(rng.uniform(6500, 8400)),
        }
        for code, name, lat, lon in ESTACIONES
    ])

    # Serie mensual (top 5 estaciones más contaminadas)
    top5 = mapa.nlargest(5, "promedio")["station_code"].tolist()
    estacionalidad = np.array([1.45, 1.35, 1.25, 1.05, 0.85, 0.70,
                                0.65, 0.70, 0.80, 0.95, 1.25, 1.50])
    rows = []
    for code in top5:
        for month in range(1, 13):
            base = base_pm25[code] * estacionalidad[month - 1]
            valor = max(5.0, rng.normal(base, base * 0.08))
            station_name = next(n for c, n, _, _ in ESTACIONES if c == code)
            rows.append({"station_name": station_name, "month_number": month,
                         "promedio": valor})
    serie = pd.DataFrame(rows)

    # Heatmap hora × mes (promedio CDMX completa)
    horas = np.arange(24)
    # Patrón bimodal: pico matutino 7-9, vespertino 19-21
    perfil_horario = (
        1.0
        + 0.75 * np.exp(-((horas - 8.5) ** 2) / 4)
        + 0.55 * np.exp(-((horas - 20) ** 2) / 5)
        - 0.35 * np.exp(-((horas - 3) ** 2) / 6)
    )
    heatmap = np.zeros((24, 12))
    base_mes = np.mean(list(base_pm25.values()))
    for mes in range(12):
        for hora in range(24):
            valor = base_mes * estacionalidad[mes] * perfil_horario[hora]
            heatmap[hora, mes] = max(4.0, valor + rng.normal(0, 1.0))

    return mapa, serie, heatmap


def consultar_aurora():
    """Queries reales contra Aurora (no implementadas inline — ver README)."""
    from sqlalchemy import create_engine

    engine = create_engine(
        f"postgresql+psycopg2://postgres:"
        f"{os.environ['AURORA_PASSWORD']}@{os.environ['AURORA_HOST']}:5432/"
        f"{os.environ.get('AURORA_DATABASE', 'northwind')}"
    )

    mapa = pd.read_sql("""
        SELECT ds.station_code, ds.station_name, ds.latitude, ds.longitude,
               ROUND(AVG(fm.valor), 2)            AS promedio,
               COUNT(*) FILTER (WHERE fm.is_valid) AS lecturas
        FROM   aire_dwh.fact_mediciones fm
        JOIN   aire_dwh.dim_station    ds USING (station_key)
        JOIN   aire_dwh.dim_pollutant  dp USING (pollutant_key)
        WHERE  dp.code = 'PM25' AND fm.is_valid
        GROUP BY ds.station_code, ds.station_name, ds.latitude, ds.longitude
    """, engine)

    serie = pd.read_sql("""
        WITH top5 AS (
            SELECT ds.station_key
            FROM   aire_dwh.fact_mediciones fm
            JOIN   aire_dwh.dim_station ds USING (station_key)
            JOIN   aire_dwh.dim_pollutant dp USING (pollutant_key)
            WHERE  dp.code = 'PM25' AND fm.is_valid
            GROUP BY ds.station_key
            ORDER BY AVG(fm.valor) DESC
            LIMIT 5
        )
        SELECT ds.station_name, dd.month_number,
               ROUND(AVG(fm.valor), 2) AS promedio
        FROM   aire_dwh.fact_mediciones fm
        JOIN   aire_dwh.dim_station    ds USING (station_key)
        JOIN   aire_dwh.dim_pollutant  dp USING (pollutant_key)
        JOIN   aire_dwh.dim_date       dd USING (date_key)
        WHERE  dp.code = 'PM25' AND fm.is_valid
          AND  ds.station_key IN (SELECT station_key FROM top5)
        GROUP BY ds.station_name, dd.month_number
    """, engine)

    heat_df = pd.read_sql("""
        SELECT dh.hour, dd.month_number,
               ROUND(AVG(fm.valor), 2) AS promedio
        FROM   aire_dwh.fact_mediciones fm
        JOIN   aire_dwh.dim_pollutant  dp USING (pollutant_key)
        JOIN   aire_dwh.dim_hour       dh USING (hour_key)
        JOIN   aire_dwh.dim_date       dd USING (date_key)
        WHERE  dp.code = 'PM25' AND fm.is_valid
        GROUP BY dh.hour, dd.month_number
    """, engine)
    heatmap = heat_df.pivot(index="hour", columns="month_number", values="promedio").values

    return mapa, serie, heatmap


print(f"Modo: {'Aurora' if USE_AURORA else 'sintético'}")
mapa, serie, heatmap = (consultar_aurora() if USE_AURORA else generar_sintetico())


# =============================================================================
# Visualización 1 — Mapa de estaciones
# =============================================================================

fig, ax = plt.subplots(figsize=(10, 7))
sc = ax.scatter(
    mapa["longitude"], mapa["latitude"],
    c=mapa["promedio"], s=mapa["lecturas"] / 30,
    cmap="RdYlGn_r", vmin=10, vmax=25,
    edgecolors="black", linewidths=0.5, alpha=0.85,
)
for _, row in mapa.iterrows():
    ax.annotate(
        row["station_code"], (row["longitude"], row["latitude"]),
        fontsize=7, ha="center", va="center",
    )
cbar = plt.colorbar(sc, ax=ax, label="PM2.5 promedio anual (µg/m³)")
cbar.ax.axhline(WHO_LIMIT_PM25, color="black", linewidth=1)
cbar.ax.text(2.2, WHO_LIMIT_PM25, "OMS", va="center", fontsize=8)
ax.set_xlabel("Longitud")
ax.set_ylabel("Latitud")
ax.set_title("PM2.5 promedio anual por estación RAMA — CDMX 2023\n(tamaño = número de lecturas válidas)")
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig(OUT / "01_mapa.png", dpi=110)
plt.close()


# =============================================================================
# Visualización 2 — Serie temporal mensual (top 5 estaciones)
# =============================================================================

fig, ax = plt.subplots(figsize=(11, 5.5))
meses = ["Ene", "Feb", "Mar", "Abr", "May", "Jun",
         "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]
for nombre, grupo in serie.groupby("station_name"):
    grupo = grupo.sort_values("month_number")
    ax.plot(grupo["month_number"], grupo["promedio"], marker="o",
            linewidth=2, label=nombre)
ax.axhline(WHO_LIMIT_PM25, color="red", linestyle="--", linewidth=1, label="Límite OMS (15 µg/m³)")
ax.set_xticks(range(1, 13))
ax.set_xticklabels(meses)
ax.set_ylabel("PM2.5 promedio mensual (µg/m³)")
ax.set_title("Evolución mensual de PM2.5 — top 5 estaciones más contaminadas")
ax.legend(loc="upper right", fontsize=9)
ax.grid(True, alpha=0.3)
plt.tight_layout()
plt.savefig(OUT / "02_serie_mensual.png", dpi=110)
plt.close()


# =============================================================================
# Visualización 3 — Top 10 estaciones más contaminadas
# =============================================================================

top10 = mapa.nlargest(10, "promedio").sort_values("promedio")
fig, ax = plt.subplots(figsize=(10, 6))
colores = ["#d73027" if v > WHO_LIMIT_PM25 else "#1a9850" for v in top10["promedio"]]
ax.barh(top10["station_name"], top10["promedio"], color=colores, edgecolor="black")
ax.axvline(WHO_LIMIT_PM25, color="black", linestyle="--", linewidth=1.2)
ax.text(WHO_LIMIT_PM25 + 0.3, len(top10) - 0.5, "Límite OMS\n(15 µg/m³)",
        fontsize=9, va="top")
ax.set_xlabel("PM2.5 promedio anual (µg/m³)")
ax.set_title("Top 10 estaciones con mayor PM2.5 promedio en 2023")
ax.grid(True, alpha=0.3, axis="x")
for i, v in enumerate(top10["promedio"]):
    ax.text(v + 0.2, i, f"{v:.1f}", va="center", fontsize=9)
plt.tight_layout()
plt.savefig(OUT / "03_top_estaciones.png", dpi=110)
plt.close()


# =============================================================================
# Visualización 4 — Heatmap hora × mes
# =============================================================================

fig, ax = plt.subplots(figsize=(10, 7))
im = ax.imshow(heatmap, aspect="auto", cmap="RdYlGn_r", vmin=8, vmax=30,
               origin="upper")
ax.set_xticks(range(12))
ax.set_xticklabels(meses)
ax.set_yticks(range(0, 24, 3))
ax.set_yticklabels([f"{h:02d}:00" for h in range(0, 24, 3)])
ax.set_xlabel("Mes")
ax.set_ylabel("Hora del día")
ax.set_title("PM2.5 promedio por hora y mes — CDMX 2023\n(promedio metropolitano de las 22 estaciones)")
cbar = plt.colorbar(im, ax=ax, label="PM2.5 (µg/m³)")
cbar.ax.axhline(WHO_LIMIT_PM25, color="black", linewidth=1)
cbar.ax.text(2.2, WHO_LIMIT_PM25, "OMS", va="center", fontsize=8)
plt.tight_layout()
plt.savefig(OUT / "04_heatmap.png", dpi=110)
plt.close()


print(f"✓ 4 visualizaciones generadas en {OUT}/")
