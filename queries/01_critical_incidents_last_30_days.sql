SELECT
    incident_id,
    occurred_at,
    service_name,
    clients_affected_count,
    duration_minutes,
    notified_at
FROM ict_incidents
WHERE severity = 'critical'
  AND occurred_at >= now() - INTERVAL '30 days'
ORDER BY occurred_at DESC;
