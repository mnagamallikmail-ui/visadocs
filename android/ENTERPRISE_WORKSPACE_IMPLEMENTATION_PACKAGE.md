# Enterprise Single-Editor Workspace Architecture: Final Implementation Blueprint (Amended V2.1)

**Document ID:** PV-ARCH-V2.1-FINAL-AMENDED  
**Target Systems:** ProValuer Web, ProValuer Backend (Spring Boot 3 / Java 17), PostgreSQL 16 (Flyway), Flutter Web  
**Specification Level:** Definitive Implementation Blueprint  
**Status:** Approved with All Final Amendments Incorporated  
**Date:** 2026-11-14  

---

## 1. Traceability Matrix: Final Architectural Amendments

Every one of the 7 final mandatory amendments is mapped directly to its architectural construct and technical design below:

| # | Amendment Requirement | Design & Architectural Implementation | Section |
|---|---|---|---|
| **1** | **Configurable `SESSION_CHALLENGE_TIMEOUT`** | Added `app.security.session-challenge-timeout-seconds` to Spring Boot properties (default: 30s) overridable via environment variable `APP_SESSION_CHALLENGE_TIMEOUT_SECONDS`. The backend challenge generator dynamically injects this timeout into the `user_sessions.challenge_expiry` column and pushes `timeoutSeconds` in the SSE challenge payload. | §4.1, §7 |
| **2** | **Graceful Same-User Multiple Tabs Handling** | When User A already holds the active lease in Tab 1 and opens Tab 2 on the same report: Tab 2 detects matching `userId` and displays an explicit choice: `[Switch Editing to This Tab]` or `[Keep as Read-Only]`. Clicking "Switch" invokes `POST /api/v1/orders/{id}/switch-tab`, atomically updating `tab_session_id` on `workspace_sessions` and pushing a `LEASE_LOST (reason: TAB_SWITCH)` event to Tab 1. Tab 1 drops to Read-Only mode without signing out the user. | §4.2, §5 |
| **3** | **Extended IndexedDB Draft Schema** | Upgraded HTML5 IndexedDB store `order_drafts` to schema version 2. Fields include: `orderId` (PK), `revision` (int), `draftVersion` (int sequence), `sourceSession` (UUID string), `savedAt` (ISO8601 UTC timestamp), `dirtyFieldCount` (int), `deltaValues` (Map), and `fullSnapshot` (Map). | §5.1 |
| **4** | **Admin Takeover Pre-Flight Forced Autosave** | When SPA/Admin calls `POST /api/v1/orders/{id}/takeover-lock`, the backend immediately dispatches an SSE/WebSocket `FORCE_AUTOSAVE_REQUEST` to the active PA editor. The PA tab flushes dirty deltas within a 1,500ms deadline. The backend commits these final deltas before executing the atomic lease reassignment, ensuring zero data loss during takeovers. | §4.3 |
| **5** | **Real-Time Push via SSE / WebSocket** | Built unified event streaming over Server-Sent Events (`GET /api/v1/events/session-stream`) with bidirectional WebSocket fallback (`/ws/workspace`). Dispatches `LOGIN_CHALLENGE`, `SESSION_EVICTED`, `FORCE_AUTOSAVE_REQUEST`, `LEASE_LOST`, and `WORKSPACE_INVALIDATED` instantly, eliminating all client polling delays. | §4.4 |
| **6** | **Persistent Workspace Health Indicator** | Implemented a 4-segment health header component in Flutter Web: (1) Connectivity Status (`● Online` / `● Offline`), (2) Lock Ownership (`ACTIVE EDITOR` / `READ ONLY`), (3) Last Saved Timestamp (`Last Saved: 1:24:18 PM`), and (4) Pending Sync Badge (`Pending Sync: N fields`). | §6 |
| **7** | **Cascade Lease Release on Session Termination** | Hooked `WorkspaceSessionRepository.releaseAllUserLeases(userId, sessionId)` into: (a) `POST /api/v1/auth/logout`, (b) `SESSION_EVICTED` handler, (c) refresh token revocation, and (d) browser `window.onbeforeunload` Navigator Beacon call (`POST /orders/{id}/release-lock`). | §4.5 |

