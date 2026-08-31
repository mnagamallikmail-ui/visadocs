package com.provaluer.util;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class UnitConversionEngine {

    // Default conversion factors to standard Sq.Ft
    private static final Map<String, BigDecimal> UNIT_FACTORS = new ConcurrentHashMap<>();

    static {
        UNIT_FACTORS.put("SQ.FT", new BigDecimal("1.000000"));
        UNIT_FACTORS.put("SQFT", new BigDecimal("1.000000"));
        UNIT_FACTORS.put("SQ.FT.", new BigDecimal("1.000000"));
        UNIT_FACTORS.put("SQ.M", new BigDecimal("10.763910"));
        UNIT_FACTORS.put("SQM", new BigDecimal("10.763910"));
        UNIT_FACTORS.put("SQ.M.", new BigDecimal("10.763910"));
        UNIT_FACTORS.put("SQ.YD", new BigDecimal("9.000000"));
        UNIT_FACTORS.put("SQYD", new BigDecimal("9.000000"));
        UNIT_FACTORS.put("SQ.YD.", new BigDecimal("9.000000"));
        UNIT_FACTORS.put("ACRES", new BigDecimal("43560.000000"));
        UNIT_FACTORS.put("ACRE", new BigDecimal("43560.000000"));
        UNIT_FACTORS.put("CENTS", new BigDecimal("435.600000"));
        UNIT_FACTORS.put("CENT", new BigDecimal("435.600000"));
        UNIT_FACTORS.put("GROUNDS", new BigDecimal("2400.000000"));
        UNIT_FACTORS.put("GROUND", new BigDecimal("2400.000000"));
        UNIT_FACTORS.put("HECTARES", new BigDecimal("107639.104000"));
        UNIT_FACTORS.put("HECTARE", new BigDecimal("107639.104000"));
    }

    public static BigDecimal getConversionFactor(String unitName) {
        if (unitName == null || unitName.trim().isEmpty()) {
            return BigDecimal.ONE;
        }
        String key = unitName.trim().toUpperCase();
        return UNIT_FACTORS.getOrDefault(key, BigDecimal.ONE);
    }

    public static void registerFactor(String unitName, BigDecimal factor) {
        if (unitName != null && factor != null) {
            UNIT_FACTORS.put(unitName.trim().toUpperCase(), factor);
        }
    }

    /**
     * Converts entered area in a specific unit to standard Square Feet.
     */
    public static BigDecimal toStandardSqFt(BigDecimal enteredArea, String enteredUnit) {
        if (enteredArea == null) return BigDecimal.ZERO;
        BigDecimal factor = getConversionFactor(enteredUnit);
        return enteredArea.multiply(factor).setScale(4, RoundingMode.HALF_UP);
    }
}
