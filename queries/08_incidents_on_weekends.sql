SELECT
    incident_id,
    occurred_at,
    TO_CHAR(occurred_at, 'Day') AS day_of_week,
    service_name,
    severity,
    clients_affected_count
FROM ict_incidents
WHERE EXTRACT(DOW FROM occurred_at) IN (0, 6)  -- 0 = Sunday, 6 = Saturday
ORDER BY occurred_at DESC;