---

## 2. End-to-End System Architecture

```
                                  PROVALUER ENTERPRISE REAL-TIME ARCHITECTURE
                                  
   Device A (Active Session / Tab 1)                           Device B / Admin / Tab 2
   ┌────────────────────────────────┐                           ┌────────────────────────────────┐
   │ - Active Editor Lease (300s)   │                           │ - Device B Login OR Tab 2 Open │
   │ - 10s Heartbeat (staggered)    │                           │ - Admin Break-Glass Takeover   │
   │ - 15s Autosave                 │                           │ - Configurable Challenge (30s) │
   │ - IndexedDB V2 Local Store     │                           └───────────────┬────────────────┘
   │ - Connected to SSE Stream      │                                           │
   └───────────────┬────────────────┘                                           │
                   │                                                            │
    Real-Time SSE: │ ◄──────────────────────────────────────────────────────────┘
    - LOGIN_CHALLENGE (30s countdown)                                           │
    - FORCE_AUTOSAVE_REQUEST (Pre-takeover flush)                               │
    - LEASE_LOST (Switched to Read-Only)                                        │
    - SESSION_EVICTED (Forced logout)                                           │
                   ▼                                                            ▼
   ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
   │                                     SPRING BOOT GATEWAY                                     │
   │                                                                                             │
   │  ┌──────────────────────────────┐                       ┌────────────────────────────────┐  │
   │  │   Auth & Session Controller  │                       │    Workspace Lease Service     │  │
   │  │  - Single Active Device      │                       │  - 300s Pessimistic Lease      │  │
   │  │  - Static 256-bit JWT        │                       │  - Isolated Native Heartbeat   │  │
   │  │  - Dynamic Challenge Timeout │                       │  - Pre-Takeover Flush Engine   │  │
   │  │  - Silent Refresh Interceptor│                       │  - Same-User Tab Switcher      │  │
   │  └──────────────┬───────────────┘                       └───────────────┬────────────────┘  │
   └─────────────────┼───────────────────────────────────────────────────────┼───────────────────┘
                     │                                                       │
                     ▼                                                       ▼
   ┌────────────────────────────────────┐                  ┌─────────────────────────────────────┐
   │    user_sessions (PostgreSQL)      │                  │   workspace_sessions (PostgreSQL)   │
   ├────────────────────────────────────┤                  ├─────────────────────────────────────┤
   │ user_id, session_id, device_info   │                  │ order_id (UNIQUE), user_id,         │
   │ is_active, challenge_status,       │                  │ session_id, tab_session_id,         │
   │ challenge_expiry (Configurable),   │                  │ lock_status ('ACTIVE'),             │
   │ refresh_token_hash, ip_address     │                  │ last_heartbeat (300s expiry),       │
   └────────────────────────────────────┘                  │ last_activity, machine_name         │
                                                           └──────────────────┬──────────────────┘
                                                                              │
                                                           ┌──────────────────▼──────────────────┐
                                                           │        orders & order_inputs        │
                                                           ├─────────────────────────────────────┤
                                                           │ - workspace_revision (Statutory)    │
                                                           │ - input_values (JSONB)              │
                                                           │ - order_revision_history (Auditing) │
                                                           │ - workspace_lease_audits            │
                                                           └─────────────────────────────────────┘
```

---

## 3. Database Schema (Flyway V22 Script)

File: `backend/src/main/resources/db/migration/V22__enterprise_workspace_and_session_concurrency.sql`

