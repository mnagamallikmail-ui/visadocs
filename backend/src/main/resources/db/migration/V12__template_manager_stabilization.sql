-- ============================================================
-- ProValuer Commercial — V12 Template Manager Stabilization
-- Hardening, Processing Error Tracking, Timestamps & Full Version History
-- ============================================================

-- 1. Add processing error and timestamp columns to templates table
ALTER TABLE templates 
    ADD COLUMN IF NOT EXISTS processing_error TEXT,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- Ensure created_at exists if missing
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'templates' AND column_name = 'created_at') THEN
        ALTER TABLE templates ADD COLUMN created_at TIMESTAMP DEFAULT NOW();
    END IF;
END $$;

-- 2. Create template_versions table for immutable version snapshotting & rollback
CREATE TABLE IF NOT EXISTS template_versions (
    id BIGSERIAL PRIMARY KEY,
    template_id BIGINT NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    version INTEGER NOT NULL,
    name VARCHAR(255) NOT NULL,
    template_content BYTEA NOT NULL,
    field_mapping TEXT NOT NULL,
    document_dom JSONB,
    placeholder_registry JSONB,
    change_summary VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by BIGINT REFERENCES users(id),
    CONSTRAINT uk_template_version UNIQUE (template_id, version)
);

-- Index for rapid version lookup by template_id
CREATE INDEX IF NOT EXISTS idx_template_versions_template_id 
ON template_versions(template_id);
