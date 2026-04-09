CREATE TABLE dim_service (
    service_name  TEXT      PRIMARY KEY,
    first_seen_at TIMESTAMP NOT NULL DEFAULT now(),
    last_seen_at  TIMESTAMP NOT NULL DEFAULT now()
);

INSERT INTO dim_service (service_name, first_seen_at, last_seen_at)
SELECT
    service_name,
    MIN(occurred_at),
    MAX(occurred_at)
FROM ict_incidents
WHERE service_name IS NOT NULL
GROUP BY service_name
ON CONFLICT DO NOTHING;
