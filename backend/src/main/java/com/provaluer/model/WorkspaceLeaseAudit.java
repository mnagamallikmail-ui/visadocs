package com.provaluer.model;

import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import java.time.LocalDateTime;

@Entity
@Table(name = "workspace_lease_audits", indexes = {
    @Index(name = "idx_ws_lease_audits_order_time", columnList = "order_id, timestamp DESC"),
    @Index(name = "idx_ws_lease_audits_user_time", columnList = "user_id, timestamp DESC")
})
public class WorkspaceLeaseAudit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "user_email")
    private String userEmail;

    @Column(name = "session_id", nullable = false, length = 64)
    private String sessionId;

    @Column(name = "event_type", nullable = false, length = 50)
    private String eventType; // ACQUIRED, RENEWED, RELEASED, EXPIRED, TAKEOVER, TAB_SWITCH

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trigger_user_id")
    private User triggerUser;

    @Column(name = "trigger_user_email")
    private String triggerUserEmail;

    @Column(name = "ip_address", length = 50)
    private String ipAddress;

    @Column(name = "device_info", length = 255)
    private String deviceInfo;

    @Column(name = "timestamp", nullable = false)
    private LocalDateTime timestamp = LocalDateTime.now();

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "details", columnDefinition = "JSONB")
    private String details;

    public WorkspaceLeaseAudit() {}

    public WorkspaceLeaseAudit(Order order, User user, String userEmail, String sessionId,
                               String eventType, User triggerUser, String triggerUserEmail,
                               String ipAddress, String deviceInfo, String details) {
        this.order = order;
        this.user = user;
        this.userEmail = userEmail;
        this.sessionId = sessionId;
        this.eventType = eventType;
        this.triggerUser = triggerUser;
        this.triggerUserEmail = triggerUserEmail;
        this.ipAddress = ipAddress;
        this.deviceInfo = deviceInfo;
        this.details = details;
        this.timestamp = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Order getOrder() { return order; }
    public void setOrder(Order order) { this.order = order; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public String getUserEmail() { return userEmail; }
    public void setUserEmail(String userEmail) { this.userEmail = userEmail; }

    public String getSessionId() { return sessionId; }
    public void setSessionId(String sessionId) { this.sessionId = sessionId; }

    public String getEventType() { return eventType; }
    public void setEventType(String eventType) { this.eventType = eventType; }

    public User getTriggerUser() { return triggerUser; }
    public void setTriggerUser(User triggerUser) { this.triggerUser = triggerUser; }

    public String getTriggerUserEmail() { return triggerUserEmail; }
    public void setTriggerUserEmail(String triggerUserEmail) { this.triggerUserEmail = triggerUserEmail; }

    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }

    public String getDeviceInfo() { return deviceInfo; }
    public void setDeviceInfo(String deviceInfo) { this.deviceInfo = deviceInfo; }

    public LocalDateTime getTimestamp() { return timestamp; }
    public void setTimestamp(LocalDateTime timestamp) { this.timestamp = timestamp; }

    public String getDetails() { return details; }
    public void setDetails(String details) { this.details = details; }
}

