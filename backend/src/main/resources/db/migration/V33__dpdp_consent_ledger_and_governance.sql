-- ==============================================================================
-- ProValuer Commercial Platform — Schema Migration Version 33
-- DPDP Act 2023 Statutory Consent Ledger, Notice Versioning & Governance
-- Target: PostgreSQL 15+
-- ==============================================================================

-- 1. Create statutory consent_ledger table
CREATE TABLE IF NOT EXISTS consent_ledger (
    id                      BIGSERIAL PRIMARY KEY,
    user_id                 BIGINT REFERENCES users(id),
    lead_id                 BIGINT REFERENCES valuation_leads(id),
    actor_identifier        VARCHAR(255) NOT NULL, -- Email, username, or lead phone
    consent_type            VARCHAR(64) NOT NULL,  -- TERMS_ACCEPTANCE, VALUATION_PROCESSING, ANALYTICS_TRACKING, MARKETING
    consent_given           BOOLEAN NOT NULL,
    notice_version          VARCHAR(32) NOT NULL DEFAULT 'DPDP-NOTICE-V1.0',
    terms_version           VARCHAR(32) NOT NULL DEFAULT 'v2.4',
    ip_address              VARCHAR(64),
    user_agent              TEXT,
    withdrawn               BOOLEAN NOT NULL DEFAULT FALSE,
    withdrawn_at            TIMESTAMP,
    withdrawal_reason       TEXT,
    created_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_consent_ledger_user_id ON consent_ledger(user_id);
CREATE INDEX IF NOT EXISTS idx_consent_ledger_lead_id ON consent_ledger(lead_id);
CREATE INDEX IF NOT EXISTS idx_consent_ledger_actor ON consent_ledger(actor_identifier);
CREATE INDEX IF NOT EXISTS idx_consent_ledger_type ON consent_ledger(consent_type);

-- 2. Correct default in valuation_leads: consent must NEVER be default TRUE under Sec 6(1)
ALTER TABLE valuation_leads 
    ALTER COLUMN consent_given DROP DEFAULT,
    ALTER COLUMN consent_given SET DEFAULT FALSE;

-- 3. Extend users table with DPDP consent metadata
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS dpdp_consent_given BOOLEAN DEFAULT FALSE NOT NULL,
    ADD COLUMN IF NOT EXISTS dpdp_consent_version VARCHAR(32),
    ADD COLUMN IF NOT EXISTS dpdp_consent_timestamp TIMESTAMP;