```sql
-- =============================================================================
-- Migration V22: Enterprise Single-Editor Lease & Single-Session Authentication
-- =============================================================================

-- 1. Single Active Login Session Table with Configurable Challenge Support
CREATE TABLE IF NOT EXISTS user_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id VARCHAR(64) NOT NULL UNIQUE,
    session_token_hash VARCHAR(64) NOT NULL,
    refresh_token_hash VARCHAR(64) NOT NULL,
    device_info VARCHAR(255) NOT NULL,
    ip_address VARCHAR(50) NOT NULL,
    last_activity TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    challenge_status VARCHAR(30) DEFAULT 'NONE', -- NONE, PENDING_CHALLENGE, CHALLENGE_REJECTED
    challenge_target_session VARCHAR(64),
    challenge_expiry TIMESTAMP WITHOUT TIME ZONE,
    terminated_at TIMESTAMP WITHOUT TIME ZONE,
    termination_reason VARCHAR(255)
);

CREATE INDEX idx_user_sessions_user_active ON user_sessions(user_id, is_active);
CREATE INDEX idx_user_sessions_session_id ON user_sessions(session_id);
CREATE INDEX idx_user_sessions_challenge ON user_sessions(user_id, challenge_status) WHERE challenge_status = 'PENDING_CHALLENGE';

-- 2. Dedicated Single-Editor Workspace Lease Table (300s TTL + Tab Session)
CREATE TABLE IF NOT EXISTS workspace_sessions (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id VARCHAR(64) NOT NULL,
    tab_session_id VARCHAR(64) NOT NULL,
    lock_status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, RELEASED, EXPIRED, FORCIBLY_TERMINATED
    acquired_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    last_heartbeat TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    last_activity TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    machine_name VARCHAR(100),
    ip_address VARCHAR(50) NOT NULL
);

CREATE INDEX idx_ws_sessions_order_lock ON workspace_sessions(order_id, lock_status);
CREATE INDEX idx_ws_sessions_expiry ON workspace_sessions(last_heartbeat) WHERE lock_status = 'ACTIVE';
CREATE INDEX idx_ws_sessions_user_sess ON workspace_sessions(user_id, session_id);

-- 3. Permanent Statutory Revision History Table (IBBI / Banking Audit Compliance)
CREATE TABLE IF NOT EXISTS order_revision_history (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    revision_number INTEGER NOT NULL,
    saved_by BIGINT NOT NULL REFERENCES users(id),
    session_id VARCHAR(64) NOT NULL,
    tab_session_id VARCHAR(64) NOT NULL,
    saved_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    keys_changed INTEGER NOT NULL,
    snapshot_summary JSONB,
    ip_address VARCHAR(50)
);

CREATE INDEX idx_order_revision_history_order ON order_revision_history(order_id, revision_number DESC);

-- 4. Workspace Lease Audit Trail
CREATE TABLE IF NOT EXISTS workspace_lease_audits (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id VARCHAR(64) NOT NULL,
    event_type VARCHAR(50) NOT NULL, -- ACQUIRED, RENEWED, RELEASED, EXPIRED, TAKEOVER, TAB_SWITCH
    trigger_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    ip_address VARCHAR(50),
    device_info VARCHAR(255),
    timestamp TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    details JSONB
);

CREATE INDEX idx_ws_lease_audits_order_time ON workspace_lease_audits(order_id, timestamp DESC);
```

---

## 4. Real-Time Push, Workflows & API Contracts

### 4.1 Configurable Challenge Flow (Amendment 1)
- Spring property: `app.security.session-challenge-timeout-seconds` (default: 30).
- When Device B logs in, backend calculates:
  ```java
  LocalDateTime expiry = LocalDateTime.now().plusSeconds(sessionChallengeTimeoutSeconds);
  userSession.setChallengeExpiry(expiry);
  ```
- SSE payload pushed to Device A:
  ```json
  {
    "event": "LOGIN_CHALLENGE",
    "challengeSessionId": "chal_7781a9bc",
    "requestingDevice": "Chrome Laptop (Windows 11)",
    "requestingIp": "122.177.247.252",
    "timeoutSeconds": 30
  }
  ```

### 4.2 Same-User Multi-Tab Resolution Flow (Amendment 2)
When User A opens Tab 2 of Report 108 while Tab 1 is the active editor:
1. Tab 2 calls `POST /api/v1/orders/108/acquire-lock`.
2. Backend detects `existingSession.userId == caller.userId`:
   - Returns HTTP 200:
     ```json
     {
       "role": "SAME_USER_SECONDARY_TAB",
       "activeTabSessionId": "tab_112233",
       "canSwitchTab": true
     }
     ```
