package com.provaluer.service;

import com.provaluer.model.ValuationBuildingItem;
import com.provaluer.model.ValuationData;
import com.provaluer.model.ValuationLandItem;
import com.provaluer.util.IndianCurrencyToWords;
import com.provaluer.util.IndianNumberFormatter;
import com.provaluer.util.UnitConversionEngine;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

public class StagingUatMatrixExecutionTest {

    private final ValuationCalculationFormulaService formulaService = new ValuationCalculationFormulaService();

    @Test
    @DisplayName("UAT1: Residential Single Family Home")
    public void testUat1_ResidentialSingleFamily() {
        ValuationData data = new ValuationData(101L);
        data.setRealizablePercentage(new BigDecimal("85.00"));
        data.setDistressSalePercentage(new BigDecimal("75.00"));

        ValuationLandItem land = new ValuationLandItem();
        land.setEnteredArea(new BigDecimal("2400"));
        land.setEnteredUnit("Sq.Ft");
        land.setRate(new BigDecimal("2500.00"));

        ValuationBuildingItem bldg = new ValuationBuildingItem();
        bldg.setBuildingType("RCC Residential");
        bldg.setEnteredArea(new BigDecimal("1500"));
        bldg.setEnteredUnit("Sq.Ft");
        bldg.setReplacementRate(new BigDecimal("2000.00"));
        bldg.setBuildingAge(new BigDecimal("5"));
        bldg.setBuildingUsefulLife(60);
        bldg.setSalvagePercentage(new BigDecimal("10.00"));

        formulaService.calculateSummary(data, List.of(land), List.of(bldg));

        assertEquals(0, new BigDecimal("6000000.00").compareTo(data.getTotalLandValue()));
        assertEquals(0, new BigDecimal("3000000.00").compareTo(data.getTotalReplacementCost()));
        assertEquals(0, new BigDecimal("225000.00").compareTo(data.getTotalDepreciationAmount()));
        assertEquals(0, new BigDecimal("2775000.00").compareTo(data.getTotalBuildingValue()));
        assertEquals(0, new BigDecimal("8775000.00").compareTo(data.getFairValue()));
        assertEquals(0, new BigDecimal("7458750.00").compareTo(data.getRealizableValue()));
        assertEquals(0, new BigDecimal("6581250.00").compareTo(data.getDistressSaleValue()));

        assertEquals("87,75,000", IndianNumberFormatter.format(data.getFairValue()));
        assertEquals("Rupees Eighty Seven Lakh Seventy Five Thousand Only", IndianCurrencyToWords.convertToWords(data.getFairValue()));
    }

    @Test
    @DisplayName("UAT2: Multi-Story Commercial Office")
    public void testUat2_CommercialOffice() {
        ValuationData data = new ValuationData(102L);

        ValuationLandItem land = new ValuationLandItem();
        land.setEnteredArea(new BigDecimal("10000"));
        land.setEnteredUnit("Sq.Ft");
        land.setRate(new BigDecimal("8000.00"));

        ValuationBuildingItem bldg = new ValuationBuildingItem();
        bldg.setBuildingType("RCC Commercial");
        bldg.setEnteredArea(new BigDecimal("25000"));
        bldg.setEnteredUnit("Sq.Ft");
        bldg.setReplacementRate(new BigDecimal("3500.00"));
        bldg.setBuildingAge(new BigDecimal("12"));
        bldg.setBuildingUsefulLife(60);
        bldg.setSalvagePercentage(new BigDecimal("10.00"));

        formulaService.calculateSummary(data, List.of(land), List.of(bldg));

        assertEquals(0, new BigDecimal("80000000.00").compareTo(data.getTotalLandValue()));
        assertEquals(0, new BigDecimal("87500000.00").compareTo(data.getTotalReplacementCost()));
        assertEquals(0, new BigDecimal("15750000.00").compareTo(data.getTotalDepreciationAmount()));
        assertEquals(0, new BigDecimal("71750000.00").compareTo(data.getTotalBuildingValue()));
        assertEquals(0, new BigDecimal("151750000.00").compareTo(data.getFairValue()));
        assertEquals(0, new BigDecimal("128987500.00").compareTo(data.getRealizableValue()));
        assertEquals(0, new BigDecimal("113812500.00").compareTo(data.getDistressSaleValue()));

        assertEquals("15,17,50,000", IndianNumberFormatter.format(data.getFairValue()));
        assertEquals("Rupees Fifteen Crore Seventeen Lakh Fifty Thousand Only", IndianCurrencyToWords.convertToWords(data.getFairValue()));
    }

