-- Optional staging-only fixture. It is intentionally source-shaped.
BEGIN;

INSERT INTO iris_staging.ingest_record (
    entity_type, country_code, region_code, source_id, source_date, geom, payload
) VALUES (
    'parcel', 'GB', 'TEST-01', 'staging-parcel-001', DATE '2026-09-01',
    ST_GeomFromText(
        'MULTIPOLYGON (((-0.130 51.500, -0.125 51.500, -0.125 51.505, -0.130 51.505, -0.130 51.500)))',
        4326
    ),
    '{"fixture":true,"stage":"raw"}'::jsonb
)
ON CONFLICT (country_code, entity_type, source_id) DO NOTHING;

COMMIT;
