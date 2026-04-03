CREATE INDEX idx_ict_incidents_service_occurred
    ON ict_incidents (service_name, occurred_at);

CREATE INDEX idx_ict_incidents_occurred_high_critical
    ON ict_incidents (occurred_at)
    WHERE severity IN ('high', 'critical');