    @Test
    @DisplayName("UAT3: Vacant Commercial Land Parcel (Land Only)")
    public void testUat3_LandOnly() {
        ValuationData data = new ValuationData(103L);

        ValuationLandItem land = new ValuationLandItem();
        land.setEnteredArea(new BigDecimal("2.5"));
        land.setEnteredUnit("Acres"); // 108,900 Sq.Ft
        land.setRate(new BigDecimal("1000.00"));

        formulaService.calculateSummary(data, List.of(land), Collections.emptyList());

        assertEquals(0, new BigDecimal("108900000.00").compareTo(data.getTotalLandValue()));
        assertEquals(0, BigDecimal.ZERO.compareTo(data.getTotalBuildingValue()));
        assertEquals(0, new BigDecimal("108900000.00").compareTo(data.getFairValue()));
        assertEquals(0, new BigDecimal("92565000.00").compareTo(data.getRealizableValue()));
        assertEquals(0, new BigDecimal("81675000.00").compareTo(data.getDistressSaleValue()));

        assertEquals("10,89,00,000", IndianNumberFormatter.format(data.getFairValue()));
        assertEquals("Rupees Ten Crore Eighty Nine Lakh Only", IndianCurrencyToWords.convertToWords(data.getFairValue()));
    }

    @Test
    @DisplayName("UAT4: Industrial Warehouse & PEB Shed (40y Useful Life Default)")
    public void testUat4_IndustrialWarehouseShed() {
        ValuationData data = new ValuationData(104L);

        ValuationLandItem land = new ValuationLandItem();
        land.setEnteredArea(new BigDecimal("1.0"));
        land.setEnteredUnit("Acres"); // 43,560 Sq.Ft
        land.setRate(new BigDecimal("1200.00"));

        ValuationBuildingItem bldg = new ValuationBuildingItem();
        bldg.setBuildingType("Industrial Shed");
        bldg.setEnteredArea(new BigDecimal("20000"));
        bldg.setEnteredUnit("Sq.Ft");
        bldg.setReplacementRate(new BigDecimal("1800.00"));
        bldg.setBuildingAge(new BigDecimal("8"));
        bldg.setBuildingUsefulLife(40);
        bldg.setSalvagePercentage(new BigDecimal("10.00"));

        formulaService.calculateSummary(data, List.of(land), List.of(bldg));

        assertEquals(0, new BigDecimal("52272000.00").compareTo(data.getTotalLandValue()));
        assertEquals(0, new BigDecimal("36000000.00").compareTo(data.getTotalReplacementCost()));
        assertEquals(0, new BigDecimal("6480000.00").compareTo(data.getTotalDepreciationAmount()));
        assertEquals(0, new BigDecimal("29520000.00").compareTo(data.getTotalBuildingValue()));
        assertEquals(0, new BigDecimal("81792000.00").compareTo(data.getFairValue()));
        assertEquals(0, new BigDecimal("69523200.00").compareTo(data.getRealizableValue()));
        assertEquals(0, new BigDecimal("61344000.00").compareTo(data.getDistressSaleValue()));

        assertEquals("8,17,92,000", IndianNumberFormatter.format(data.getFairValue()));
        assertEquals("Rupees Eight Crore Seventeen Lakh Ninety Two Thousand Only", IndianCurrencyToWords.convertToWords(data.getFairValue()));
    }

