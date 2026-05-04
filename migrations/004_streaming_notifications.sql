CREATE TABLE IF NOT EXISTS compliance.streaming_notifications (
    notification_id    UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    service_name       TEXT NOT NULL,
    alert_type         TEXT NOT NULL,
    event_count        INTEGER NOT NULL,
    window_minutes     INTEGER NOT NULL,
    latest_incident_id TEXT,
    triggered_at       TIMESTAMPTZ NOT NULL,
    notification_channel TEXT NOT NULL DEFAULT 'streaming-classifier',
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ON compliance.streaming_notifications (service_name, triggered_at DESC);
CREATE INDEX ON compliance.streaming_notifications (triggered_at DESC);
