-- Migration: V25__sprint2_quotation_engine.sql
-- Sprint 2: Quotation Engine Schema Additions (QUOTE_PENDING -> QUOTE_PROVIDED)

ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS quote_number VARCHAR(32) UNIQUE,
    ADD COLUMN IF NOT EXISTS quote_amount NUMERIC(12, 2),
    ADD COLUMN IF NOT EXISTS quote_tax NUMERIC(12, 2),
    ADD COLUMN IF NOT EXISTS quote_total NUMERIC(12, 2),
    ADD COLUMN IF NOT EXISTS quote_turnaround VARCHAR(64),
    ADD COLUMN IF NOT EXISTS quote_notes TEXT,
    ADD COLUMN IF NOT EXISTS quote_terms TEXT,
    ADD COLUMN IF NOT EXISTS quote_valid_until TIMESTAMP,
    ADD COLUMN IF NOT EXISTS quoted_by BIGINT REFERENCES users(id),
    ADD COLUMN IF NOT EXISTS quoted_at TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_orders_quote_number ON orders(quote_number);
