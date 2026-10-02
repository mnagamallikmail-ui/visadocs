package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "order_acknowledgements")
public class OrderAcknowledgement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "action", nullable = false, length = 64)
    private String action; // VIEWED, DOWNLOADED, ACCEPTED, CLARIFICATION_REQUESTED, AUTO_ACCEPTED

    @Column(name = "actor_id")
    private Long actorId;

    @Column(name = "actor_role", length = 32)
    private String actorRole;

    @Column(name = "client_ip", length = 64)
    private String clientIp;

    @Column(name = "user_agent", columnDefinition = "TEXT")
    private String userAgent;

    @Column(name = "clarification_type", length = 64)
    private String clarificationType;

    @Column(name = "clarification_notes", columnDefinition = "TEXT")
    private String clarificationNotes;

    @Column(name = "acceptance_declaration", columnDefinition = "TEXT")
    private String acceptanceDeclaration;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public OrderAcknowledgement() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }

    public Long getActorId() { return actorId; }
    public void setActorId(Long actorId) { this.actorId = actorId; }

    public String getActorRole() { return actorRole; }
    public void setActorRole(String actorRole) { this.actorRole = actorRole; }

    public String getClientIp() { return clientIp; }
    public void setClientIp(String clientIp) { this.clientIp = clientIp; }

    public String getUserAgent() { return userAgent; }
    public void setUserAgent(String userAgent) { this.userAgent = userAgent; }

    public String getClarificationType() { return clarificationType; }
    public void setClarificationType(String clarificationType) { this.clarificationType = clarificationType; }

    public String getClarificationNotes() { return clarificationNotes; }
    public void setClarificationNotes(String clarificationNotes) { this.clarificationNotes = clarificationNotes; }

    public String getAcceptanceDeclaration() { return acceptanceDeclaration; }
    public void setAcceptanceDeclaration(String acceptanceDeclaration) { this.acceptanceDeclaration = acceptanceDeclaration; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
