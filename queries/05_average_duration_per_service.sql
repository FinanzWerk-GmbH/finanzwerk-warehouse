SELECT
    service_name,
    COUNT(*)                              AS incident_count,
    ROUND(AVG(duration_minutes), 2)       AS avg_duration_minutes,
    MIN(duration_minutes)                 AS min_duration_minutes,
    MAX(duration_minutes)                 AS max_duration_minutes
FROM ict_incidents
GROUP BY service_name
ORDER BY avg_duration_minutes DESC;
