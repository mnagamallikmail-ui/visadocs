-- ============================================================
-- V20__backfill_legacy_template_version_snapshots.sql
-- Backfill initial immutable version snapshot for legacy templates missing version records
-- ============================================================

INSERT INTO template_versions (
    template_id,
    version,
    name,
    template_content,
    field_mapping,
    document_dom,
    placeholder_registry,
    change_summary,
    created_at,
    created_by,
    status
)
SELECT 
    t.id,
    COALESCE(NULLIF(t.version, 0), 1),
    t.name,
    t.template_content,
    t.field_mapping,
    t.document_dom,
    t.placeholder_registry,
    'Initial immutable version snapshot for legacy template',
    t.created_at,
    t.uploaded_by,
    CASE 
        WHEN t.status = 'ACTIVE' AND t.is_active = 'Y' THEN 'ACTIVE'
        WHEN t.status = 'DELETED' OR t.deleted_at IS NOT NULL THEN 'DELETED'
        ELSE 'ARCHIVED'
    END
FROM templates t
WHERE NOT EXISTS (
    SELECT 1 FROM template_versions tv WHERE tv.template_id = t.id
);

-- Backfill any existing orders whose template_version_id is NULL from the matching template_versions
UPDATE orders o
SET template_version_id = tv.id
FROM template_versions tv
WHERE o.template_version_id IS NULL
  AND o.template_id IS NOT NULL
  AND tv.template_id = o.template_id
  AND tv.version = o.template_version;
