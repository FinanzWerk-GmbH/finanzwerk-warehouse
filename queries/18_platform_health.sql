SELECT
    type,
    name,
    health,
    hours_since_last_success,
    sla_misses_7d,
    errors_7d,
    age_hours,
    threshold_hours
FROM compliance.v_pipeline_health
ORDER BY
    CASE health WHEN 'stale' THEN 0 WHEN 'no_success' THEN 1 ELSE 2 END,
    type,
    name;
