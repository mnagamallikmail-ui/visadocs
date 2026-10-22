-- =========================================================================
-- V35__dpdp_batch3_comprehensive_compliance.sql
-- DPDP Act 2023 - Batch 3 Comprehensive Compliance:
-- 1. Privacy Correction Requests (Section 12)
-- 2. Privacy Erasure Requests (Section 12)
-- 3. Privacy Nominees (Section 14)
-- 4. Retention Policies, Events & Execution Logs (Section 8(7))
-- 5. Deletion Certificates (Section 12)
-- 6. Data Breach Registry & Notification Logs (Section 8(6))
-- 7. Grievance Cases (Section 13)
-- 8. Guardian Consent Ledger (Section 9)
-- =========================================================================

-- 1. Correction Requests
CREATE TABLE IF NOT EXISTS privacy_correction_requests (
    id BIGSERIAL PRIMARY KEY,
    request_id VARCHAR(64) UNIQUE NOT NULL,
    user_id BIGINT NOT NULL,
    field_name VARCHAR(128) NOT NULL,
    existing_value TEXT,
    requested_value TEXT NOT NULL,
    reason TEXT,
    status VARCHAR(32) NOT NULL DEFAULT 'SUBMITTED',
    admin_notes TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITHOUT TIME ZONE
);
CREATE INDEX IF NOT EXISTS idx_corr_req_user ON privacy_correction_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_corr_req_status ON privacy_correction_requests(status);

-- 2. Erasure Requests
CREATE TABLE IF NOT EXISTS privacy_erasure_requests (
    id BIGSERIAL PRIMARY KEY,
    request_id VARCHAR(64) UNIQUE NOT NULL,
    user_id BIGINT NOT NULL,
    reason TEXT,
    status VARCHAR(32) NOT NULL DEFAULT 'SUBMITTED',
    legal_hold_flag BOOLEAN NOT NULL DEFAULT FALSE,
    admin_notes TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITHOUT TIME ZONE
);
CREATE INDEX IF NOT EXISTS idx_eras_req_user ON privacy_erasure_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_eras_req_status ON privacy_erasure_requests(status);

