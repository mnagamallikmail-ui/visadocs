package com.provaluer.model;

import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import java.time.LocalDateTime;
import java.util.Objects;

@Entity
@Table(name = "workspace_sync_events", indexes = {
    @Index(name = "idx_ws_sync_events_order_status", columnList = "order_id, sync_status"),
    @Index(name = "idx_ws_sync_events_session", columnList = "session_id"),
    @Index(name = "idx_ws_sync_events_created", columnList = "created_at DESC")
})
public class WorkspaceSyncEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "session_id", nullable = false, length = 64)
    private String sessionId;

    @Column(name = "tab_session_id", nullable = false, length = 64)
    private String tabSessionId;

    @Column(name = "event_type", nullable = false, length = 50)
    private String eventType; // AUTOSAVE_FLUSH, OFFLINE_REPLAY, PRE_TAKEOVER_FLUSH, DRAFT_RESTORE

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "payload", nullable = false, columnDefinition = "JSONB")
    private String payload;

    @Column(name = "sync_status", nullable = false, length = 30)
    private String syncStatus = "PENDING"; // PENDING, COMMITTED, REJECTED, SUPERSEDED

    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "processed_at")
    private LocalDateTime processedAt;

    public WorkspaceSyncEvent() {}

    public WorkspaceSyncEvent(Order order, User user, String sessionId, String tabSessionId,
                              String eventType, String payload) {
        this.order = order;
        this.user = user;
        this.sessionId = sessionId;
        this.tabSessionId = tabSessionId;
        this.eventType = eventType;
        this.payload = payload;
        this.syncStatus = "PENDING";
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Order getOrder() { return order; }
    public void setOrder(Order order) { this.order = order; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public String getSessionId() { return sessionId; }
    public void setSessionId(String sessionId) { this.sessionId = sessionId; }

    public String getTabSessionId() { return tabSessionId; }
    public void setTabSessionId(String tabSessionId) { this.tabSessionId = tabSessionId; }

    public String getEventType() { return eventType; }
    public void setEventType(String eventType) { this.eventType = eventType; }

    public String getPayload() { return payload; }
    public void setPayload(String payload) { this.payload = payload; }

    public String getSyncStatus() { return syncStatus; }
    public void setSyncStatus(String syncStatus) { this.syncStatus = syncStatus; }

    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getProcessedAt() { return processedAt; }
    public void setProcessedAt(LocalDateTime processedAt) { this.processedAt = processedAt; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof WorkspaceSyncEvent)) return false;
        WorkspaceSyncEvent that = (WorkspaceSyncEvent) o;
        return Objects.equals(id, that.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}

