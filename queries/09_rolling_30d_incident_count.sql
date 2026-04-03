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
