-- ==============================================================================
-- ProValuer Commercial Platform — Schema Migration Version 37 (Production Frozen Release)
-- ENTERPRISE SINGLE-EDITOR WORKSPACE LEASE & SINGLE-SESSION AUTHENTICATION (V2.1)
-- Target: PostgreSQL 15+
-- ==============================================================================

-- 1. Single Active Login Session Table with Configurable Challenge Support
CREATE TABLE IF NOT EXISTS user_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id VARCHAR(64) NOT NULL UNIQUE,
    session_token_hash VARCHAR(64) NOT NULL,
    refresh_token_hash VARCHAR(64) NOT NULL,
    device_info VARCHAR(255) NOT NULL,
    platform_info VARCHAR(100),
    approximate_location VARCHAR(100),
    ip_address VARCHAR(50) NOT NULL,
    last_activity TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    challenge_status VARCHAR(30) NOT NULL DEFAULT 'NONE', -- NONE, PENDING_CHALLENGE, CHALLENGE_REJECTED
    challenge_target_session VARCHAR(64),
    challenge_expiry TIMESTAMP WITHOUT TIME ZONE,
    terminated_at TIMESTAMP WITHOUT TIME ZONE,
    termination_reason VARCHAR(255)
);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user_active ON user_sessions(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_user_sessions_session_id ON user_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_challenge ON user_sessions(user_id, challenge_status) WHERE challenge_status = 'PENDING_CHALLENGE';

-- 2. Dedicated Single-Editor Workspace Lease Table (Pessimistic 300s TTL)
CREATE TABLE IF NOT EXISTS workspace_sessions (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id VARCHAR(64) NOT NULL REFERENCES user_sessions(session_id) ON DELETE CASCADE,
    tab_session_id VARCHAR(64) NOT NULL,
    lock_status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, RELEASED, EXPIRED, FORCIBLY_TERMINATED
    acquired_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    last_heartbeat TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    last_activity TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    machine_name VARCHAR(100),
    platform_info VARCHAR(100),
    ip_address VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);

-- High-performance indexes for production workloads:
CREATE INDEX IF NOT EXISTS idx_ws_sessions_order_lock ON workspace_sessions(order_id, lock_status);
CREATE INDEX IF NOT EXISTS idx_ws_sessions_order_user ON workspace_sessions(order_id, user_id);
CREATE INDEX IF NOT EXISTS idx_ws_sessions_session_id ON workspace_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_ws_sessions_active_heartbeat ON workspace_sessions(last_heartbeat) WHERE lock_status = 'ACTIVE';

-- 3. Permanent Statutory Revision History Table (IBBI / Banking Audit Compliance)
-- Reconciliation Item 1: Immutable audit design (saved_by FK ON DELETE SET NULL + saved_by_username permanent snapshot)
CREATE TABLE IF NOT EXISTS order_revision_history (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    revision_number INTEGER NOT NULL,
    saved_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
    saved_by_username VARCHAR(100) NOT NULL,
    saved_by_role VARCHAR(50),
    session_id VARCHAR(64) NOT NULL,
    tab_session_id VARCHAR(64) NOT NULL,
    saved_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    keys_changed INTEGER NOT NULL,
    snapshot_summary JSONB,
    ip_address VARCHAR(50)
);

CREATE INDEX IF NOT EXISTS idx_order_revision_history_order ON order_revision_history(order_id, revision_number DESC);
CREATE INDEX IF NOT EXISTS idx_order_revision_history_saved_at ON order_revision_history(saved_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_revision_history_username ON order_revision_history(saved_by_username);

-- 4. Workspace Lease Audit Trail Table
CREATE TABLE IF NOT EXISTS workspace_lease_audits (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    user_email VARCHAR(255),
    session_id VARCHAR(64) NOT NULL,
    event_type VARCHAR(50) NOT NULL, -- ACQUIRED, RENEWED, RELEASED, EXPIRED, TAKEOVER, TAB_SWITCH
    trigger_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    trigger_user_email VARCHAR(255),
    ip_address VARCHAR(50),
    device_info VARCHAR(255),
    timestamp TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    details JSONB
);

CREATE INDEX IF NOT EXISTS idx_ws_lease_audits_order_time ON workspace_lease_audits(order_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_ws_lease_audits_user_time ON workspace_lease_audits(user_id, timestamp DESC);

-- 5. Dedicated Offline Replay & Autosave Sync Diagnostics Event Table (90-Day Operational Diagnostic)
CREATE TABLE IF NOT EXISTS workspace_sync_events (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    session_id VARCHAR(64) NOT NULL REFERENCES user_sessions(session_id) ON DELETE CASCADE,
    tab_session_id VARCHAR(64) NOT NULL,
    event_type VARCHAR(50) NOT NULL, -- AUTOSAVE_FLUSH, OFFLINE_REPLAY, PRE_TAKEOVER_FLUSH, DRAFT_RESTORE
    payload JSONB NOT NULL,
    sync_status VARCHAR(30) NOT NULL DEFAULT 'PENDING', -- PENDING, COMMITTED, REJECTED, SUPERSEDED
    error_message TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMP WITHOUT TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_ws_sync_events_order_status ON workspace_sync_events(order_id, sync_status);
CREATE INDEX IF NOT EXISTS idx_ws_sync_events_session ON workspace_sync_events(session_id);
CREATE INDEX IF NOT EXISTS idx_ws_sync_events_created ON workspace_sync_events(created_at DESC);
