-- =========================================================================
-- V36__dpdp_pii_encryption_and_mfa.sql
-- DPDP Act 2023 Statutory Hardening:
-- 1. Expanded column definitions for AES-256-GCM ciphertext envelopes
-- 2. Email blind index hash columns for O(1) indexed lookups without plaintext
-- 3. Multi-Factor Authentication (MFA/TOTP) credentials and recovery codes
-- 4. Account brute-force lockout safeguards
-- 5. Valuation lead upload token and minor linkage
-- =========================================================================

-- 1. Users Table Hardening
ALTER TABLE users 
    ALTER COLUMN full_name TYPE VARCHAR(1024),
    ALTER COLUMN mobile_number TYPE VARCHAR(1024),
    ALTER COLUMN email TYPE VARCHAR(1024);

ALTER TABLE users 
    ADD COLUMN IF NOT EXISTS email_hash VARCHAR(128),
    ADD COLUMN IF NOT EXISTS mfa_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS mfa_secret VARCHAR(255),
    ADD COLUMN IF NOT EXISTS mfa_recovery_codes TEXT,
    ADD COLUMN IF NOT EXISTS failed_login_attempts INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS lockout_until TIMESTAMP WITHOUT TIME ZONE;

CREATE INDEX IF NOT EXISTS idx_users_email_hash ON users(email_hash);

-- 2. Valuation Leads Table Hardening
ALTER TABLE valuation_leads 
    ALTER COLUMN contact_name TYPE VARCHAR(1024),
    ALTER COLUMN contact_phone TYPE VARCHAR(1024),
    ALTER COLUMN contact_email TYPE VARCHAR(1024);

ALTER TABLE valuation_leads 
    ADD COLUMN IF NOT EXISTS contact_email_hash VARCHAR(128),
    ADD COLUMN IF NOT EXISTS upload_token VARCHAR(128),
    ADD COLUMN IF NOT EXISTS is_minor BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS guardian_consent_id BIGINT;

CREATE INDEX IF NOT EXISTS idx_leads_email_hash ON valuation_leads(contact_email_hash);
CREATE INDEX IF NOT EXISTS idx_leads_upload_token ON valuation_leads(upload_token);
