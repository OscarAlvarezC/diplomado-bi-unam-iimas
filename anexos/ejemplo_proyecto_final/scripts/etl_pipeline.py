#!/usr/bin/env python3
"""
ETL Pipeline — Calidad del aire CDMX (SIMAT)

Descarga el catálogo anual de mediciones horarias del SIMAT, lo transforma
al modelo dimensional y lo carga a Aurora PostgreSQL.

Uso:
    python etl_pipeline.py \
        --host  aurora-mod4.cluster-XXX.us-east-1.rds.amazonaws.com \
        --password TU_PASSWORD \
        --database northwind \
        --year 2023

Prerrequisito: las tres tablas de dimensión (dim_date, dim_hour, dim_station,
dim_pollutant) ya están pobladas vía 02-04_*.sql.
"""

import argparse
import io
import logging
import sys
import zipfile

import pandas as pd
import requests
from sqlalchemy import create_engine, text
from sqlalchemy.types import Integer, Numeric, Boolean, SmallInteger
from tqdm import tqdm

logger = logging.getLogger("etl_aire")

SIMAT_URLS_2023 = {
    "PM25": "http://www.aire.cdmx.gob.mx/estadisticas-consultas/concentraciones/respuesta.php?qtipo=HORARIOS&parametro=pm2&anio=2023&qmes=00",
    "PM10": "http://www.aire.cdmx.gob.mx/estadisticas-consultas/concentraciones/respuesta.php?qtipo=HORARIOS&parametro=pmco&anio=2023&qmes=00",
    "O3":   "http://www.aire.cdmx.gob.mx/estadisticas-consultas/concentraciones/respuesta.php?qtipo=HORARIOS&parametro=o3&anio=2023&qmes=00",
    "NO2":  "http://www.aire.cdmx.gob.mx/estadisticas-consultas/concentraciones/respuesta.php?qtipo=HORARIOS&parametro=no2&anio=2023&qmes=00",
    "SO2":  "http://www.aire.cdmx.gob.mx/estadisticas-consultas/concentraciones/respuesta.php?qtipo=HORARIOS&parametro=so2&anio=2023&qmes=00",
    "CO":   "http://www.aire.cdmx.gob.mx/estadisticas-consultas/concentraciones/respuesta.php?qtipo=HORARIOS&parametro=co&anio=2023&qmes=00",
}


# =============================================================================
# Extract
# =============================================================================

def extract(pollutant_code: str, year: int) -> pd.DataFrame:
    """Descarga el CSV del SIMAT para un contaminante × año dado."""
    logger.info("Descargando %s para %d", pollutant_code, year)
    url = SIMAT_URLS_2023[pollutant_code]   # En producción real: parametrizar año

    response = requests.get(url, timeout=60)
    response.raise_for_status()

    # El SIMAT devuelve CSV ancho con una columna por estación
    df = pd.read_csv(io.StringIO(response.text), skiprows=10)
    logger.info("  %s descargado: %s filas × %s columnas", pollutant_code, *df.shape)
    return df


# =============================================================================
# Transform
# =============================================================================

def transform_wide_to_long(df: pd.DataFrame, pollutant_code: str) -> pd.DataFrame:
    """
    Convierte el CSV ancho del SIMAT (estaciones como columnas) al formato
    largo que necesita la fact: una fila por (date, hour, station_code).
    """
    df = df.copy()

    # Las primeras dos columnas son Fecha y Hora; el resto son estaciones
    df = df.rename(columns={"FECHA": "fecha", "HORA": "hora"})
    df["fecha"] = pd.to_datetime(df["fecha"], errors="coerce")
    df["hora"] = df["hora"].astype("Int8")

    # Melt: estaciones a filas
    estaciones = [c for c in df.columns if c not in ("fecha", "hora")]
    largo = df.melt(
        id_vars=["fecha", "hora"],
        value_vars=estaciones,
        var_name="station_code",
        value_name="valor",
    )

    # Marcar lecturas inválidas — SIMAT usa -99 como sentinela de "sin dato"
    largo["is_valid"] = largo["valor"].notna() & (largo["valor"] > -50)
    largo.loc[~largo["is_valid"], "valor"] = pd.NA

    # Calcular claves
    largo["date_key"] = largo["fecha"].dt.strftime("%Y%m%d").astype("Int32")
    largo["hour_key"] = largo["hora"]
    largo["pollutant_code"] = pollutant_code

    return largo[["date_key", "hour_key", "station_code", "pollutant_code", "valor", "is_valid"]].dropna(subset=["date_key"])


