package com.provaluer.dto;

import com.provaluer.model.ValuationBuildingItem;
import com.provaluer.model.ValuationComparableSale;
import com.provaluer.model.ValuationLandItem;

import java.math.BigDecimal;
import java.util.List;

public class SaveValuationRequest {
    private BigDecimal realizablePercentage;
    private BigDecimal distressSalePercentage;
    private BigDecimal defaultSalvagePercentage;
    private BigDecimal governmentValue;
    private List<ValuationLandItem> landItems;
    private List<ValuationBuildingItem> buildingItems;
    private List<ValuationComparableSale> comparableSales;
    private String reason; // for audit logging

    public SaveValuationRequest() {}

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

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
}
