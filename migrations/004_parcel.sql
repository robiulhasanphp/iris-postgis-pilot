CREATE TABLE iris_core.parcel (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    country_code TEXT NOT NULL,
    region_code TEXT NOT NULL,
    source_id TEXT NOT NULL,
    source_date DATE NOT NULL,
    source_run_id UUID NOT NULL,

    geom geometry(MultiPolygon, 4326) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT parcel_country_code_ck
        CHECK (country_code ~ '^[A-Z]{2}$'),

    CONSTRAINT parcel_country_source_uq
        UNIQUE (country_code, source_id),

    CONSTRAINT parcel_country_id_uq
        UNIQUE (country_code, id),

    CONSTRAINT parcel_source_run_fk
        FOREIGN KEY (country_code, source_run_id)
        REFERENCES iris_core.source_run (country_code, id)
);

CREATE INDEX parcel_country_region_idx
    ON iris_core.parcel (country_code, region_code);

CREATE INDEX parcel_source_run_idx
    ON iris_core.parcel (country_code, source_run_id);

CREATE INDEX parcel_geom_gix
    ON iris_core.parcel
    USING GIST (geom);

-- Supports distance-in-metres queries using ST_DWithin on geography.
CREATE INDEX parcel_geog_gix
    ON iris_core.parcel
    USING GIST ((geom::geography));
