CREATE TABLE compliance.hub_vendor (
    hub_vendor_key  SERIAL    PRIMARY KEY,
    vendor_id       UUID      NOT NULL UNIQUE,
    load_timestamp  TIMESTAMP NOT NULL DEFAULT now(),
    record_source   TEXT      NOT NULL
);

-- is_current is a convenience flag; strict DV2.0 uses MAX(load_timestamp) instead
CREATE TABLE compliance.sat_vendor_details (
    hub_vendor_key      INTEGER      NOT NULL REFERENCES compliance.hub_vendor (hub_vendor_key),
    load_timestamp      TIMESTAMP    NOT NULL,
    vendor_name         TEXT         NOT NULL,
    service_category    TEXT         NOT NULL,
    risk_score          NUMERIC(3,1) NOT NULL,
    contract_reference  TEXT         NOT NULL,
    is_current          BOOLEAN      NOT NULL DEFAULT true,
    PRIMARY KEY (hub_vendor_key, load_timestamp)
);

CREATE UNIQUE INDEX idx_sat_vendor_current
    ON compliance.sat_vendor_details (hub_vendor_key)
    WHERE is_current;

CREATE TABLE compliance.lnk_vendor_incident (
    link_key        SERIAL    PRIMARY KEY,
    hub_vendor_key  INTEGER   NOT NULL REFERENCES compliance.hub_vendor (hub_vendor_key),
    incident_id     UUID      NOT NULL REFERENCES ict_incidents (incident_id),
    load_timestamp  TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (hub_vendor_key, incident_id)
);
