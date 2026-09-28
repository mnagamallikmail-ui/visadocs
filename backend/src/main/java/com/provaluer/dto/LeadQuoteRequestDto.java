package com.provaluer.dto;

import java.math.BigDecimal;

public class LeadQuoteRequestDto {
    private BigDecimal estimatedFee;
    private int turnaroundDays;
    private String scopeOfWork;
    private String termsConditions;

    public LeadQuoteRequestDto() {}

    public BigDecimal getEstimatedFee() { return estimatedFee; }
    public void setEstimatedFee(BigDecimal estimatedFee) { this.estimatedFee = estimatedFee; }

    public int getTurnaroundDays() { return turnaroundDays; }
    public void setTurnaroundDays(int turnaroundDays) { this.turnaroundDays = turnaroundDays; }

    public String getScopeOfWork() { return scopeOfWork; }
    public void setScopeOfWork(String scopeOfWork) { this.scopeOfWork = scopeOfWork; }

    public String getTermsConditions() { return termsConditions; }
    public void setTermsConditions(String termsConditions) { this.termsConditions = termsConditions; }
}