3. Tab 2 renders dialog: `[Switch Editing to This Tab]` or `[Keep as Read-Only]`.
4. If "Switch" is chosen:
   - Tab 2 calls `POST /api/v1/orders/108/switch-tab` with `{ "newTabSessionId": "tab_445566" }`.
   - Backend atomically updates `workspace_sessions.tab_session_id = 'tab_445566'`.
   - Backend pushes SSE event to Tab 1:
     ```json
     {
       "event": "LEASE_LOST",
       "orderId": 108,
       "reason": "TAB_SWITCH",
       "message": "Editing switched to another tab in this browser."
     }
     ```
   - Tab 1 switches to Read-Only mode. Tab 2 becomes Active Editor. Zero login eviction occurs.

### 4.3 Pre-Flight Admin Takeover Flow (Amendment 4)
```
Admin / SPA (Takeover)              Spring Boot API                 PA Active Editor Tab
        │                                  │                                  │
        │ 1. POST /takeover-lock           │                                  │
        ├─────────────────────────────────►│                                  │
        │                                  │ 2. SSE: FORCE_AUTOSAVE_REQUEST   │
        │                                  ├─────────────────────────────────►│
        │                                  │    (1500ms deadline)             │ 3. Immediate flush of
        │                                  │                                  │    dirty fields to API
        │                                  │ 4. POST /save-document-values    │    and IndexedDB
        │                                  │◄─────────────────────────────────┤
        │                                  │ 5. Commit Final PA Save          │
        │                                  │                                  │
        │                                  │ 6. Reassign Lease to Admin       │
        │                                  │ 7. SSE: LEASE_LOST (TAKEOVER)    │
        │                                  ├─────────────────────────────────►│
        │ 8. HTTP 200 { status: OK }       │                                  │ 8. Switch to Read-Only
        │◄─────────────────────────────────┤                                  │
```

### 4.4 Real-Time Push Channels (Amendment 5)
- **SSE Stream Endpoint:** `GET /api/v1/events/session-stream`
- Handled via `SseEmitter` managed by `RealtimePushService`.
- Fallback: Bidirectional WebSocket `/ws/workspace` for networks blocking chunked HTTP/2 streaming.

### 4.5 Cascade Lease Release Protocol (Amendment 7)
Whenever an account session ends:
```java
@Transactional
public void cascadeReleaseLeases(Long userId, String sessionId, String reason) {
    workspaceSessionRepository.releaseAllActiveLeases(userId, sessionId);
    auditLogService.logLeaseRelease(userId, sessionId, reason);
}
```
Triggered automatically on:
1. `POST /api/v1/auth/logout`
2. Remote session eviction (`SESSION_EVICTED`)
3. Refresh token revocation
4. Browser unload beacon (`POST /api/v1/orders/{id}/release-lock` dispatched via `navigator.sendBeacon`)

---

## 5. Extended IndexedDB Draft Schema (Version 2)

### 5.1 Object Store Definition (Amendment 3)
- **Database:** `provaluer_workspace_db`
- **Object Store:** `order_drafts`
- **Key Path:** `orderId` (Integer)

```typescript
interface OrderDraftV2 {
  orderId: number;                     // Primary Key
  revision: number;                    // Order workspace_revision at time of save
  draftVersion: number;                // Sequence counter incremented per local draft write
  sourceSession: string;               // session_id + "_" + tab_session_id
  savedAt: string;                     // ISO 8601 UTC timestamp (e.g. 2026-11-14T15:24:18.120Z)
  dirtyFieldCount: number;             // Count of modified keys
  deltaValues: Record<string, string>; // Modified key-value pairs
  fullSnapshot: Record<string, string>;// Complete form state
}
```

IndexedDB Indices created:
- `by_savedAt`: `savedAt` (Non-unique)
- `by_revision`: `revision` (Non-unique)
- `by_sourceSession`: `sourceSession` (Non-unique)

