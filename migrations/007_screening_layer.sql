CREATE TABLE iris_core.screening_layer (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    country_code TEXT NOT NULL,
    region_code TEXT NOT NULL,
    source_id TEXT NOT NULL,
    source_date DATE NOT NULL,
    source_run_id UUID NOT NULL,

    layer_type TEXT NOT NULL,

    geom geometry(MultiPolygon, 4326) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT screening_layer_country_code_ck
        CHECK (country_code ~ '^[A-Z]{2}$'),

    CONSTRAINT screening_layer_country_source_uq
        UNIQUE (country_code, source_id),

    CONSTRAINT screening_layer_country_id_uq
        UNIQUE (country_code, id),

    CONSTRAINT screening_layer_source_run_fk
        FOREIGN KEY (country_code, source_run_id)
        REFERENCES iris_core.source_run (country_code, id)
);

CREATE INDEX screening_layer_country_region_idx
    ON iris_core.screening_layer (country_code, region_code);

CREATE INDEX screening_layer_source_run_idx
    ON iris_core.screening_layer (country_code, source_run_id);

CREATE INDEX screening_layer_geom_gix
    ON iris_core.screening_layer
    USING GIST (geom);
