-- Notification delay and NIS2 24-hour compliance status for high/critical incidents.
-- Joins notification_log so each notification entry is one row.
-- ROW_NUMBER() within incident_id reveals whether regulators were reached on
-- the first attempt or required a follow-up.
-- nis2_status: NOT_NOTIFIED | COMPLIANT (≤24 h) | BREACHED (>24 h).
SELECT
    i.incident_id,
    i.service_name,
    i.occurred_at,
    i.severity,
    i.clients_affected_count,
    n.notification_type,
    n.sent_at                                              AS notification_sent_at,
    ROW_NUMBER() OVER (
        PARTITION BY i.incident_id
        ORDER BY n.sent_at
    )                                                      AS notification_sequence,
    ROUND(
        EXTRACT(EPOCH FROM (n.sent_at - i.occurred_at)) / 3600.0,
        2
    )                                                      AS delay_hours,
    CASE
        WHEN n.sent_at IS NULL                                 THEN 'NOT_NOTIFIED'
        WHEN n.sent_at - i.occurred_at <= INTERVAL '24 hours' THEN 'COMPLIANT'
        ELSE                                                        'BREACHED'
    END                                                    AS nis2_status
FROM ict_incidents i
LEFT JOIN notification_log n ON n.incident_id = i.incident_id
WHERE i.severity IN ('high', 'critical')
ORDER BY i.occurred_at DESC, i.incident_id, notification_sequence;
