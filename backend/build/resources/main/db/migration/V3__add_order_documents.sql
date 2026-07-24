CREATE TABLE order_documents (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    category VARCHAR(100) NOT NULL,
    filename VARCHAR(255) NOT NULL,
    file_content BYTEA NOT NULL,
    uploaded_by BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW() NOT NULL
);
