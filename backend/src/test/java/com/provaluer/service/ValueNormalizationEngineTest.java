package com.provaluer.service;

import com.provaluer.util.ValueNormalizationEngine;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

public class ValueNormalizationEngineTest {

    @Test
    @DisplayName("Unit-Aware Area Normalization correctly derives raw, numeric, detected unit, and standard sqft")
    public void testUnitAwareAreaNormalization() {
        // 2.375 Acres
        ValueNormalizationEngine.NormalizedValue acreVal = ValueNormalizationEngine.normalizeAreaValue("2.375 Acres");
        assertEquals("2.375 Acres", acreVal.getRawValue());
        assertEquals(0, new BigDecimal("2.375").compareTo(acreVal.getNumericValue()));
        assertEquals("ACRES", acreVal.getDetectedUnit());
        assertEquals(0, new BigDecimal("103455.000").compareTo(acreVal.getStandardSqftValue()));

        // 250 Sq.Yd
        ValueNormalizationEngine.NormalizedValue sqydVal = ValueNormalizationEngine.normalizeAreaValue("250 Sq.Yd");
        assertEquals("250 Sq.Yd", sqydVal.getRawValue());
        assertEquals(0, new BigDecimal("250").compareTo(sqydVal.getNumericValue()));
        assertEquals("SQYD", sqydVal.getDetectedUnit());
        assertEquals(0, new BigDecimal("2250.000").compareTo(sqydVal.getStandardSqftValue()));

        // 100 Sq.M
        ValueNormalizationEngine.NormalizedValue sqmVal = ValueNormalizationEngine.normalizeAreaValue("100 Sq.M");
        assertEquals("100 Sq.M", sqmVal.getRawValue());
        assertEquals(0, new BigDecimal("100").compareTo(sqmVal.getNumericValue()));
        assertEquals("SQM", sqmVal.getDetectedUnit());
        assertEquals(0, new BigDecimal("1076.391").compareTo(sqmVal.getStandardSqftValue()));

        // 40 Cents
        ValueNormalizationEngine.NormalizedValue centsVal = ValueNormalizationEngine.normalizeAreaValue("40 Cents");
        assertEquals("40 Cents", centsVal.getRawValue());
        assertEquals(0, new BigDecimal("40").compareTo(centsVal.getNumericValue()));
        assertEquals("CENTS", centsVal.getDetectedUnit());
        assertEquals(0, new BigDecimal("17424.000").compareTo(centsVal.getStandardSqftValue()));

        // 5 Grounds
        ValueNormalizationEngine.NormalizedValue groundsVal = ValueNormalizationEngine.normalizeAreaValue("5 Grounds");
        assertEquals("5 Grounds", groundsVal.getRawValue());
        assertEquals(0, new BigDecimal("5").compareTo(groundsVal.getNumericValue()));
        assertEquals("GROUNDS", groundsVal.getDetectedUnit());
        assertEquals(0, new BigDecimal("12000.000").compareTo(groundsVal.getStandardSqftValue()));

        // 1000.125 Sq.Ft
        ValueNormalizationEngine.NormalizedValue sqftVal = ValueNormalizationEngine.normalizeAreaValue("1000.125 Sq.Ft");
        assertEquals("1000.125 Sq.Ft", sqftVal.getRawValue());
        assertEquals(0, new BigDecimal("1000.125").compareTo(sqftVal.getNumericValue()));
        assertEquals("SQFT", sqftVal.getDetectedUnit());
        assertEquals(0, new BigDecimal("1000.125").compareTo(sqftVal.getStandardSqftValue()));
    }

    @Test
    @DisplayName("Area Normalization extracts exact numeric values ignoring prefixes, units, and punctuation")
    public void testAreaNormalization() {
        assertEquals(0, new BigDecimal("1000").compareTo(ValueNormalizationEngine.normalizeArea("1000 sq.ft")));
        assertEquals(0, new BigDecimal("1000.125").compareTo(ValueNormalizationEngine.normalizeArea("1000.125 sq.ft")));
        assertEquals(0, new BigDecimal("1000").compareTo(ValueNormalizationEngine.normalizeArea("1000 sqft")));
        assertEquals(0, new BigDecimal("1000").compareTo(ValueNormalizationEngine.normalizeArea("1000 SFT")));
        assertEquals(0, new BigDecimal("1000").compareTo(ValueNormalizationEngine.normalizeArea("1000 Square Feet")));
        assertEquals(0, new BigDecimal("1000").compareTo(ValueNormalizationEngine.normalizeArea("Approx 1000 Sq.Ft")));
        assertEquals(0, new BigDecimal("1000").compareTo(ValueNormalizationEngine.normalizeArea("Approx. 1000 Sq.Ft")));
        assertEquals(0, new BigDecimal("1000").compareTo(ValueNormalizationEngine.normalizeArea("Area = 1000 Sq Ft")));
        assertEquals(0, new BigDecimal("1250.50").compareTo(ValueNormalizationEngine.normalizeArea("1,250.50 sq.ft")));
        assertEquals(0, new BigDecimal("2.5").compareTo(ValueNormalizationEngine.normalizeArea("2.5 Acres")));
        assertEquals(0, new BigDecimal("2.375").compareTo(ValueNormalizationEngine.normalizeArea("2.375 Acres")));
        assertEquals(0, new BigDecimal("5.0").compareTo(ValueNormalizationEngine.normalizeArea("5.0 Grounds")));
        assertEquals(0, new BigDecimal("5.125").compareTo(ValueNormalizationEngine.normalizeArea("5.125 Grounds")));
    }

