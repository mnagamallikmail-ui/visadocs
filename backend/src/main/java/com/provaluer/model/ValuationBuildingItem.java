package com.provaluer.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "valuation_building_items")
public class ValuationBuildingItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id", nullable = false)
    private Long orderId;

    @Column(name = "structure_type", nullable = false)
    private String structureType = "Ground Floor";

    @Column(name = "building_type", nullable = false)
    private String buildingType = "RCC Residential";

    @Column(name = "description")
    private String description;

    @Column(name = "entered_area", precision = 19, scale = 4, nullable = false)
    private BigDecimal enteredArea = BigDecimal.ZERO;

    @Column(name = "entered_unit", nullable = false)
    private String enteredUnit = "Sq.Ft";

    @Column(name = "standard_area_sqft", precision = 19, scale = 4, nullable = false)
    private BigDecimal standardAreaSqft = BigDecimal.ZERO;

    @Column(name = "replacement_rate", precision = 19, scale = 2, nullable = false)
    private BigDecimal replacementRate = BigDecimal.ZERO;

    @Column(name = "replacement_cost", precision = 19, scale = 2, nullable = false)
    private BigDecimal replacementCost = BigDecimal.ZERO;

    @Column(name = "building_age", precision = 5, scale = 2, nullable = false)
    private BigDecimal buildingAge = BigDecimal.ZERO;

    @Column(name = "building_useful_life", nullable = false)
    private int buildingUsefulLife = 60;

    @Column(name = "salvage_percentage", precision = 5, scale = 2, nullable = false)
    private BigDecimal salvagePercentage = new BigDecimal("10.00");

    @Column(name = "depreciation_percentage", precision = 5, scale = 2, nullable = false)
    private BigDecimal depreciationPercentage = BigDecimal.ZERO;

    @Column(name = "depreciation_amount", precision = 19, scale = 2, nullable = false)
    private BigDecimal depreciationAmount = BigDecimal.ZERO;

    @Column(name = "building_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal buildingValue = BigDecimal.ZERO;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder = 0;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @com.fasterxml.jackson.annotation.JsonIgnore
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    public ValuationBuildingItem() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public String getStructureType() { return structureType; }
    public void setStructureType(String structureType) { this.structureType = structureType; }

    public String getBuildingType() { return buildingType; }
    public void setBuildingType(String buildingType) { this.buildingType = buildingType; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public BigDecimal getEnteredArea() { return enteredArea; }
    public void setEnteredArea(BigDecimal enteredArea) { this.enteredArea = enteredArea; }

    public String getEnteredUnit() { return enteredUnit; }
    public void setEnteredUnit(String enteredUnit) { this.enteredUnit = enteredUnit; }

    public BigDecimal getStandardAreaSqft() { return standardAreaSqft; }
    public void setStandardAreaSqft(BigDecimal standardAreaSqft) { this.standardAreaSqft = standardAreaSqft; }

    public BigDecimal getReplacementRate() { return replacementRate; }
    public void setReplacementRate(BigDecimal replacementRate) { this.replacementRate = replacementRate; }

    public BigDecimal getReplacementCost() { return replacementCost; }
    public void setReplacementCost(BigDecimal replacementCost) { this.replacementCost = replacementCost; }

    public BigDecimal getBuildingAge() { return buildingAge; }
    public void setBuildingAge(BigDecimal buildingAge) { this.buildingAge = buildingAge; }

    public int getBuildingUsefulLife() { return buildingUsefulLife; }
    public void setBuildingUsefulLife(int buildingUsefulLife) { this.buildingUsefulLife = buildingUsefulLife; }

    public BigDecimal getSalvagePercentage() { return salvagePercentage; }
    public void setSalvagePercentage(BigDecimal salvagePercentage) { this.salvagePercentage = salvagePercentage; }

    public BigDecimal getDepreciationPercentage() { return depreciationPercentage; }
    public void setDepreciationPercentage(BigDecimal depreciationPercentage) { this.depreciationPercentage = depreciationPercentage; }

    public BigDecimal getDepreciationAmount() { return depreciationAmount; }
    public void setDepreciationAmount(BigDecimal depreciationAmount) { this.depreciationAmount = depreciationAmount; }

    public BigDecimal getBuildingValue() { return buildingValue; }
    public void setBuildingValue(BigDecimal buildingValue) { this.buildingValue = buildingValue; }

    public int getSortOrder() { return sortOrder; }
    public void setSortOrder(int sortOrder) { this.sortOrder = sortOrder; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
