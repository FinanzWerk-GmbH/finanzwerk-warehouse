SELECT
    incident_id,
    service_name,
    occurred_at,
    severity,
    previous_incident_at,
    ROUND(
        EXTRACT(EPOCH FROM (occurred_at - previous_incident_at)) / 3600.0,
        2
    ) AS hours_since_previous
FROM (
    SELECT
        incident_id,
        service_name,
        occurred_at,
        severity,
        LAG(occurred_at) OVER (
            PARTITION BY service_name
            ORDER BY occurred_at
        ) AS previous_incident_at
    FROM ict_incidents
) lagged
ORDER BY service_name, occurred_at;
