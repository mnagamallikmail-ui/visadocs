-- V13__enterprise_valuation_engine_schema.sql
-- Enterprise Valuation Engine Schema Migration

-- 1. Area Unit Master Table
CREATE TABLE IF NOT EXISTS area_units (
    id BIGSERIAL PRIMARY KEY,
    unit_name VARCHAR(50) UNIQUE NOT NULL,
    conversion_factor_sqft NUMERIC(19, 6) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Seed Area Units
INSERT INTO area_units (unit_name, conversion_factor_sqft, is_active) VALUES
('Sq.Ft', 1.000000, TRUE),
('Sq.M', 10.763910, TRUE),
('Sq.Yd', 9.000000, TRUE),
('Acres', 43560.000000, TRUE),
('Cents', 435.600000, TRUE),
('Grounds', 2400.000000, TRUE),
('Hectares', 107639.104000, TRUE)
ON CONFLICT (unit_name) DO NOTHING;

-- 2. Building Structure Master Table
CREATE TABLE IF NOT EXISTS structure_types (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    sort_order INTEGER DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Seed Structure Types
INSERT INTO structure_types (name, sort_order, is_active) VALUES
('Basement', 1, TRUE),
('Stilt', 2, TRUE),
('Ground Floor', 3, TRUE),
('First Floor', 4, TRUE),
('Second Floor', 5, TRUE),
('Third Floor', 6, TRUE),
('Fourth Floor', 7, TRUE),
('Fifth Floor', 8, TRUE),
('Terrace Structure', 9, TRUE),
('Servant Quarters', 10, TRUE),
('Watchman Cabin', 11, TRUE),
('Security Cabin', 12, TRUE),
('Compound Wall', 13, TRUE),
('Parking Block', 14, TRUE),
('Warehouse Block', 15, TRUE),
('Office Block', 16, TRUE),
('Other Structures', 17, TRUE)
ON CONFLICT (name) DO NOTHING;

-- 3. Building Type Master Table
CREATE TABLE IF NOT EXISTS building_types (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    default_useful_life INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Seed Building Types
INSERT INTO building_types (name, default_useful_life, is_active) VALUES
('RCC Residential', 60, TRUE),
('RCC Commercial', 60, TRUE),
('Industrial Building', 50, TRUE),
('Factory Building', 50, TRUE),
('Warehouse', 40, TRUE),
('Steel Shed', 40, TRUE),
('PEB Structure', 35, TRUE),
('Semi Pucca Structure', 30, TRUE),
('Temporary Structure', 15, TRUE)
ON CONFLICT (name) DO NOTHING;

-- 4. Extend orders table
ALTER TABLE orders ADD COLUMN IF NOT EXISTS valuation_status VARCHAR(50) DEFAULT 'DRAFT' NOT NULL;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE NOT NULL;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS deleted_by BIGINT REFERENCES users(id);

-- 5. Valuation Data (Single source of truth per order)
CREATE TABLE IF NOT EXISTS valuation_data (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT UNIQUE NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    total_land_value NUMERIC(19,2) DEFAULT 0 NOT NULL,
    total_building_value NUMERIC(19,2) DEFAULT 0 NOT NULL,
    total_replacement_cost NUMERIC(19,2) DEFAULT 0 NOT NULL,
    total_depreciation_amount NUMERIC(19,2) DEFAULT 0 NOT NULL,
    total_salvage_value NUMERIC(19,2) DEFAULT 0 NOT NULL,
    fair_value NUMERIC(19,2) DEFAULT 0 NOT NULL,
    realizable_percentage NUMERIC(5,2) DEFAULT 85.00 NOT NULL,
    realizable_value NUMERIC(19,2) DEFAULT 0 NOT NULL,
    distress_sale_percentage NUMERIC(5,2) DEFAULT 75.00 NOT NULL,
    distress_sale_value NUMERIC(19,2) DEFAULT 0 NOT NULL,
    default_salvage_percentage NUMERIC(5,2) DEFAULT 10.00 NOT NULL,
    valuation_status VARCHAR(50) DEFAULT 'DRAFT' NOT NULL,
    current_version INTEGER DEFAULT 1 NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_valuation_data_order ON valuation_data(order_id);

-- 6. Valuation Land Items (Multi-parcel)
CREATE TABLE IF NOT EXISTS valuation_land_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    description VARCHAR(255),
    survey_no VARCHAR(100),
    entered_area NUMERIC(19,4) NOT NULL,
    entered_unit VARCHAR(50) DEFAULT 'Sq.Ft' NOT NULL,
    standard_area_sqft NUMERIC(19,4) NOT NULL,
    rate NUMERIC(19,2) NOT NULL,
    value NUMERIC(19,2) NOT NULL,
    sort_order INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_valuation_land_order ON valuation_land_items(order_id);

-- 7. Valuation Building Items (Multi-structure area breakup)
CREATE TABLE IF NOT EXISTS valuation_building_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    structure_type VARCHAR(100) NOT NULL,
    building_type VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    entered_area NUMERIC(19,4) NOT NULL,
    entered_unit VARCHAR(50) DEFAULT 'Sq.Ft' NOT NULL,
    standard_area_sqft NUMERIC(19,4) NOT NULL,
    replacement_rate NUMERIC(19,2) NOT NULL,
    replacement_cost NUMERIC(19,2) NOT NULL,
    building_age NUMERIC(5,2) NOT NULL,
    building_useful_life INTEGER NOT NULL,
    salvage_percentage NUMERIC(5,2) DEFAULT 10.00 NOT NULL,
    depreciation_percentage NUMERIC(5,2) NOT NULL,
    depreciation_amount NUMERIC(19,2) NOT NULL,
    building_value NUMERIC(19,2) NOT NULL,
    sort_order INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_valuation_building_order ON valuation_building_items(order_id);

-- 8. Valuation Comparable Sales Table
CREATE TABLE IF NOT EXISTS valuation_comparable_sales (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    location VARCHAR(255) NOT NULL,
    survey_no VARCHAR(100),
    extent VARCHAR(100),
    entered_area NUMERIC(19,4) NOT NULL,
    entered_unit VARCHAR(50) DEFAULT 'Sq.Ft' NOT NULL,
    standard_area_sqft NUMERIC(19,4) NOT NULL,
    rate NUMERIC(19,2) NOT NULL,
    sale_value NUMERIC(19,2) NOT NULL,
    transaction_date VARCHAR(50),
    source VARCHAR(100),
    remarks TEXT,
    sort_order INTEGER DEFAULT 0 NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_valuation_comparables_order ON valuation_comparable_sales(order_id);

-- 9. Valuation Snapshots Table (Immutable archives + Binaries + SHA-256)
CREATE TABLE IF NOT EXISTS valuation_snapshots (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    snapshot_trigger VARCHAR(50) NOT NULL,
    snapshot_hash VARCHAR(64) NOT NULL,
    document_hash VARCHAR(64),
    snapshot_data JSONB NOT NULL,
    docx_content BYTEA,
    pdf_content BYTEA,
    version_notes VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    created_by BIGINT REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_valuation_snapshots_order ON valuation_snapshots(order_id);

-- 10. Valuation Audit Logs Table
CREATE TABLE IF NOT EXISTS valuation_audit_logs (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    field_name VARCHAR(100) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    source VARCHAR(50) NOT NULL,
    reason VARCHAR(255),
    changed_by BIGINT REFERENCES users(id),
    changed_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_valuation_audit_order ON valuation_audit_logs(order_id);

-- 11. Seed default master settings in system_settings if present
INSERT INTO system_settings (key, value) VALUES
('val_realizable_percentage', '85'),
('val_distress_percentage', '75'),
('val_salvage_percentage', '10')
ON CONFLICT (key) DO NOTHING;

-- 12. Backfill existing orders with default valuation_data records
INSERT INTO valuation_data (order_id, total_land_value, total_building_value, total_replacement_cost, total_depreciation_amount, total_salvage_value, fair_value, realizable_percentage, realizable_value, distress_sale_percentage, distress_sale_value, default_salvage_percentage, valuation_status, current_version, created_at, updated_at)
SELECT o.id, 0, 0, 0, 0, 0, COALESCE(o.estimated_value, 0), 85.00, COALESCE(o.estimated_value, 0) * 0.85, 75.00, COALESCE(o.estimated_value, 0) * 0.75, 10.00, 'DRAFT', 1, NOW(), NOW()
FROM orders o
WHERE NOT EXISTS (SELECT 1 FROM valuation_data vd WHERE vd.order_id = o.id);
