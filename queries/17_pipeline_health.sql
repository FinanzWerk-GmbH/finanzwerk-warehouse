SELECT
    ps.pipeline_name,
    ps.last_processed_at,
    pr.rows_processed,
    pr.rows_quarantined,
    pr.status,
    ROUND(EXTRACT(EPOCH FROM (now() - ps.last_processed_at)) / 3600, 1) AS hours_since_last_run,
    CASE
        WHEN EXTRACT(EPOCH FROM (now() - ps.last_processed_at)) / 3600 >= 25 THEN 'STALE'
        ELSE 'ok'
    END AS health
FROM compliance.pipeline_state ps
JOIN compliance.pipeline_runs pr ON pr.run_id = ps.last_run_id
ORDER BY hours_since_last_run DESC;
