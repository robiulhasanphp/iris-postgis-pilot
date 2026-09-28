-- Deterministic, local-only fixture.
-- Coordinates are intentionally simple and are not production data.

BEGIN;

INSERT INTO iris_core.source_run (
    country_code, source_id, source_date, source_name, source_version
) VALUES
    ('GB', 'fixture_parcels_001', '2026-09-01', 'deterministic_fixture', '1'),
    ('GB', 'fixture_grid_001', '2026-09-01', 'deterministic_fixture', '1'),
    ('GB', 'fixture_environment_001', '2026-09-01', 'deterministic_fixture', '1'),
    ('NL', 'fixture_grid_001', '2026-09-01', 'deterministic_fixture', '1')
ON CONFLICT (country_code, source_id) DO NOTHING;

INSERT INTO iris_core.parcel (
    country_code, region_code, source_id, source_date, source_run_id, geom
)
SELECT
    'GB', 'TEST-01', 'parcel-001', '2026-09-01', sr.id,
    ST_GeomFromText(
        'MULTIPOLYGON (((-0.120 51.500, -0.110 51.500, -0.110 51.510, -0.120 51.510, -0.120 51.500)))',
        4326
    )
FROM iris_core.source_run sr
WHERE sr.country_code = 'GB'
  AND sr.source_id = 'fixture_parcels_001'
ON CONFLICT (country_code, source_id) DO NOTHING;

INSERT INTO iris_core.parcel (
    country_code, region_code, source_id, source_date, source_run_id, geom
)
SELECT
    'GB', 'TEST-01', 'parcel-002', '2026-09-01', sr.id,
    ST_GeomFromText(
        'MULTIPOLYGON (((-0.080 51.500, -0.070 51.500, -0.070 51.510, -0.080 51.510, -0.080 51.500)))',
        4326
    )
FROM iris_core.source_run sr
WHERE sr.country_code = 'GB'
  AND sr.source_id = 'fixture_parcels_001'
ON CONFLICT (country_code, source_id) DO NOTHING;

INSERT INTO iris_core.substation (
    country_code, region_code, source_id, source_date, source_run_id, geom, voltage_kv
)
SELECT
    'GB', 'TEST-01', 'substation-001', '2026-09-01', sr.id,
    ST_SetSRID(ST_MakePoint(-0.115, 51.505), 4326), 132
FROM iris_core.source_run sr
WHERE sr.country_code = 'GB'
  AND sr.source_id = 'fixture_grid_001'
ON CONFLICT (country_code, source_id) DO NOTHING;

INSERT INTO iris_core.substation (
    country_code, region_code, source_id, source_date, source_run_id, geom, voltage_kv
)
SELECT
    'GB', 'TEST-01', 'substation-002', '2026-09-01', sr.id,
    ST_SetSRID(ST_MakePoint(-0.300, 51.600), 4326), 400
FROM iris_core.source_run sr
WHERE sr.country_code = 'GB'
  AND sr.source_id = 'fixture_grid_001'
ON CONFLICT (country_code, source_id) DO NOTHING;

INSERT INTO iris_core.peatland (
    country_code, region_code, source_id, source_date, source_run_id, geom, classification
)
SELECT
    'GB', 'TEST-01', 'peatland-001', '2026-09-01', sr.id,
    ST_GeomFromText(
        'MULTIPOLYGON (((-0.118 51.502, -0.112 51.502, -0.112 51.508, -0.118 51.508, -0.118 51.502)))',
        4326
    ), 'test-peat'
FROM iris_core.source_run sr
WHERE sr.country_code = 'GB'
  AND sr.source_id = 'fixture_environment_001'
ON CONFLICT (country_code, source_id) DO NOTHING;

INSERT INTO iris_core.screening_layer (
    country_code, region_code, source_id, source_date, source_run_id, layer_type, geom
)
SELECT
    'GB', 'TEST-01', 'screening-001', '2026-09-01', sr.id, 'protected_area_fixture',
    ST_GeomFromText(
        'MULTIPOLYGON (((-0.060 51.490, -0.040 51.490, -0.040 51.510, -0.060 51.510, -0.060 51.490)))',
        4326
    )
FROM iris_core.source_run sr
WHERE sr.country_code = 'GB'
  AND sr.source_id = 'fixture_environment_001'
ON CONFLICT (country_code, source_id) DO NOTHING;

INSERT INTO iris_core.evidence (
    country_code, source_id, source_date, source_run_id,
    parcel_id, evidence_type, uncertainty, value
)
SELECT
    p.country_code,
    'evidence-parcel-001',
    '2026-09-01',
    p.source_run_id,
    p.id,
    'fixture_screening',
    'illustrative',
    '{"status":"candidate"}'::jsonb
FROM iris_core.parcel p
WHERE p.country_code = 'GB'
  AND p.source_id = 'parcel-001'
ON CONFLICT (country_code, source_id) DO NOTHING;

COMMIT;
