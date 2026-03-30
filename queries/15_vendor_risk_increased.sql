-- Type 3 detection: vendors whose risk score jumped by more than 2 points.
-- A sudden increase is a DORA red flag — may indicate a vendor deterioration event
-- that needs to be cross-referenced against incidents in that period.
-- previous_risk_score is NULL for vendors that have never been updated.
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
