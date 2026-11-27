-- ==============================================================================
-- ProValuer Commercial Platform — Schema Migration Version 38
-- Authority Governance (ADMIN > SPA > PA > SYSTEM), Field Provenance,
-- Canonical Key Uniqueness & Immutable Delivery Package Revisions
-- ==============================================================================

-- 1. Field provenance & authority rank on order_inputs
ALTER TABLE order_inputs
    ADD COLUMN IF NOT EXISTS authority_rank INTEGER NOT NULL DEFAULT 1,
    ADD COLUMN IF NOT EXISTS last_modified_by_role VARCHAR(32),
    ADD COLUMN IF NOT EXISTS last_modified_by_user VARCHAR(255),
    ADD COLUMN IF NOT EXISTS updated_by BIGINT,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Backfill authority_rank=2 for already SPA-confirmed/delivered orders
UPDATE order_inputs oi
SET authority_rank = 2,
    last_modified_by_role = COALESCE(oi.last_modified_by_role, 'SPA')
FROM orders o
WHERE oi.order_id = o.id
  AND UPPER(o.status) IN ('SPA_CONFIRMED', 'DELIVERY_READY', 'FINAL_DELIVERY', 'CLIENT_DOWNLOADED', 'CLOSED')
  AND oi.authority_rank < 2;

-- Deduplicate case-variant keys keeping the newest row (highest id)
DELETE FROM order_inputs a
USING order_inputs b
WHERE a.order_id = b.order_id
  AND UPPER(TRIM(a.field_key)) = UPPER(TRIM(b.field_key))
  AND a.id < b.id;

-- Normalize all existing field_key values to canonical UPPER_SNAKE_CASE
UPDATE order_inputs
SET field_key = UPPER(TRIM(field_key))
WHERE field_key IS NOT NULL
  AND field_key <> UPPER(TRIM(field_key));

-- Enforce case-insensitive uniqueness per order
CREATE UNIQUE INDEX IF NOT EXISTS idx_order_inputs_order_upper_key
    ON order_inputs (order_id, UPPER(field_key));

-- 2. Authority rank on valuation_data
ALTER TABLE valuation_data
    ADD COLUMN IF NOT EXISTS authority_rank INTEGER NOT NULL DEFAULT 1,
    ADD COLUMN IF NOT EXISTS updated_by BIGINT;

-- 3. Immutable versioned delivery_packages (Revision 1, 2, ... N)
ALTER TABLE delivery_packages
    ADD COLUMN IF NOT EXISTS revision_number INTEGER NOT NULL DEFAULT 1,
    ADD COLUMN IF NOT EXISTS parent_package_id BIGINT,
    ADD COLUMN IF NOT EXISTS superseded BOOLEAN NOT NULL DEFAULT FALSE;

-- Drop single-row unique constraint on delivery_packages(order_id) if present
DO $$
DECLARE
    con_name text;
BEGIN
    SELECT c.conname INTO con_name
    FROM pg_constraint c
    JOIN pg_class t ON c.conrelid = t.oid
    JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(c.conkey)
    WHERE t.relname = 'delivery_packages'
      AND c.contype = 'u'
      AND a.attname = 'order_id'
    LIMIT 1;

    IF con_name IS NOT NULL THEN
        EXECUTE format('ALTER TABLE delivery_packages DROP CONSTRAINT %I', con_name);
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_delivery_packages_order_revision
    ON delivery_packages (order_id, revision_number);

