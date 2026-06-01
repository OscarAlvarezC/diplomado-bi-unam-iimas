"""
Dashboard de calidad del aire CDMX 2023 — Streamlit + Plotly.

Ejecutar:
    export AURORA_HOST=aurora-mod4.cluster-XXX.us-east-1.rds.amazonaws.com
    export AURORA_PASSWORD=tu_password
    streamlit run dashboard_streamlit.py
"""

import os

import pandas as pd
import plotly.express as px
import streamlit as st
from sqlalchemy import create_engine

# =============================================================================
# Setup
# =============================================================================

st.set_page_config(page_title="Aire CDMX 2023", page_icon=":wind_face:", layout="wide")

AURORA_HOST     = os.environ["AURORA_HOST"]
AURORA_PASSWORD = os.environ["AURORA_PASSWORD"]
AURORA_DATABASE = os.environ.get("AURORA_DATABASE", "northwind")

engine = create_engine(
    f"postgresql+psycopg2://postgres:{AURORA_PASSWORD}@{AURORA_HOST}:5432/{AURORA_DATABASE}"
)


@st.cache_data(ttl=3600)
def query(sql: str) -> pd.DataFrame:
    return pd.read_sql(sql, engine)


# =============================================================================
# Sidebar — filtros
# =============================================================================

st.sidebar.title("Filtros")

contaminantes = query(
    "SELECT code, name FROM aire_dwh.dim_pollutant ORDER BY code"
)
pollutant = st.sidebar.selectbox(
    "Contaminante",
    options=contaminantes["code"],
    format_func=lambda c: contaminantes.set_index("code").loc[c, "name"],
    index=0,
)

mes = st.sidebar.slider(
    "Mes (rango)",
    min_value=1, max_value=12, value=(1, 12),
)

# =============================================================================
# Header
# =============================================================================

st.title(":wind_face: Calidad del aire — CDMX 2023")
st.markdown(
    f"Mediciones horarias del SIMAT — contaminante seleccionado: **{pollutant}**, "
    f"meses **{mes[0]} a {mes[1]}**."
)

# =============================================================================
# Vista 1 — Mapa de estaciones por promedio anual
# =============================================================================

st.subheader(":world_map: Promedio anual por estación")

mapa = query(f"""
    SELECT
        ds.station_name,
        ds.alcaldia,
        ds.latitude,
        ds.longitude,
        ROUND(AVG(fm.valor), 2)            AS promedio,
        COUNT(*) FILTER (WHERE fm.is_valid) AS lecturas
    FROM      aire_dwh.fact_mediciones fm
    JOIN      aire_dwh.dim_station    ds USING (station_key)
    JOIN      aire_dwh.dim_pollutant  dp USING (pollutant_key)
    JOIN      aire_dwh.dim_date       dd USING (date_key)
    WHERE     dp.code = '{pollutant}'
      AND     fm.is_valid
      AND     dd.month_number BETWEEN {mes[0]} AND {mes[1]}
    GROUP BY  ds.station_name, ds.alcaldia, ds.latitude, ds.longitude
""")

fig_mapa = px.scatter_mapbox(
    mapa,
    lat="latitude", lon="longitude",
    size="lecturas", color="promedio",
    color_continuous_scale="RdYlGn_r",
    hover_name="station_name",
    hover_data=["alcaldia", "promedio", "lecturas"],
    zoom=9, mapbox_style="open-street-map",
    height=500,
)
st.plotly_chart(fig_mapa, use_container_width=True)

# =============================================================================
# Vista 2 — Serie temporal mensual
# =============================================================================

st.subheader(":chart_with_upwards_trend: Evolución mensual por estación")

serie = query(f"""
    SELECT
        ds.station_code,
        ds.station_name,
        dd.month_number,
        ROUND(AVG(fm.valor), 2) AS promedio
    FROM      aire_dwh.fact_mediciones fm
    JOIN      aire_dwh.dim_station    ds USING (station_key)
    JOIN      aire_dwh.dim_pollutant  dp USING (pollutant_key)
    JOIN      aire_dwh.dim_date       dd USING (date_key)
    WHERE     dp.code = '{pollutant}' AND fm.is_valid
    GROUP BY  ds.station_code, ds.station_name, dd.month_number
""")

fig_serie = px.line(
    serie,
    x="month_number", y="promedio", color="station_name",
    title=f"Promedio mensual de {pollutant} por estación",
    labels={"month_number": "Mes", "promedio": pollutant, "station_name": "Estación"},
)
st.plotly_chart(fig_serie, use_container_width=True)

# =============================================================================
# Vista 3 — Top estaciones
# =============================================================================

col1, col2 = st.columns([2, 1])

with col1:
    st.subheader(":bar_chart: Top 10 estaciones más contaminadas")
    top = query(f"""
        SELECT
            ds.station_name,
            ROUND(AVG(fm.valor), 2)  AS promedio,
            dp.who_safe_limit
        FROM      aire_dwh.fact_mediciones fm
        JOIN      aire_dwh.dim_station    ds USING (station_key)
        JOIN      aire_dwh.dim_pollutant  dp USING (pollutant_key)
        JOIN      aire_dwh.dim_date       dd USING (date_key)
        WHERE     dp.code = '{pollutant}' AND fm.is_valid
          AND     dd.month_number BETWEEN {mes[0]} AND {mes[1]}
        GROUP BY  ds.station_name, dp.who_safe_limit
        ORDER BY  promedio DESC
        LIMIT 10
    """)
    fig_top = px.bar(
        top, x="promedio", y="station_name", orientation="h",
        labels={"promedio": pollutant, "station_name": ""},
    )
    fig_top.add_vline(
        x=top["who_safe_limit"].iloc[0],
        line_dash="dash", line_color="red",
        annotation_text=f"OMS: {top['who_safe_limit'].iloc[0]}",
    )
    st.plotly_chart(fig_top, use_container_width=True)

# =============================================================================
# Vista 4 — Heatmap hora × mes
# =============================================================================

with col2:
    st.subheader(":fire: Patrón hora × mes")
    heat = query(f"""
        SELECT
            dh.hour                   AS hora,
            dd.month_number           AS mes,
            ROUND(AVG(fm.valor), 2)   AS promedio
        FROM      aire_dwh.fact_mediciones fm
        JOIN      aire_dwh.dim_pollutant  dp USING (pollutant_key)
        JOIN      aire_dwh.dim_hour       dh USING (hour_key)
        JOIN      aire_dwh.dim_date       dd USING (date_key)
        WHERE     dp.code = '{pollutant}' AND fm.is_valid
        GROUP BY  dh.hour, dd.month_number
    """)
    heat_pivot = heat.pivot(index="hora", columns="mes", values="promedio")
    fig_heat = px.imshow(
        heat_pivot,
        labels={"x": "Mes", "y": "Hora", "color": pollutant},
        color_continuous_scale="RdYlGn_r",
        aspect="auto",
    )
    st.plotly_chart(fig_heat, use_container_width=True)

st.caption("Fuente: SIMAT (Sistema de Monitoreo Atmosférico) — Gobierno de la CDMX.")
