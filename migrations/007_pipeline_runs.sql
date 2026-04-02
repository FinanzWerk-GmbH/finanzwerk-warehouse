CREATE TABLE compliance.pipeline_runs (
    run_id          SERIAL    PRIMARY KEY,
    pipeline_name   TEXT      NOT NULL,
    started_at      TIMESTAMP NOT NULL DEFAULT now(),
    finished_at     TIMESTAMP,
    rows_processed  INTEGER,
    rows_quarantined INTEGER,
    status          TEXT      NOT NULL DEFAULT 'running'
                              CHECK (status IN ('running', 'success', 'error'))
);
