-- =========================================================================
-- V34__dpdp_batch2_security_hardening.sql
-- DPDP Act 2023 - Batch 2 Security Hardening:
-- 1. Expand order_invoices.client_pan to accommodate AES-256-GCM ciphertext
-- 2. Add document encryption metadata to lead_documents
-- 3. Create document_access_logs table for access auditing
-- =========================================================================

-- 1. Expand client_pan length for AES-256-GCM ciphertext + IV (ENC_GCM:...)
ALTER TABLE order_invoices ALTER COLUMN client_pan TYPE VARCHAR(255);

-- 2. Add encryption metadata columns to lead_documents if not present
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_documents' AND column_name = 'is_encrypted'
    ) THEN
        ALTER TABLE lead_documents ADD COLUMN is_encrypted BOOLEAN NOT NULL DEFAULT TRUE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_documents' AND column_name = 'encryption_iv'
    ) THEN
        ALTER TABLE lead_documents ADD COLUMN encryption_iv VARCHAR(64);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lead_documents' AND column_name = 'key_version'
    ) THEN
        ALTER TABLE lead_documents ADD COLUMN key_version VARCHAR(32) DEFAULT 'v1-aes256-gcm';
    END IF;
END $$;

-- 3. Create document_access_logs table for single-use / expiring download security & access audits
CREATE TABLE IF NOT EXISTS document_access_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    username VARCHAR(100),
    document_type VARCHAR(64) NOT NULL,
    document_id VARCHAR(128) NOT NULL,
    document_name VARCHAR(255),
    action VARCHAR(64) NOT NULL,
    token_used VARCHAR(128),
    ip_address VARCHAR(64),
    user_agent TEXT,
    access_status VARCHAR(32) NOT NULL DEFAULT 'SUCCESS',
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_doc_access_logs_user ON document_access_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_doc_access_logs_doc ON document_access_logs(document_type, document_id);
CREATE INDEX IF NOT EXISTS idx_doc_access_logs_created ON document_access_logs(created_at);
