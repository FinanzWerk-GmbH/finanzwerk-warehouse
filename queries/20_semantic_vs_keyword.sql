-- Comparison: semantic similarity vs keyword search for the same intent.
-- Query intent: "payment service outage affecting many clients"

-- 1. Keyword search (traditional full-text)
-- Finds incidents that contain these specific words. Misses synonyms.
SELECT
    incident_id,
    service_name,
    severity,
    clients_affected_count,
    occurred_at,
    'keyword' AS method
FROM compliance.ict_incidents
WHERE to_tsvector('english', service_name || ' ' || severity)
      @@ plainto_tsquery('english', 'payment failure outage')
ORDER BY occurred_at DESC
LIMIT 10;


-- 2. Semantic similarity search
-- Finds incidents conceptually similar regardless of exact wording.
-- Replace embedding literal with embed_query("payment service outage affecting many clients").
SELECT
    incident_id,
    service_name,
    severity,
    clients_affected_count,
    occurred_at,
    'semantic' AS method
FROM compliance.ict_incidents
WHERE description_embedding IS NOT NULL
ORDER BY description_embedding <=> '[QUERY_EMBEDDING]'::vector
LIMIT 10;


-- 3. Hybrid search: keyword filter narrows the set, vector score ranks within it.
-- Best of both: keyword ensures domain relevance, vector ensures semantic quality.
SELECT
    i.incident_id,
    i.service_name,
    i.severity,
    i.clients_affected_count,
    i.occurred_at,
    round((1 - (i.description_embedding <=> '[QUERY_EMBEDDING]'::vector))::numeric, 4) AS vector_score,
    round(ts_rank(
        to_tsvector('english', i.service_name || ' ' || i.severity),
        plainto_tsquery('english', 'payment failure')
    )::numeric, 4) AS text_score,
    'hybrid' AS method
FROM compliance.ict_incidents i
WHERE i.description_embedding IS NOT NULL
  AND to_tsvector('english', i.service_name || ' ' || i.severity)
      @@ plainto_tsquery('english', 'payment')
ORDER BY vector_score DESC
LIMIT 10;