    @Test
    @DisplayName("Rate Normalization extracts exact numeric rates ignoring currency symbols, slashes, and qualifiers")
    public void testRateNormalization() {
        assertEquals(0, new BigDecimal("5000").compareTo(ValueNormalizationEngine.normalizeRate("Rs 5000")));
        assertEquals(0, new BigDecimal("5000").compareTo(ValueNormalizationEngine.normalizeRate("Rs. 5000")));
        assertEquals(0, new BigDecimal("5000.125").compareTo(ValueNormalizationEngine.normalizeRate("Rs 5000.125")));
        assertEquals(0, new BigDecimal("6000").compareTo(ValueNormalizationEngine.normalizeRate("INR 6000")));
        assertEquals(0, new BigDecimal("5000").compareTo(ValueNormalizationEngine.normalizeRate("₹5000")));
        assertEquals(0, new BigDecimal("7500").compareTo(ValueNormalizationEngine.normalizeRate("₹ 7,500")));
        assertEquals(0, new BigDecimal("7500").compareTo(ValueNormalizationEngine.normalizeRate("₹ 7,500 per sq.ft")));
        assertEquals(0, new BigDecimal("7500.750").compareTo(ValueNormalizationEngine.normalizeRate("₹ 7500.750 per sq.ft")));
        assertEquals(0, new BigDecimal("8500").compareTo(ValueNormalizationEngine.normalizeRate("Rs. 8,500/SFT")));
        assertEquals(0, new BigDecimal("5000").compareTo(ValueNormalizationEngine.normalizeRate("5000/-")));
    }

    @Test
    @DisplayName("Percentage Normalization handles percentages, decimals, and negative values")
    public void testPercentageNormalization() {
        assertEquals(0, new BigDecimal("85").compareTo(ValueNormalizationEngine.normalizePercentage("85%")));
        assertEquals(0, new BigDecimal("90").compareTo(ValueNormalizationEngine.normalizePercentage("90 %")));
        assertEquals(0, new BigDecimal("12.5").compareTo(ValueNormalizationEngine.normalizePercentage("12.5%")));
        assertEquals(0, new BigDecimal("12.875").compareTo(ValueNormalizationEngine.normalizePercentage("12.875%")));
        assertEquals(0, new BigDecimal("-10").compareTo(ValueNormalizationEngine.normalizePercentage("-10%")));
    }

    @Test
    @DisplayName("Decimal Precision Governance preserves up to 3 decimal places and rounds > 3 to 3 with HALF_UP")
    public void testDecimalPrecisionGovernance() {
        assertEquals("1000.123", ValueNormalizationEngine.normalize("SALEABLE_AREA", "1000.1234 sq.ft").toPlainString());
        assertEquals("1000.568", ValueNormalizationEngine.normalize("SALEABLE_AREA", "1000.56789 sq.ft").toPlainString());
        assertEquals("3.000", ValueNormalizationEngine.normalize("LAND_AREA", "2.9999 Acres").toPlainString());
        assertEquals("1000.125", ValueNormalizationEngine.normalize("SALEABLE_AREA", "1000.125 sq.ft").toPlainString());
        assertEquals("5000.25", ValueNormalizationEngine.normalize("MARKET_RATE_FLAT", "Rs 5000.25").toPlainString());
    }

    @Test
    @DisplayName("Validation Rejections: Non-numeric inputs reject with expected error message and no silent conversion to zero")
    public void testRejections() {
        IllegalArgumentException ex1 = assertThrows(IllegalArgumentException.class, () ->
                ValueNormalizationEngine.normalize("SALEABLE_AREA", "abc"));
        assertEquals("Numeric value could not be derived from input.", ex1.getMessage());

        IllegalArgumentException ex2 = assertThrows(IllegalArgumentException.class, () ->
                ValueNormalizationEngine.normalize("MARKET_RATE_FLAT", "Rs only"));
        assertEquals("Numeric value could not be derived from input.", ex2.getMessage());

        IllegalArgumentException ex3 = assertThrows(IllegalArgumentException.class, () ->
                ValueNormalizationEngine.normalize("SUPER_BUILT_UP_AREA", "sq.ft only"));
        assertEquals("Numeric value could not be derived from input.", ex3.getMessage());

        IllegalArgumentException ex4 = assertThrows(IllegalArgumentException.class, () ->
                ValueNormalizationEngine.normalize("REALIZABLE_PERCENTAGE", ""));
        assertEquals("Numeric value could not be derived from input.", ex4.getMessage());
    }

    @Test
    @DisplayName("Calculation Accuracy: Authoritative Area Calculation uses STANDARD_AREA_SQFT")
    public void testAuthoritativeAreaCalculation() {
        // 2.375 Acres @ Rs 5000/sq.ft
        ValueNormalizationEngine.NormalizedValue acreArea = ValueNormalizationEngine.normalizeAreaValue("2.375 Acres");
        BigDecimal rate = ValueNormalizationEngine.normalizeRate("Rs 5000");

        // Authoritative calculation rule: UNIT_AMOUNT = STANDARD_AREA_SQFT * MARKET_RATE_FLAT_NUMERIC
        BigDecimal unitAmount = acreArea.getStandardSqftValue().multiply(rate);
        assertEquals(0, new BigDecimal("517275000").compareTo(unitAmount)); // 103455 * 5000 = 517,275,000

        // 1000 sq.ft @ Rs 5000
        ValueNormalizationEngine.NormalizedValue sqftArea = ValueNormalizationEngine.normalizeAreaValue("1000 sq.ft");
        assertEquals(0, new BigDecimal("5000000").compareTo(sqftArea.getStandardSqftValue().multiply(rate)));
    }
}
