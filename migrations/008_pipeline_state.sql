CREATE TABLE compliance.pipeline_state (
    pipeline_name     TEXT      PRIMARY KEY,
    last_processed_at TIMESTAMP NOT NULL,
    last_run_id       INTEGER   REFERENCES compliance.pipeline_runs (run_id)
);
