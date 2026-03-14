SELECT
    severity,
    COUNT(*) AS incident_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct
FROM ict_incidents
GROUP BY severity
ORDER BY incident_count DESC;
