package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * DPDP Act 2023 - Document Access Audit Log
 * Tracks every access, download token generation, and document retrieval.
 */
@Entity
@Table(name = "document_access_logs")
public class DocumentAccessLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id")
    private Long userId;

    @Column(name = "username", length = 100)
    private String username;

    @Column(name = "document_type", nullable = false, length = 64)
    private String documentType; // LEAD_DOCUMENT, ORDER_DOCUMENT, DELIVERABLE, INVOICE

    @Column(name = "document_id", nullable = false, length = 128)
    private String documentId;

    @Column(name = "document_name", length = 255)
    private String documentName;

    @Column(name = "action", nullable = false, length = 64)
    private String action; // TOKEN_GENERATED, DOWNLOAD_SUCCESS, ACCESS_DENIED, TOKEN_EXPIRED

    @Column(name = "token_used", length = 128)
    private String tokenUsed;

    @Column(name = "ip_address", length = 64)
    private String ipAddress;

    @Column(name = "user_agent", columnDefinition = "TEXT")
    private String userAgent;

    @Column(name = "access_status", nullable = false, length = 32)
    private String accessStatus = "SUCCESS";

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public DocumentAccessLog() {}

    public DocumentAccessLog(Long userId, String username, String documentType, String documentId,
                             String documentName, String action, String tokenUsed, String ipAddress,
                             String userAgent, String accessStatus) {
        this.userId = userId;
        this.username = username;
        this.documentType = documentType;
        this.documentId = documentId;
        this.documentName = documentName;
        this.action = action;
        this.tokenUsed = tokenUsed;
        this.ipAddress = ipAddress;
        this.userAgent = userAgent;
        this.accessStatus = accessStatus;
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getDocumentType() { return documentType; }
    public void setDocumentType(String documentType) { this.documentType = documentType; }

    public String getDocumentId() { return documentId; }
    public void setDocumentId(String documentId) { this.documentId = documentId; }

    public String getDocumentName() { return documentName; }
    public void setDocumentName(String documentName) { this.documentName = documentName; }

    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }

    public String getTokenUsed() { return tokenUsed; }
    public void setTokenUsed(String tokenUsed) { this.tokenUsed = tokenUsed; }

    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }

    public String getUserAgent() { return userAgent; }
    public void setUserAgent(String userAgent) { this.userAgent = userAgent; }

    public String getAccessStatus() { return accessStatus; }
    public void setAccessStatus(String accessStatus) { this.accessStatus = accessStatus; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
