package com.provaluer.service;

import com.provaluer.util.ValueNormalizationEngine;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

public class DependencyIntegrationTest {

    private final FormulaExpressionEngine formulaEngine = new FormulaExpressionEngine();

    @Test
    @DisplayName("Dual Value Model generates raw and numeric pairs across canonical keys and aliases")
    public void testDualValueGeneration() {
        ValueNormalizationEngine.DualValueResult areaResult = 
                ValueNormalizationEngine.createDualValueResult("SUPER_BUILT_UP_AREA", "1000.125 sq.ft");
        Map<String, String> values = areaResult.getValuesToStore();

        assertEquals("1000.125 sq.ft", values.get("SUPER_BUILT_UP_AREA"));
        assertEquals("1000.125 sq.ft", values.get("SUPER_BUILT_UP_AREA_RAW"));
        assertEquals("1000.125", values.get("SUPER_BUILT_UP_AREA_NUMERIC"));

        assertEquals("1000.125 sq.ft", values.get("SALEABLE_AREA"));
        assertEquals("1000.125 sq.ft", values.get("SALEABLE_AREA_RAW"));
        assertEquals("1000.125", values.get("SALEABLE_AREA_NUMERIC"));

        assertEquals("1000.125 sq.ft", values.get("SBUA"));
        assertEquals("1000.125", values.get("SBUA_NUMERIC"));
    }

    @Test
    @DisplayName("FormulaExpressionEngine correctly evaluates expressions with human-friendly units in row values")
    public void testFormulaEvaluationWithHumanFriendlyInputs() {
        // formula: {col_0} * {col_1}
        // col_0: "1000 sq.ft"
        // col_1: "Rs. 5000"
        double result1 = formulaEngine.evaluateRowFormula("{col_0} * {col_1}", List.of("1000 sq.ft", "Rs. 5000"), 2);
        assertEquals(5000000.0, result1, 0.001);

        // col_0: "1200 sqft"
        // col_1: "INR 6000"
        double result2 = formulaEngine.evaluateRowFormula("{col_0} * {col_1}", List.of("1200 sqft", "INR 6000"), 2);
        assertEquals(7200000.0, result2, 0.001);

        // 3-decimal precision test: "1000.125 sq.ft" * "Rs 5000.250"
        double result3 = formulaEngine.evaluateRowFormula("{col_0} * {col_1}", List.of("1000.125 sq.ft", "Rs 5000.250"), 2);
        assertEquals(5000875.03125, result3, 0.00001);
    }

    @Test
    @DisplayName("Composite dependency: UNIT_AMOUNT calculation never consumes raw string directly, only numeric")
    public void testCompositeDependencyCalculation() {
        String rawArea = "1000 sq.ft";
        String rawRate = "Rs 5000 per sq.ft";

        BigDecimal numericArea = ValueNormalizationEngine.normalize("SALEABLE_AREA", rawArea);
        BigDecimal numericRate = ValueNormalizationEngine.normalize("MARKET_RATE_FLAT", rawRate);

        BigDecimal unitAmount = numericArea.multiply(numericRate);
        assertEquals(0, new BigDecimal("5000000").compareTo(unitAmount));
    }
}
