package com.provaluer.model;

import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import java.time.LocalDateTime;
import java.util.Objects;

@Entity
@Table(name = "order_revision_history", indexes = {
    @Index(name = "idx_order_revision_history_order", columnList = "order_id, revision_number DESC"),
    @Index(name = "idx_order_revision_history_saved_at", columnList = "saved_at DESC"),
    @Index(name = "idx_order_revision_history_username", columnList = "saved_by_username")
})
public class OrderRevisionHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @Column(name = "revision_number", nullable = false)
    private Integer revisionNumber;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "saved_by")
    private User savedBy;

    @Column(name = "saved_by_username", nullable = false, length = 100)
    private String savedByUsername;

    @Column(name = "saved_by_role", length = 50)
    private String savedByRole;

    @Column(name = "session_id", nullable = false, length = 64)
    private String sessionId;

    @Column(name = "tab_session_id", nullable = false, length = 64)
    private String tabSessionId;

    @Column(name = "saved_at", nullable = false)
    private LocalDateTime savedAt = LocalDateTime.now();

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "keys_changed", nullable = false)
    private Integer keysChanged;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "snapshot_summary", columnDefinition = "JSONB")
    private String snapshotSummary;

    @Column(name = "ip_address", length = 50)
    private String ipAddress;

    public OrderRevisionHistory() {}

    public OrderRevisionHistory(Order order, Integer revisionNumber, User savedBy, String savedByUsername,
                                String savedByRole, String sessionId, String tabSessionId,
                                Integer keysChanged, String snapshotSummary, String ipAddress) {
        this.order = order;
        this.revisionNumber = revisionNumber;
        this.savedBy = savedBy;
        this.savedByUsername = savedByUsername;
        this.savedByRole = savedByRole;
        this.sessionId = sessionId;
        this.tabSessionId = tabSessionId;
        this.keysChanged = keysChanged != null ? keysChanged : 0;
        this.snapshotSummary = snapshotSummary;
        this.ipAddress = ipAddress;
        this.savedAt = LocalDateTime.now();
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Order getOrder() { return order; }
    public void setOrder(Order order) { this.order = order; }

    public Integer getRevisionNumber() { return revisionNumber; }
    public void setRevisionNumber(Integer revisionNumber) { this.revisionNumber = revisionNumber; }

    public User getSavedBy() { return savedBy; }
    public void setSavedBy(User savedBy) { this.savedBy = savedBy; }

    public String getSavedByUsername() { return savedByUsername; }
    public void setSavedByUsername(String savedByUsername) { this.savedByUsername = savedByUsername; }

    public String getSavedByRole() { return savedByRole; }
    public void setSavedByRole(String savedByRole) { this.savedByRole = savedByRole; }

    public String getSessionId() { return sessionId; }
    public void setSessionId(String sessionId) { this.sessionId = sessionId; }

    public String getTabSessionId() { return tabSessionId; }
    public void setTabSessionId(String tabSessionId) { this.tabSessionId = tabSessionId; }

    public LocalDateTime getSavedAt() { return savedAt; }
    public void setSavedAt(LocalDateTime savedAt) { this.savedAt = savedAt; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public Integer getKeysChanged() { return keysChanged; }
    public void setKeysChanged(Integer keysChanged) { this.keysChanged = keysChanged; }

    public String getSnapshotSummary() { return snapshotSummary; }
    public void setSnapshotSummary(String snapshotSummary) { this.snapshotSummary = snapshotSummary; }

    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof OrderRevisionHistory)) return false;
        OrderRevisionHistory that = (OrderRevisionHistory) o;
        return Objects.equals(id, that.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}

