-- ==============================================================================
-- ProValuer Commercial Platform — Schema Migration Version 28
-- SPRINT 5: Site Inspection Lifecycle (ASSIGNED → INSPECTION_COMPLETED)
-- Target: PostgreSQL 15+
-- ==============================================================================

-- 1. Add pre_pause_status column to orders for multi-state resume
ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS pre_pause_status VARCHAR(32);

-- 2. Create order_inspections table
CREATE TABLE IF NOT EXISTS order_inspections (
    id                      BIGSERIAL PRIMARY KEY,
    order_id                BIGINT NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
    pa_id                   BIGINT NOT NULL REFERENCES users(id),

    -- Scheduling
    inspection_date         DATE,
    inspection_time         TIME,
    site_contact_name       VARCHAR(200),
    site_contact_number     VARCHAR(20),
    alt_contact_name        VARCHAR(200),
    alt_contact_number      VARCHAR(20),
    property_access_notes   TEXT,
    scheduled_at            TIMESTAMP,

    -- Schedule history (JSON array of reschedule events)
    schedule_history        JSONB DEFAULT '[]',

    -- Visit Execution
    started_at              TIMESTAMP,
    completed_at            TIMESTAMP,

    -- GPS at start
    gps_lat_start           DECIMAL(10, 7),
    gps_lng_start           DECIMAL(10, 7),
    gps_accuracy_start      REAL,

    -- GPS at completion
    gps_lat_end             DECIMAL(10, 7),
    gps_lng_end             DECIMAL(10, 7),
    gps_accuracy_end        REAL,

    -- Visit Outcome
    visit_status            VARCHAR(32),
    inspection_remarks      TEXT,
    access_confirmed        BOOLEAN DEFAULT TRUE,
    access_notes            TEXT,

    -- Metadata
    created_at              TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 3. Create inspection_photos table
CREATE TABLE IF NOT EXISTS inspection_photos (
    id                      BIGSERIAL PRIMARY KEY,
    inspection_id           BIGINT NOT NULL REFERENCES order_inspections(id) ON DELETE CASCADE,
    order_id                BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    pa_id                   BIGINT NOT NULL REFERENCES users(id),

    category                VARCHAR(32) NOT NULL,
    filename                VARCHAR(500) NOT NULL,
    file_size_bytes         BIGINT,
    mime_type               VARCHAR(32),
    file_content            BYTEA,
    md5_hash                VARCHAR(64),

    -- GPS at photo capture
    gps_lat                 DECIMAL(10, 7),
    gps_lng                 DECIMAL(10, 7),
    gps_accuracy            REAL,

    -- Device metadata
    device_timestamp        TIMESTAMP,
    capture_sequence        INT,

    -- Audit
    uploaded_at             TIMESTAMP NOT NULL DEFAULT NOW(),
    uploaded_by             BIGINT NOT NULL REFERENCES users(id),
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at              TIMESTAMP,
    deleted_by              BIGINT,
    delete_reason           VARCHAR(1000),

    -- Storage key for future cloud migration
    storage_key             VARCHAR(1000)
);

-- 4. Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_order_inspections_order_id
    ON order_inspections (order_id);

CREATE INDEX IF NOT EXISTS idx_order_inspections_pa_id
    ON order_inspections (pa_id);

CREATE INDEX IF NOT EXISTS idx_inspection_photos_order_id
    ON inspection_photos (order_id, is_deleted);

CREATE INDEX IF NOT EXISTS idx_inspection_photos_inspection_id
    ON inspection_photos (inspection_id, is_deleted);

CREATE INDEX IF NOT EXISTS idx_inspection_photos_category
    ON inspection_photos (order_id, category, is_deleted);