    @Test
    @DisplayName("UAT5: Aged Structure (Salvage Floor Protection Guard Verification)")
    public void testUat5_AgedStructureSalvageFloor() {
        ValuationData data = new ValuationData(105L);

        ValuationLandItem land = new ValuationLandItem();
        land.setEnteredArea(new BigDecimal("3000"));
        land.setEnteredUnit("Sq.Ft");
        land.setRate(new BigDecimal("3000.00"));

        ValuationBuildingItem bldg = new ValuationBuildingItem();
        bldg.setBuildingType("RCC Residential");
        bldg.setEnteredArea(new BigDecimal("2000"));
        bldg.setEnteredUnit("Sq.Ft");
        bldg.setReplacementRate(new BigDecimal("2200.00")); // Repl Cost = 44,00,000
        bldg.setBuildingAge(new BigDecimal("70")); // Exceeds 60y life
        bldg.setBuildingUsefulLife(60);
        bldg.setSalvagePercentage(new BigDecimal("10.00")); // 10% Salvage floor = 4,40,000

        formulaService.calculateSummary(data, List.of(land), List.of(bldg));

        assertEquals(0, new BigDecimal("9000000.00").compareTo(data.getTotalLandValue()));
        assertEquals(0, new BigDecimal("4400000.00").compareTo(data.getTotalReplacementCost()));
        // Must be capped at salvage floor 4,40,000 (10% of 44,00,000)
        assertEquals(0, new BigDecimal("440000.00").compareTo(data.getTotalBuildingValue()));
        assertEquals(0, new BigDecimal("9440000.00").compareTo(data.getFairValue()));
        assertEquals(0, new BigDecimal("8024000.00").compareTo(data.getRealizableValue()));
        assertEquals(0, new BigDecimal("7080000.00").compareTo(data.getDistressSaleValue()));

        assertEquals("94,40,000", IndianNumberFormatter.format(data.getFairValue()));
        assertEquals("Rupees Ninety Four Lakh Forty Thousand Only", IndianCurrencyToWords.convertToWords(data.getFairValue()));
    }

    @Test
    @DisplayName("UAT6: Retail Showroom (Grounds Unit Normalization)")
    public void testUat6_RetailShowroom() {
        ValuationData data = new ValuationData(106L);

        ValuationLandItem land = new ValuationLandItem();
        land.setEnteredArea(new BigDecimal("5.0"));
        land.setEnteredUnit("Grounds"); // 5 * 2,400 = 12,000 Sq.Ft
        land.setRate(new BigDecimal("1500.00"));

        ValuationBuildingItem bldg = new ValuationBuildingItem();
        bldg.setBuildingType("RCC Commercial");
        bldg.setEnteredArea(new BigDecimal("8000"));
        bldg.setEnteredUnit("Sq.Ft");
        bldg.setReplacementRate(new BigDecimal("2800.00"));
        bldg.setBuildingAge(new BigDecimal("15"));
        bldg.setBuildingUsefulLife(60);
        bldg.setSalvagePercentage(new BigDecimal("10.00"));

        formulaService.calculateSummary(data, List.of(land), List.of(bldg));

        assertEquals(0, new BigDecimal("18000000.00").compareTo(data.getTotalLandValue()));
        assertEquals(0, new BigDecimal("22400000.00").compareTo(data.getTotalReplacementCost()));
        assertEquals(0, new BigDecimal("5040000.00").compareTo(data.getTotalDepreciationAmount()));
        assertEquals(0, new BigDecimal("17360000.00").compareTo(data.getTotalBuildingValue()));
        assertEquals(0, new BigDecimal("35360000.00").compareTo(data.getFairValue()));
        assertEquals(0, new BigDecimal("30056000.00").compareTo(data.getRealizableValue()));
        assertEquals(0, new BigDecimal("26520000.00").compareTo(data.getDistressSaleValue()));

        assertEquals("3,53,60,000", IndianNumberFormatter.format(data.getFairValue()));
        assertEquals("Rupees Three Crore Fifty Three Lakh Sixty Thousand Only", IndianCurrencyToWords.convertToWords(data.getFairValue()));
    }