### 5.2 First-Class Draft Recovery Modal
When opening Report 108, if an IndexedDB draft exists:
```
┌────────────────────────────────────────────────────────┐
│ Unsaved Draft Detected                                 │
├────────────────────────────────────────────────────────┤
│ Draft Version: #4                                      │
│ Revision Base: Rev 14                                  │
│ Fields Changed: 15                                     │
│ Last Local Save: 1:32:45 PM (Saved on this device)     │
│                                                        │
│ [ Discard Draft ]                    [ Restore Draft ] │
└────────────────────────────────────────────────────────┘
```
Never silently hydrated. The appraiser retains full agency.

---

## 6. Frontend Workspace Health Indicator Component

Implemented in `frontend/lib/widgets/workspace_editor_status_bar.dart` (Amendment 6). Rendered persistently at the top of the Document Workspace.

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│ [● Online]  Editing As: Poojitha (ACTIVE EDITOR)  |  Last Saved: 1:24:18 PM  |  [Sync Pending: 3] │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Visual Specifications:
1. **Connectivity Pill:**
   - Online: `● Online` (Green container `#ECFDF5`, text `#059669`, border `#A7F3D0`)
   - Offline: `● Offline` (Red container `#FEF2F2`, text `#DC2626`, border `#FECACA`)
2. **Editor Ownership:**
   - Active Editor: `Editing As: <Name> (ACTIVE EDITOR)` (Navy `#0A2540`, bold)
   - Read-Only Viewer: `Viewing Only | Active Editor: <Name>` (Amber `#D97706`, bold)
3. **Sync Diagnostics:**
   - `Last Saved: <HH:mm:ss a>`
   - `[Sync Pending: N]` pill (Amber `#FFFBEB`) displayed only when IndexedDB holds uncommitted delta keys.

---

## 7. Configuration Properties (`application.yml`)

```yaml
app:
  jwt:
    secret: 9a62a9386c9135003f42b8e3ea954cfd3a1f9e9d6bc4bf38ea2f6bbd688bfa1f
    expiration-ms: 1800000          # 30 Minutes
    refresh-expiration-ms: 604800000 # 7 Days
  security:
    session-challenge-timeout-seconds: ${APP_SESSION_CHALLENGE_TIMEOUT_SECONDS:30}
  workspace:
    lease-ttl-seconds: 300           # 5 Minutes
    heartbeat-interval-seconds: 10   # 10 Seconds
    autosave-interval-seconds: 15    # 15 Seconds
    takeover-autosave-deadline-ms: 1500 # 1.5 Seconds
```

---

## 8. Complete File Modification Inventory

### Backend (Java / Spring Boot)

| File Path | Action | Description of Changes |
|---|---|---|
| `backend/src/main/resources/db/migration/V22__enterprise_workspace_and_session_concurrency.sql` | **Create** | DDL for `user_sessions`, `workspace_sessions` (with `tab_session_id`), `order_revision_history`, and `workspace_lease_audits`. |
| `backend/src/main/java/com/provaluer/model/UserSession.java` | **Create** | Session entity with challenge status & dynamic expiry. |
| `backend/src/main/java/com/provaluer/model/WorkspaceSession.java` | **Create** | Lease entity with `tab_session_id`, 300s TTL. |
| `backend/src/main/java/com/provaluer/model/OrderRevisionHistory.java` | **Create** | Statutory audit record entity for banking compliance. |
| `backend/src/main/java/com/provaluer/repository/WorkspaceSessionRepository.java` | **Create** | Native non-entity SQL for 10s heartbeat renewal, lease release, and tab-switch. |
| `backend/src/main/java/com/provaluer/service/WorkspaceLeaseService.java` | **Create** | Lease lifecycle, takeover with 1500ms pre-flight flush, tab switching. |
| `backend/src/main/java/com/provaluer/service/RealtimePushService.java` | **Create** | SSE / WebSocket event dispatcher for challenges, takeovers, and lease loss. |
| `backend/src/main/java/com/provaluer/controller/WorkspaceLeaseController.java` | **Create** | Endpoints: `/acquire-lock`, `/heartbeat`, `/takeover-lock`, `/switch-tab`, `/release-lock`. |
| `backend/src/main/java/com/provaluer/controller/SseNotificationController.java` | **Create** | SSE stream endpoint `/api/v1/events/session-stream`. |
| `backend/src/main/java/com/provaluer/controller/AuthController.java` | **Modify** | Integrate dynamic challenge timeout, challenge response, and cascade lease release on logout. |
| `backend/src/main/java/com/provaluer/controller/OrderController.java` | **Modify** | Decouple telemetry heartbeat completely from `Order` entity; remove legacy revision checks. |

