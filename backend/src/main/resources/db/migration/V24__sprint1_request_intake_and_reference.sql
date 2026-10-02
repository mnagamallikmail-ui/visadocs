-- ==============================================================================
-- ProValuer Commercial Platform — Schema Migration Version 24
-- SPRINT 1: Client Request Intake, Unique Reference Code & Service Category
-- Target: PostgreSQL 15+
-- ==============================================================================

-- 1. Extend 'orders' table with Sprint 1 reference_code and service_category
ALTER TABLE orders 
    ADD COLUMN IF NOT EXISTS reference_code VARCHAR(32) UNIQUE,
    ADD COLUMN IF NOT EXISTS service_category VARCHAR(100);

-- 2. Indexes for fast reference code and status lookup
CREATE INDEX IF NOT EXISTS idx_orders_reference_code ON orders(reference_code);
CREATE INDEX IF NOT EXISTS idx_orders_service_category ON orders(service_category);
