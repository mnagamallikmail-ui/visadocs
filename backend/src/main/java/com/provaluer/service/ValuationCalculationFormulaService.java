package com.provaluer.service;

import com.provaluer.model.ValuationBuildingItem;
import com.provaluer.model.ValuationData;
import com.provaluer.model.ValuationLandItem;
import com.provaluer.util.UnitConversionEngine;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

@Service
public class ValuationCalculationFormulaService {

    /**
     * Calculates values for a single land parcel.
     */
    public void calculateLandItem(ValuationLandItem item) {
        if (item == null) return;
        BigDecimal enteredArea = item.getEnteredArea() != null ? item.getEnteredArea() : BigDecimal.ZERO;
        String enteredUnit = item.getEnteredUnit() != null ? item.getEnteredUnit() : "Sq.Ft";
        BigDecimal rate = item.getRate() != null ? item.getRate() : BigDecimal.ZERO;

        BigDecimal standardAreaSqft = UnitConversionEngine.toStandardSqFt(enteredArea, enteredUnit);
        item.setStandardAreaSqft(standardAreaSqft);

        BigDecimal value = standardAreaSqft.multiply(rate).setScale(2, RoundingMode.HALF_UP);
        item.setValue(value);
    }

    /**
     * Calculates replacement cost, depreciation, and building value for a single structure item.
     */
    public void calculateBuildingItem(ValuationBuildingItem item) {
        if (item == null) return;
        BigDecimal enteredArea = item.getEnteredArea() != null ? item.getEnteredArea() : BigDecimal.ZERO;
        String enteredUnit = item.getEnteredUnit() != null ? item.getEnteredUnit() : "Sq.Ft";
        BigDecimal replacementRate = item.getReplacementRate() != null ? item.getReplacementRate() : BigDecimal.ZERO;
        BigDecimal buildingAge = item.getBuildingAge() != null ? item.getBuildingAge() : BigDecimal.ZERO;
        int usefulLife = item.getBuildingUsefulLife() > 0 ? item.getBuildingUsefulLife() : 60;
        BigDecimal salvagePercentage = item.getSalvagePercentage() != null ? item.getSalvagePercentage() : new BigDecimal("10.00");

        // 1. Standard Area
        BigDecimal standardAreaSqft = UnitConversionEngine.toStandardSqFt(enteredArea, enteredUnit);
        item.setStandardAreaSqft(standardAreaSqft);

        // 2. Replacement Cost = standard_area * replacement_rate
        BigDecimal replacementCost = standardAreaSqft.multiply(replacementRate).setScale(2, RoundingMode.HALF_UP);
        item.setReplacementCost(replacementCost);

        // 3. Depreciation calculation with salvage retention:
        // Formula: depr_amount = replacement_cost * (building_age / useful_life) * (1 - salvage_percentage/100)
        BigDecimal usefulLifeBd = BigDecimal.valueOf(usefulLife);
        BigDecimal salvageFactor = BigDecimal.ONE.subtract(salvagePercentage.divide(BigDecimal.valueOf(100), 6, RoundingMode.HALF_UP));

        BigDecimal ageRatio = buildingAge.divide(usefulLifeBd, 6, RoundingMode.HALF_UP);
        BigDecimal depreciationPercentage = ageRatio.multiply(salvageFactor).multiply(BigDecimal.valueOf(100)).setScale(2, RoundingMode.HALF_UP);
        item.setDepreciationPercentage(depreciationPercentage);

        // Exact depreciation amount: (replacement_cost * building_age * salvage_factor) / useful_life
        BigDecimal depreciationAmount = replacementCost.multiply(buildingAge).multiply(salvageFactor)
                .divide(usefulLifeBd, 2, RoundingMode.HALF_UP);
        item.setDepreciationAmount(depreciationAmount);

        // 4. Salvage Floor Guard: building_value must never fall below (replacement_cost * salvage_percentage / 100)
        BigDecimal salvageFloor = replacementCost.multiply(salvagePercentage).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        BigDecimal rawBuildingValue = replacementCost.subtract(depreciationAmount).setScale(2, RoundingMode.HALF_UP);

        BigDecimal buildingValue = rawBuildingValue.max(salvageFloor);
        item.setBuildingValue(buildingValue);
    }

