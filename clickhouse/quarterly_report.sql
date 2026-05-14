-- Quarterly DORA compliance report — ClickHouse version.
-- Same logic as queries/13_quarterly_dora_report.sql in finanzwerk-warehouse,
-- written in ClickHouse SQL (countIf, avgIf instead of COUNT FILTER, toYear/toQuarter instead of EXTRACT).
--
-- Run: SELECT * FROM ... FORMAT Pretty

WITH
incident_base AS (
    SELECT
        toYear(occurred_at)    AS year,
        toQuarter(occurred_at) AS quarter,
        incident_id,
        severity,
        clients_affected_count,
        duration_minutes,
        vendor_id,
        notified_at,
        occurred_at,
        -- major incident definition mirrors the dbt macro
        (severity = 'critical'
          OR clients_affected_count > 1000
          OR (duration_minutes > 120 AND severity = 'high')) AS is_major
    FROM compliance.ict_incidents
),
notification_check AS (
    SELECT
        year,
        quarter,
        count()                                                          AS total_incidents,
        countIf(is_major)                                                AS major_incidents,
        countIf(is_major AND isNull(notified_at))                        AS gaps_no_notification,
        countIf(
            is_major
            AND isNotNull(notified_at)
            AND dateDiff('second', occurred_at, notified_at) > 4 * 3600
        )                                                                AS gaps_late_notification,
        round(avgIf(duration_minutes, severity = 'critical'), 0)         AS avg_critical_duration_min,
        sum(clients_affected_count)                                      AS total_clients_affected
    FROM incident_base
    GROUP BY year, quarter
),
vendor_concentration AS (
    SELECT
        toYear(i.occurred_at)    AS year,
        toQuarter(i.occurred_at) AS quarter,
        count(DISTINCT i.vendor_id)                                      AS unique_vendors,
        round(avg(v.risk_score), 2)                                      AS avg_vendor_risk_score,
        countIf(i.clients_affected_count > 5000)                         AS high_impact_events
    FROM compliance.ict_incidents i
    LEFT JOIN compliance.vendors v ON v.vendor_id = i.vendor_id
    GROUP BY year, quarter
)
SELECT
    nc.year,
    nc.quarter,
    nc.total_incidents,
    nc.major_incidents,
    nc.gaps_no_notification + nc.gaps_late_notification                  AS total_compliance_gaps,
    round(
        100.0 * (nc.major_incidents - nc.gaps_no_notification - nc.gaps_late_notification)
        / nullIf(nc.major_incidents, 0), 1
    )                                                                    AS notification_compliance_pct,
    nc.avg_critical_duration_min,
    nc.total_clients_affected,
    vc.unique_vendors,
    vc.avg_vendor_risk_score,
    vc.high_impact_events
FROM notification_check nc
JOIN vendor_concentration vc USING (year, quarter)
ORDER BY nc.year DESC, nc.quarter DESC;