    @Test
    @DisplayName("UAT7: Factory Shed (Cents Unit Normalization)")
    public void testUat7_FactoryShed() {
        ValuationData data = new ValuationData(107L);

        ValuationLandItem land = new ValuationLandItem();
        land.setEnteredArea(new BigDecimal("100.0"));
        land.setEnteredUnit("Cents"); // 100 * 435.6 = 43,560 Sq.Ft
        land.setRate(new BigDecimal("800.00"));

        ValuationBuildingItem bldg = new ValuationBuildingItem();
        bldg.setBuildingType("Steel Shed");
        bldg.setEnteredArea(new BigDecimal("15000"));
        bldg.setEnteredUnit("Sq.Ft");
        bldg.setReplacementRate(new BigDecimal("1600.00"));
        bldg.setBuildingAge(new BigDecimal("20"));
        bldg.setBuildingUsefulLife(40);
        bldg.setSalvagePercentage(new BigDecimal("10.00"));

        formulaService.calculateSummary(data, List.of(land), List.of(bldg));

        assertEquals(0, new BigDecimal("34848000.00").compareTo(data.getTotalLandValue()));
        assertEquals(0, new BigDecimal("24000000.00").compareTo(data.getTotalReplacementCost()));
        assertEquals(0, new BigDecimal("10800000.00").compareTo(data.getTotalDepreciationAmount()));
        assertEquals(0, new BigDecimal("13200000.00").compareTo(data.getTotalBuildingValue()));
        assertEquals(0, new BigDecimal("48048000.00").compareTo(data.getFairValue()));
        assertEquals(0, new BigDecimal("40840800.00").compareTo(data.getRealizableValue()));
        assertEquals(0, new BigDecimal("36036000.00").compareTo(data.getDistressSaleValue()));

        assertEquals("4,80,48,000", IndianNumberFormatter.format(data.getFairValue()));
        assertEquals("Rupees Four Crore Eighty Lakh Forty Eight Thousand Only", IndianCurrencyToWords.convertToWords(data.getFairValue()));
    }

    @Test
    @DisplayName("UAT8: Mixed Development (Custom Realizable 90% and Distress 80%)")
    public void testUat8_MixedDevelopmentCustomPercentages() {
        ValuationData data = new ValuationData(108L);
        data.setRealizablePercentage(new BigDecimal("90.00"));
        data.setDistressSalePercentage(new BigDecimal("80.00"));

        ValuationLandItem land = new ValuationLandItem();
        land.setEnteredArea(new BigDecimal("12000"));
        land.setEnteredUnit("Sq.Ft");
        land.setRate(new BigDecimal("4500.00"));

        ValuationBuildingItem bldg = new ValuationBuildingItem();
        bldg.setBuildingType("RCC Commercial");
        bldg.setEnteredArea(new BigDecimal("18000"));
        bldg.setEnteredUnit("Sq.Ft");
        bldg.setReplacementRate(new BigDecimal("3000.00"));
        bldg.setBuildingAge(new BigDecimal("10"));
        bldg.setBuildingUsefulLife(60);
        bldg.setSalvagePercentage(new BigDecimal("10.00"));

        formulaService.calculateSummary(data, List.of(land), List.of(bldg));

        assertEquals(0, new BigDecimal("54000000.00").compareTo(data.getTotalLandValue()));
        assertEquals(0, new BigDecimal("54000000.00").compareTo(data.getTotalReplacementCost()));
        assertEquals(0, new BigDecimal("8100000.00").compareTo(data.getTotalDepreciationAmount()));
        assertEquals(0, new BigDecimal("45900000.00").compareTo(data.getTotalBuildingValue()));
        assertEquals(0, new BigDecimal("99900000.00").compareTo(data.getFairValue()));
        assertEquals(0, new BigDecimal("89910000.00").compareTo(data.getRealizableValue()));
        assertEquals(0, new BigDecimal("79920000.00").compareTo(data.getDistressSaleValue()));

        assertEquals("9,99,00,000", IndianNumberFormatter.format(data.getFairValue()));
        assertEquals("Rupees Nine Crore Ninety Nine Lakh Only", IndianCurrencyToWords.convertToWords(data.getFairValue()));
    }

