CREATE TABLE iris_core.evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    country_code TEXT NOT NULL,
    source_id TEXT NOT NULL,
    source_date DATE NOT NULL,
    source_run_id UUID NOT NULL,

    parcel_id UUID,
    substation_id UUID,
    peatland_id UUID,
    screening_layer_id UUID,

    evidence_type TEXT NOT NULL,
    uncertainty TEXT NOT NULL DEFAULT 'unknown',
    value JSONB NOT NULL DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT evidence_country_code_ck
        CHECK (country_code ~ '^[A-Z]{2}$'),

    CONSTRAINT evidence_uncertainty_ck
        CHECK (uncertainty IN ('unknown', 'low', 'medium', 'high', 'illustrative')),

    CONSTRAINT evidence_one_target_ck
        CHECK (
            num_nonnulls(
                parcel_id,
                substation_id,
                peatland_id,
                screening_layer_id
            ) = 1
        ),

    CONSTRAINT evidence_country_source_uq
        UNIQUE (country_code, source_id),

    CONSTRAINT evidence_country_id_uq
        UNIQUE (country_code, id),

    CONSTRAINT evidence_source_run_fk
        FOREIGN KEY (country_code, source_run_id)
        REFERENCES iris_core.source_run (country_code, id),

    CONSTRAINT evidence_parcel_fk
        FOREIGN KEY (country_code, parcel_id)
        REFERENCES iris_core.parcel (country_code, id),

    CONSTRAINT evidence_substation_fk
        FOREIGN KEY (country_code, substation_id)
        REFERENCES iris_core.substation (country_code, id),

    CONSTRAINT evidence_peatland_fk
        FOREIGN KEY (country_code, peatland_id)
        REFERENCES iris_core.peatland (country_code, id),

    CONSTRAINT evidence_screening_layer_fk
        FOREIGN KEY (country_code, screening_layer_id)
        REFERENCES iris_core.screening_layer (country_code, id)
);

CREATE INDEX evidence_country_idx
    ON iris_core.evidence (country_code);

CREATE INDEX evidence_source_run_idx
    ON iris_core.evidence (country_code, source_run_id);

CREATE INDEX evidence_parcel_idx
    ON iris_core.evidence (country_code, parcel_id)
    WHERE parcel_id IS NOT NULL;

CREATE INDEX evidence_substation_idx
    ON iris_core.evidence (country_code, substation_id)
    WHERE substation_id IS NOT NULL;
