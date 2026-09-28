CREATE TABLE iris_core.substation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    country_code TEXT NOT NULL,
    region_code TEXT NOT NULL,
    source_id TEXT NOT NULL,
    source_date DATE NOT NULL,
    source_run_id UUID NOT NULL,

    geom geometry(Point, 4326) NOT NULL,

    voltage_kv NUMERIC,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT substation_country_code_ck
        CHECK (country_code ~ '^[A-Z]{2}$'),

    CONSTRAINT substation_voltage_ck
        CHECK (voltage_kv IS NULL OR voltage_kv > 0),

    CONSTRAINT substation_country_source_uq
        UNIQUE (country_code, source_id),

    CONSTRAINT substation_country_id_uq
        UNIQUE (country_code, id),

    CONSTRAINT substation_source_run_fk
        FOREIGN KEY (country_code, source_run_id)
        REFERENCES iris_core.source_run (country_code, id)
);

CREATE INDEX substation_country_region_idx
    ON iris_core.substation (country_code, region_code);

CREATE INDEX substation_source_run_idx
    ON iris_core.substation (country_code, source_run_id);

CREATE INDEX substation_geom_gix
    ON iris_core.substation
    USING GIST (geom);

CREATE INDEX substation_geog_gix
    ON iris_core.substation
    USING GIST ((geom::geography));
