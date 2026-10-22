package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "consent_ledger")
public class ConsentLedger {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id")
    private Long userId;

    @Column(name = "lead_id")
    private Long leadId;

    @Column(name = "actor_identifier", nullable = false, length = 255)
    private String actorIdentifier;

    @Column(name = "consent_type", nullable = false, length = 64)
    private String consentType; // TERMS_ACCEPTANCE, VALUATION_PROCESSING, ANALYTICS_TRACKING, MARKETING

    @Column(name = "consent_given", nullable = false)
    private boolean consentGiven;

    @Column(name = "notice_version", nullable = false, length = 32)
    private String noticeVersion = "DPDP-NOTICE-V1.0";

    @Column(name = "terms_version", nullable = false, length = 32)
    private String termsVersion = "v2.4";

    @Column(name = "ip_address", length = 64)
    private String ipAddress;

    @Column(name = "user_agent", columnDefinition = "TEXT")
    private String userAgent;

    @Column(name = "withdrawn", nullable = false)
    private boolean withdrawn = false;

    @Column(name = "withdrawn_at")
    private LocalDateTime withdrawnAt;

    @Column(name = "withdrawal_reason", columnDefinition = "TEXT")
    private String withdrawalReason;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public ConsentLedger() {}

    public ConsentLedger(Long userId, Long leadId, String actorIdentifier, String consentType, 
                         boolean consentGiven, String noticeVersion, String termsVersion, 
                         String ipAddress, String userAgent) {
        this.userId = userId;
        this.leadId = leadId;
        this.actorIdentifier = actorIdentifier;
        this.consentType = consentType;
        this.consentGiven = consentGiven;
        this.noticeVersion = noticeVersion != null ? noticeVersion : "DPDP-NOTICE-V1.0";
        this.termsVersion = termsVersion != null ? termsVersion : "v2.4";
        this.ipAddress = ipAddress;
        this.userAgent = userAgent;
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public Long getLeadId() { return leadId; }
    public void setLeadId(Long leadId) { this.leadId = leadId; }

    public String getActorIdentifier() { return actorIdentifier; }
    public void setActorIdentifier(String actorIdentifier) { this.actorIdentifier = actorIdentifier; }

    public String getConsentType() { return consentType; }
    public void setConsentType(String consentType) { this.consentType = consentType; }

    public boolean isConsentGiven() { return consentGiven; }
    public void setConsentGiven(boolean consentGiven) { this.consentGiven = consentGiven; }

    public String getNoticeVersion() { return noticeVersion; }
    public void setNoticeVersion(String noticeVersion) { this.noticeVersion = noticeVersion; }

    public String getTermsVersion() { return termsVersion; }
    public void setTermsVersion(String termsVersion) { this.termsVersion = termsVersion; }

    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }

    public String getUserAgent() { return userAgent; }
    public void setUserAgent(String userAgent) { this.userAgent = userAgent; }

    public boolean isWithdrawn() { return withdrawn; }
    public void setWithdrawn(boolean withdrawn) { this.withdrawn = withdrawn; }

    public LocalDateTime getWithdrawnAt() { return withdrawnAt; }
    public void setWithdrawnAt(LocalDateTime withdrawnAt) { this.withdrawnAt = withdrawnAt; }

    public String getWithdrawalReason() { return withdrawalReason; }
    public void setWithdrawalReason(String withdrawalReason) { this.withdrawalReason = withdrawalReason; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
