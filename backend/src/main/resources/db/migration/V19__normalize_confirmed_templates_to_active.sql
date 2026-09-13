-- ============================================================
-- V19__normalize_confirmed_templates_to_active.sql
-- Normalize any templates in CONFIRMED state to ACTIVE state
-- ============================================================

UPDATE templates
SET status = 'ACTIVE'
WHERE status = 'CONFIRMED'
  AND is_active = 'Y';
