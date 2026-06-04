-- Find incidents semantically similar to a given description.
-- Replace the embedding literal with the output of embed_query() from rag/retrieval.py.

SELECT
    i.incident_id,
    i.service_name,
    i.severity,
    i.clients_affected_count,
    i.occurred_at,
    i.notified_at,
    round((1 - (i.description_embedding <=> '[QUERY_EMBEDDING]'::vector))::numeric, 4) AS similarity
FROM compliance.ict_incidents i
WHERE i.description_embedding IS NOT NULL
ORDER BY i.description_embedding <=> '[QUERY_EMBEDDING]'::vector
LIMIT 5;


-- Find DORA/NIS2 articles relevant to an incident description.

SELECT
    rd.source,
    rd.article,
    rd.content,
    round((1 - (rd.content_embedding <=> '[INCIDENT_EMBEDDING]'::vector))::numeric, 4) AS relevance
FROM compliance.regulatory_docs rd
WHERE rd.content_embedding IS NOT NULL
ORDER BY rd.content_embedding <=> '[INCIDENT_EMBEDDING]'::vector
LIMIT 3;
