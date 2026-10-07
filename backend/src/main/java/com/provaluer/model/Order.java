package com.provaluer.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "orders")
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "client_id", nullable = false)
    private Long clientId;

    @Column(name = "pa_id")
    private Long paId;

    @Column(name = "template_id")
    private Long templateId;

    @Column(nullable = false)
    private String purpose;

    @Column(name = "property_category", nullable = false)
    private String propertyCategory;

    @Column(nullable = false)
    private String status;

    @Column(name = "estimated_value")
    private BigDecimal estimatedValue;

    @Column(name = "final_value")
    private BigDecimal finalValue;

    @Column(name = "fee_charged")
    private BigDecimal feeCharged;

    @Column(name = "balance_due")
    private BigDecimal balanceDue;

    @Column(name = "is_paused", nullable = false)
    private boolean isPaused = false;

    @Column(name = "pause_reason")
    private String pauseReason;

    @Column(name = "sla_expiry_time")
    private LocalDateTime slaExpiryTime;

    @Column(name = "claimed_at")
    private LocalDateTime claimedAt;

    @Column(name = "last_heartbeat")
    private LocalDateTime lastHeartbeat;

    @Column(name = "revision_count", nullable = false)
    private int revisionCount = 0;

    @Column(name = "revision_limit", nullable = false)
    private int revisionLimit = 2;

    @Column(name = "field_mapping_snapshot", columnDefinition = "TEXT")
    private String fieldMappingSnapshot;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "document_dom_snapshot", columnDefinition = "JSONB")
    private String documentDomSnapshot;

    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.JSON)
    @Column(name = "input_values", columnDefinition = "JSONB")
    private String inputValues;

    @Column(name = "template_version")
    private Integer templateVersion = 1;

    @Column(name = "template_version_id")
    private Long templateVersionId;

    @Column(name = "workspace_revision", nullable = false)
    private Integer workspaceRevision = 1;

    @Version
    @Column(name = "version", nullable = false)
    private Long version = 0L;


    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    @Transient
    private Boolean adminCreated = false;

    @Transient
    private String utrNumber;

    @Transient
    private LocalDateTime paymentSubmittedAt;

    @Transient
    private Integer documentCount;

    @Transient
    private BigDecimal paymentAmount;

    @Transient
    private String paymentMethod;

    @Transient
    private Long paymentProofDocumentId;

    @Transient
    private LocalDateTime paymentVerifiedAt;

    @Transient
    private String paymentVerifiedBy;

    @Transient
    private java.util.List<String> documentCategories;

    @Transient
    private Boolean hasPaymentProof;

    public Boolean getAdminCreated() { return adminCreated != null && adminCreated; }
    public void setAdminCreated(Boolean adminCreated) { this.adminCreated = adminCreated; }

    public String getUtrNumber() { return utrNumber; }
    public void setUtrNumber(String utrNumber) { this.utrNumber = utrNumber; }

    public LocalDateTime getPaymentSubmittedAt() { return paymentSubmittedAt; }
    public void setPaymentSubmittedAt(LocalDateTime paymentSubmittedAt) { this.paymentSubmittedAt = paymentSubmittedAt; }

    public Integer getDocumentCount() { return documentCount; }
    public void setDocumentCount(Integer documentCount) { this.documentCount = documentCount; }

    public BigDecimal getPaymentAmount() { return paymentAmount; }
    public void setPaymentAmount(BigDecimal paymentAmount) { this.paymentAmount = paymentAmount; }

    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }

    public Long getPaymentProofDocumentId() { return paymentProofDocumentId; }
    public void setPaymentProofDocumentId(Long paymentProofDocumentId) { this.paymentProofDocumentId = paymentProofDocumentId; }

    public LocalDateTime getPaymentVerifiedAt() { return paymentVerifiedAt; }
    public void setPaymentVerifiedAt(LocalDateTime paymentVerifiedAt) { this.paymentVerifiedAt = paymentVerifiedAt; }

    public String getPaymentVerifiedBy() { return paymentVerifiedBy; }
    public void setPaymentVerifiedBy(String paymentVerifiedBy) { this.paymentVerifiedBy = paymentVerifiedBy; }

    public java.util.List<String> getDocumentCategories() { return documentCategories; }
    public void setDocumentCategories(java.util.List<String> documentCategories) { this.documentCategories = documentCategories; }

    public Boolean getHasPaymentProof() { return hasPaymentProof != null && hasPaymentProof; }
    public void setHasPaymentProof(Boolean hasPaymentProof) { this.hasPaymentProof = hasPaymentProof; }

    public Order() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getClientId() { return clientId; }
    public void setClientId(Long clientId) { this.clientId = clientId; }
    public Long getPaId() { return paId; }
    public void setPaId(Long paId) { this.paId = paId; }
    public Long getTemplateId() { return templateId; }
    public void setTemplateId(Long templateId) { this.templateId = templateId; }
    public String getPurpose() { return purpose; }
    public void setPurpose(String purpose) { this.purpose = purpose; }
    public String getPropertyCategory() { return propertyCategory; }
    public void setPropertyCategory(String propertyCategory) { this.propertyCategory = propertyCategory; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public BigDecimal getEstimatedValue() { return estimatedValue; }
    public void setEstimatedValue(BigDecimal estimatedValue) { this.estimatedValue = estimatedValue; }
    public BigDecimal getFinalValue() { return finalValue; }
    public void setFinalValue(BigDecimal finalValue) { this.finalValue = finalValue; }
    public BigDecimal getFeeCharged() { return feeCharged; }
    public void setFeeCharged(BigDecimal feeCharged) { this.feeCharged = feeCharged; }
    public BigDecimal getBalanceDue() { return balanceDue; }
    public void setBalanceDue(BigDecimal balanceDue) { this.balanceDue = balanceDue; }
    public boolean isPaused() { return isPaused; }
    public void setPaused(boolean paused) { isPaused = paused; }
    public String getPauseReason() { return pauseReason; }
    public void setPauseReason(String pauseReason) { this.pauseReason = pauseReason; }
    public LocalDateTime getSlaExpiryTime() { return slaExpiryTime; }
    public void setSlaExpiryTime(LocalDateTime slaExpiryTime) { this.slaExpiryTime = slaExpiryTime; }
    public LocalDateTime getClaimedAt() { return claimedAt; }
    public void setClaimedAt(LocalDateTime claimedAt) { this.claimedAt = claimedAt; }
    public LocalDateTime getLastHeartbeat() { return lastHeartbeat; }
    public void setLastHeartbeat(LocalDateTime lastHeartbeat) { this.lastHeartbeat = lastHeartbeat; }
    public int getRevisionCount() { return revisionCount; }
    public void setRevisionCount(int revisionCount) { this.revisionCount = revisionCount; }
    public int getRevisionLimit() { return revisionLimit; }
    public void setRevisionLimit(int revisionLimit) { this.revisionLimit = revisionLimit; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public String getFieldMappingSnapshot() { return fieldMappingSnapshot; }
    public void setFieldMappingSnapshot(String fieldMappingSnapshot) { this.fieldMappingSnapshot = fieldMappingSnapshot; }

    public String getDocumentDomSnapshot() { return documentDomSnapshot; }
    public void setDocumentDomSnapshot(String documentDomSnapshot) { this.documentDomSnapshot = documentDomSnapshot; }

    public String getInputValues() { return inputValues; }
    public void setInputValues(String inputValues) { this.inputValues = inputValues; }

    public Integer getTemplateVersion() { return templateVersion; }
    public void setTemplateVersion(Integer templateVersion) { this.templateVersion = templateVersion; }

    public Long getTemplateVersionId() { return templateVersionId; }
    public void setTemplateVersionId(Long templateVersionId) { this.templateVersionId = templateVersionId; }

    @Column(name = "report_number")
    private String reportNumber;

    @Column(name = "client_name")
    private String clientName;

    @Column(name = "bank_name")
    private String bankName;

    @Column(name = "branch_name")
    private String branchName;

    public String getReportNumber() { return reportNumber; }
    public void setReportNumber(String reportNumber) { this.reportNumber = reportNumber; }

    public String getClientName() { return clientName; }
    public void setClientName(String clientName) { this.clientName = clientName; }

    public String getBankName() { return bankName; }
    public void setBankName(String bankName) { this.bankName = bankName; }

    public String getBranchName() { return branchName; }
    public void setBranchName(String branchName) { this.branchName = branchName; }

    @Column(name = "reference_code", unique = true, length = 32)
    private String referenceCode;

    @Column(name = "service_category")
    private String serviceCategory;

    public String getReferenceCode() { return referenceCode; }
    public void setReferenceCode(String referenceCode) { this.referenceCode = referenceCode; }

    public String getServiceCategory() { return serviceCategory; }
    public void setServiceCategory(String serviceCategory) { this.serviceCategory = serviceCategory; }

    @Column(name = "valuation_status", nullable = false)
    private String valuationStatus = "DRAFT"; // DRAFT, FINALIZED, LOCKED, ARCHIVED

    @Column(name = "is_deleted", nullable = false)
    private boolean isDeleted = false;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    @Column(name = "deleted_by")
    private Long deletedBy;

    public String getValuationStatus() { return valuationStatus; }
    public void setValuationStatus(String valuationStatus) { this.valuationStatus = valuationStatus; }

    public boolean isDeleted() { return isDeleted; }
    public void setDeleted(boolean deleted) { isDeleted = deleted; }

    public LocalDateTime getDeletedAt() { return deletedAt; }
    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }

    public Long getDeletedBy() { return deletedBy; }
    public void setDeletedBy(Long deletedBy) { this.deletedBy = deletedBy; }

    // SPRINT 2: Quotation Fields
    @Column(name = "quote_number", unique = true, length = 32)
    private String quoteNumber;

    @Column(name = "quote_amount")
    private BigDecimal quoteAmount;

    @Column(name = "quote_tax")
    private BigDecimal quoteTax;

    @Column(name = "quote_total")
    private BigDecimal quoteTotal;

    @Column(name = "quote_turnaround", length = 64)
    private String quoteTurnaround;

    @Column(name = "quote_notes", columnDefinition = "TEXT")
    private String quoteNotes;

    @Column(name = "quote_terms", columnDefinition = "TEXT")
    private String quoteTerms;

    @Column(name = "quote_valid_until")
    private LocalDateTime quoteValidUntil;

    @Column(name = "quoted_by")
    private Long quotedBy;

    @Column(name = "quoted_at")
    private LocalDateTime quotedAt;

    public String getQuoteNumber() { return quoteNumber; }
    public void setQuoteNumber(String quoteNumber) { this.quoteNumber = quoteNumber; }

    public BigDecimal getQuoteAmount() { return quoteAmount; }
    public void setQuoteAmount(BigDecimal quoteAmount) { this.quoteAmount = quoteAmount; }

    public BigDecimal getQuoteTax() { return quoteTax; }
    public void setQuoteTax(BigDecimal quoteTax) { this.quoteTax = quoteTax; }

    public BigDecimal getQuoteTotal() { return quoteTotal; }
    public void setQuoteTotal(BigDecimal quoteTotal) { this.quoteTotal = quoteTotal; }

    public String getQuoteTurnaround() { return quoteTurnaround; }
    public void setQuoteTurnaround(String quoteTurnaround) { this.quoteTurnaround = quoteTurnaround; }

    public String getQuoteNotes() { return quoteNotes; }
    public void setQuoteNotes(String quoteNotes) { this.quoteNotes = quoteNotes; }

    public String getQuoteTerms() { return quoteTerms; }
    public void setQuoteTerms(String quoteTerms) { this.quoteTerms = quoteTerms; }

    public LocalDateTime getQuoteValidUntil() { return quoteValidUntil; }
    public void setQuoteValidUntil(LocalDateTime quoteValidUntil) { this.quoteValidUntil = quoteValidUntil; }

    public Long getQuotedBy() { return quotedBy; }
    public void setQuotedBy(Long quotedBy) { this.quotedBy = quotedBy; }

    public LocalDateTime getQuotedAt() { return quotedAt; }
    public void setQuotedAt(LocalDateTime quotedAt) { this.quotedAt = quotedAt; }

    @Column(name = "payment_status", length = 32)
    private String paymentStatus = "PENDING"; // PENDING, SUBMITTED, VERIFIED, REJECTED

    @Column(name = "latest_payment_id")
    private Long latestPaymentId;

    public String getPaymentStatus() { return paymentStatus; }
    public void setPaymentStatus(String paymentStatus) { this.paymentStatus = paymentStatus; }

    public Long getLatestPaymentId() { return latestPaymentId; }
    public void setLatestPaymentId(Long latestPaymentId) { this.latestPaymentId = latestPaymentId; }

    // SPRINT 4: Admin Controlled Pool Release fields
    @Column(name = "released_to_pool_at")
    private LocalDateTime releasedToPoolAt;

    @Column(name = "released_by", length = 255)
    private String releasedBy;

    @Column(name = "intake_hold_reason", length = 1000)
    private String intakeHoldReason;

    @Column(name = "intake_notes", columnDefinition = "TEXT")
    private String intakeNotes;

    public LocalDateTime getReleasedToPoolAt() { return releasedToPoolAt; }
    public void setReleasedToPoolAt(LocalDateTime releasedToPoolAt) { this.releasedToPoolAt = releasedToPoolAt; }

    public String getReleasedBy() { return releasedBy; }
    public void setReleasedBy(String releasedBy) { this.releasedBy = releasedBy; }

    public String getIntakeHoldReason() { return intakeHoldReason; }
    public void setIntakeHoldReason(String intakeHoldReason) { this.intakeHoldReason = intakeHoldReason; }

    public String getIntakeNotes() { return intakeNotes; }
    public void setIntakeNotes(String intakeNotes) { this.intakeNotes = intakeNotes; }

    // SPRINT 5: Site Inspection Lifecycle & Multi-State Resume
    @Column(name = "pre_pause_status", length = 32)
    private String prePauseStatus;

    public String getPrePauseStatus() { return prePauseStatus; }
    public void setPrePauseStatus(String prePauseStatus) { this.prePauseStatus = prePauseStatus; }

    // SPRINT 8: Delivery, Revenue Recognition, and Archival Lock
    @Column(name = "corporate_credit_active", nullable = false)
    private boolean corporateCreditActive = false;

    @Column(name = "commercial_override_notes", columnDefinition = "TEXT")
    private String commercialOverrideNotes;

    @Column(name = "archival_locked", nullable = false)
    private boolean archivalLocked = false;

    @Column(name = "revenue_recognized", nullable = false)
    private boolean revenueRecognized = false;

    @Column(name = "revenue_recognized_at")
    private LocalDateTime revenueRecognizedAt;

    @Column(name = "delivered_at")
    private LocalDateTime deliveredAt;

    @Column(name = "downloaded_at")
    private LocalDateTime downloadedAt;

    @Column(name = "closed_at")
    private LocalDateTime closedAt;

    public boolean isCorporateCreditActive() { return corporateCreditActive; }
    public void setCorporateCreditActive(boolean corporateCreditActive) { this.corporateCreditActive = corporateCreditActive; }

    public String getCommercialOverrideNotes() { return commercialOverrideNotes; }
    public void setCommercialOverrideNotes(String commercialOverrideNotes) { this.commercialOverrideNotes = commercialOverrideNotes; }

    public boolean isArchivalLocked() { return archivalLocked; }
    public void setArchivalLocked(boolean archivalLocked) { this.archivalLocked = archivalLocked; }

    public boolean isRevenueRecognized() { return revenueRecognized; }
    public void setRevenueRecognized(boolean revenueRecognized) { this.revenueRecognized = revenueRecognized; }

    public LocalDateTime getRevenueRecognizedAt() { return revenueRecognizedAt; }
    public void setRevenueRecognizedAt(LocalDateTime revenueRecognizedAt) { this.revenueRecognizedAt = revenueRecognizedAt; }

    public LocalDateTime getDeliveredAt() { return deliveredAt; }
    public void setDeliveredAt(LocalDateTime deliveredAt) { this.deliveredAt = deliveredAt; }

    public LocalDateTime getDownloadedAt() { return downloadedAt; }
    public void setDownloadedAt(LocalDateTime downloadedAt) { this.downloadedAt = downloadedAt; }

    public LocalDateTime getClosedAt() { return closedAt; }
    public void setClosedAt(LocalDateTime closedAt) { this.closedAt = closedAt; }

    public Integer getWorkspaceRevision() { return workspaceRevision; }
    public void setWorkspaceRevision(Integer workspaceRevision) { this.workspaceRevision = workspaceRevision; }

    public Long getVersion() { return version; }
    public void setVersion(Long version) { this.version = version; }
}

