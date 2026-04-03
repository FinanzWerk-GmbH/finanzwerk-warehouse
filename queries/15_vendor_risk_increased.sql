SELECT
    vendor_id,
    vendor_name,
    service_category,
    previous_risk_score,
    risk_score                        AS current_risk_score,
    risk_score - previous_risk_score  AS increase
FROM vendors
WHERE previous_risk_score IS NOT NULL
  AND risk_score - previous_risk_score > 2
ORDER BY increase DESC;
