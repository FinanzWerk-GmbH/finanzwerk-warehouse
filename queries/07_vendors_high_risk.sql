SELECT
    vendor_id,
    vendor_name,
    service_category,
    risk_score,
    contract_reference
FROM vendors
WHERE risk_score >= 8
ORDER BY risk_score DESC, vendor_name;
