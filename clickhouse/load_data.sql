-- Load operational data from PostgreSQL into ClickHouse using the built-in postgresql() table function.
-- Requires ClickHouse to have network access to PostgreSQL (both in-cluster: use svc FQDN).
-- Run from clickhouse-client connected to the ClickHouse instance.

-- Load incidents (public schema is default, no prefix needed)
INSERT INTO compliance.ict_incidents
    (incident_id, occurred_at, service_name, severity,
     clients_affected_count, duration_minutes, vendor_id, notified_at)
SELECT
    toUUID(toString(incident_id)),
    toDateTime(occurred_at),
    service_name,
    severity,
    toUInt32(clients_affected_count),
    toUInt32(duration_minutes),
    toUUID(toString(vendor_id)),
    if(notified_at IS NOT NULL, toDateTime(notified_at), NULL)
FROM postgresql(
    'postgres-rw.postgres.svc.cluster.local:5432',
    'finanzwerk',
    'ict_incidents',
    'readwrite',
    'readwrite_password'
);

-- Load vendors
INSERT INTO compliance.vendors
    (vendor_id, vendor_name, service_category, risk_score, contract_reference)
SELECT
    toUUID(toString(vendor_id)),
    vendor_name,
    service_category,
    toFloat32(risk_score),
    coalesce(contract_reference, '')
FROM postgresql(
    'postgres-rw.postgres.svc.cluster.local:5432',
    'finanzwerk',
    'vendors',
    'readwrite',
    'readwrite_password'
);

SELECT 'loaded incidents:' AS msg, count() FROM compliance.ict_incidents;
SELECT 'loaded vendors:'   AS msg, count() FROM compliance.vendors;