### Frontend (Flutter Web)

| File Path | Action | Description of Changes |
|---|---|---|
| `frontend/lib/services/indexed_db_draft_service.dart` | **Create** | IndexedDB V2 store (`revision`, `draftVersion`, `sourceSession`, `savedAt`) + migration. |
| `frontend/lib/services/sse_event_service.dart` | **Create** | Real-time SSE listener for `LOGIN_CHALLENGE`, `FORCE_AUTOSAVE`, `LEASE_LOST`, `SESSION_EVICTED`. |
| `frontend/lib/widgets/workspace_editor_status_bar.dart` | **Create** | Health indicator: Online/Offline pill, Editor name, Last Saved time, Pending Sync count. |
| `frontend/lib/widgets/same_user_tab_switch_dialog.dart` | **Create** | Prompt: "Switch Editing to This Tab" vs "Keep as Read-Only". |
| `frontend/lib/widgets/draft_recovery_dialog.dart` | **Create** | Modal with field count, timestamp, "[Restore Draft]" vs "[Discard Draft]". |
| `frontend/lib/widgets/concurrent_login_challenge_dialog.dart` | **Create** | Dynamic countdown challenge on Device A. |
| `frontend/lib/features/document_workspace/providers/document_workspace_provider.dart` | **Modify** | Staggered 10s HB / 15s AS, pre-flight flush on takeover, IndexedDB V2 dual-write. |
| `frontend/lib/features/document_workspace/document_workspace_screen.dart` | **Modify** | Embed health status bar, hook SSE stream, trigger unload beacon for lease release. |

---

## 9. Regression Test Suite

| Test ID | Scenario | Steps | Expected Outcome |
|:---:|---|---|---|
| **RTS-01** | Configurable Challenge Timeout | Set timeout to 45s. Login on Device B. | Challenge payload returns `expiresInSeconds: 45`. UI counts down from 45s. |
| **RTS-02** | Same-User Multi-Tab Switch | Open Tab 1 (Active). Open Tab 2. Click "Switch Editing to This Tab". | Tab 2 becomes Active Editor. Tab 1 receives SSE `LEASE_LOST` and converts to Read-Only mode. Zero lockout. |
| **RTS-03** | IndexedDB V2 Schema Integrity | Save draft offline. Inspect IndexedDB via Chrome DevTools. | Record contains `revision`, `draftVersion`, `sourceSession`, `savedAt`, and `deltaValues`. |
| **RTS-04** | Admin Takeover Pre-Flight Flush | PA has dirty unsaved fields. SPA triggers Takeover. | Backend emits `FORCE_AUTOSAVE_REQUEST`. PA flushes deltas to server. SPA acquires lease with latest values. Zero data loss. |
| **RTS-05** | Real-Time SSE Notification | Device A logged in. Device B logs in. | Device A immediately opens challenge dialog via SSE without polling delay. |
| **RTS-06** | Health Indicator Status | Disconnect network. Edit 3 fields. | Status pill turns Red `Offline`. Pending sync shows `Sync Pending: 3`. Reconnect -> turns Green `Online`, flushes, Sync: 0. |
| **RTS-07** | Cascade Lease Release on Logout | Active Editor clicks Logout. Query `workspace_sessions`. | `lock_status` is updated to `RELEASED` immediately. Another user can claim lock without waiting 300s. |

---

*This specification represents the final, fully amended architectural blueprint. Ready for implementation.*
