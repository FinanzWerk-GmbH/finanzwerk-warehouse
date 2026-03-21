-- Separate schema for compliance reporting objects.
CREATE SCHEMA IF NOT EXISTS compliance;

-- Materialized view: pre-computed quarterly vendor summary.
-- Refreshing takes seconds on large tables; reads are sub-millisecond.
-- Tradeoff: data is as fresh as the last REFRESH — not real-time.
CREATE MATERIALIZED VIEW compliance.mv_quarterly_summary AS
WITH incidents_this_quarter AS (
    SELECT *
    FROM ict_incidents
    WHERE occurred_at >= date_trunc('quarter', now())
      AND occurred_at <  date_trunc('quarter', now()) + INTERVAL '3 months'
),

major_incidents AS (
    SELECT *
    FROM incidents_this_quarter
    WHERE severity IN ('high', 'critical')
       OR clients_affected_count > 1000
),

notification_compliance AS (
    SELECT
        incident_id,
        service_name,
        occurred_at,
        severity,
        clients_affected_count,
        duration_minutes,
        vendor_id,
        notified_at,
        CASE
            WHEN notified_at IS NULL                                 THEN false
            WHEN notified_at - occurred_at <= INTERVAL '24 hours'   THEN true
            ELSE                                                          false
        END AS within_24h
    FROM major_incidents
),

vendor_summary AS (
    SELECT
        vendor_id,
        COUNT(*)                                               AS incident_count,
        SUM(clients_affected_count)                           AS total_clients_affected,
        ROUND(AVG(duration_minutes), 0)                       AS avg_duration_minutes,
        COUNT(*) FILTER (WHERE within_24h)                    AS notified_within_24h,
        COUNT(*) FILTER (WHERE NOT within_24h)                AS not_compliant
    FROM notification_compliance
    WHERE vendor_id IS NOT NULL
    GROUP BY vendor_id
)

SELECT
    v.vendor_id,
    v.vendor_name,
    v.service_category,
    v.risk_score,
    vs.incident_count,
    vs.total_clients_affected,
    vs.avg_duration_minutes,
    vs.notified_within_24h,
    vs.not_compliant,
    ROUND(
        vs.notified_within_24h::numeric / NULLIF(vs.incident_count, 0) * 100,
        1
    )                                                         AS compliance_rate_pct
FROM vendor_summary vs
JOIN vendors v ON v.vendor_id = vs.vendor_id
ORDER BY vs.incident_count DESC, v.vendor_name
WITH DATA;

-- Unique index is required for REFRESH MATERIALIZED VIEW CONCURRENTLY.
-- CONCURRENTLY allows reads during refresh without a full table lock.
CREATE UNIQUE INDEX ON compliance.mv_quarterly_summary (vendor_id);

-- ── How to use ────────────────────────────────────────────────────────────────
-- Query (milliseconds, reads pre-computed rows):
--   SELECT * FROM compliance.mv_quarterly_summary;
--
-- Refresh nightly (e.g. from a cron job or Airflow DAG):
--   REFRESH MATERIALIZED VIEW CONCURRENTLY compliance.mv_quarterly_summary;
--
-- Check data age:
--   SELECT last_modified
--   FROM pg_stat_user_tables
--   WHERE relname = 'mv_quarterly_summary';
