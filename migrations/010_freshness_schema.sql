CREATE TABLE compliance.data_freshness_alerts (
    alert_id        SERIAL    PRIMARY KEY,
    checked_at      TIMESTAMP NOT NULL DEFAULT now(),
    table_name      TEXT      NOT NULL,
    max_record_at   TIMESTAMP,
    age_hours       NUMERIC(8,2),
    threshold_hours INTEGER   NOT NULL,
    status          TEXT      NOT NULL CHECK (status IN ('ok', 'stale'))
);

CREATE INDEX ON compliance.data_freshness_alerts (table_name, checked_at DESC);
