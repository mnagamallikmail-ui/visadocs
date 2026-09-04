-- ============================================================
-- V17__composite_valuation_engine_schema.sql
-- Composite Valuation Engine for Flats, Apartments, Commercial Spaces, Office Spaces, Retail Shops, Commercial Units
-- ============================================================

CREATE TABLE IF NOT EXISTS valuation_composite_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    item_category VARCHAR(50) NOT NULL DEFAULT 'INTERIOR_WORK',
    description VARCHAR(255) NOT NULL,
    entered_unit VARCHAR(50) NOT NULL DEFAULT 'LS',
    quantity NUMERIC(19, 4) NOT NULL DEFAULT 1.0000,
    rate NUMERIC(19, 2) NOT NULL DEFAULT 0.00,
    amount NUMERIC(19, 2) NOT NULL DEFAULT 0.00,
    construction_cost NUMERIC(19, 2) DEFAULT 2000.00,
    building_age NUMERIC(6, 2) DEFAULT 0.00,
    total_life INT DEFAULT 60,
    depreciation_mode VARCHAR(20) DEFAULT 'PERCENTAGE',
    depreciation_percentage NUMERIC(6, 2) DEFAULT 0.00,
    depreciation_amount NUMERIC(19, 2) NOT NULL DEFAULT 0.00,
    is_insurable BOOLEAN DEFAULT TRUE,
    fair_value NUMERIC(19, 2) NOT NULL DEFAULT 0.00,
    sort_order INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_comp_items_order ON valuation_composite_items (order_id, sort_order);

ALTER TABLE valuation_data 
    ADD COLUMN IF NOT EXISTS valuation_methodology VARCHAR(50) DEFAULT 'LAND_BUILDING' NOT NULL,
    ADD COLUMN IF NOT EXISTS composite_government_rate NUMERIC(19, 2) DEFAULT 0.00 NOT NULL,
    ADD COLUMN IF NOT EXISTS composite_construction_cost NUMERIC(19, 2) DEFAULT 2000.00 NOT NULL,
    ADD COLUMN IF NOT EXISTS composite_building_age NUMERIC(6, 2) DEFAULT 0.00 NOT NULL,
    ADD COLUMN IF NOT EXISTS composite_building_total_life INT DEFAULT 60 NOT NULL,
    ADD COLUMN IF NOT EXISTS composite_building_depreciation_pct NUMERIC(6, 2) DEFAULT 0.00 NOT NULL,
    ADD COLUMN IF NOT EXISTS raw_fair_value NUMERIC(19, 2) DEFAULT 0.00 NOT NULL,
    ADD COLUMN IF NOT EXISTS say_fair_value NUMERIC(19, 2) DEFAULT 0.00 NOT NULL,
    ADD COLUMN IF NOT EXISTS total_interior_amount NUMERIC(19, 2) DEFAULT 0.00 NOT NULL,
    ADD COLUMN IF NOT EXISTS total_interior_depreciation NUMERIC(19, 2) DEFAULT 0.00 NOT NULL,
    ADD COLUMN IF NOT EXISTS total_interior_fair_value NUMERIC(19, 2) DEFAULT 0.00 NOT NULL;
