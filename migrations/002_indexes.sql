-- Index 1: composite index on (service_name, occurred_at).
-- Covers the rolling-30d window function query (09) and any filter that
-- combines both columns. The planner can satisfy an ORDER BY occurred_at
-- within a service_name prefix without a sort step.
CREATE INDEX idx_ict_incidents_service_occurred
    ON ict_incidents (service_name, occurred_at);

-- Index 2: partial index on occurred_at restricted to high/critical rows.
-- Smaller index footprint than a full occurred_at index; the planner will
-- use it whenever the WHERE clause includes severity IN ('high','critical'),
-- which is the common case for NIS2 compliance queries (12, 13).
CREATE INDEX idx_ict_incidents_occurred_high_critical
    ON ict_incidents (occurred_at)
    WHERE severity IN ('high', 'critical');
