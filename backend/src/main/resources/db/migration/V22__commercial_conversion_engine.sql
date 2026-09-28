-- ==============================================================================
-- ProValuer Commercial — V22 Commercial Conversion Engine Schema
-- Multi-Vertical Lead Intake, Documents, Scored CRM & Quotation Pipeline
-- ==============================================================================

-- 1. Master Valuation Leads Table
CREATE TABLE IF NOT EXISTS valuation_leads (
    id BIGSERIAL PRIMARY KEY,
    reference_code VARCHAR(32) NOT NULL UNIQUE,       -- REQ-2026-XXXX
    service_vertical VARCHAR(50) NOT NULL,           -- SHARE_VALUATION, PROPERTY, etc.
    mandate_purpose VARCHAR(100) NOT NULL,           -- RULE_11UA, SEC_50C, CIRP, etc.
    asset_name VARCHAR(255) NOT NULL,
    asset_location VARCHAR(255),
    value_bracket VARCHAR(50) NOT NULL,              -- ABOVE_100CR, 25CR_100CR, etc.
    urgency_sla VARCHAR(50) NOT NULL,                -- EXPRESS_24H, STANDARD_3D, COMPREHENSIVE_7D
    contact_name VARCHAR(255) NOT NULL,
    contact_role VARCHAR(100),                       -- CFO, PROMOTER, ADVOCATE, RP, INDIVIDUAL
    company_name VARCHAR(255),
    contact_email VARCHAR(255) NOT NULL,
    contact_phone VARCHAR(50) NOT NULL,
    preferred_channel VARCHAR(50) DEFAULT 'EMAIL',   -- EMAIL, PHONE, WHATSAPP
    lead_score INTEGER DEFAULT 0 NOT NULL,
    intent_level VARCHAR(20) DEFAULT 'MEDIUM' NOT NULL, -- LOW, MEDIUM, HIGH, CRITICAL
    status VARCHAR(50) DEFAULT 'NEW' NOT NULL,       -- NEW, QUALIFIED, QUOTED, WON, LOST
    assigned_valuer_id BIGINT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_leads_service ON valuation_leads(service_vertical);
CREATE INDEX IF NOT EXISTS idx_leads_status ON valuation_leads(status);
CREATE INDEX IF NOT EXISTS idx_leads_score ON valuation_leads(lead_score DESC);
CREATE INDEX IF NOT EXISTS idx_leads_intent ON valuation_leads(intent_level);
CREATE INDEX IF NOT EXISTS idx_leads_created_at ON valuation_leads(created_at DESC);

-- 2. Lead Uploaded Documents Table
CREATE TABLE IF NOT EXISTS lead_documents (
    id BIGSERIAL PRIMARY KEY,
    lead_id BIGINT NOT NULL REFERENCES valuation_leads(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    storage_path VARCHAR(500) NOT NULL,
    is_confidential BOOLEAN DEFAULT TRUE NOT NULL,
    uploaded_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_lead_docs_lead_id ON lead_documents(lead_id);

-- 3. Lead Interaction Notes & Audit Log Table
CREATE TABLE IF NOT EXISTS lead_notes (
    id BIGSERIAL PRIMARY KEY,
    lead_id BIGINT NOT NULL REFERENCES valuation_leads(id) ON DELETE CASCADE,
    author_id BIGINT REFERENCES users(id),
    author_name VARCHAR(255),
    note_content TEXT NOT NULL,
    action_type VARCHAR(50) DEFAULT 'NOTE' NOT NULL,  -- NOTE, CALL_LOG, EMAIL_SENT, QUOTE_ISSUED
    created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_lead_notes_lead_id ON lead_notes(lead_id);

-- 4. Lead Formal Quotation Table
CREATE TABLE IF NOT EXISTS lead_quotations (
    id BIGSERIAL PRIMARY KEY,
    lead_id BIGINT NOT NULL REFERENCES valuation_leads(id) ON DELETE CASCADE,
    quote_number VARCHAR(50) NOT NULL UNIQUE,        -- QUO-2026-XXXX
    estimated_fee NUMERIC(15,2) NOT NULL,
    tax_amount NUMERIC(15,2) NOT NULL,               -- 18% GST
    total_fee NUMERIC(15,2) NOT NULL,
    turnaround_days INTEGER NOT NULL,
    scope_of_work TEXT NOT NULL,
    terms_conditions TEXT NOT NULL,
    is_accepted BOOLEAN DEFAULT FALSE NOT NULL,
    accepted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_lead_quotations_lead_id ON lead_quotations(lead_id);

-- 5. Lead Activity Log Table (Telemetry & Status History)
CREATE TABLE IF NOT EXISTS lead_activity_log (
    id BIGSERIAL PRIMARY KEY,
    lead_id BIGINT NOT NULL REFERENCES valuation_leads(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,                    -- STATUS_CHANGED, ASSIGNED, QUOTE_SENT, VIEWED
    details TEXT,
    actor_name VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_lead_activity_lead_id ON lead_activity_log(lead_id);
