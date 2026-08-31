package com.provaluer.dto;

import com.provaluer.model.*;

import java.util.List;
import java.util.Map;

public class ValuationBundleResponse {
    private ValuationData valuationData;
    private List<ValuationLandItem> landItems;
    private List<ValuationBuildingItem> buildingItems;
    private List<ValuationComparableSale> comparableSales;
    private List<ValuationSnapshot> snapshots;
    private Map<String, String> placeholders;
    private boolean isLocked;

    public ValuationBundleResponse() {}

    public ValuationBundleResponse(ValuationData valuationData, List<ValuationLandItem> landItems,
                                   List<ValuationBuildingItem> buildingItems, List<ValuationComparableSale> comparableSales,
                                   List<ValuationSnapshot> snapshots, Map<String, String> placeholders, boolean isLocked) {
        this.valuationData = valuationData;
        this.landItems = landItems;
        this.buildingItems = buildingItems;
        this.comparableSales = comparableSales;
        this.snapshots = snapshots;
        this.placeholders = placeholders;
        this.isLocked = isLocked;
    }

    public ValuationData getValuationData() { return valuationData; }
    public void setValuationData(ValuationData valuationData) { this.valuationData = valuationData; }

    public List<ValuationLandItem> getLandItems() { return landItems; }
    public void setLandItems(List<ValuationLandItem> landItems) { this.landItems = landItems; }

    public List<ValuationBuildingItem> getBuildingItems() { return buildingItems; }
    public void setBuildingItems(List<ValuationBuildingItem> buildingItems) { this.buildingItems = buildingItems; }

    public List<ValuationComparableSale> getComparableSales() { return comparableSales; }
    public void setComparableSales(List<ValuationComparableSale> comparableSales) { this.comparableSales = comparableSales; }

    public List<ValuationSnapshot> getSnapshots() { return snapshots; }
    public void setSnapshots(List<ValuationSnapshot> snapshots) { this.snapshots = snapshots; }

    public Map<String, String> getPlaceholders() { return placeholders; }
    public void setPlaceholders(Map<String, String> placeholders) { this.placeholders = placeholders; }

    public boolean isLocked() { return isLocked; }
    public void setLocked(boolean locked) { isLocked = locked; }
}
