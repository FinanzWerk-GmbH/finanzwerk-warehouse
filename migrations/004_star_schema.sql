CREATE TABLE compliance.dim_date (
    date_key     INTEGER  PRIMARY KEY,  -- YYYYMMDD
    full_date    DATE     NOT NULL UNIQUE,
    day_of_week  TEXT     NOT NULL,
    week_number  INTEGER  NOT NULL,
    quarter      INTEGER  NOT NULL CHECK (quarter BETWEEN 1 AND 4),
    year         INTEGER  NOT NULL,
    is_weekend   BOOLEAN  NOT NULL
);

-- SCD Type 2: valid_to IS NULL = current record for this vendor_id
CREATE TABLE compliance.dim_vendor (
    vendor_key        SERIAL       PRIMARY KEY,
    vendor_id         UUID         NOT NULL,
    vendor_name       TEXT         NOT NULL,
    service_category  TEXT         NOT NULL,
    risk_score        NUMERIC(3,1) NOT NULL,
    valid_from        TIMESTAMP    NOT NULL,
    valid_to          TIMESTAMP
);

CREATE UNIQUE INDEX idx_dim_vendor_current
    ON compliance.dim_vendor (vendor_id)
    WHERE valid_to IS NULL;

CREATE TABLE compliance.dim_service (
    service_key   SERIAL  PRIMARY KEY,
    service_name  TEXT    NOT NULL UNIQUE,
    service_tier  TEXT    NOT NULL DEFAULT 'standard',
    display_name  TEXT
);

-- is_major_incident and is_notified_within_24h computed on load, not at query time
CREATE TABLE compliance.fact_ict_incidents (
    incident_key            SERIAL         PRIMARY KEY,
    incident_id             UUID           NOT NULL UNIQUE,
    date_key                INTEGER        NOT NULL REFERENCES compliance.dim_date (date_key),
    vendor_key              INTEGER        REFERENCES compliance.dim_vendor (vendor_key),
    service_key             INTEGER        NOT NULL REFERENCES compliance.dim_service (service_key),
    severity                severity_level NOT NULL,
    duration_minutes        INTEGER        NOT NULL,
    clients_affected_count  INTEGER        NOT NULL,
    is_major_incident       BOOLEAN        NOT NULL,
    is_notified_within_24h  BOOLEAN        NOT NULL
);

CREATE INDEX idx_fact_incidents_date   ON compliance.fact_ict_incidents (date_key);
CREATE INDEX idx_fact_incidents_vendor ON compliance.fact_ict_incidents (vendor_key);
CREATE INDEX idx_fact_incidents_date_major
    ON compliance.fact_ict_incidents (date_key)
    WHERE is_major_incident;
