package com.provaluer.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class QuoteResponseDto {
    private Long orderId;
    private String referenceCode;
    private String quoteNumber;
    private String status;
    private String serviceCategory;
    private String assetCategory;
    private String purpose;
    private String clientName;
    private String clientEmail;
    private String clientMobile;

    private BigDecimal quoteAmount;
    private BigDecimal gstRate;
    private BigDecimal quoteTax;
    private BigDecimal quoteTotal;
    private String turnaroundTime;
    private String scopeNotes;
    private String termsConditions;

    private LocalDateTime validUntil;
    private LocalDateTime quotedAt;
    private String quotedByName;

    public QuoteResponseDto() {}

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public String getReferenceCode() { return referenceCode; }
    public void setReferenceCode(String referenceCode) { this.referenceCode = referenceCode; }

    public String getQuoteNumber() { return quoteNumber; }
    public void setQuoteNumber(String quoteNumber) { this.quoteNumber = quoteNumber; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getServiceCategory() { return serviceCategory; }
    public void setServiceCategory(String serviceCategory) { this.serviceCategory = serviceCategory; }

    public String getAssetCategory() { return assetCategory; }
    public void setAssetCategory(String assetCategory) { this.assetCategory = assetCategory; }

    public String getPurpose() { return purpose; }
    public void setPurpose(String purpose) { this.purpose = purpose; }

    public String getClientName() { return clientName; }
    public void setClientName(String clientName) { this.clientName = clientName; }

    public String getClientEmail() { return clientEmail; }
    public void setClientEmail(String clientEmail) { this.clientEmail = clientEmail; }

    public String getClientMobile() { return clientMobile; }
    public void setClientMobile(String clientMobile) { this.clientMobile = clientMobile; }

    public BigDecimal getQuoteAmount() { return quoteAmount; }
    public void setQuoteAmount(BigDecimal quoteAmount) { this.quoteAmount = quoteAmount; }

    public BigDecimal getGstRate() { return gstRate; }
    public void setGstRate(BigDecimal gstRate) { this.gstRate = gstRate; }

    public BigDecimal getQuoteTax() { return quoteTax; }
    public void setQuoteTax(BigDecimal quoteTax) { this.quoteTax = quoteTax; }

    public BigDecimal getQuoteTotal() { return quoteTotal; }
    public void setQuoteTotal(BigDecimal quoteTotal) { this.quoteTotal = quoteTotal; }

    public String getTurnaroundTime() { return turnaroundTime; }
    public void setTurnaroundTime(String turnaroundTime) { this.turnaroundTime = turnaroundTime; }

    public String getScopeNotes() { return scopeNotes; }
    public void setScopeNotes(String scopeNotes) { this.scopeNotes = scopeNotes; }

    public String getTermsConditions() { return termsConditions; }
    public void setTermsConditions(String termsConditions) { this.termsConditions = termsConditions; }

    public LocalDateTime getValidUntil() { return validUntil; }
    public void setValidUntil(LocalDateTime validUntil) { this.validUntil = validUntil; }

    public LocalDateTime getQuotedAt() { return quotedAt; }
    public void setQuotedAt(LocalDateTime quotedAt) { this.quotedAt = quotedAt; }

    public String getQuotedByName() { return quotedByName; }
    public void setQuotedByName(String quotedByName) { this.quotedByName = quotedByName; }
}
