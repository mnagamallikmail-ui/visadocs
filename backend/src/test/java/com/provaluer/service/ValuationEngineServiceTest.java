package com.provaluer.service;

import com.provaluer.model.*;
import com.provaluer.util.IndianCurrencyToWords;
import com.provaluer.util.IndianNumberFormatter;
import com.provaluer.util.UnitConversionEngine;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

public class ValuationEngineServiceTest {

    private ValuationCalculationFormulaService formulaService;

    @BeforeEach
    public void setUp() {
        formulaService = new ValuationCalculationFormulaService();
    }

    @Test
    @DisplayName("Unit Conversion Engine converts Land Units accurately to Standard Sq.Ft")
    public void testUnitConversion() {
        // 1 Acre = 43,560 Sq.Ft
        assertEquals(0, new BigDecimal("43560.00").compareTo(UnitConversionEngine.toStandardSqFt(new BigDecimal("1.0"), "Acres")));

        // 1 Ground = 2,400 Sq.Ft
        assertEquals(0, new BigDecimal("2400.00").compareTo(UnitConversionEngine.toStandardSqFt(new BigDecimal("1.0"), "Grounds")));

        // 1 Cent = 435.6 Sq.Ft
        assertEquals(0, new BigDecimal("435.60").compareTo(UnitConversionEngine.toStandardSqFt(new BigDecimal("1.0"), "Cents")));

        // 1 Sq.M = 10.76391 Sq.Ft
        assertEquals(0, new BigDecimal("107.6391").compareTo(UnitConversionEngine.toStandardSqFt(new BigDecimal("10.0"), "Sq.M")));
    }

    @Test
    @DisplayName("Indian Number Formatter formats with Indian grouping standard")
    public void testIndianNumberFormatting() {
        assertEquals("5,75,00,000", IndianNumberFormatter.format(new BigDecimal("57500000")));
        assertEquals("1,00,000", IndianNumberFormatter.format(new BigDecimal("100000")));
        assertEquals("85,50,000", IndianNumberFormatter.format(new BigDecimal("8550000")));
        assertEquals("12,34,56,789", IndianNumberFormatter.format(new BigDecimal("123456789")));
    }

    @Test
    @DisplayName("Indian Currency To Words formats Banking Standard Words")
    public void testIndianCurrencyToWords() {
        assertEquals("Rupees Five Crore Seventy Five Lakh Only",
                IndianCurrencyToWords.convertToWords(new BigDecimal("57500000")));

        assertEquals("Rupees Eighty Five Lakh Fifty Thousand Only",
                IndianCurrencyToWords.convertToWords(new BigDecimal("8550000")));

        assertEquals("Rupees One Crore Only",
                IndianCurrencyToWords.convertToWords(new BigDecimal("10000000")));
    }

    @Test
    @DisplayName("Valuation Calculation computes Land, Building, Fair Value, Realizable, and Distress Values")
    public void testFullValuationCalculation() {
        ValuationData data = new ValuationData(101L);
        data.setRealizablePercentage(new BigDecimal("85.00"));
        data.setDistressSalePercentage(new BigDecimal("75.00"));

        List<ValuationLandItem> landItems = new ArrayList<>();
        ValuationLandItem land1 = new ValuationLandItem();
        land1.setOrderId(101L);
        land1.setDescription("Parcel A");
        land1.setSurveyNo("12/A");
        land1.setEnteredArea(new BigDecimal("2400"));
        land1.setEnteredUnit("Sq.Ft");
        land1.setRate(new BigDecimal("2500"));
        landItems.add(land1);

        List<ValuationBuildingItem> buildingItems = new ArrayList<>();
        ValuationBuildingItem b1 = new ValuationBuildingItem();
        b1.setOrderId(101L);
        b1.setStructureType("Ground Floor");
        b1.setBuildingType("RCC Residential");
        b1.setDescription("Main structure");
        b1.setEnteredArea(new BigDecimal("1500"));
        b1.setEnteredUnit("Sq.Ft");
        b1.setReplacementRate(new BigDecimal("2000"));
        b1.setBuildingAge(new BigDecimal("10"));
        b1.setBuildingUsefulLife(60);
        b1.setSalvagePercentage(new BigDecimal("10.00"));
        buildingItems.add(b1);

        formulaService.calculateSummary(data, landItems, buildingItems);

        // Land: 2400 * 2500 = 60,00,000
        assertEquals(0, new BigDecimal("6000000.00").compareTo(land1.getValue()));
        assertEquals(0, new BigDecimal("6000000.00").compareTo(data.getTotalLandValue()));

        // Building Replacement Cost: 1500 * 2000 = 30,00,000
        assertEquals(0, new BigDecimal("3000000.00").compareTo(b1.getReplacementCost()));

        // Building Depreciation: Age 10 / 60 * (1 - 0.10) = 0.15 => 30,00,000 * 0.15 = 4,50,000
        assertEquals(0, new BigDecimal("450000.00").compareTo(b1.getDepreciationAmount()));

        // Building Value: 30,00,000 - 4,50,000 = 25,50,000
        assertEquals(0, new BigDecimal("2550000.00").compareTo(b1.getBuildingValue()));
        assertEquals(0, new BigDecimal("2550000.00").compareTo(data.getTotalBuildingValue()));

        // Fair Value = 60,00,000 + 25,50,000 = 85,50,000
        assertEquals(0, new BigDecimal("8550000.00").compareTo(data.getFairValue()));

        // Realizable Value (85%) = 85,50,000 * 0.85 = 72,67,500
        assertEquals(0, new BigDecimal("7267500.00").compareTo(data.getRealizableValue()));

        // Distress Sale Value (75%) = 85,50,000 * 0.75 = 64,12,500
        assertEquals(0, new BigDecimal("6412500.00").compareTo(data.getDistressSaleValue()));

        // Insurable Value (Business Rule: SUM of building replacement costs = 30,00,000, land excluded)
        assertEquals(0, new BigDecimal("3000000.00").compareTo(data.getInsurableValue()));
    }

