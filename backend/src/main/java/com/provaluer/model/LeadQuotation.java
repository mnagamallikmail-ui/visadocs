package com.provaluer.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "lead_quotations")
public class LeadQuotation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lead_id", nullable = false)
    @JsonIgnore
    private ValuationLead lead;

    @Column(name = "quote_number", nullable = false, unique = true, length = 50)
    private String quoteNumber;

    @Column(name = "estimated_fee", nullable = false, precision = 15, scale = 2)
    private BigDecimal estimatedFee;

    @Column(name = "tax_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal taxAmount;

    @Column(name = "total_fee", nullable = false, precision = 15, scale = 2)
    private BigDecimal totalFee;

    @Column(name = "turnaround_days", nullable = false)
    private int turnaroundDays;

    @Column(name = "scope_of_work", nullable = false, columnDefinition = "TEXT")
    private String scopeOfWork;

    @Column(name = "terms_conditions", nullable = false, columnDefinition = "TEXT")
    private String termsConditions;

    @Column(name = "is_accepted", nullable = false)
    private boolean isAccepted = false;

    @Column(name = "accepted_at")
    private LocalDateTime acceptedAt;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public LeadQuotation() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public ValuationLead getLead() { return lead; }
    public void setLead(ValuationLead lead) { this.lead = lead; }

    public String getQuoteNumber() { return quoteNumber; }
    public void setQuoteNumber(String quoteNumber) { this.quoteNumber = quoteNumber; }

    public BigDecimal getEstimatedFee() { return estimatedFee; }
    public void setEstimatedFee(BigDecimal estimatedFee) { this.estimatedFee = estimatedFee; }

    public BigDecimal getTaxAmount() { return taxAmount; }
    public void setTaxAmount(BigDecimal taxAmount) { this.taxAmount = taxAmount; }

    public BigDecimal getTotalFee() { return totalFee; }
    public void setTotalFee(BigDecimal totalFee) { this.totalFee = totalFee; }

    public int getTurnaroundDays() { return turnaroundDays; }
    public void setTurnaroundDays(int turnaroundDays) { this.turnaroundDays = turnaroundDays; }

    public String getScopeOfWork() { return scopeOfWork; }
    public void setScopeOfWork(String scopeOfWork) { this.scopeOfWork = scopeOfWork; }

    public String getTermsConditions() { return termsConditions; }
    public void setTermsConditions(String termsConditions) { this.termsConditions = termsConditions; }

    public boolean isAccepted() { return isAccepted; }
    public void setAccepted(boolean accepted) { isAccepted = accepted; }

    public LocalDateTime getAcceptedAt() { return acceptedAt; }
    public void setAcceptedAt(LocalDateTime acceptedAt) { this.acceptedAt = acceptedAt; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
