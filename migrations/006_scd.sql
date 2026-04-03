ALTER TABLE vendors
    ADD COLUMN previous_risk_score NUMERIC(3,1);

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