    @Test
    @DisplayName("Insurable Value equals Total Building Replacement Cost and excludes Land Value")
    public void testInsurableValueCalculation() {
        ValuationData data = new ValuationData(103L);

        List<ValuationLandItem> landItems = new ArrayList<>();
        ValuationLandItem land = new ValuationLandItem();
        land.setEnteredArea(new BigDecimal("5000"));
        land.setRate(new BigDecimal("1000")); // Land value = 50,00,000
        landItems.add(land);

        List<ValuationBuildingItem> buildingItems = new ArrayList<>();
        ValuationBuildingItem b1 = new ValuationBuildingItem();
        b1.setEnteredArea(new BigDecimal("2000"));
        b1.setReplacementRate(new BigDecimal("1500")); // Repl Cost 1 = 30,00,000
        b1.setBuildingAge(new BigDecimal("5"));
        b1.setBuildingUsefulLife(60);
        buildingItems.add(b1);

        ValuationBuildingItem b2 = new ValuationBuildingItem();
        b2.setEnteredArea(new BigDecimal("1000"));
        b2.setReplacementRate(new BigDecimal("2000")); // Repl Cost 2 = 20,00,000
        b2.setBuildingAge(new BigDecimal("10"));
        b2.setBuildingUsefulLife(60);
        buildingItems.add(b2);

        formulaService.calculateSummary(data, landItems, buildingItems);

        // Land value = 50,00,000
        assertEquals(0, new BigDecimal("5000000.00").compareTo(data.getTotalLandValue()));
        // Total Replacement Cost = 30,00,000 + 20,00,000 = 50,00,000
        assertEquals(0, new BigDecimal("5000000.00").compareTo(data.getTotalReplacementCost()));
        // Insurable Value must equal Total Replacement Cost (50,00,000), ignoring Land
        assertEquals(0, new BigDecimal("5000000.00").compareTo(data.getInsurableValue()));
    }

    @Test
    @DisplayName("Government Value is independently tracked and preserved")
    public void testGovernmentValueTracking() {
        ValuationData data = new ValuationData(104L);
        data.setGovernmentValue(new BigDecimal("4500000.00"));

        formulaService.calculateSummary(data, new ArrayList<>(), new ArrayList<>());

        assertEquals(0, new BigDecimal("4500000.00").compareTo(data.getGovernmentValue()));
    }

    @Test
    @DisplayName("Say Value rounds to nearest Lakh when Fair Value is 1 Crore or above")
    public void testSayValueCalculation() {
        // Example 1: 8,99,97,730 -> 9,00,00,000
        BigDecimal ex1 = new BigDecimal("89997730.00");
        assertEquals(0, new BigDecimal("90000000.00").compareTo(ValuationEngineService.computeSayValue(ex1)));

        // Example 2: 24,38,72,110 -> 24,39,00,000
        BigDecimal ex2 = new BigDecimal("243872110.00");
        assertEquals(0, new BigDecimal("243900000.00").compareTo(ValuationEngineService.computeSayValue(ex2)));

        // Example 3: 109,38,22,456 -> 109,38,00,000
        BigDecimal ex3 = new BigDecimal("1093822456.00");
        assertEquals(0, new BigDecimal("1093800000.00").compareTo(ValuationEngineService.computeSayValue(ex3)));

        // Under 1 Crore: Exact Fair Value preserved (no rounding)
        BigDecimal under1Cr = new BigDecimal("7542380.00");
        assertEquals(0, new BigDecimal("7542380.00").compareTo(ValuationEngineService.computeSayValue(under1Cr)));
    }

    @Test
    @DisplayName("Salvage Floor Guard prevents building value from dropping below salvage percentage")
    public void testSalvageFloorProtection() {
        ValuationBuildingItem oldBuilding = new ValuationBuildingItem();
        oldBuilding.setOrderId(102L);
        oldBuilding.setStructureType("Warehouse");
        oldBuilding.setBuildingType("Steel Shed");
        oldBuilding.setDescription("Very old shed");
        oldBuilding.setEnteredArea(new BigDecimal("1000"));
        oldBuilding.setEnteredUnit("Sq.Ft");
        oldBuilding.setReplacementRate(new BigDecimal("1000"));
        oldBuilding.setBuildingAge(new BigDecimal("100"));
        oldBuilding.setBuildingUsefulLife(40);
        oldBuilding.setSalvagePercentage(new BigDecimal("10.00"));

        formulaService.calculateBuildingItem(oldBuilding);

        // Replacement Cost = 10,00,000
        assertEquals(0, new BigDecimal("1000000.00").compareTo(oldBuilding.getReplacementCost()));

        // Salvage floor = 10% of 10,00,000 = 1,00,000
        // Even though age > usefulLife, building value cannot drop below salvage floor
        assertEquals(0, new BigDecimal("100000.00").compareTo(oldBuilding.getBuildingValue()));
    }
}
