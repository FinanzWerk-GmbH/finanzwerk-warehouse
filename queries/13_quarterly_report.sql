-- DORA/NIS2 quarterly vendor compliance report, built as a CTE chain.
--
-- Step 1 – incidents_this_quarter: scope to the current calendar quarter.
-- Step 2 – major_incidents: DORA "major ICT incident" filter (severity OR scale).
-- Step 3 – notification_compliance: derive 24-hour NIS2 flag per incident using
--           ict_incidents.notified_at (set at first notification).
-- Step 4 – vendor_summary: aggregate per vendor.
-- Final SELECT: join vendors dimension, compute compliance rate %.
--
-- CTE note: PostgreSQL 12+ inlines CTEs by default (not an optimisation fence),
-- so the planner can push predicates through. Add MATERIALIZED to any CTE to
-- force independent execution and cache its result.

WITH incidents_this_quarter AS (
    SELECT *
    FROM ict_incidents
    WHERE occurred_at >= date_trunc('quarter', now())
      AND occurred_at <  date_trunc('quarter', now()) + INTERVAL '3 months'
),

major_incidents AS (
    -- DORA Art. 18: high/critical severity OR > 1,000 clients affected.
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
ORDER BY vs.incident_count DESC, v.vendor_name;
