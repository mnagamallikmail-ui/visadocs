package com.provaluer.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "valuation_land_items")
public class ValuationLandItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "description")
    private String description;

    @Column(name = "survey_no")
    private String surveyNo;

    @Column(name = "entered_area", precision = 19, scale = 4, nullable = false)
    private BigDecimal enteredArea = BigDecimal.ZERO;

    @Column(name = "entered_unit", nullable = false)
    private String enteredUnit = "Sq.Ft";

    @Column(name = "standard_area_sqft", precision = 19, scale = 4, nullable = false)
    private BigDecimal standardAreaSqft = BigDecimal.ZERO;

    @Column(name = "rate", precision = 19, scale = 2, nullable = false)
    private BigDecimal rate = BigDecimal.ZERO;

    @Column(name = "\"value\"", precision = 19, scale = 2, nullable = false)
    private BigDecimal value = BigDecimal.ZERO;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder = 0;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @com.fasterxml.jackson.annotation.JsonIgnore
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    public ValuationLandItem() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getSurveyNo() { return surveyNo; }
    public void setSurveyNo(String surveyNo) { this.surveyNo = surveyNo; }

    public BigDecimal getEnteredArea() { return enteredArea; }
    public void setEnteredArea(BigDecimal enteredArea) { this.enteredArea = enteredArea; }

    public String getEnteredUnit() { return enteredUnit; }
    public void setEnteredUnit(String enteredUnit) { this.enteredUnit = enteredUnit; }

    public BigDecimal getStandardAreaSqft() { return standardAreaSqft; }
    public void setStandardAreaSqft(BigDecimal standardAreaSqft) { this.standardAreaSqft = standardAreaSqft; }

    public BigDecimal getRate() { return rate; }
    public void setRate(BigDecimal rate) { this.rate = rate; }

    public BigDecimal getValue() { return value; }
    public void setValue(BigDecimal value) { this.value = value; }

    public int getSortOrder() { return sortOrder; }
    public void setSortOrder(int sortOrder) { this.sortOrder = sortOrder; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
