-- Type 1: display_name on dim_service — overwrite on change, no history.
ALTER TABLE compliance.dim_service
    ADD COLUMN display_name TEXT;

-- Type 3: previous_risk_score on vendors — tracks one level of history.
-- risk_score stays as the current value; previous_risk_score holds what it was before.
ALTER TABLE vendors
    ADD COLUMN previous_risk_score NUMERIC(3,1);

-- Type 4: compliance config split into a slim current table and a full history table.
-- config_current is the fast lookup path; config_history is the audit trail.
CREATE TABLE compliance.config_current (
    key        TEXT      PRIMARY KEY,
    value      TEXT      NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE compliance.config_history (
    id         SERIAL    PRIMARY KEY,
    key        TEXT      NOT NULL,
    value      TEXT      NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT now(),
    changed_by TEXT      NOT NULL
);

CREATE INDEX idx_config_history_key_time
    ON compliance.config_history (key, changed_at DESC);
