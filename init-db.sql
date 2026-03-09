-- Initialize PostgreSQL database with pgvector extension

-- Create pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create a sample table for vector embeddings
CREATE TABLE IF NOT EXISTS document_embeddings (
    id SERIAL PRIMARY KEY,
    document_id VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    embedding vector(768),  -- 768 dimensions for nomic-embed-text
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster similarity search
CREATE INDEX IF NOT EXISTS document_embeddings_vector_idx 
ON document_embeddings 
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);

-- Create index on document_id for faster lookups
CREATE INDEX IF NOT EXISTS document_embeddings_doc_id_idx 
ON document_embeddings(document_id);

-- Grant permissions
GRANT ALL PRIVILEGES ON TABLE document_embeddings TO ka_user;
GRANT USAGE, SELECT ON SEQUENCE document_embeddings_id_seq TO ka_user;

-- Create a function for similarity search
CREATE OR REPLACE FUNCTION search_similar_documents(
    query_embedding vector(768),
    match_threshold float DEFAULT 0.7,
    match_count int DEFAULT 10
)
RETURNS TABLE (
    id int,
    document_id varchar,
    content text,
    similarity float,
    metadata jsonb
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        document_embeddings.id,
        document_embeddings.document_id,
        document_embeddings.content,
        1 - (document_embeddings.embedding <=> query_embedding) as similarity,
        document_embeddings.metadata
    FROM document_embeddings
    WHERE 1 - (document_embeddings.embedding <=> query_embedding) > match_threshold
    ORDER BY document_embeddings.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- Confirm setup
DO $$
BEGIN
    RAISE NOTICE 'PostgreSQL with pgvector initialized successfully';
    RAISE NOTICE 'Created table: document_embeddings';
    RAISE NOTICE 'Created similarity search function: search_similar_documents()';
END $$;
