CREATE EXTENSION IF NOT EXISTS vector;

ALTER TABLE compliance.ict_incidents
    ADD COLUMN IF NOT EXISTS description_embedding vector(1024);

CREATE TABLE IF NOT EXISTS compliance.regulatory_docs (
    doc_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source            TEXT NOT NULL,
    article           TEXT NOT NULL,
    content           TEXT NOT NULL,
    content_embedding vector(1024),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ict_incidents_embedding_hnsw
    ON compliance.ict_incidents
    USING hnsw (description_embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

CREATE INDEX IF NOT EXISTS regulatory_docs_embedding_hnsw
    ON compliance.regulatory_docs
    USING hnsw (content_embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

CREATE INDEX IF NOT EXISTS regulatory_docs_source_idx
    ON compliance.regulatory_docs (source);
