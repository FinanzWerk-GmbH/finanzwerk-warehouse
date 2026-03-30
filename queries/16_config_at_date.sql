-- Type 4 point-in-time audit: the value of every config key as of a given timestamp.
-- DISTINCT ON (key) keeps only the most recent change at or before the target time.
-- Swap the timestamp to reconstruct the config state during any past incident.
SELECT DISTINCT ON (key)
    key,
    value,
    changed_at,
    changed_by
FROM compliance.config_history
WHERE changed_at <= '2026-01-01 00:00:00'
ORDER BY key, changed_at DESC;
