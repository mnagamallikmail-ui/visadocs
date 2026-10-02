-- ==============================================================================
-- ProValuer Commercial Platform — Schema Migration Version 29
-- SPRINT 8: Delivery Lifecycle, Secure Client Download Portal,
-- Invoice Engine, Acknowledgement Tracking, Revenue Recognition & Project Closure
-- Target: PostgreSQL 15+
-- ==============================================================================

-- 1. Extend orders table with Sprint 8 delivery and closure columns
ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS corporate_credit_active BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS commercial_override_notes TEXT,
    ADD COLUMN IF NOT EXISTS archival_locked BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS revenue_recognized BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS revenue_recognized_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS downloaded_at TIMESTAMP,
    ADD COLUMN IF NOT EXISTS closed_at TIMESTAMP;

-- 2. Create sequence for gap-free tax invoice numbers
CREATE SEQUENCE IF NOT EXISTS invoice_number_seq START WITH 1 INCREMENT BY 1;

-- 3. Create order_invoices table
CREATE TABLE IF NOT EXISTS order_invoices (
    id                      BIGSERIAL PRIMARY KEY,
    order_id                BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    invoice_number          VARCHAR(64) NOT NULL UNIQUE,
    financial_year          VARCHAR(16) NOT NULL,
    invoice_date            DATE NOT NULL,
    due_date                DATE NOT NULL,

    -- Client Billing Profile Snapshot
    client_name             VARCHAR(255) NOT NULL,
    client_address          TEXT,
    client_gstin            VARCHAR(32),
    client_pan              VARCHAR(32),
    place_of_supply         VARCHAR(100) NOT NULL,
    state_code              VARCHAR(10) NOT NULL,

    -- Valuer Corporate Entity
    firm_name               VARCHAR(255) NOT NULL,
    firm_address            TEXT,
    firm_gstin              VARCHAR(32) NOT NULL,
    firm_pan                VARCHAR(32) NOT NULL,

    -- Financials & Taxes
    sac_code                VARCHAR(32) DEFAULT '998311',
    base_amount             NUMERIC(15,2) NOT NULL,
    is_inter_state          BOOLEAN NOT NULL DEFAULT FALSE,
    cgst_rate               NUMERIC(5,2) DEFAULT 0.00,
    cgst_amount             NUMERIC(15,2) DEFAULT 0.00,
    sgst_rate               NUMERIC(5,2) DEFAULT 0.00,
    sgst_amount             NUMERIC(15,2) DEFAULT 0.00,
    igst_rate               NUMERIC(5,2) DEFAULT 0.00,
    igst_amount             NUMERIC(15,2) DEFAULT 0.00,
    total_tax               NUMERIC(15,2) NOT NULL,
    grand_total             NUMERIC(15,2) NOT NULL,
    amount_paid             NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    balance_due             NUMERIC(15,2) NOT NULL DEFAULT 0.00,

    -- Document Asset
    invoice_pdf_content     BYTEA,
    invoice_hash            VARCHAR(64),

    status                  VARCHAR(32) NOT NULL DEFAULT 'ISSUED',
    created_at              TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by              VARCHAR(100)
);

CREATE INDEX IF NOT EXISTS idx_order_invoices_order_id ON order_invoices(order_id);
CREATE INDEX IF NOT EXISTS idx_order_invoices_number ON order_invoices(invoice_number);

-- 4. Create order_acknowledgements table
CREATE TABLE IF NOT EXISTS order_acknowledgements (
    id                      BIGSERIAL PRIMARY KEY,
    order_id                BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    action                  VARCHAR(64) NOT NULL,
    actor_id                BIGINT REFERENCES users(id),
    actor_role              VARCHAR(32),
    client_ip               VARCHAR(64),
    user_agent              TEXT,
    clarification_type      VARCHAR(64),
    clarification_notes     TEXT,
    acceptance_declaration  TEXT,
    created_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_ack_order_id ON order_acknowledgements(order_id);

-- 5. Create delivery_tokens table
CREATE TABLE IF NOT EXISTS delivery_tokens (
    id                      BIGSERIAL PRIMARY KEY,
    token                   VARCHAR(128) NOT NULL UNIQUE,
    order_id                BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    client_id               BIGINT NOT NULL REFERENCES users(id),
    file_type               VARCHAR(64) NOT NULL,
    client_ip               VARCHAR(64),
    user_agent              TEXT,
    expires_at              TIMESTAMP NOT NULL,
    consumed                BOOLEAN NOT NULL DEFAULT FALSE,
    consumed_at             TIMESTAMP,
    created_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_delivery_tokens_token ON delivery_tokens(token);
CREATE INDEX IF NOT EXISTS idx_delivery_tokens_order_id ON delivery_tokens(order_id);

-- 6. Create delivery_access_logs table
CREATE TABLE IF NOT EXISTS delivery_access_logs (
    id                      BIGSERIAL PRIMARY KEY,
    order_id                BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    event_type              VARCHAR(64) NOT NULL,
    actor_id                BIGINT,
    actor_role              VARCHAR(32),
    client_ip               VARCHAR(64),
    user_agent              TEXT,
    details                 TEXT,
    created_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_delivery_access_logs_order ON delivery_access_logs(order_id);

-- 7. Create revenue_ledger table (Ind AS 115 / IFRS 15)
CREATE TABLE IF NOT EXISTS revenue_ledger (
    id                      BIGSERIAL PRIMARY KEY,
    order_id                BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    entry_type              VARCHAR(64) NOT NULL,
    account_name            VARCHAR(128) NOT NULL,
    debit_amount            NUMERIC(15,2) DEFAULT 0.00,
    credit_amount           NUMERIC(15,2) DEFAULT 0.00,
    standard_code           VARCHAR(32) DEFAULT 'IND_AS_115',
    notes                   TEXT,
    posted_at               TIMESTAMP NOT NULL DEFAULT NOW(),
    posted_by               VARCHAR(100) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_revenue_ledger_order ON revenue_ledger(order_id);

-- 8. Create delivery_packages table
CREATE TABLE IF NOT EXISTS delivery_packages (
    id                      BIGSERIAL PRIMARY KEY,
    order_id                BIGINT NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
    encrypted_pdf_content   BYTEA,
    encrypted_pdf_hash      VARCHAR(64),
    manifest_json           TEXT,
    compliance_cert_pdf     BYTEA,
    created_at              TIMESTAMP NOT NULL DEFAULT NOW()
);
