package com.provaluer.dto;

import com.provaluer.model.ValuationBuildingItem;
import com.provaluer.model.ValuationComparableSale;
import com.provaluer.model.ValuationCompositeItem;
import com.provaluer.model.ValuationLandItem;

import java.math.BigDecimal;
import java.util.List;

public class SaveValuationRequest {
    private BigDecimal realizablePercentage;
    private BigDecimal distressSalePercentage;
    private BigDecimal landRealizablePercentage;
    private BigDecimal buildingRealizablePercentage;
    private BigDecimal landDistressPercentage;
    private BigDecimal buildingDistressPercentage;
    private BigDecimal sayLandValue;
    private BigDecimal sayBuildingValue;
    private BigDecimal defaultSalvagePercentage;
    private BigDecimal governmentValue;
    private List<ValuationLandItem> landItems;
    private List<ValuationBuildingItem> buildingItems;
    private List<ValuationComparableSale> comparableSales;
    private List<ValuationCompositeItem> compositeItems;
    private String valuationMethodology;
    private BigDecimal compositeGovernmentRate;
    private BigDecimal compositeConstructionCost;
    private BigDecimal compositeBuildingAge;
    private Integer compositeBuildingTotalLife;
    private BigDecimal compositeBuildingDepreciationPct;
    private String reason; // for audit logging

    public SaveValuationRequest() {}

    public BigDecimal getLandRealizablePercentage() { return landRealizablePercentage; }
    public void setLandRealizablePercentage(BigDecimal landRealizablePercentage) { this.landRealizablePercentage = landRealizablePercentage; }

    public BigDecimal getBuildingRealizablePercentage() { return buildingRealizablePercentage; }
    public void setBuildingRealizablePercentage(BigDecimal buildingRealizablePercentage) { this.buildingRealizablePercentage = buildingRealizablePercentage; }

    public BigDecimal getLandDistressPercentage() { return landDistressPercentage; }
    public void setLandDistressPercentage(BigDecimal landDistressPercentage) { this.landDistressPercentage = landDistressPercentage; }

    public BigDecimal getBuildingDistressPercentage() { return buildingDistressPercentage; }
    public void setBuildingDistressPercentage(BigDecimal buildingDistressPercentage) { this.buildingDistressPercentage = buildingDistressPercentage; }

    public BigDecimal getSayLandValue() { return sayLandValue; }
    public void setSayLandValue(BigDecimal sayLandValue) { this.sayLandValue = sayLandValue; }

    public BigDecimal getSayBuildingValue() { return sayBuildingValue; }
    public void setSayBuildingValue(BigDecimal sayBuildingValue) { this.sayBuildingValue = sayBuildingValue; }

    public BigDecimal getRealizablePercentage() { return realizablePercentage; }
    public void setRealizablePercentage(BigDecimal realizablePercentage) { this.realizablePercentage = realizablePercentage; }

    public BigDecimal getDistressSalePercentage() { return distressSalePercentage; }
    public void setDistressSalePercentage(BigDecimal distressSalePercentage) { this.distressSalePercentage = distressSalePercentage; }

    public BigDecimal getDefaultSalvagePercentage() { return defaultSalvagePercentage; }
    public void setDefaultSalvagePercentage(BigDecimal defaultSalvagePercentage) { this.defaultSalvagePercentage = defaultSalvagePercentage; }

    public BigDecimal getGovernmentValue() { return governmentValue; }
    public void setGovernmentValue(BigDecimal governmentValue) { this.governmentValue = governmentValue; }

    public List<ValuationLandItem> getLandItems() { return landItems; }
    public void setLandItems(List<ValuationLandItem> landItems) { this.landItems = landItems; }

    public List<ValuationBuildingItem> getBuildingItems() { return buildingItems; }
    public void setBuildingItems(List<ValuationBuildingItem> buildingItems) { this.buildingItems = buildingItems; }

    public List<ValuationComparableSale> getComparableSales() { return comparableSales; }
    public void setComparableSales(List<ValuationComparableSale> comparableSales) { this.comparableSales = comparableSales; }

    public List<ValuationCompositeItem> getCompositeItems() { return compositeItems; }
    public void setCompositeItems(List<ValuationCompositeItem> compositeItems) { this.compositeItems = compositeItems; }

    public String getValuationMethodology() { return valuationMethodology; }
    public void setValuationMethodology(String valuationMethodology) { this.valuationMethodology = valuationMethodology; }

    public BigDecimal getCompositeGovernmentRate() { return compositeGovernmentRate; }
    public void setCompositeGovernmentRate(BigDecimal compositeGovernmentRate) { this.compositeGovernmentRate = compositeGovernmentRate; }

    public BigDecimal getCompositeConstructionCost() { return compositeConstructionCost; }
    public void setCompositeConstructionCost(BigDecimal compositeConstructionCost) { this.compositeConstructionCost = compositeConstructionCost; }

    public BigDecimal getCompositeBuildingAge() { return compositeBuildingAge; }
    public void setCompositeBuildingAge(BigDecimal compositeBuildingAge) { this.compositeBuildingAge = compositeBuildingAge; }

    public Integer getCompositeBuildingTotalLife() { return compositeBuildingTotalLife; }
    public void setCompositeBuildingTotalLife(Integer compositeBuildingTotalLife) { this.compositeBuildingTotalLife = compositeBuildingTotalLife; }

    public BigDecimal getCompositeBuildingDepreciationPct() { return compositeBuildingDepreciationPct; }
    public void setCompositeBuildingDepreciationPct(BigDecimal compositeBuildingDepreciationPct) { this.compositeBuildingDepreciationPct = compositeBuildingDepreciationPct; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
}
