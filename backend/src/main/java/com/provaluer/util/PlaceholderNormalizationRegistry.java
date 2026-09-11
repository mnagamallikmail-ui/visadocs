package com.provaluer.util;

import java.util.*;

/**
 * Registry defining normalization categories for valuation placeholders.
 */
public class PlaceholderNormalizationRegistry {

    public enum NormalizationType {
        AREA,
        RATE,
        PERCENTAGE,
        NUMERIC,
        TEXT
    }

    private static final Set<String> AREA_KEYS = new HashSet<>(Arrays.asList(
            "SALEABLE_AREA",
            "SUPER_BUILT_UP_AREA",
            "PROPERTY_AREA_SFT",
            "SBUA",
            "FLAT_AREA",
            "LAND_AREA",
            "PLOT_AREA",
            "BUILTUP_AREA",
            "SALEABLE_AREA_SQFT"
    ));

    private static final Set<String> RATE_KEYS = new HashSet<>(Arrays.asList(
            "MARKET_RATE_FLAT",
            "COMPOSITE_RATE",
            "CURRENT_MARKET_RATE",
            "FLAT_MARKET_RATE",
            "BUILDING_MARKET_RATE",
            "LAND_RATE",
            "GOVERNMENT_RATE",
            "GUIDELINE_RATE",
            "COMPOSITE_GOVERNMENT_RATE",
            "REPLACEMENT_COST",
            "REPLACEMENT_RATE"
    ));

    private static final Set<String> PERCENTAGE_KEYS = new HashSet<>(Arrays.asList(
            "REALIZABLE_PERCENTAGE",
            "DISTRESS_SALE_PERCENTAGE",
            "LAND_REALIZABLE_PERCENTAGE",
            "BUILDING_REALIZABLE_PERCENTAGE",
            "LAND_DISTRESS_PERCENTAGE",
            "BUILDING_DISTRESS_PERCENTAGE",
            "DEFAULT_SALVAGE_PERCENTAGE",
            "SALVAGE_PERCENTAGE",
            "COMPOSITE_BUILDING_DEPRECIATION_PCT",
            "DEPRECIATION_PERCENTAGE"
    ));

    private static final Set<String> NUMERIC_KEYS = new HashSet<>(Arrays.asList(
            "TOTAL_LIFE",
            "BUILDING_AGE",
            "COMPOSITE_BUILDING_AGE",
            "COMPOSITE_BUILDING_TOTAL_LIFE",
            "GOVERNMENT_VALUE",
            "COMPOSITE_CONSTRUCTION_COST",
            "SAY_VALUE",
            "FAIR_VALUE",
            "REALIZABLE_VALUE",
            "DISTRESS_SALE_VALUE",
            "INSURABLE_VALUE"
    ));

    public static NormalizationType getNormalizationType(String key) {
        if (key == null) return NormalizationType.TEXT;
        String cleanKey = key.trim().toUpperCase()
                .replaceAll("^<<", "")
                .replaceAll(">>$", "")
                .replaceAll("_(RAW|NUMERIC)$", "");

        if (AREA_KEYS.contains(cleanKey)) {
            return NormalizationType.AREA;
        }
        if (RATE_KEYS.contains(cleanKey)) {
            return NormalizationType.RATE;
        }
        if (PERCENTAGE_KEYS.contains(cleanKey)) {
            return NormalizationType.PERCENTAGE;
        }
        if (NUMERIC_KEYS.contains(cleanKey)) {
            return NormalizationType.NUMERIC;
        }
        return NormalizationType.TEXT;
    }

    public static boolean isAreaKey(String key) {
        return getNormalizationType(key) == NormalizationType.AREA;
    }

    public static boolean isRateKey(String key) {
        return getNormalizationType(key) == NormalizationType.RATE;
    }

    public static boolean isPercentageKey(String key) {
        return getNormalizationType(key) == NormalizationType.PERCENTAGE;
    }

    public static boolean isNumericKey(String key) {
        NormalizationType type = getNormalizationType(key);
        return type == NormalizationType.AREA || type == NormalizationType.RATE
                || type == NormalizationType.PERCENTAGE || type == NormalizationType.NUMERIC;
    }

    public static Set<String> getAreaKeys() {
        return Collections.unmodifiableSet(AREA_KEYS);
    }

    public static Set<String> getRateKeys() {
        return Collections.unmodifiableSet(RATE_KEYS);
    }

    public static Set<String> getPercentageKeys() {
        return Collections.unmodifiableSet(PERCENTAGE_KEYS);
    }
}
