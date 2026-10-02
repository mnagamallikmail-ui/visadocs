package com.provaluer.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * SPRINT 4: DTO returned by GET /api/v1/orders/release-queue.
 * Contains all fields required by the Admin Release Queue screen.
 */
public class ReleaseQueueOrderDto {

    private Long orderId;
    private String referenceCode;
    private String quoteNumber;
    private String clientName;
    private String clientEmail;
    private String serviceCategory;
    private String assetCategory;
    private String purpose;

    // Quotation summary
    private BigDecimal quoteAmount;
    private BigDecimal quoteTax;
    private BigDecimal quoteTotal;
    private LocalDateTime quotedAt;

    // Payment summary
    private BigDecimal verifiedAmount;
    private LocalDateTime paymentVerifiedAt;
    private String paymentVerifiedBy;
    private String utrNumber;

    // Document count
    private int documentCount;

    // Current order state
    private String status;
    private String paymentStatus;
    private LocalDateTime createdAt;

    // ── Getters / Setters ────────────────────────────────────────────────────

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public String getReferenceCode() { return referenceCode; }
    public void setReferenceCode(String referenceCode) { this.referenceCode = referenceCode; }

    public String getQuoteNumber() { return quoteNumber; }
    public void setQuoteNumber(String quoteNumber) { this.quoteNumber = quoteNumber; }

    public String getClientName() { return clientName; }
    public void setClientName(String clientName) { this.clientName = clientName; }

    public String getClientEmail() { return clientEmail; }
    public void setClientEmail(String clientEmail) { this.clientEmail = clientEmail; }

    public String getServiceCategory() { return serviceCategory; }
    public void setServiceCategory(String serviceCategory) { this.serviceCategory = serviceCategory; }

    public String getAssetCategory() { return assetCategory; }
    public void setAssetCategory(String assetCategory) { this.assetCategory = assetCategory; }

    public String getPurpose() { return purpose; }
    public void setPurpose(String purpose) { this.purpose = purpose; }

    public BigDecimal getQuoteAmount() { return quoteAmount; }
    public void setQuoteAmount(BigDecimal quoteAmount) { this.quoteAmount = quoteAmount; }

    public BigDecimal getQuoteTax() { return quoteTax; }
    public void setQuoteTax(BigDecimal quoteTax) { this.quoteTax = quoteTax; }

    public BigDecimal getQuoteTotal() { return quoteTotal; }
    public void setQuoteTotal(BigDecimal quoteTotal) { this.quoteTotal = quoteTotal; }

    public LocalDateTime getQuotedAt() { return quotedAt; }
    public void setQuotedAt(LocalDateTime quotedAt) { this.quotedAt = quotedAt; }

    public BigDecimal getVerifiedAmount() { return verifiedAmount; }
    public void setVerifiedAmount(BigDecimal verifiedAmount) { this.verifiedAmount = verifiedAmount; }

    public LocalDateTime getPaymentVerifiedAt() { return paymentVerifiedAt; }
    public void setPaymentVerifiedAt(LocalDateTime paymentVerifiedAt) { this.paymentVerifiedAt = paymentVerifiedAt; }

    public String getPaymentVerifiedBy() { return paymentVerifiedBy; }
    public void setPaymentVerifiedBy(String paymentVerifiedBy) { this.paymentVerifiedBy = paymentVerifiedBy; }

    public String getUtrNumber() { return utrNumber; }
    public void setUtrNumber(String utrNumber) { this.utrNumber = utrNumber; }

    public int getDocumentCount() { return documentCount; }
    public void setDocumentCount(int documentCount) { this.documentCount = documentCount; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getPaymentStatus() { return paymentStatus; }
    public void setPaymentStatus(String paymentStatus) { this.paymentStatus = paymentStatus; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
