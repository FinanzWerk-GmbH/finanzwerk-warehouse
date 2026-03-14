CREATE TYPE severity_level AS ENUM ('low', 'medium', 'high', 'critical');

CREATE TABLE vendors (
    vendor_id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_name        TEXT         NOT NULL,
    service_category   TEXT         NOT NULL,
    risk_score         NUMERIC(3,1) NOT NULL CHECK (risk_score BETWEEN 1 AND 10),
    contract_reference TEXT         NOT NULL,
    created_at         TIMESTAMP    NOT NULL DEFAULT now()
);

CREATE TABLE ict_incidents (
    incident_id            UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    occurred_at            TIMESTAMP      NOT NULL,
    service_name           TEXT           NOT NULL,
    severity               severity_level NOT NULL,
    clients_affected_count INTEGER        NOT NULL,
    duration_minutes       INTEGER        NOT NULL,
    vendor_id              UUID           REFERENCES vendors (vendor_id),
    notified_at            TIMESTAMP,
    created_at             TIMESTAMP      NOT NULL DEFAULT now()
);

CREATE TABLE notification_log (
    notification_id   UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id       UUID      NOT NULL REFERENCES ict_incidents (incident_id),
    notification_type TEXT      NOT NULL,
    sent_at           TIMESTAMP NOT NULL,
    schema_version    TEXT      NOT NULL
);
