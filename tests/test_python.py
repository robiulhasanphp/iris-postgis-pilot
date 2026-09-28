import os

import pytest

try:
    import psycopg
except ImportError:  # pragma: no cover
    psycopg = None


pytestmark = pytest.mark.skipif(
    psycopg is None or not os.getenv("DATABASE_URL"),
    reason="requires psycopg and DATABASE_URL",
)


@pytest.fixture(scope="module")
def conn():
    with psycopg.connect(os.environ["DATABASE_URL"]) as connection:
        yield connection


def test_postgis_available(conn):
    with conn.cursor() as cur:
        cur.execute("SELECT PostGIS_Full_Version()")
        value = cur.fetchone()[0]
    assert "POSTGIS" in value.upper()


def test_country_scoped_source_identity(conn):
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT COUNT(*)
            FROM iris_core.source_run
            WHERE country_code = 'GB'
              AND source_id = 'fixture_grid_001'
            """
        )
        assert cur.fetchone()[0] == 1


def test_geometry_contracts(conn):
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT
                ST_SRID(p.geom),
                GeometryType(p.geom),
                ST_SRID(s.geom),
                GeometryType(s.geom)
            FROM iris_core.parcel p
            CROSS JOIN iris_core.substation s
            WHERE p.source_id = 'parcel-001'
              AND s.source_id = 'substation-001'
            """
        )
        srid_p, type_p, srid_s, type_s = cur.fetchone()

    assert (srid_p, type_p) == (4326, "MULTIPOLYGON")
    assert (srid_s, type_s) == (4326, "POINT")


def test_spatial_round_trip(conn):
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT ST_Distance(p.geom::geography, s.geom::geography)
            FROM iris_core.parcel p
            JOIN iris_core.substation s
              ON p.country_code = s.country_code
            WHERE p.source_id = 'parcel-001'
              AND s.source_id = 'substation-001'
            """
        )
        distance_m = cur.fetchone()[0]

    assert distance_m < 10_000
