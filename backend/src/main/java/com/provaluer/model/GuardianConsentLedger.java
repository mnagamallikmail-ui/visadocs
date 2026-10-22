package com.provaluer.model;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * DPDP Act 2023 - Section 9 Processing of Personal Data of Children
 * Ensures verified parental/guardian consent is obtained before processing personal data of individuals under 18 years.
 */
@Entity
@Table(name = "guardian_consent_ledger")
public class GuardianConsentLedger {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id")
    private Long orderId;

    @Column(name = "lead_id")
    private Long leadId;

    @Column(name = "applicant_dob", nullable = false)
    private LocalDate applicantDob;

    @Column(name = "is_minor", nullable = false)
    private boolean isMinor = false;

    @Column(name = "guardian_name")
    private String guardianName;

    @Column(name = "guardian_relationship", length = 100)
    private String guardianRelationship;

    @Column(name = "guardian_phone", length = 32)
    private String guardianPhone;

    @Column(name = "guardian_email")
    private String guardianEmail;

    @Column(name = "guardian_consent_given", nullable = false)
    private boolean guardianConsentGiven = false;

    @Column(name = "consent_timestamp", nullable = false)
    private LocalDateTime consentTimestamp = LocalDateTime.now();

    @Column(name = "ip_address", length = 64)
    private String ipAddress;

    @Column(name = "user_agent", columnDefinition = "TEXT")
    private String userAgent;

    @Column(name = "notice_version", length = 32)
    private String noticeVersion = "v1.0";

    @Column(name = "withdrawn", nullable = false)
    private boolean withdrawn = false;

    @Column(name = "withdrawn_at")
    private LocalDateTime withdrawnAt;

    public GuardianConsentLedger() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public Long getLeadId() { return leadId; }
    public void setLeadId(Long leadId) { this.leadId = leadId; }

    public LocalDate getApplicantDob() { return applicantDob; }
    public void setApplicantDob(LocalDate applicantDob) { this.applicantDob = applicantDob; }

    public boolean isMinor() { return isMinor; }
    public void setMinor(boolean minor) { isMinor = minor; }

    public String getGuardianName() { return guardianName; }
    public void setGuardianName(String guardianName) { this.guardianName = guardianName; }

    public String getGuardianRelationship() { return guardianRelationship; }
    public void setGuardianRelationship(String guardianRelationship) { this.guardianRelationship = guardianRelationship; }

    public String getGuardianPhone() { return guardianPhone; }
    public void setGuardianPhone(String guardianPhone) { this.guardianPhone = guardianPhone; }

    public String getGuardianEmail() { return guardianEmail; }
    public void setGuardianEmail(String guardianEmail) { this.guardianEmail = guardianEmail; }

    public boolean isGuardianConsentGiven() { return guardianConsentGiven; }
    public void setGuardianConsentGiven(boolean guardianConsentGiven) { this.guardianConsentGiven = guardianConsentGiven; }

    public LocalDateTime getConsentTimestamp() { return consentTimestamp; }
    public void setConsentTimestamp(LocalDateTime consentTimestamp) { this.consentTimestamp = consentTimestamp; }

    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }

    public String getUserAgent() { return userAgent; }
    public void setUserAgent(String userAgent) { this.userAgent = userAgent; }

    public String getNoticeVersion() { return noticeVersion; }
    public void setNoticeVersion(String noticeVersion) { this.noticeVersion = noticeVersion; }

    public boolean isWithdrawn() { return withdrawn; }
    public void setWithdrawn(boolean withdrawn) { this.withdrawn = withdrawn; }

    public LocalDateTime getWithdrawnAt() { return withdrawnAt; }
    public void setWithdrawnAt(LocalDateTime withdrawnAt) { this.withdrawnAt = withdrawnAt; }
}
