-- ==============================================================================
-- ProValuer Commercial — V23 Commercial Conversion Engine Security & Compliance
-- DPDP Act 2023 Consent Tracking and Audit Columns
-- ==============================================================================

ALTER TABLE valuation_leads 
    ADD COLUMN IF NOT EXISTS consent_given BOOLEAN DEFAULT TRUE NOT NULL,
    ADD COLUMN IF NOT EXISTS consent_timestamp TIMESTAMP DEFAULT NOW() NOT NULL;
