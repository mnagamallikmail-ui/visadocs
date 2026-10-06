-- V30: Atomic Report Sequence Generation Governance
-- Eliminates sequence gaps and duplicate report numbers caused by count(*) + 1

CREATE TABLE IF NOT EXISTS report_sequences (
    prefix VARCHAR(32) PRIMARY KEY,
    last_sequence BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Seed current month sequence starting from current max sequential order (326)
INSERT INTO report_sequences (prefix, last_sequence, updated_at)
VALUES ('PV-2610-', 326, CURRENT_TIMESTAMP)
ON CONFLICT (prefix) DO NOTHING;
