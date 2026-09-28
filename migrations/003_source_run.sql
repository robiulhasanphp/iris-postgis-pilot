CREATE TABLE iris_core.source_run (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    country_code TEXT NOT NULL,
    source_id TEXT NOT NULL,
    source_date DATE NOT NULL,

    source_name TEXT NOT NULL,
    source_version TEXT,
    status TEXT NOT NULL DEFAULT 'loaded',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT source_run_country_code_ck
        CHECK (country_code ~ '^[A-Z]{2}$'),

    CONSTRAINT source_run_status_ck
        CHECK (status IN ('loaded', 'failed', 'superseded')),

    CONSTRAINT source_run_country_source_uq
        UNIQUE (country_code, source_id),

    CONSTRAINT source_run_country_id_uq
        UNIQUE (country_code, id)
);

CREATE INDEX source_run_country_date_idx
    ON iris_core.source_run (country_code, source_date);