    @Test
    @DisplayName("UAT9: High-Value Commercial Asset (> 100 Crore Formatting)")
    public void testUat9_HighValueCommercialAsset() {
        ValuationData data = new ValuationData(109L);

        ValuationLandItem land = new ValuationLandItem();
        land.setEnteredArea(new BigDecimal("50000"));
        land.setEnteredUnit("Sq.Ft");
        land.setRate(new BigDecimal("15000.00"));

        ValuationBuildingItem bldg = new ValuationBuildingItem();
        bldg.setBuildingType("RCC Commercial");
        bldg.setEnteredArea(new BigDecimal("80000"));
        bldg.setEnteredUnit("Sq.Ft");
        bldg.setReplacementRate(new BigDecimal("4500.00"));
        bldg.setBuildingAge(new BigDecimal("3"));
        bldg.setBuildingUsefulLife(60);
        bldg.setSalvagePercentage(new BigDecimal("10.00"));

        formulaService.calculateSummary(data, List.of(land), List.of(bldg));

        assertEquals(0, new BigDecimal("750000000.00").compareTo(data.getTotalLandValue()));
        assertEquals(0, new BigDecimal("360000000.00").compareTo(data.getTotalReplacementCost()));
        assertEquals(0, new BigDecimal("16200000.00").compareTo(data.getTotalDepreciationAmount()));
        assertEquals(0, new BigDecimal("343800000.00").compareTo(data.getTotalBuildingValue()));
        assertEquals(0, new BigDecimal("1093800000.00").compareTo(data.getFairValue()));
        assertEquals(0, new BigDecimal("929730000.00").compareTo(data.getRealizableValue()));
        assertEquals(0, new BigDecimal("820350000.00").compareTo(data.getDistressSaleValue()));

        assertEquals("1,09,38,00,000", IndianNumberFormatter.format(data.getFairValue()));
        assertEquals("Rupees One Hundred Nine Crore Thirty Eight Lakh Only", IndianCurrencyToWords.convertToWords(data.getFairValue()));
    }

    @Test
    @DisplayName("UAT10: Micro Plot Single Story Home")
    public void testUat10_MicroPlot() {
        ValuationData data = new ValuationData(110L);

        ValuationLandItem land = new ValuationLandItem();
        land.setEnteredArea(new BigDecimal("800"));
        land.setEnteredUnit("Sq.Ft");
        land.setRate(new BigDecimal("1500.00"));

        ValuationBuildingItem bldg = new ValuationBuildingItem();
        bldg.setBuildingType("RCC Residential");
        bldg.setEnteredArea(new BigDecimal("600"));
        bldg.setEnteredUnit("Sq.Ft");
        bldg.setReplacementRate(new BigDecimal("1400.00"));
        bldg.setBuildingAge(new BigDecimal("2"));
        bldg.setBuildingUsefulLife(60);
        bldg.setSalvagePercentage(new BigDecimal("10.00"));

        formulaService.calculateSummary(data, List.of(land), List.of(bldg));

        assertEquals(0, new BigDecimal("1200000.00").compareTo(data.getTotalLandValue()));
        assertEquals(0, new BigDecimal("840000.00").compareTo(data.getTotalReplacementCost()));
        assertEquals(0, new BigDecimal("25200.00").compareTo(data.getTotalDepreciationAmount()));
        assertEquals(0, new BigDecimal("814800.00").compareTo(data.getTotalBuildingValue()));
        assertEquals(0, new BigDecimal("2014800.00").compareTo(data.getFairValue()));
        assertEquals(0, new BigDecimal("1712580.00").compareTo(data.getRealizableValue()));
        assertEquals(0, new BigDecimal("1511100.00").compareTo(data.getDistressSaleValue()));

        assertEquals("20,14,800", IndianNumberFormatter.format(data.getFairValue()));
        assertEquals("Rupees Twenty Lakh Fourteen Thousand Eight Hundred Only", IndianCurrencyToWords.convertToWords(data.getFairValue()));
    }
}
