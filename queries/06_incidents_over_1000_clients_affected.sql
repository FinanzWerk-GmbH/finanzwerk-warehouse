SELECT
    incident_id,
    occurred_at,
    service_name,
    severity,
    clients_affected_count,
    duration_minutes
FROM ict_incidents
WHERE clients_affected_count > 1000
ORDER BY clients_affected_count DESC;
