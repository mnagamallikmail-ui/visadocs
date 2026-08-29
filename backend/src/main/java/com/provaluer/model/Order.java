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


    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

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
}

