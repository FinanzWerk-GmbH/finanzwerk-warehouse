SELECT
    v.vendor_id,
    v.vendor_name,
    v.service_category,
    v.risk_score,
    COUNT(i.incident_id) AS incident_count
FROM vendors v
JOIN ict_incidents i ON i.vendor_id = v.vendor_id
GROUP BY v.vendor_id, v.vendor_name, v.service_category, v.risk_score
ORDER BY incident_count DESC
LIMIT 10;
