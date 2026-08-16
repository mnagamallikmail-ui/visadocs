-- ============================================================
-- ProValuer Commercial — V9 Document Studio Foundation
-- Safe Additive Migration: Zero Table Locks, Zero Workflow Disruption
-- ============================================================

-- 1. Document Studio Custom Overrides & Configuration Table
CREATE TABLE IF NOT EXISTS document_studio_configs (
    id BIGSERIAL PRIMARY KEY,
    template_id BIGINT NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    custom_labels TEXT DEFAULT '{}' NOT NULL,
    table_configs TEXT DEFAULT '[]' NOT NULL,
    updated_by BIGINT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL,
    CONSTRAINT uk_document_studio_template UNIQUE (template_id)
);

-- Fast lookup index by template ID
CREATE INDEX IF NOT EXISTS idx_studio_configs_template_id 
ON document_studio_configs(template_id);

-- 2. Seed Initial Feature Flag Values into Existing system_settings Table
INSERT INTO system_settings (setting_key, setting_value, updated_at)
VALUES 
    ('feature_flag_document_studio', 'SUPER_ADMIN_ONLY', NOW()),
    ('document_studio_pilot_users', 'pa@provaluer.com,spa@provaluer.com', NOW())
ON CONFLICT (setting_key) DO NOTHING;
