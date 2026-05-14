-- Incremental materialized view: weekly incident counts by service and severity.
-- Unlike PostgreSQL materialized views (full refresh), ClickHouse MVs update as rows are inserted.
-- Insert a row into compliance.ict_incidents and this view reflects it immediately.

-- Backing table: AggregatingMergeTree stores partial aggregation state
CREATE TABLE IF NOT EXISTS compliance.weekly_incident_counts_agg (
    week_start   Date,
    service_name LowCardinality(String),
    severity     LowCardinality(String),
    incident_count AggregateFunction(count),
    total_clients  AggregateFunction(sum, UInt32)
) ENGINE = AggregatingMergeTree()
ORDER BY (week_start, service_name, severity);

-- Materialized view feeds from ict_incidents on every INSERT
CREATE MATERIALIZED VIEW IF NOT EXISTS compliance.mv_weekly_incident_counts
TO compliance.weekly_incident_counts_agg
AS
SELECT
    toMonday(occurred_at)          AS week_start,
    service_name,
    severity,
    countState()                   AS incident_count,
    sumState(clients_affected_count) AS total_clients
FROM compliance.ict_incidents
GROUP BY week_start, service_name, severity;

-- Query the MV (merge partial states with Merge suffix functions)
-- SELECT
--     week_start,
--     service_name,
--     severity,
--     countMerge(incident_count)  AS incident_count,
--     sumMerge(total_clients)     AS total_clients_affected
-- FROM compliance.weekly_incident_counts_agg
-- GROUP BY week_start, service_name, severity
-- ORDER BY week_start DESC, incident_count DESC;

-- Simpler read-friendly view over the AggregatingMergeTree
CREATE VIEW IF NOT EXISTS compliance.weekly_incident_summary AS
SELECT
    week_start,
    service_name,
    severity,
    countMerge(incident_count)     AS incident_count,
    sumMerge(total_clients)        AS total_clients_affected
FROM compliance.weekly_incident_counts_agg
GROUP BY week_start, service_name, severity
ORDER BY week_start DESC, incident_count DESC;
