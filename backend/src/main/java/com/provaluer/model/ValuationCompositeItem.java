package com.provaluer.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "valuation_composite_items")
public class ValuationCompositeItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "item_category", nullable = false)
    private String itemCategory = "INTERIOR_WORK"; // MAIN_UNIT or INTERIOR_WORK

    @Column(name = "description", nullable = false)
    private String description = "Interior Works & Improvements";

    @Column(name = "entered_unit", nullable = false)
    private String enteredUnit = "LS";

    @Column(name = "quantity", precision = 19, scale = 4, nullable = false)
    private BigDecimal quantity = BigDecimal.ONE;

    @Column(name = "rate", precision = 19, scale = 2, nullable = false)
    private BigDecimal rate = BigDecimal.ZERO;

    @Column(name = "amount", precision = 19, scale = 2, nullable = false)
    private BigDecimal amount = BigDecimal.ZERO;

    @Column(name = "construction_cost", precision = 19, scale = 2, nullable = false)
    private BigDecimal constructionCost = new BigDecimal("2000.00");

    @Column(name = "building_age", precision = 6, scale = 2, nullable = false)
    private BigDecimal buildingAge = BigDecimal.ZERO;

    @Column(name = "total_life", nullable = false)
    private int totalLife = 60;

    @Column(name = "depreciation_mode", nullable = false)
    private String depreciationMode = "PERCENTAGE"; // PERCENTAGE or DIRECT_AMOUNT

    @Column(name = "depreciation_percentage", precision = 6, scale = 2, nullable = false)
    private BigDecimal depreciationPercentage = BigDecimal.ZERO;

    @Column(name = "depreciation_amount", precision = 19, scale = 2, nullable = false)
    private BigDecimal depreciationAmount = BigDecimal.ZERO;

    @Column(name = "is_insurable", nullable = false)
    private Boolean isInsurable = true;

    @Column(name = "fair_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal fairValue = BigDecimal.ZERO;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder = 1;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @com.fasterxml.jackson.annotation.JsonIgnore
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    public ValuationCompositeItem() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public String getItemCategory() { return itemCategory; }
    public void setItemCategory(String itemCategory) { this.itemCategory = itemCategory; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getEnteredUnit() { return enteredUnit; }
    public void setEnteredUnit(String enteredUnit) { this.enteredUnit = enteredUnit; }

    public BigDecimal getQuantity() { return quantity; }
    public void setQuantity(BigDecimal quantity) { this.quantity = quantity; }

    public BigDecimal getRate() { return rate; }
    public void setRate(BigDecimal rate) { this.rate = rate; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public BigDecimal getConstructionCost() { return constructionCost; }
    public void setConstructionCost(BigDecimal constructionCost) { this.constructionCost = constructionCost; }

    public BigDecimal getBuildingAge() { return buildingAge; }
    public void setBuildingAge(BigDecimal buildingAge) { this.buildingAge = buildingAge; }

    public int getTotalLife() { return totalLife; }
    public void setTotalLife(int totalLife) { this.totalLife = totalLife; }

    public String getDepreciationMode() { return depreciationMode; }
    public void setDepreciationMode(String depreciationMode) { this.depreciationMode = depreciationMode; }

    public BigDecimal getDepreciationPercentage() { return depreciationPercentage; }
    public void setDepreciationPercentage(BigDecimal depreciationPercentage) { this.depreciationPercentage = depreciationPercentage; }

    public BigDecimal getDepreciationAmount() { return depreciationAmount; }
    public void setDepreciationAmount(BigDecimal depreciationAmount) { this.depreciationAmount = depreciationAmount; }

    public Boolean getIsInsurable() { return isInsurable; }
    public void setIsInsurable(Boolean isInsurable) { this.isInsurable = isInsurable; }

    public BigDecimal getFairValue() { return fairValue; }
    public void setFairValue(BigDecimal fairValue) { this.fairValue = fairValue; }

    public int getSortOrder() { return sortOrder; }
    public void setSortOrder(int sortOrder) { this.sortOrder = sortOrder; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
