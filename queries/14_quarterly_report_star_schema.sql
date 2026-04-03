SELECT
    dv.vendor_name,
    dv.service_category,
    dv.risk_score,
    COUNT(*)                                                        AS incident_count,
    SUM(f.clients_affected_count)                                   AS total_clients_affected,
    ROUND(AVG(f.duration_minutes), 0)                               AS avg_duration_minutes,
    COUNT(*) FILTER (WHERE f.is_notified_within_24h)                AS notified_within_24h,
    COUNT(*) FILTER (WHERE NOT f.is_notified_within_24h)            AS not_compliant,
    ROUND(
        COUNT(*) FILTER (WHERE f.is_notified_within_24h)::numeric
        / NULLIF(COUNT(*), 0) * 100,
        1
    )                                                               AS compliance_rate_pct
FROM compliance.fact_ict_incidents f
JOIN compliance.dim_vendor dv
    ON dv.vendor_key = f.vendor_key
   AND dv.valid_to IS NULL
JOIN compliance.dim_date dd
    ON dd.date_key = f.date_key
WHERE dd.year    = EXTRACT(year    FROM now())::int
  AND dd.quarter = EXTRACT(quarter FROM now())::int
  AND f.is_major_incident
GROUP BY dv.vendor_key, dv.vendor_name, dv.service_category, dv.risk_score
ORDER BY incident_count DESC, dv.vendor_name;