def resolve_keys(df_long: pd.DataFrame, engine) -> pd.DataFrame:
    """Sustituye station_code y pollutant_code por sus surrogate keys."""
    stations = pd.read_sql(
        "SELECT station_key, station_code FROM aire_dwh.dim_station",
        engine,
    )
    pollutants = pd.read_sql(
        "SELECT pollutant_key, code AS pollutant_code FROM aire_dwh.dim_pollutant",
        engine,
    )

    fact = df_long.merge(stations,   on="station_code",   how="inner", validate="many_to_one")
    fact = fact.merge(pollutants,    on="pollutant_code", how="inner", validate="many_to_one")
    return fact[["date_key", "hour_key", "station_key", "pollutant_key", "valor", "is_valid"]]


# =============================================================================
# Load
# =============================================================================

def load(df: pd.DataFrame, engine, chunksize: int = 5000):
    """Carga incrementalmente al fact con method='multi'."""
    logger.info("Cargando %s filas a fact_mediciones", f"{len(df):,}")

    n_chunks = (len(df) + chunksize - 1) // chunksize
    for i in tqdm(range(n_chunks), desc="  chunks"):
        chunk = df.iloc[i * chunksize:(i + 1) * chunksize]
        chunk.to_sql(
            "fact_mediciones",
            engine,
            schema="aire_dwh",
            if_exists="append",
            index=False,
            method="multi",
            dtype={
                "date_key":      Integer(),
                "hour_key":      SmallInteger(),
                "station_key":   Integer(),
                "pollutant_key": Integer(),
                "valor":         Numeric(8, 2),
                "is_valid":      Boolean(),
            },
        )


# =============================================================================
# Validate
# =============================================================================

def validate(engine, year: int):
    """Validaciones post-carga."""
    logger.info("Validaciones post-carga")
    checks = pd.read_sql(text("""
        SELECT
            dp.code                           AS pollutant,
            COUNT(*)                          AS lecturas_totales,
            COUNT(*) FILTER (WHERE is_valid)  AS lecturas_validas,
            ROUND(AVG(valor) FILTER (WHERE is_valid), 2) AS promedio
        FROM      aire_dwh.fact_mediciones fm
        JOIN      aire_dwh.dim_pollutant   dp USING (pollutant_key)
        GROUP BY  dp.code
        ORDER BY  dp.code
    """), engine)
    logger.info("Resumen por contaminante:\n%s", checks.to_string(index=False))

    # Sanity: no debería haber valores fuera de rango razonable
    bogus = pd.read_sql(text("""
        SELECT count(*) AS n
        FROM   aire_dwh.fact_mediciones
        WHERE  is_valid AND valor > 1000
    """), engine).iloc[0, 0]
    assert bogus == 0, f"Hay {bogus} lecturas válidas con valor > 1000 — revisar parsing"
    logger.info("✓ Sin valores fuera de rango")


# =============================================================================
# Main
# =============================================================================

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host",     required=True)
    parser.add_argument("--password", required=True)
    parser.add_argument("--database", default="northwind")
    parser.add_argument("--year",     type=int, default=2023)
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )

    engine = create_engine(
        f"postgresql+psycopg2://postgres:{args.password}@{args.host}:5432/{args.database}"
    )

    try:
        with engine.begin() as conn:
            for pollutant_code in SIMAT_URLS_2023:
                df_wide = extract(pollutant_code, args.year)
                df_long = transform_wide_to_long(df_wide, pollutant_code)
                df_fact = resolve_keys(df_long, conn)
                load(df_fact, conn)
        validate(engine, args.year)
        logger.info("ETL completado correctamente")
    except Exception as exc:
        logger.exception("ETL falló: %s", exc)
        sys.exit(1)


if __name__ == "__main__":
    main()
