-- Sprint 3: Client Payment Proof Submission & Verification Schema

CREATE TABLE IF NOT EXISTS order_payments (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    quote_number VARCHAR(64) NOT NULL,
    utr_number VARCHAR(64) NOT NULL,
    payment_method VARCHAR(32) NOT NULL,
    payment_date DATE NOT NULL,
    amount_expected NUMERIC(15, 2) NOT NULL,
    amount_paid NUMERIC(15, 2) NOT NULL,
    verified_amount NUMERIC(15, 2),
    receipt_document_id BIGINT REFERENCES order_documents(id),
    status VARCHAR(32) NOT NULL DEFAULT 'SUBMITTED',
    submitted_by VARCHAR(255) NOT NULL,
    submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    verified_by VARCHAR(255),
    verified_at TIMESTAMP,
    rejection_reason TEXT,
    admin_notes VARCHAR(2000),
    client_notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_order_payments_order_id ON order_payments(order_id);
CREATE INDEX IF NOT EXISTS idx_order_payments_status ON order_payments(status);

-- Unique index to prevent duplicate active/verified UTR usage
CREATE UNIQUE INDEX IF NOT EXISTS idx_order_payments_utr_active 
ON order_payments (LOWER(TRIM(utr_number))) 
WHERE status IN ('SUBMITTED', 'VERIFIED');

-- Update orders with payment tracking
ALTER TABLE orders 
  ADD COLUMN IF NOT EXISTS payment_status VARCHAR(32) DEFAULT 'PENDING',
  ADD COLUMN IF NOT EXISTS latest_payment_id BIGINT REFERENCES order_payments(id);
