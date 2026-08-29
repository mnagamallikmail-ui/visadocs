-- ============================================================
-- ProValuer Commercial — V10 Document Workspace Engine Migration
-- Transition to PDF Overlay Document-Driven Architecture
-- ============================================================

-- 1. Extend templates table with canonical document DOM and placeholder registry
-- (Note: templates.version already exists in V1__init_schema.sql)
ALTER TABLE templates 
    ADD COLUMN IF NOT EXISTS document_dom JSONB,
    ADD COLUMN IF NOT EXISTS placeholder_registry JSONB;

-- 2. Extend orders table with immutable DOM snapshot, structured input values JSON, and template version pin
ALTER TABLE orders 
    ADD COLUMN IF NOT EXISTS document_dom_snapshot JSONB,
    ADD COLUMN IF NOT EXISTS input_values JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS template_version INTEGER DEFAULT 1;

-- 3. Document deprecation of synthetic question artifacts
COMMENT ON COLUMN templates.field_mapping IS 'DEPRECATED: Legacy synthetic field mapping. Use document_dom & placeholder_registry.';
COMMENT ON COLUMN orders.field_mapping_snapshot IS 'DEPRECATED: Legacy synthetic field mapping snapshot. Use document_dom_snapshot & input_values.';
