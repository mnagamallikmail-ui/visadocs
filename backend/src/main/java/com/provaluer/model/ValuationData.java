package com.provaluer.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "valuation_data")
public class ValuationData {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id", unique = true, nullable = false)
    private Long orderId;

    @Column(name = "total_land_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal totalLandValue = BigDecimal.ZERO;

    @Column(name = "total_building_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal totalBuildingValue = BigDecimal.ZERO;

    @Column(name = "total_replacement_cost", precision = 19, scale = 2, nullable = false)
    private BigDecimal totalReplacementCost = BigDecimal.ZERO;

    @Column(name = "total_depreciation_amount", precision = 19, scale = 2, nullable = false)
    private BigDecimal totalDepreciationAmount = BigDecimal.ZERO;

    @Column(name = "total_salvage_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal totalSalvageValue = BigDecimal.ZERO;

    @Column(name = "fair_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal fairValue = BigDecimal.ZERO;

    @Column(name = "realizable_percentage", precision = 5, scale = 2, nullable = false)
    private BigDecimal realizablePercentage = new BigDecimal("85.00");

    @Column(name = "realizable_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal realizableValue = BigDecimal.ZERO;

    @Column(name = "distress_sale_percentage", precision = 5, scale = 2, nullable = false)
    private BigDecimal distressSalePercentage = new BigDecimal("75.00");

    @Column(name = "distress_sale_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal distressSaleValue = BigDecimal.ZERO;

    @Column(name = "government_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal governmentValue = BigDecimal.ZERO;

    @Column(name = "insurable_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal insurableValue = BigDecimal.ZERO;

    @Column(name = "default_salvage_percentage", precision = 5, scale = 2, nullable = false)
    private BigDecimal defaultSalvagePercentage = new BigDecimal("10.00");

    @Column(name = "say_land_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal sayLandValue = BigDecimal.ZERO;

    @Column(name = "say_building_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal sayBuildingValue = BigDecimal.ZERO;

    @Column(name = "land_realizable_percentage", precision = 5, scale = 2, nullable = false)
    private BigDecimal landRealizablePercentage = new BigDecimal("85.00");

    @Column(name = "building_realizable_percentage", precision = 5, scale = 2, nullable = false)
    private BigDecimal buildingRealizablePercentage = new BigDecimal("85.00");

    @Column(name = "land_distress_percentage", precision = 5, scale = 2, nullable = false)
    private BigDecimal landDistressPercentage = new BigDecimal("75.00");

    @Column(name = "building_distress_percentage", precision = 5, scale = 2, nullable = false)
    private BigDecimal buildingDistressPercentage = new BigDecimal("75.00");

    @Column(name = "land_realizable_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal landRealizableValue = BigDecimal.ZERO;

    @Column(name = "building_realizable_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal buildingRealizableValue = BigDecimal.ZERO;

    @Column(name = "land_distress_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal landDistressValue = BigDecimal.ZERO;

    @Column(name = "building_distress_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal buildingDistressValue = BigDecimal.ZERO;

    @Column(name = "land_government_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal landGovernmentValue = BigDecimal.ZERO;

    @Column(name = "building_government_value", precision = 19, scale = 2, nullable = false)
    private BigDecimal buildingGovernmentValue = BigDecimal.ZERO;

    @Column(name = "valuation_status", nullable = false)
    private String valuationStatus = "DRAFT"; // DRAFT, FINALIZED, LOCKED, ARCHIVED

    @Column(name = "current_version", nullable = false)
    private int currentVersion = 1;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @com.fasterxml.jackson.annotation.JsonIgnore
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    public ValuationData() {}

    public ValuationData(Long orderId) {
        this.orderId = orderId;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getOrderId() { return orderId; }
    public void setOrderId(Long orderId) { this.orderId = orderId; }

    public BigDecimal getTotalLandValue() { return totalLandValue; }
    public void setTotalLandValue(BigDecimal totalLandValue) { this.totalLandValue = totalLandValue; }

    public BigDecimal getTotalBuildingValue() { return totalBuildingValue; }
    public void setTotalBuildingValue(BigDecimal totalBuildingValue) { this.totalBuildingValue = totalBuildingValue; }

    public BigDecimal getTotalReplacementCost() { return totalReplacementCost; }
    public void setTotalReplacementCost(BigDecimal totalReplacementCost) { this.totalReplacementCost = totalReplacementCost; }

    public BigDecimal getTotalDepreciationAmount() { return totalDepreciationAmount; }
    public void setTotalDepreciationAmount(BigDecimal totalDepreciationAmount) { this.totalDepreciationAmount = totalDepreciationAmount; }

    public BigDecimal getTotalSalvageValue() { return totalSalvageValue; }
    public void setTotalSalvageValue(BigDecimal totalSalvageValue) { this.totalSalvageValue = totalSalvageValue; }

    public BigDecimal getFairValue() { return fairValue; }
    public void setFairValue(BigDecimal fairValue) { this.fairValue = fairValue; }

    public BigDecimal getRealizablePercentage() { return realizablePercentage; }
    public void setRealizablePercentage(BigDecimal realizablePercentage) { this.realizablePercentage = realizablePercentage; }

    public BigDecimal getRealizableValue() { return realizableValue; }
    public void setRealizableValue(BigDecimal realizableValue) { this.realizableValue = realizableValue; }

    public BigDecimal getDistressSalePercentage() { return distressSalePercentage; }
    public void setDistressSalePercentage(BigDecimal distressSalePercentage) { this.distressSalePercentage = distressSalePercentage; }

    public BigDecimal getDistressSaleValue() { return distressSaleValue; }
    public void setDistressSaleValue(BigDecimal distressSaleValue) { this.distressSaleValue = distressSaleValue; }

    public BigDecimal getGovernmentValue() { return governmentValue; }
    public void setGovernmentValue(BigDecimal governmentValue) { this.governmentValue = governmentValue; }

    public BigDecimal getInsurableValue() { return insurableValue; }
    public void setInsurableValue(BigDecimal insurableValue) { this.insurableValue = insurableValue; }

    public BigDecimal getDefaultSalvagePercentage() { return defaultSalvagePercentage; }
    public void setDefaultSalvagePercentage(BigDecimal defaultSalvagePercentage) { this.defaultSalvagePercentage = defaultSalvagePercentage; }

    public BigDecimal getSayLandValue() { return sayLandValue; }
    public void setSayLandValue(BigDecimal sayLandValue) { this.sayLandValue = sayLandValue; }

    public BigDecimal getSayBuildingValue() { return sayBuildingValue; }
    public void setSayBuildingValue(BigDecimal sayBuildingValue) { this.sayBuildingValue = sayBuildingValue; }

    public BigDecimal getLandRealizablePercentage() { return landRealizablePercentage; }
    public void setLandRealizablePercentage(BigDecimal landRealizablePercentage) { this.landRealizablePercentage = landRealizablePercentage; }

    public BigDecimal getBuildingRealizablePercentage() { return buildingRealizablePercentage; }
    public void setBuildingRealizablePercentage(BigDecimal buildingRealizablePercentage) { this.buildingRealizablePercentage = buildingRealizablePercentage; }

    public BigDecimal getLandDistressPercentage() { return landDistressPercentage; }
    public void setLandDistressPercentage(BigDecimal landDistressPercentage) { this.landDistressPercentage = landDistressPercentage; }

    public BigDecimal getBuildingDistressPercentage() { return buildingDistressPercentage; }
    public void setBuildingDistressPercentage(BigDecimal buildingDistressPercentage) { this.buildingDistressPercentage = buildingDistressPercentage; }

    public BigDecimal getLandRealizableValue() { return landRealizableValue; }
    public void setLandRealizableValue(BigDecimal landRealizableValue) { this.landRealizableValue = landRealizableValue; }

    public BigDecimal getBuildingRealizableValue() { return buildingRealizableValue; }
    public void setBuildingRealizableValue(BigDecimal buildingRealizableValue) { this.buildingRealizableValue = buildingRealizableValue; }

    public BigDecimal getLandDistressValue() { return landDistressValue; }
    public void setLandDistressValue(BigDecimal landDistressValue) { this.landDistressValue = landDistressValue; }

    public BigDecimal getBuildingDistressValue() { return buildingDistressValue; }
    public void setBuildingDistressValue(BigDecimal buildingDistressValue) { this.buildingDistressValue = buildingDistressValue; }

    public BigDecimal getLandGovernmentValue() { return landGovernmentValue; }
    public void setLandGovernmentValue(BigDecimal landGovernmentValue) { this.landGovernmentValue = landGovernmentValue; }

    public BigDecimal getBuildingGovernmentValue() { return buildingGovernmentValue; }
    public void setBuildingGovernmentValue(BigDecimal buildingGovernmentValue) { this.buildingGovernmentValue = buildingGovernmentValue; }

    public String getValuationStatus() { return valuationStatus; }
    public void setValuationStatus(String valuationStatus) { this.valuationStatus = valuationStatus; }

    public int getCurrentVersion() { return currentVersion; }
    public void setCurrentVersion(int currentVersion) { this.currentVersion = currentVersion; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
