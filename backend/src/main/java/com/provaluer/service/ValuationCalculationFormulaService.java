package com.provaluer.service;

import com.provaluer.model.ValuationBuildingItem;
import com.provaluer.model.ValuationCompositeItem;
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
     * Phase 1: Rate belongs to the selected unit (e.g. ₹ / Sq.Yd, ₹ / Sq.Ft, ₹ / Acre).
     * Value = enteredArea * rate.
     * standardAreaSqft is maintained for standardized display and statutory / government calculations.
     */
    public void calculateLandItem(ValuationLandItem item) {
        if (item == null) return;
        BigDecimal enteredArea = item.getEnteredArea() != null ? item.getEnteredArea() : BigDecimal.ZERO;
        String enteredUnit = item.getEnteredUnit() != null ? item.getEnteredUnit() : "Sq.Ft";
        BigDecimal rate = item.getRate() != null ? item.getRate() : BigDecimal.ZERO;

        BigDecimal standardAreaSqft = UnitConversionEngine.toStandardSqFt(enteredArea, enteredUnit);
        item.setStandardAreaSqft(standardAreaSqft);

        BigDecimal value = enteredArea.multiply(rate).setScale(2, RoundingMode.HALF_UP);
        item.setValue(value);
    }

    /**
     * Calculates replacement cost, depreciation, and building value for a single structure item.
     * Phase 2: PEB Structures and Steel Sheds default to 40 years useful life.
     */
    public void calculateBuildingItem(ValuationBuildingItem item) {
        if (item == null) return;
        BigDecimal enteredArea = item.getEnteredArea() != null ? item.getEnteredArea() : BigDecimal.ZERO;
        String enteredUnit = item.getEnteredUnit() != null ? item.getEnteredUnit() : "Sq.Ft";
        BigDecimal replacementRate = item.getReplacementRate() != null ? item.getReplacementRate() : BigDecimal.ZERO;
        BigDecimal buildingAge = item.getBuildingAge() != null ? item.getBuildingAge() : BigDecimal.ZERO;

        String bType = (item.getBuildingType() != null ? item.getBuildingType() : "").toLowerCase();
        String desc = (item.getDescription() != null ? item.getDescription() : "").toLowerCase();
        String struct = (item.getStructureType() != null ? item.getStructureType() : "").toLowerCase();

        int usefulLife = item.getBuildingUsefulLife();
        if (usefulLife <= 0 || (usefulLife == 60 && (bType.contains("peb") || bType.contains("shed") || desc.contains("peb") || desc.contains("shed") || struct.contains("shed")))) {
            if (bType.contains("peb") || bType.contains("shed") || desc.contains("peb") || desc.contains("shed") || struct.contains("shed")) {
                usefulLife = 40;
                item.setBuildingUsefulLife(40);
            } else {
                usefulLife = 60;
                item.setBuildingUsefulLife(60);
            }
        }

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
     * Implements Say Value driven model, separate realizable/distress percentages, and component breakdowns.
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

        // 3. Say Values (Phase 4): Say Land Value & Say Building Value
        BigDecimal sayLand = computeSayValue(totalLand);
        BigDecimal sayBldg = computeSayValue(totalBuilding);
        data.setSayLandValue(sayLand);
        data.setSayBuildingValue(sayBldg);

        // 4. Fair Value = Say Land Value + Say Building Value (NOT raw totals) (Phase 4 & 9)
        BigDecimal fairValue = sayLand.add(sayBldg).setScale(2, RoundingMode.HALF_UP);
        data.setFairValue(fairValue);

        // 5. Separate Realizable Percentages (Phase 6 & 10)
        BigDecimal landRealPct = data.getLandRealizablePercentage() != null ? data.getLandRealizablePercentage() : new BigDecimal("85.00");
        BigDecimal bldgRealPct = data.getBuildingRealizablePercentage() != null ? data.getBuildingRealizablePercentage() : new BigDecimal("85.00");
        data.setLandRealizablePercentage(landRealPct);
        data.setBuildingRealizablePercentage(bldgRealPct);

        BigDecimal landRealVal = sayLand.multiply(landRealPct).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        BigDecimal bldgRealVal = sayBldg.multiply(bldgRealPct).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        BigDecimal totalRealVal = landRealVal.add(bldgRealVal).setScale(2, RoundingMode.HALF_UP);

        data.setLandRealizableValue(landRealVal);
        data.setBuildingRealizableValue(bldgRealVal);
        data.setRealizableValue(totalRealVal);

        // 6. Separate Distress Percentages (Phase 7 & 11)
        BigDecimal landDistPct = data.getLandDistressPercentage() != null ? data.getLandDistressPercentage() : new BigDecimal("75.00");
        BigDecimal bldgDistPct = data.getBuildingDistressPercentage() != null ? data.getBuildingDistressPercentage() : new BigDecimal("75.00");
        data.setLandDistressPercentage(landDistPct);
        data.setBuildingDistressPercentage(bldgDistPct);

        BigDecimal landDistVal = sayLand.multiply(landDistPct).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        BigDecimal bldgDistVal = sayBldg.multiply(bldgDistPct).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        BigDecimal totalDistVal = landDistVal.add(bldgDistVal).setScale(2, RoundingMode.HALF_UP);

        data.setLandDistressValue(landDistVal);
        data.setBuildingDistressValue(bldgDistVal);
        data.setDistressSaleValue(totalDistVal);

        // 7. Insurable Value = Total Replacement Cost of Buildings (Phase 13)
        BigDecimal insurableValue = totalReplCost.setScale(2, RoundingMode.HALF_UP);
        data.setInsurableValue(insurableValue);

        // 8. Government Values (Phase 12)
        BigDecimal landGovt = calculateLandGovernmentValue(landItems, new BigDecimal("5500"));
        BigDecimal bldgGovt = calculateBuildingGovernmentValue(buildingItems, new BigDecimal("2400"), new BigDecimal("1900"));
        data.setLandGovernmentValue(landGovt);
        data.setBuildingGovernmentValue(bldgGovt);

        if (data.getGovernmentValue() == null || data.getGovernmentValue().compareTo(BigDecimal.ZERO) == 0) {
            data.setGovernmentValue(landGovt.add(bldgGovt).setScale(2, RoundingMode.HALF_UP));
        }
    }

    public BigDecimal calculateLandGovernmentValue(List<ValuationLandItem> landItems, BigDecimal govtLandRate) {
        BigDecimal totalGovt = BigDecimal.ZERO;
        BigDecimal landRate = (govtLandRate != null && govtLandRate.compareTo(BigDecimal.ZERO) > 0)
                ? govtLandRate : new BigDecimal("5500");

        if (landItems != null) {
            for (ValuationLandItem l : landItems) {
                BigDecimal area = l.getStandardAreaSqft() != null ? l.getStandardAreaSqft() : BigDecimal.ZERO;
                totalGovt = totalGovt.add(area.multiply(landRate));
            }
        }
        return totalGovt.setScale(2, RoundingMode.HALF_UP);
    }

    public BigDecimal calculateBuildingGovernmentValue(List<ValuationBuildingItem> buildingItems, BigDecimal govtRccRate, BigDecimal govtSteelRate) {
        BigDecimal totalGovt = BigDecimal.ZERO;
        BigDecimal rccRate = (govtRccRate != null && govtRccRate.compareTo(BigDecimal.ZERO) > 0)
                ? govtRccRate : new BigDecimal("2400");
        BigDecimal steelRate = (govtSteelRate != null && govtSteelRate.compareTo(BigDecimal.ZERO) > 0)
                ? govtSteelRate : new BigDecimal("1900");

        if (buildingItems != null) {
            for (ValuationBuildingItem b : buildingItems) {
                BigDecimal area = b.getStandardAreaSqft() != null ? b.getStandardAreaSqft() : BigDecimal.ZERO;
                String bType = (b.getBuildingType() != null ? b.getBuildingType() : "").toLowerCase();
                String desc = (b.getDescription() != null ? b.getDescription() : "").toLowerCase();
                String struct = (b.getStructureType() != null ? b.getStructureType() : "").toLowerCase();

                if (bType.contains("steel") || desc.contains("steel") || struct.contains("steel") || desc.contains("shed") || bType.contains("peb") || desc.contains("peb")) {
                    totalGovt = totalGovt.add(area.multiply(steelRate));
                } else {
                    totalGovt = totalGovt.add(area.multiply(rccRate));
                }
            }
        }
        return totalGovt.setScale(2, RoundingMode.HALF_UP);
    }

    public BigDecimal calculateGovernmentValue(List<ValuationLandItem> landItems,
                                               List<ValuationBuildingItem> buildingItems,
                                               BigDecimal govtLandRate,
                                               BigDecimal govtRccRate,
                                               BigDecimal govtSteelRate) {
        BigDecimal landGovt = calculateLandGovernmentValue(landItems, govtLandRate);
        BigDecimal bldgGovt = calculateBuildingGovernmentValue(buildingItems, govtRccRate, govtSteelRate);
        return landGovt.add(bldgGovt).setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Calculates values for a single composite item (Main Unit or Interior Work).
     * Main Unit: Amount = Area * Composite Rate.
     * Depreciation = Area * Construction Cost * 90% * Age / Total Life.
     * Fair Value = Amount - Depreciation.
     * Interior Work: Supports Option A (Depreciation %) or Option B (Direct Depreciation Amount in ₹).
     */
    public void calculateCompositeItem(ValuationCompositeItem item) {
        if (item == null) return;
        BigDecimal qty = item.getQuantity() != null ? item.getQuantity() : BigDecimal.ZERO;
        BigDecimal rate = item.getRate() != null ? item.getRate() : BigDecimal.ZERO;

        BigDecimal amount = qty.multiply(rate).setScale(2, RoundingMode.HALF_UP);
        item.setAmount(amount);

        String cat = item.getItemCategory() != null ? item.getItemCategory().toUpperCase() : "INTERIOR_WORK";
        if ("MAIN_UNIT".equals(cat)) {
            BigDecimal cost = item.getConstructionCost() != null ? item.getConstructionCost() : new BigDecimal("2000.00");
            BigDecimal age = item.getBuildingAge() != null ? item.getBuildingAge() : BigDecimal.ZERO;
            int usefulLife = item.getTotalLife() > 0 ? item.getTotalLife() : 60;
            BigDecimal usefulLifeBd = BigDecimal.valueOf(usefulLife);

            // Depreciation = Area * Construction Cost * 90% * Age / Total Life
            BigDecimal deprFactor = new BigDecimal("0.90");
            BigDecimal deprPct = age.divide(usefulLifeBd, 6, RoundingMode.HALF_UP)
                    .multiply(deprFactor).multiply(BigDecimal.valueOf(100)).setScale(2, RoundingMode.HALF_UP);
            item.setDepreciationPercentage(deprPct);

            BigDecimal deprAmount = qty.multiply(cost).multiply(deprFactor).multiply(age)
                    .divide(usefulLifeBd, 2, RoundingMode.HALF_UP);
            item.setDepreciationAmount(deprAmount);

            BigDecimal fairVal = amount.subtract(deprAmount).setScale(2, RoundingMode.HALF_UP);
            item.setFairValue(fairVal);
        } else {
            // Interior Work: Option A (%) vs Option B (Direct Amount)
            String mode = item.getDepreciationMode() != null ? item.getDepreciationMode().toUpperCase() : "PERCENTAGE";
            BigDecimal deprAmount;
            if ("DIRECT_AMOUNT".equals(mode)) {
                deprAmount = item.getDepreciationAmount() != null ? item.getDepreciationAmount() : BigDecimal.ZERO;
                if (amount.compareTo(BigDecimal.ZERO) > 0) {
                    BigDecimal pct = deprAmount.multiply(BigDecimal.valueOf(100)).divide(amount, 2, RoundingMode.HALF_UP);
                    item.setDepreciationPercentage(pct);
                } else {
                    item.setDepreciationPercentage(BigDecimal.ZERO);
                }
            } else {
                BigDecimal pct = item.getDepreciationPercentage() != null ? item.getDepreciationPercentage() : BigDecimal.ZERO;
                deprAmount = amount.multiply(pct).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
                item.setDepreciationAmount(deprAmount);
            }

            BigDecimal fairVal = amount.subtract(deprAmount).setScale(2, RoundingMode.HALF_UP);
            item.setFairValue(fairVal);
        }
    }

    /**
     * Aggregates composite items, applies ProValuer Say Value tiered rounding,
     * and updates ValuationData summary parameters.
     * Downstream realizable and distress calculations consume the Say Fair Value.
     */
    public void calculateCompositeSummary(ValuationData data, List<ValuationCompositeItem> compositeItems) {
        if (data == null) return;

        BigDecimal mainUnitFairVal = BigDecimal.ZERO;
        BigDecimal mainUnitArea = BigDecimal.ZERO;
        BigDecimal mainUnitCost = data.getCompositeConstructionCost() != null ? data.getCompositeConstructionCost() : new BigDecimal("2000.00");

        BigDecimal totalInteriorAmt = BigDecimal.ZERO;
        BigDecimal totalInteriorDepr = BigDecimal.ZERO;
        BigDecimal totalInteriorFairVal = BigDecimal.ZERO;
        BigDecimal totalInsurableInteriors = BigDecimal.ZERO;

        if (compositeItems != null) {
            for (ValuationCompositeItem item : compositeItems) {
                calculateCompositeItem(item);
                String cat = item.getItemCategory() != null ? item.getItemCategory().toUpperCase() : "INTERIOR_WORK";
                if ("MAIN_UNIT".equals(cat)) {
                    mainUnitFairVal = mainUnitFairVal.add(item.getFairValue() != null ? item.getFairValue() : BigDecimal.ZERO);
                    mainUnitArea = mainUnitArea.add(item.getQuantity() != null ? item.getQuantity() : BigDecimal.ZERO);
                    if (item.getConstructionCost() != null && item.getConstructionCost().compareTo(BigDecimal.ZERO) > 0) {
                        mainUnitCost = item.getConstructionCost();
                    }
                } else {
                    totalInteriorAmt = totalInteriorAmt.add(item.getAmount() != null ? item.getAmount() : BigDecimal.ZERO);
                    totalInteriorDepr = totalInteriorDepr.add(item.getDepreciationAmount() != null ? item.getDepreciationAmount() : BigDecimal.ZERO);
                    totalInteriorFairVal = totalInteriorFairVal.add(item.getFairValue() != null ? item.getFairValue() : BigDecimal.ZERO);
                    if (Boolean.TRUE.equals(item.getIsInsurable())) {
                        totalInsurableInteriors = totalInsurableInteriors.add(item.getAmount() != null ? item.getAmount() : BigDecimal.ZERO);
                    }
                }
            }
        }

        data.setTotalInteriorAmount(totalInteriorAmt.setScale(2, RoundingMode.HALF_UP));
        data.setTotalInteriorDepreciation(totalInteriorDepr.setScale(2, RoundingMode.HALF_UP));
        data.setTotalInteriorFairValue(totalInteriorFairVal.setScale(2, RoundingMode.HALF_UP));

        // 1. Raw Fair Value = Main Unit Fair Value + Sum(Interior Works Fair Values)
        BigDecimal rawFairValue = mainUnitFairVal.add(totalInteriorFairVal).setScale(2, RoundingMode.HALF_UP);
        data.setRawFairValue(rawFairValue);

        // 2. Say Fair Value = computeSayValue(rawFairValue)
        BigDecimal sayFairValue = computeSayValue(rawFairValue);
        data.setSayFairValue(sayFairValue);

        // 3. Fair Value in summary displays Say Fair Value
        data.setFairValue(sayFairValue);

        // 4. Downstream Realizable & Distress Sale Values consume Say Fair Value
        BigDecimal realPct = data.getRealizablePercentage() != null ? data.getRealizablePercentage() : new BigDecimal("85.00");
        BigDecimal distPct = data.getDistressSalePercentage() != null ? data.getDistressSalePercentage() : new BigDecimal("75.00");
        data.setRealizablePercentage(realPct);
        data.setDistressSalePercentage(distPct);

        BigDecimal realizableVal = sayFairValue.multiply(realPct).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        BigDecimal distressVal = sayFairValue.multiply(distPct).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        data.setRealizableValue(realizableVal);
        data.setDistressSaleValue(distressVal);

        // 5. Government Value = Area * Government Composite Rate
        BigDecimal govtRate = data.getCompositeGovernmentRate() != null ? data.getCompositeGovernmentRate() : BigDecimal.ZERO;
        BigDecimal govtVal = mainUnitArea.multiply(govtRate).setScale(2, RoundingMode.HALF_UP);
        data.setGovernmentValue(govtVal);

        // 6. Insurable Value = Area * Construction Cost + Insurable Interior Improvements
        BigDecimal insurableVal = mainUnitArea.multiply(mainUnitCost).add(totalInsurableInteriors).setScale(2, RoundingMode.HALF_UP);
        data.setInsurableValue(insurableVal);
    }

    /**
     * Presentation Say Value Rounding Rules (Phase 5):
     * - If value is in Lakhs (< 50 Lakhs): Round to nearest ₹ 1,000 (e.g. ₹ 23,12,500 -> ₹ 23,13,000)
     * - If value is in Tens of Lakhs (50L to 1Cr): Round to nearest ₹ 10,000 (e.g. ₹ 68,75,000 -> ₹ 68,80,000)
     * - If value is in Crores (>= 1 Crore): Round to nearest ₹ 1,00,000 (e.g. ₹ 7,08,12,500 -> ₹ 7,08,00,000)
     */
    public static BigDecimal computeSayValue(BigDecimal value) {
        if (value == null || value.compareTo(BigDecimal.ZERO) <= 0) return BigDecimal.ZERO;
        BigDecimal fiftyLakhs = new BigDecimal("5000000");
        BigDecimal oneCrore = new BigDecimal("10000000");
        BigDecimal oneThousand = new BigDecimal("1000");
        BigDecimal tenThousand = new BigDecimal("10000");
        BigDecimal oneLakh = new BigDecimal("100000");

        if (value.compareTo(oneCrore) >= 0) {
            BigDecimal rounded = value.divide(oneLakh, 0, RoundingMode.HALF_UP);
            return rounded.multiply(oneLakh).setScale(2, RoundingMode.HALF_UP);
        } else if (value.compareTo(fiftyLakhs) >= 0) {
            BigDecimal rounded = value.divide(tenThousand, 0, RoundingMode.HALF_UP);
            return rounded.multiply(tenThousand).setScale(2, RoundingMode.HALF_UP);
        } else {
            BigDecimal rounded = value.divide(oneThousand, 0, RoundingMode.HALF_UP);
            return rounded.multiply(oneThousand).setScale(2, RoundingMode.HALF_UP);
        }
    }
}
