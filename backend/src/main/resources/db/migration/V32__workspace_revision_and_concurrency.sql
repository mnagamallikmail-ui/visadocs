-- ==============================================================================
-- ProValuer Commercial Platform — Schema Migration Version 32
-- CONCURRENCY HARDENING & DATA INTEGRITY REMEDIATION
-- Target: PostgreSQL 15+
-- ==============================================================================

-- 1. Workspace revision governance column on orders
ALTER TABLE orders ADD COLUMN IF NOT EXISTS workspace_revision INT NOT NULL DEFAULT 1;

-- 2. JPA Optimistic locking version columns
ALTER TABLE orders ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE valuation_data ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE order_inputs ADD COLUMN IF NOT EXISTS version BIGINT NOT NULL DEFAULT 0;
