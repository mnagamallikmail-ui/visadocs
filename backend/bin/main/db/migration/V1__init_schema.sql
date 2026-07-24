-- ============================================================
-- ProValuer Commercial — V1 Enterprise Schema (Clean Reset)
-- SUPER_ADMIN Platform with Full RBAC, Audit Logs & Pricing
-- ============================================================

-- Users Table (Enterprise Enhanced)
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,          -- SUPER_ADMIN | SPA | PA | CLIENT
    full_name VARCHAR(255),
    mobile_number VARCHAR(20),
    accepted_tc_version VARCHAR(50),
    is_locked BOOLEAN DEFAULT FALSE NOT NULL,
    is_deleted BOOLEAN DEFAULT FALSE NOT NULL,
    deleted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- System Settings Table
CREATE TABLE system_settings (
    setting_key VARCHAR(255) PRIMARY KEY,
    setting_value TEXT NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Pricing Configuration Table (DB-Editable by SUPER_ADMIN)
CREATE TABLE pricing_config (
    id BIGSERIAL PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value NUMERIC(19,4) NOT NULL,
    description VARCHAR(255),
    updated_by BIGINT REFERENCES users(id),
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Templates Table (Versioned)
CREATE TABLE templates (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    template_content BYTEA NOT NULL,
    field_mapping TEXT NOT NULL,
    is_active VARCHAR(1) DEFAULT 'Y' NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING' NOT NULL,
    version INTEGER DEFAULT 1 NOT NULL,
    uploaded_by BIGINT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Orders Table (Full Enterprise)
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    client_id BIGINT NOT NULL REFERENCES users(id),
    pa_id BIGINT REFERENCES users(id),
    template_id BIGINT REFERENCES templates(id),
    purpose VARCHAR(100) NOT NULL,
    property_category VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL,
    estimated_value NUMERIC(19,2),
    final_value NUMERIC(19,2),
    fee_charged NUMERIC(19,2),
    balance_due NUMERIC(19,2),
    is_paused BOOLEAN DEFAULT FALSE NOT NULL,
    pause_reason VARCHAR(255),
    sla_expiry_time TIMESTAMP,
    claimed_at TIMESTAMP,
    last_heartbeat TIMESTAMP,
    revision_count INTEGER DEFAULT 0 NOT NULL,
    revision_limit INTEGER DEFAULT 2 NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Order Inputs Table
CREATE TABLE order_inputs (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    field_key VARCHAR(255) NOT NULL,
    field_value TEXT NOT NULL
);

-- Transactions Table
CREATE TABLE transactions (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id),
    amount NUMERIC(19,2) NOT NULL,
    stage VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    transaction_ref VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Revisions Table
CREATE TABLE revisions (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id),
    error_classification VARCHAR(255) NOT NULL,
    feedback VARCHAR(500) NOT NULL,
    attachment_path VARCHAR(255),
    round_number INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

-- Performance Ledger Table
CREATE TABLE performance_ledger (
    employee_id BIGINT PRIMARY KEY REFERENCES users(id),
    active_allocations INTEGER DEFAULT 0 NOT NULL,
    files_completed INTEGER DEFAULT 0 NOT NULL,
    sla_timeouts INTEGER DEFAULT 0 NOT NULL,
    freeze_counts INTEGER DEFAULT 0 NOT NULL
);

-- Audit Logs Table (IMMUTABLE — never updated or deleted by application)
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    actor_id BIGINT NOT NULL,
    actor_email VARCHAR(255) NOT NULL,
    actor_role VARCHAR(50) NOT NULL,
    action_type VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id VARCHAR(255),
    old_value TEXT,
    new_value TEXT,
    description TEXT,
    ip_address VARCHAR(50),
    timestamp TIMESTAMP DEFAULT NOW() NOT NULL
);

-- ============================================================
-- SEED DATA
-- ============================================================

-- System Settings
INSERT INTO system_settings (setting_key, setting_value) VALUES
('tc_version', 'v1.0'),
('system_version', '2.0.0'),
('platform_name', 'ProValuer Commercial');

-- Pricing Configuration (DB-Editable via SUPER_ADMIN)
INSERT INTO pricing_config (config_key, config_value, description) VALUES
('visa_flat_fee',        3000.0000, 'Flat fee (INR) for Visa purpose valuations'),
('standard_flat_fee',   10000.0000, 'Flat fee (INR) for standard valuations under high-value threshold'),
('high_value_threshold', 100000000.0000, 'Property value threshold (INR) above which percentage fee applies'),
('high_value_rate',      0.0010, 'Fee rate (e.g. 0.001 = 0.1%) applied to values above threshold');

-- Pre-seed Users
-- All passwords = 'password'
-- BCrypt hash: $2a$10$9VXqoCiZgs72jN/tf0xlsOSASqvnSAkqbaqApUWORvxP7WQxHQMQy
INSERT INTO users (email, password, role, full_name, mobile_number, accepted_tc_version) VALUES
('superadmin@provaluer.com', '$2a$10$9VXqoCiZgs72jN/tf0xlsOSASqvnSAkqbaqApUWORvxP7WQxHQMQy', 'SUPER_ADMIN', 'System Super Administrator', '9000000000', 'v1.0'),
('pa@provaluer.com',         '$2a$10$9VXqoCiZgs72jN/tf0xlsOSASqvnSAkqbaqApUWORvxP7WQxHQMQy', 'PA',          'Demo Property Analyst',      '9876543211', 'v1.0'),
('spa@provaluer.com',        '$2a$10$9VXqoCiZgs72jN/tf0xlsOSASqvnSAkqbaqApUWORvxP7WQxHQMQy', 'SPA',         'Demo Senior Property Analyst','9876543212', 'v1.0'),
('client@provaluer.com',     '$2a$10$9VXqoCiZgs72jN/tf0xlsOSASqvnSAkqbaqApUWORvxP7WQxHQMQy', 'CLIENT',      'Demo Client User',            '9876543213', 'v1.0');

-- Performance Ledger for PA (id=2) and SPA (id=3)
INSERT INTO performance_ledger (employee_id, active_allocations, files_completed, sla_timeouts, freeze_counts) VALUES
(2, 0, 0, 0, 0),
(3, 0, 0, 0, 0);
