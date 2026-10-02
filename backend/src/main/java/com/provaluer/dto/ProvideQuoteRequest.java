package com.provaluer.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public class ProvideQuoteRequest {

    @NotNull(message = "Quote amount is required")
    @DecimalMin(value = "0.01", message = "Quote amount must be greater than zero")
    private BigDecimal quoteAmount;

    private BigDecimal gstRate;

    private BigDecimal quoteTax;

    private BigDecimal quoteTotal;

    @NotBlank(message = "Turnaround time is required")
    private String turnaroundTime;

    @NotBlank(message = "Scope notes are required")
    private String scopeNotes;

    private String termsConditions;

    private Integer validityDays;

    public ProvideQuoteRequest() {}

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

    public Integer getValidityDays() { return validityDays; }
    public void setValidityDays(Integer validityDays) { this.validityDays = validityDays; }
}
