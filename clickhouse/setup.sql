-- Run against ClickHouse HTTP interface:
-- clickhouse-client --host localhost --port 9000 --user admin --password clickhouse_admin

CREATE DATABASE IF NOT EXISTS compliance;

-- Primary incidents table for analytical queries.
-- MergeTree: partitioned by month, ordered by (occurred_at, service_name) for common filters.
CREATE TABLE IF NOT EXISTS compliance.ict_incidents (
    incident_id      UUID,
    occurred_at      DateTime,
    service_name     LowCardinality(String),
    severity         LowCardinality(String),
    clients_affected_count UInt32,
    duration_minutes UInt32,
    vendor_id        UUID,
    notified_at      Nullable(DateTime),
    created_at       DateTime DEFAULT now()
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(occurred_at)
ORDER BY (occurred_at, service_name, severity);

-- Vendors table for joins in analytical queries.
CREATE TABLE IF NOT EXISTS compliance.vendors (
    vendor_id        UUID,
    vendor_name      String,
    service_category LowCardinality(String),
    risk_score       Float32,
    contract_reference String,
    created_at       DateTime DEFAULT now()
) ENGINE = MergeTree()
ORDER BY (service_category, vendor_id);

-- ReplacingMergeTree variant of incidents — demonstrates deduplication.
-- Insert the same incident_id multiple times; FINAL or background merge deduplicates.
CREATE TABLE IF NOT EXISTS compliance.ict_incidents_dedup (
    incident_id      UUID,
    occurred_at      DateTime,
    service_name     LowCardinality(String),
    severity         LowCardinality(String),
    clients_affected_count UInt32,
    duration_minutes UInt32,
    vendor_id        UUID,
    notified_at      Nullable(DateTime),
    -- _version used by ReplacingMergeTree to pick the latest row on merge
    _version         UInt64 DEFAULT toUnixTimestamp64Milli(now64())
) ENGINE = ReplacingMergeTree(_version)
ORDER BY incident_id;
