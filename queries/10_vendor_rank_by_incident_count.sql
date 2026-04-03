SELECT
    v.vendor_name,
    v.service_category,
    v.risk_score,
    COUNT(i.incident_id)                                   AS total_incidents,
    RANK() OVER (
        ORDER BY COUNT(i.incident_id) DESC
    )                                                      AS global_rank,
    RANK() OVER (
        PARTITION BY v.service_category
        ORDER BY COUNT(i.incident_id) DESC
    )                                                      AS category_rank
FROM vendors v
LEFT JOIN ict_incidents i ON i.vendor_id = v.vendor_id
GROUP BY v.vendor_id, v.vendor_name, v.service_category, v.risk_score
ORDER BY global_rank, v.vendor_name;