    /**
     * Aggregates land items, building items, and updates the overall ValuationData totals.
     */
    public void calculateSummary(ValuationData data, List<ValuationLandItem> landItems, List<ValuationBuildingItem> buildingItems) {
        if (data == null) return;

        // 1. Aggregate Land
        BigDecimal totalLand = BigDecimal.ZERO;
        if (landItems != null) {
            for (ValuationLandItem l : landItems) {
                calculateLandItem(l);
                totalLand = totalLand.add(l.getValue() != null ? l.getValue() : BigDecimal.ZERO);
            }
        }
        data.setTotalLandValue(totalLand.setScale(2, RoundingMode.HALF_UP));

        // 2. Aggregate Buildings
        BigDecimal totalReplCost = BigDecimal.ZERO;
        BigDecimal totalDepr = BigDecimal.ZERO;
        BigDecimal totalSalvage = BigDecimal.ZERO;
        BigDecimal totalBuilding = BigDecimal.ZERO;

        if (buildingItems != null) {
            for (ValuationBuildingItem b : buildingItems) {
                calculateBuildingItem(b);
                BigDecimal repl = b.getReplacementCost() != null ? b.getReplacementCost() : BigDecimal.ZERO;
                BigDecimal depr = b.getDepreciationAmount() != null ? b.getDepreciationAmount() : BigDecimal.ZERO;
                BigDecimal salvPct = b.getSalvagePercentage() != null ? b.getSalvagePercentage() : new BigDecimal("10.00");
                BigDecimal salvVal = repl.multiply(salvPct).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
                BigDecimal val = b.getBuildingValue() != null ? b.getBuildingValue() : BigDecimal.ZERO;

                totalReplCost = totalReplCost.add(repl);
                totalDepr = totalDepr.add(depr);
                totalSalvage = totalSalvage.add(salvVal);
                totalBuilding = totalBuilding.add(val);
            }
        }
        data.setTotalReplacementCost(totalReplCost.setScale(2, RoundingMode.HALF_UP));
        data.setTotalDepreciationAmount(totalDepr.setScale(2, RoundingMode.HALF_UP));
        data.setTotalSalvageValue(totalSalvage.setScale(2, RoundingMode.HALF_UP));
        data.setTotalBuildingValue(totalBuilding.setScale(2, RoundingMode.HALF_UP));

        // 3. Fair Value = Total Land + Total Building
        BigDecimal fairValue = totalLand.add(totalBuilding).setScale(2, RoundingMode.HALF_UP);
        data.setFairValue(fairValue);

        // 4. Realizable Value = Fair Value * realizable_percentage / 100
        BigDecimal realizablePct = data.getRealizablePercentage() != null ? data.getRealizablePercentage() : new BigDecimal("85.00");
        BigDecimal realizableVal = fairValue.multiply(realizablePct).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        data.setRealizableValue(realizableVal);

        // 5. Distress Sale Value = Fair Value * distress_sale_percentage / 100
        BigDecimal distressPct = data.getDistressSalePercentage() != null ? data.getDistressSalePercentage() : new BigDecimal("75.00");
        BigDecimal distressVal = fairValue.multiply(distressPct).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        data.setDistressSaleValue(distressVal);

        // 6. Insurable Value = Total Replacement Cost (Building replacement costs only, excluding land)
        BigDecimal insurableValue = totalReplCost.setScale(2, RoundingMode.HALF_UP);
        data.setInsurableValue(insurableValue);

        // 7. Government Value calculation: (Land Area * Govt Land Rate) + (RCC Area * Govt RCC Rate) + (Steel Area * Govt Steel Rate)
        if (data.getGovernmentValue() == null || data.getGovernmentValue().compareTo(BigDecimal.ZERO) == 0) {
            BigDecimal govtVal = calculateGovernmentValue(landItems, buildingItems, new BigDecimal("5500"), new BigDecimal("2400"), new BigDecimal("1900"));
            data.setGovernmentValue(govtVal);
        }
    }

    /**
     * Calculates Government Value according to statutory formula:
     * (Land Area * Govt Land Rate) + (RCC Area * Govt RCC Rate) + (Steel Area * Govt Steel Rate)
     */
    public BigDecimal calculateGovernmentValue(List<ValuationLandItem> landItems,
                                               List<ValuationBuildingItem> buildingItems,
                                               BigDecimal govtLandRate,
                                               BigDecimal govtRccRate,
                                               BigDecimal govtSteelRate) {
        BigDecimal totalGovt = BigDecimal.ZERO;

        BigDecimal landRate = (govtLandRate != null && govtLandRate.compareTo(BigDecimal.ZERO) > 0)
                ? govtLandRate : new BigDecimal("5500");
        BigDecimal rccRate = (govtRccRate != null && govtRccRate.compareTo(BigDecimal.ZERO) > 0)
                ? govtRccRate : new BigDecimal("2400");
        BigDecimal steelRate = (govtSteelRate != null && govtSteelRate.compareTo(BigDecimal.ZERO) > 0)
                ? govtSteelRate : new BigDecimal("1900");

        if (landItems != null) {
            for (ValuationLandItem l : landItems) {
                BigDecimal area = l.getStandardAreaSqft() != null ? l.getStandardAreaSqft() : BigDecimal.ZERO;
                totalGovt = totalGovt.add(area.multiply(landRate));
            }
        }

        if (buildingItems != null) {
            for (ValuationBuildingItem b : buildingItems) {
                BigDecimal area = b.getStandardAreaSqft() != null ? b.getStandardAreaSqft() : BigDecimal.ZERO;
                String bType = (b.getBuildingType() != null ? b.getBuildingType() : "").toLowerCase();
                String desc = (b.getDescription() != null ? b.getDescription() : "").toLowerCase();
                String struct = (b.getStructureType() != null ? b.getStructureType() : "").toLowerCase();

                if (bType.contains("steel") || desc.contains("steel") || struct.contains("steel") || desc.contains("shed")) {
                    totalGovt = totalGovt.add(area.multiply(steelRate));
                } else {
                    totalGovt = totalGovt.add(area.multiply(rccRate));
                }
            }
        }

        return totalGovt.setScale(2, RoundingMode.HALF_UP);
    }
}
