SELECT
    i.incident_id,
    i.occurred_at,
    i.service_name,
    i.severity,
    i.clients_affected_count
FROM ict_incidents i
LEFT JOIN notification_log n ON n.incident_id = i.incident_id
WHERE n.notification_id IS NULL
ORDER BY i.occurred_at DESC;
