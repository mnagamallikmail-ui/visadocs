package com.provaluer.service;

import com.provaluer.model.ValuationCompositeItem;
import com.provaluer.model.ValuationData;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;

public class FinalValuationValueUnificationTest {

    private final ValuationEngineService valuationEngineService = new ValuationEngineService();
    private final ValuationCalculationFormulaService formulaService = new ValuationCalculationFormulaService();

    @Test
    @DisplayName("Runtime Validation Scenario: TOTAL_FAIR_VALUE = 81,22,000 -> SAY_VALUE & all report aliases = 81,20,000")
    public void testRuntimeValidationScenario() {
        // Setup composite scenario with total mathematical fair value = 81,22,000
        ValuationData data = new ValuationData();
        data.setOrderId(999L);
        data.setValuationMethodology("COMPOSITE");
        data.setCompositeBuildingAge(BigDecimal.ZERO);
        data.setCompositeBuildingTotalLife(60);
        data.setCompositeConstructionCost(new BigDecimal("2500"));

        List<ValuationCompositeItem> items = new ArrayList<>();

        // Main unit: 1000 sqft @ rate 7522 -> amount 75,22,000, 0 depreciation
        ValuationCompositeItem mainUnit = new ValuationCompositeItem();
        mainUnit.setItemCategory("MAIN_UNIT");
        mainUnit.setDescription("Main Unit");
        mainUnit.setEnteredUnit("Sq.Ft");
        mainUnit.setQuantity(new BigDecimal("1000"));
        mainUnit.setRate(new BigDecimal("7522"));
        mainUnit.setAmount(new BigDecimal("7522000"));
        mainUnit.setDepreciationAmount(BigDecimal.ZERO);
        mainUnit.setFairValue(new BigDecimal("7522000"));
        items.add(mainUnit);

        // Interior: 3,00,000
        ValuationCompositeItem interior = new ValuationCompositeItem();
        interior.setItemCategory("INTERIOR_WORK");
        interior.setDescription("Interior Woodwork");
        interior.setEnteredUnit("LS");
        interior.setQuantity(BigDecimal.ONE);
        interior.setRate(new BigDecimal("300000"));
        interior.setAmount(new BigDecimal("300000"));
        interior.setDepreciationAmount(BigDecimal.ZERO);
        interior.setFairValue(new BigDecimal("300000"));
        items.add(interior);

        // Parking: 3,00,000
        ValuationCompositeItem parking = new ValuationCompositeItem();
        parking.setItemCategory("PARKING");
        parking.setDescription("Car Parking");
        parking.setEnteredUnit("Slot");
        parking.setQuantity(BigDecimal.ONE);
        parking.setRate(new BigDecimal("300000"));
        parking.setAmount(new BigDecimal("300000"));
        parking.setDepreciationAmount(BigDecimal.ZERO);
        parking.setFairValue(new BigDecimal("300000"));
        items.add(parking);

        // Run calculation
        formulaService.calculateCompositeSummary(data, items);

        // Level 1: TOTAL_FAIR_VALUE = 75,22,000 + 3,00,000 + 3,00,000 = 81,22,000
        assertEquals(0, new BigDecimal("8122000.00").compareTo(data.getRawFairValue()),
                "RAW_FAIR_VALUE must preserve exact mathematical valuation without rounding");

        // Level 2: SAY_VALUE = 81,20,000
        assertEquals(0, new BigDecimal("8120000.00").compareTo(data.getSayFairValue()),
                "SAY_VALUE must be rounded to nearest 10,000");

        // Report display: FAIR_VALUE = SAY_VALUE
        assertEquals(0, new BigDecimal("8120000.00").compareTo(data.getFairValue()),
                "FAIR_VALUE must equal SAY_VALUE");

        // Generate placeholders and inspect every report valuation key
        com.provaluer.model.Order order = new com.provaluer.model.Order();
        order.setId(999L);
        order.setReportNumber("PV-999");
        order.setClientName("Client X");
        order.setPropertyCategory("Commercial Property");

        Map<String, String> placeholders = valuationEngineService.generatePlaceholders(
                order,
                data,
                new ArrayList<>(),
                new ArrayList<>(),
                new ArrayList<>(),
                items
        );

        // LEVEL 1 placeholders
        assertEquals("81,22,000", placeholders.get("total_fair_value"));
        assertEquals("81,22,000", placeholders.get("TOTAL_FAIR_VALUE"));
        assertEquals("Rupees Eighty One Lakh Twenty Two Thousand Only", placeholders.get("total_fair_value_words"));
        assertEquals("Rupees Eighty One Lakh Twenty Two Thousand Only", placeholders.get("TOTAL_FAIR_VALUE_WORDS"));

        // LEVEL 2 & REPORT-FACING ALIASES: Must all be 81,20,000
        assertEquals("81,20,000", placeholders.get("say_value"));
        assertEquals("81,20,000", placeholders.get("SAY_VALUE"));
        assertEquals("81,20,000", placeholders.get("say_fair_value"));
        assertEquals("81,20,000", placeholders.get("SAY_FAIR_VALUE"));
        assertEquals("81,20,000", placeholders.get("report_fair_value"));
        assertEquals("81,20,000", placeholders.get("REPORT_FAIR_VALUE"));
        assertEquals("81,20,000", placeholders.get("fair_value"));
        assertEquals("81,20,000", placeholders.get("FAIR_VALUE"));
        assertEquals("81,20,000", placeholders.get("market_value"));
        assertEquals("81,20,000", placeholders.get("MARKET_VALUE"));
        assertEquals("81,20,000", placeholders.get("property_value"));
        assertEquals("81,20,000", placeholders.get("PROPERTY_VALUE"));
        assertEquals("81,20,000", placeholders.get("final_value"));
        assertEquals("81,20,000", placeholders.get("FINAL_VALUE"));
        assertEquals("81,20,000", placeholders.get("valuation_amount"));
        assertEquals("81,20,000", placeholders.get("VALUATION_AMOUNT"));
        assertEquals("81,20,000", placeholders.get("opinion_of_value"));
        assertEquals("81,20,000", placeholders.get("OPINION_OF_VALUE"));
        assertEquals("81,20,000", placeholders.get("recommended_value"));
        assertEquals("81,20,000", placeholders.get("RECOMMENDED_VALUE"));

        // WORDS GOVERNANCE: Must all be generated from SAY_VALUE (81,20,000)
        String expectedWords = "Rupees Eighty One Lakh Twenty Thousand Only";
        assertEquals(expectedWords, placeholders.get("say_value_words"));
        assertEquals(expectedWords, placeholders.get("SAY_VALUE_WORDS"));
        assertEquals(expectedWords, placeholders.get("fair_value_words"));
        assertEquals(expectedWords, placeholders.get("FAIR_VALUE_WORDS"));
        assertEquals(expectedWords, placeholders.get("market_value_words"));
        assertEquals(expectedWords, placeholders.get("MARKET_VALUE_WORDS"));
        assertEquals(expectedWords, placeholders.get("property_value_words"));
        assertEquals(expectedWords, placeholders.get("PROPERTY_VALUE_WORDS"));
        assertEquals(expectedWords, placeholders.get("final_value_words"));
        assertEquals(expectedWords, placeholders.get("FINAL_VALUE_WORDS"));
        assertEquals(expectedWords, placeholders.get("valuation_amount_words"));
        assertEquals(expectedWords, placeholders.get("VALUATION_AMOUNT_WORDS"));
        assertEquals(expectedWords, placeholders.get("opinion_of_value_words"));
        assertEquals(expectedWords, placeholders.get("OPINION_OF_VALUE_WORDS"));
        assertEquals(expectedWords, placeholders.get("recommended_value_words"));
        assertEquals(expectedWords, placeholders.get("RECOMMENDED_VALUE_WORDS"));
    }
}
