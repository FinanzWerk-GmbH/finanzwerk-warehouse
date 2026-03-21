-- Rolling 30-day incident count per service.
-- COUNT ... OVER keeps every row visible (unlike GROUP BY which collapses them).
-- RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW creates a
-- time-based window, not a fixed row count, so sparse periods shrink naturally.
SELECT
    incident_id,
    service_name,
    occurred_at,
    severity,
    clients_affected_count,
    COUNT(*) OVER (
        PARTITION BY service_name
        ORDER BY occurred_at
        RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW
    ) AS rolling_30d_count
FROM ict_incidents
ORDER BY service_name, occurred_at;
