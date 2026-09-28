-- Staging is intentionally permissive: source-shaped records are retained
-- before promotion into the canonical iris_core contract.
CREATE TABLE iris_staging.ingest_record (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type TEXT NOT NULL,
    country_code TEXT NOT NULL,
    region_code TEXT,
    source_id TEXT NOT NULL,
    source_date DATE NOT NULL,
    geom geometry(Geometry, 4326),
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT ingest_record_entity_type_ck
        CHECK (entity_type IN (
            'parcel',
            'substation',
            'peatland',
            'screening_layer'
        )),

    CONSTRAINT ingest_record_country_code_ck
        CHECK (country_code ~ '^[A-Z]{2}$'),

    CONSTRAINT ingest_record_country_source_uq
        UNIQUE (country_code, entity_type, source_id)
);

CREATE INDEX ingest_record_country_entity_idx
    ON iris_staging.ingest_record (country_code, entity_type);

CREATE INDEX ingest_record_geom_gix
    ON iris_staging.ingest_record
    USING GIST (geom);
