package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.Objects;

@Entity
@Table(name = "workspace_sessions", indexes = {
    @Index(name = "idx_ws_sessions_order_lock", columnList = "order_id, lock_status"),
    @Index(name = "idx_ws_sessions_order_user", columnList = "order_id, user_id"),
    @Index(name = "idx_ws_sessions_session_id", columnList = "session_id")
})
public class WorkspaceSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false, unique = true)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "session_id", nullable = false, length = 64)
    private String sessionId;

    @Column(name = "tab_session_id", nullable = false, length = 64)
    private String tabSessionId;

    @Column(name = "lock_status", nullable = false, length = 30)
    private String lockStatus = "ACTIVE"; // ACTIVE, RELEASED, EXPIRED, FORCIBLY_TERMINATED

    @Column(name = "acquired_at", nullable = false)
    private LocalDateTime acquiredAt = LocalDateTime.now();

    @Column(name = "last_heartbeat", nullable = false)
    private LocalDateTime lastHeartbeat = LocalDateTime.now();

    @Column(name = "last_activity", nullable = false)
    private LocalDateTime lastActivity = LocalDateTime.now();

    @Column(name = "machine_name", length = 100)
    private String machineName;

    @Column(name = "platform_info", length = 100)
    private String platformInfo;

    @Column(name = "ip_address", nullable = false, length = 50)
    private String ipAddress;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    public WorkspaceSession() {}

    public WorkspaceSession(Order order, User user, String sessionId, String tabSessionId,
                            String machineName, String platformInfo, String ipAddress) {
        this.order = order;
        this.user = user;
        this.sessionId = sessionId;
        this.tabSessionId = tabSessionId;
        this.lockStatus = "ACTIVE";
        this.acquiredAt = LocalDateTime.now();
        this.lastHeartbeat = LocalDateTime.now();
        this.lastActivity = LocalDateTime.now();
        this.machineName = machineName;
        this.platformInfo = platformInfo;
        this.ipAddress = ipAddress;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
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

    public String getLockStatus() { return lockStatus; }
    public void setLockStatus(String lockStatus) { this.lockStatus = lockStatus; }

    public LocalDateTime getAcquiredAt() { return acquiredAt; }
    public void setAcquiredAt(LocalDateTime acquiredAt) { this.acquiredAt = acquiredAt; }

    public LocalDateTime getLastHeartbeat() { return lastHeartbeat; }
    public void setLastHeartbeat(LocalDateTime lastHeartbeat) { this.lastHeartbeat = lastHeartbeat; }

    public LocalDateTime getLastActivity() { return lastActivity; }
    public void setLastActivity(LocalDateTime lastActivity) { this.lastActivity = lastActivity; }

    public String getMachineName() { return machineName; }
    public void setMachineName(String machineName) { this.machineName = machineName; }

    public String getPlatformInfo() { return platformInfo; }
    public void setPlatformInfo(String platformInfo) { this.platformInfo = platformInfo; }

    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof WorkspaceSession)) return false;
        WorkspaceSession that = (WorkspaceSession) o;
        return Objects.equals(order != null ? order.getId() : null, that.order != null ? that.order.getId() : null);
    }

    @Override
    public int hashCode() {
        return Objects.hash(order != null ? order.getId() : null);
    }
}

