-- ============================================================
-- V18__template_governance_and_snapshot_preservation.sql
-- Template Governance, Version Management & Option A Historical Report Preservation
-- ============================================================

-- 1. Enhance templates table with code, formal status model, and soft-delete timestamp
ALTER TABLE templates
    ADD COLUMN IF NOT EXISTS code VARCHAR(50) DEFAULT 'COMM_VAL_STD',
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL;

-- Normalize existing template statuses to formal 4-state lifecycle (DRAFT, ACTIVE, ARCHIVED, DELETED)
UPDATE templates SET status = 'ACTIVE' WHERE status IN ('CONFIRMED', 'PARSED') AND is_active = 'Y';
UPDATE templates SET status = 'DRAFT' WHERE status IN ('PENDING', 'PARSING');
UPDATE templates SET status = 'ARCHIVED' WHERE is_active = 'N' AND status != 'DELETED';

-- 2. Enhance template_versions with status and placeholder diff audit
ALTER TABLE template_versions
    ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'ACTIVE',
    ADD COLUMN IF NOT EXISTS placeholder_diff JSONB NULL;

-- 3. Enhance orders with immutable template_version_id FK link (Option A preservation)
ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS template_version_id BIGINT NULL;

-- Backfill orders.template_version_id for historical orders from matching template_versions
UPDATE orders o
SET template_version_id = tv.id
FROM template_versions tv
WHERE o.template_version_id IS NULL
  AND o.template_id IS NOT NULL
  AND tv.template_id = o.template_id
  AND tv.version = o.template_version;

-- Fallback for orders whose exact version was not matched: link to latest version of their template
UPDATE orders o
SET template_version_id = sub.id
FROM (
    SELECT DISTINCT ON (template_id) id, template_id
    FROM template_versions
    ORDER BY template_id, version DESC
) sub
WHERE o.template_version_id IS NULL
  AND o.template_id IS NOT NULL
  AND sub.template_id = o.template_id;

-- Index for high-performance versioned template resolution and usage impact aggregation
CREATE INDEX IF NOT EXISTS idx_orders_template_version_id ON orders(template_version_id);
CREATE INDEX IF NOT EXISTS idx_orders_template_id_status ON orders(template_id, status);
CREATE INDEX IF NOT EXISTS idx_templates_status_active ON templates(status, is_active);
CREATE INDEX IF NOT EXISTS idx_template_versions_tpl_ver ON template_versions(template_id, version);
