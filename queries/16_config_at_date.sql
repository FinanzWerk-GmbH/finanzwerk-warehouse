SELECT DISTINCT ON (key)
    key,
    value,
    changed_at,
    changed_by
FROM compliance.config_history
WHERE changed_at <= '2026-01-01 00:00:00'
ORDER BY key, changed_at DESC;
