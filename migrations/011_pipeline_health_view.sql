CREATE VIEW compliance.v_pipeline_health AS

SELECT
    'pipeline' AS type,
    pipeline_name AS name,
    CASE
        WHEN MAX(finished_at) FILTER (WHERE status = 'success') IS NULL THEN 'no_success'
        WHEN EXTRACT(EPOCH FROM (now() - MAX(finished_at) FILTER (WHERE status = 'success'))) / 3600 > 25 THEN 'stale'
        ELSE 'ok'
    END AS health,
    ROUND(
        EXTRACT(EPOCH FROM (now() - MAX(finished_at) FILTER (WHERE status = 'success'))) / 3600,
        1
    ) AS hours_since_last_success,
    COUNT(*) FILTER (WHERE status = 'sla_missed' AND started_at >= now() - INTERVAL '7 days') AS sla_misses_7d,
    COUNT(*) FILTER (WHERE status = 'error'      AND started_at >= now() - INTERVAL '7 days') AS errors_7d,
    NULL::numeric AS age_hours,
    NULL::integer AS threshold_hours
FROM compliance.pipeline_runs
GROUP BY pipeline_name

UNION ALL

SELECT
    'freshness' AS type,
    table_name AS name,
    status AS health,
    age_hours AS hours_since_last_success,
    0 AS sla_misses_7d,
    0 AS errors_7d,
    age_hours,
    threshold_hours
FROM (
    SELECT DISTINCT ON (table_name)
        table_name, status, age_hours, threshold_hours
    FROM compliance.data_freshness_alerts
    ORDER BY table_name, checked_at DESC
) latest_per_table

ORDER BY type DESC, name;
