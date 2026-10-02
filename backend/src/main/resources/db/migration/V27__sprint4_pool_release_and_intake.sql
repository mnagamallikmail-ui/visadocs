-- ==============================================================================
-- ProValuer Commercial Platform — Schema Migration Version 27
-- SPRINT 4: Admin Controlled Pool Release (PAYMENT_VERIFIED → PAID_INTAKE)
-- Target: PostgreSQL 15+
-- ==============================================================================

-- 1. Add pool-release tracking columns to orders
ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS released_to_pool_at  TIMESTAMP,
    ADD COLUMN IF NOT EXISTS released_by           VARCHAR(255),
    ADD COLUMN IF NOT EXISTS intake_hold_reason    VARCHAR(1000),
    ADD COLUMN IF NOT EXISTS intake_notes          TEXT;

-- 2. Partial index: fast lookup of PAYMENT_VERIFIED orders awaiting release
CREATE INDEX IF NOT EXISTS idx_orders_payment_verified_pool
    ON orders (status, is_deleted)
    WHERE status IN ('PAYMENT_VERIFIED', 'PAID_INTAKE');
