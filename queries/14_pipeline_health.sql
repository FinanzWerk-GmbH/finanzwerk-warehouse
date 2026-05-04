WITH pipeline_summary AS (
    SELECT
        pipeline_name,
        COUNT(*)                                                              AS total_runs,
        COUNT(*) FILTER (WHERE status = 'success')                            AS successful_runs,
        COUNT(*) FILTER (WHERE status = 'error')                              AS failed_runs,
        ROUND(
            100.0 * COUNT(*) FILTER (WHERE status = 'success')
            / NULLIF(COUNT(*), 0), 1
        )                                                                     AS success_rate_pct,
        MAX(started_at)                                                       AS last_run_at,
        ROUND(AVG(
            EXTRACT(EPOCH FROM (finished_at - started_at))
        ), 0)                                                                 AS avg_duration_sec
    FROM compliance.pipeline_runs
    WHERE started_at >= NOW() - INTERVAL '7 days'
    GROUP BY pipeline_name
),
streaming_alerts AS (
    SELECT
        service_name,
        COUNT(*)                                                              AS total_alerts,
        COUNT(*) FILTER (WHERE triggered_at >= NOW() - INTERVAL '24 hours')  AS alerts_last_24h,
        MAX(triggered_at)                                                     AS last_alert_at
    FROM compliance.streaming_notifications
    GROUP BY service_name
)
SELECT
    'pipeline_run'                                                            AS metric_type,
    pipeline_name                                                             AS name,
    total_runs::text                                                          AS metric_a,
    successful_runs::text                                                     AS metric_b,
    failed_runs::text                                                         AS metric_c,
    success_rate_pct::text                                                    AS metric_d,
    last_run_at::text                                                         AS last_event_at,
    avg_duration_sec::text                                                    AS extra
FROM pipeline_summary

UNION ALL

SELECT
    'streaming_alert',
    service_name,
    total_alerts::text,
    alerts_last_24h::text,
    NULL,
    NULL,
    last_alert_at::text,
    NULL
FROM streaming_alerts

ORDER BY metric_type, name;