-- 3. Nominees Management
CREATE TABLE IF NOT EXISTS privacy_nominees (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    nominee_name VARCHAR(255) NOT NULL,
    relationship VARCHAR(100) NOT NULL,
    mobile VARCHAR(32) NOT NULL,
    email VARCHAR(255) NOT NULL,
    address TEXT,
    verification_status VARCHAR(32) NOT NULL DEFAULT 'REGISTERED',
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_nominee_user ON privacy_nominees(user_id);

-- 4. Retention Policies, Events & Execution Logs
CREATE TABLE IF NOT EXISTS retention_policies (
    id BIGSERIAL PRIMARY KEY,
    entity_type VARCHAR(64) UNIQUE NOT NULL,
    retention_days INT NOT NULL,
    legal_basis VARCHAR(255) NOT NULL,
    archive_strategy VARCHAR(64) NOT NULL DEFAULT 'ARCHIVE_THEN_PURGE',
    purge_strategy VARCHAR(64) NOT NULL DEFAULT 'CRYPTO_SHRED',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITHOUT TIME ZONE
);

CREATE TABLE IF NOT EXISTS retention_events (
    id BIGSERIAL PRIMARY KEY,
    policy_id BIGINT,
    entity_type VARCHAR(64) NOT NULL,
    entity_id VARCHAR(128) NOT NULL,
    action_taken VARCHAR(64) NOT NULL,
    reason TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS retention_execution_log (
    id BIGSERIAL PRIMARY KEY,
    execution_timestamp TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    entities_scanned INT NOT NULL DEFAULT 0,
    entities_archived INT NOT NULL DEFAULT 0,
    entities_purged INT NOT NULL DEFAULT 0,
    status VARCHAR(32) NOT NULL DEFAULT 'SUCCESS',
    summary TEXT
);

-- Seed Initial Default Retention Policies (Configurable via Admin API)
INSERT INTO retention_policies (entity_type, retention_days, legal_basis, archive_strategy, purge_strategy)
VALUES 
    ('LEAD_RECORDS', 180, 'DPDP Act Section 8(7) - Purpose Limitation for Inquiries', 'ARCHIVE_THEN_PURGE', 'HARD_DELETE'),
    ('DRAFT_WORKSPACES', 30, 'Operational Cleanliness & Data Minimization', 'DIRECT_PURGE', 'HARD_DELETE'),
    ('UPLOADED_DOCUMENTS', 2920, 'Income Tax Act & Companies Act (8 Years Statutory)', 'LEGAL_HOLD_EXEMPT', 'CRYPTO_SHRED'),
    ('COMPLETED_ORDERS', 2920, 'Valuation Liability Limitation Act (8 Years Statutory)', 'LEGAL_HOLD_EXEMPT', 'CRYPTO_SHRED'),
    ('INVOICES', 2920, 'GST Act 2017 & Section 36 Accounting Mandate', 'LEGAL_HOLD_EXEMPT', 'CRYPTO_SHRED'),
    ('AUDIT_LOGS', 1825, 'Digital Personal Data Protection Act Compliance Trail (5 Years)', 'LEGAL_HOLD_EXEMPT', 'HARD_DELETE'),
    ('CONSENT_LEDGER', 1825, 'DPDP Act Section 6(1) Proof of Consent Mandate', 'LEGAL_HOLD_EXEMPT', 'HARD_DELETE'),
    ('GRIEVANCE_RECORDS', 1095, 'DPDP Act Section 13 Redressal Audit Trail (3 Years)', 'ARCHIVE_THEN_PURGE', 'HARD_DELETE')
ON CONFLICT (entity_type) DO NOTHING;

-- 5. Deletion Certificates
CREATE TABLE IF NOT EXISTS deletion_certificates (
    id BIGSERIAL PRIMARY KEY,
    certificate_number VARCHAR(128) UNIQUE NOT NULL,
    user_id BIGINT NOT NULL,
    user_identifier VARCHAR(255) NOT NULL,
    records_deleted INT NOT NULL DEFAULT 0,
    completion_time TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    officer VARCHAR(100) NOT NULL,
    hash_signature VARCHAR(255) NOT NULL,
    certificate_details TEXT
);
CREATE INDEX IF NOT EXISTS idx_del_cert_user ON deletion_certificates(user_id);

-- 6. Data Breach Registry & Notification Logs
CREATE TABLE IF NOT EXISTS data_breach_registry (
    id BIGSERIAL PRIMARY KEY,
    incident_id VARCHAR(64) UNIQUE NOT NULL,
    discovery_time TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    severity VARCHAR(32) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'OPEN',
    root_cause TEXT,
    impact_assessment TEXT,
    number_affected INT NOT NULL DEFAULT 0,
    containment_status VARCHAR(64),
    closure_notes TEXT,
    data_impacted TEXT,
    systems_impacted TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITHOUT TIME ZONE
);

CREATE TABLE IF NOT EXISTS breach_notification_log (
    id BIGSERIAL PRIMARY KEY,
    incident_id VARCHAR(64) NOT NULL,
    notification_type VARCHAR(64) NOT NULL,
    recipient VARCHAR(255) NOT NULL,
    discovery_timestamp TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    notification_timestamp TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    sending_officer VARCHAR(100) NOT NULL,
    evidence_package TEXT,
    delivery_status VARCHAR(32) NOT NULL DEFAULT 'DISPATCHED',
    content_payload TEXT NOT NULL
);

-- 7. Grievance Cases
CREATE TABLE IF NOT EXISTS grievance_cases (
    id BIGSERIAL PRIMARY KEY,
    ticket_number VARCHAR(64) UNIQUE NOT NULL,
    user_id BIGINT NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    category VARCHAR(64) NOT NULL,
    description TEXT NOT NULL,
    assigned_officer VARCHAR(100),
    status VARCHAR(32) NOT NULL DEFAULT 'SUBMITTED',
    sla_due_date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    resolution_notes TEXT,
    escalation_level INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITHOUT TIME ZONE
);
CREATE INDEX IF NOT EXISTS idx_grv_user ON grievance_cases(user_id);
CREATE INDEX IF NOT EXISTS idx_grv_status ON grievance_cases(status);

-- 8. Guardian Consent Ledger (Children/Minor Compliance)
CREATE TABLE IF NOT EXISTS guardian_consent_ledger (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT,
    lead_id BIGINT,
    applicant_dob DATE NOT NULL,
    is_minor BOOLEAN NOT NULL DEFAULT FALSE,
    guardian_name VARCHAR(255),
    guardian_relationship VARCHAR(100),
    guardian_phone VARCHAR(32),
    guardian_email VARCHAR(255),
    guardian_consent_given BOOLEAN NOT NULL DEFAULT FALSE,
    consent_timestamp TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    ip_address VARCHAR(64),
    user_agent TEXT,
    notice_version VARCHAR(32) DEFAULT 'v1.0',
    withdrawn BOOLEAN NOT NULL DEFAULT FALSE,
    withdrawn_at TIMESTAMP WITHOUT TIME ZONE
);
CREATE INDEX IF NOT EXISTS idx_guardian_order ON guardian_consent_ledger(order_id);
