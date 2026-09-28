-- SQL assertions for the highest-risk correctness conditions.
-- Run with: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f tests/test_schema.sql

DO $$
DECLARE
    v_source_run UUID;
    v_parcel UUID;
BEGIN
    -- Required core tables exist.
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'iris_core' AND table_name = 'parcel'
    ) THEN RAISE EXCEPTION 'missing iris_core.parcel'; END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'iris_core' AND table_name = 'substation'
    ) THEN RAISE EXCEPTION 'missing iris_core.substation'; END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'iris_core' AND table_name = 'peatland'
    ) THEN RAISE EXCEPTION 'missing iris_core.peatland'; END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'iris_core' AND table_name = 'screening_layer'
    ) THEN RAISE EXCEPTION 'missing iris_core.screening_layer'; END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'iris_core' AND table_name = 'source_run'
    ) THEN RAISE EXCEPTION 'missing iris_core.source_run'; END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'iris_core' AND table_name = 'evidence'
    ) THEN RAISE EXCEPTION 'missing iris_core.evidence'; END IF;

    -- Canonical geometry column name: no core table may use a column named geometry.
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'iris_core' AND column_name = 'geometry'
    ) THEN RAISE EXCEPTION 'forbidden core geometry column name exists'; END IF;

    -- Country is populated in all persisted business entities.
    IF EXISTS (SELECT 1 FROM iris_core.source_run WHERE country_code IS NULL)
       OR EXISTS (SELECT 1 FROM iris_core.parcel WHERE country_code IS NULL)
       OR EXISTS (SELECT 1 FROM iris_core.substation WHERE country_code IS NULL)
       OR EXISTS (SELECT 1 FROM iris_core.peatland WHERE country_code IS NULL)
       OR EXISTS (SELECT 1 FROM iris_core.screening_layer WHERE country_code IS NULL)
       OR EXISTS (SELECT 1 FROM iris_core.evidence WHERE country_code IS NULL)
    THEN RAISE EXCEPTION 'country_code contains NULL'; END IF;

    -- Geometry contracts.
    IF NOT EXISTS (
        SELECT 1 FROM iris_core.parcel
        WHERE source_id = 'parcel-001'
          AND ST_SRID(geom) = 4326
          AND GeometryType(geom) = 'MULTIPOLYGON'
    ) THEN RAISE EXCEPTION 'parcel geometry contract failed'; END IF;

    IF NOT EXISTS (
        SELECT 1 FROM iris_core.substation
        WHERE source_id = 'substation-001'
          AND ST_SRID(geom) = 4326
          AND GeometryType(geom) = 'POINT'
    ) THEN RAISE EXCEPTION 'substation geometry contract failed'; END IF;

    -- Expected fixture cardinalities.
    IF (SELECT COUNT(*) FROM iris_core.parcel WHERE country_code = 'GB') <> 2
    THEN RAISE EXCEPTION 'expected two GB parcel fixtures'; END IF;

    IF (SELECT COUNT(*) FROM iris_core.substation WHERE country_code = 'GB') <> 2
    THEN RAISE EXCEPTION 'expected two GB substations'; END IF;

    -- Spatial round trip.
    IF (
        SELECT COUNT(*)
        FROM iris_core.parcel p
        JOIN iris_core.peatland pl
          ON p.country_code = pl.country_code
         AND ST_Intersects(p.geom, pl.geom)
        WHERE p.source_id = 'parcel-001'
    ) <> 1 THEN RAISE EXCEPTION 'expected parcel-001 to intersect one peatland fixture'; END IF;

    -- Proximity round trip in metres.
    IF NOT EXISTS (
        SELECT 1
        FROM iris_core.parcel p
        JOIN iris_core.substation s
          ON p.country_code = s.country_code
        WHERE p.source_id = 'parcel-001'
          AND s.source_id = 'substation-001'
          AND ST_DWithin(p.geom::geography, s.geom::geography, 10000)
    ) THEN RAISE EXCEPTION 'expected parcel-001 and substation-001 within 10km'; END IF;

    -- Duplicate country/source identity must be rejected.
    SELECT id INTO v_source_run
    FROM iris_core.source_run
    WHERE country_code = 'GB' AND source_id = 'fixture_grid_001';

    BEGIN
        INSERT INTO iris_core.source_run (
            country_code, source_id, source_date, source_name
        ) VALUES ('GB', 'fixture_grid_001', DATE '2026-09-01', 'duplicate-test');
        RAISE EXCEPTION 'duplicate country/source was accepted';
    EXCEPTION WHEN unique_violation THEN
        NULL;
    END;

    -- Country mismatch on a composite FK must be rejected.
    SELECT id INTO v_parcel
    FROM iris_core.parcel
    WHERE country_code = 'GB' AND source_id = 'parcel-001';

    BEGIN
        INSERT INTO iris_core.evidence (
            country_code, source_id, source_date, source_run_id,
            parcel_id, evidence_type, uncertainty
        ) VALUES (
            'NL', 'country-mismatch-test', DATE '2026-09-01', v_source_run,
            v_parcel, 'negative-test', 'unknown'
        );
        RAISE EXCEPTION 'country-mismatched evidence was accepted';
    EXCEPTION WHEN foreign_key_violation THEN
        NULL;
    END;

    RAISE NOTICE 'All SQL assertions passed.';
END $$;
