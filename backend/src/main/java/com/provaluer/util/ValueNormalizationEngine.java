package com.provaluer.util;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Value Normalization Engine
 * Extracts numeric values from human-friendly inputs, identifies units,
 * calculates standardized area in Sq.Ft preserving up to 3 decimal places,
 * while maintaining backward compatibility and strict validation rules.
 */
public class ValueNormalizationEngine {

    public static final String VALIDATION_ERROR_MSG = "Numeric value could not be derived from input.";

    // Matches numbers with optional sign, optional commas, and optional decimal point
    // Negative lookbehind ensures we don't pick up trailing periods from abbreviations like "Approx."
    private static final Pattern NUMERIC_PATTERN = Pattern.compile("(?<![a-zA-Z0-9_])[-+]?(?:(?:\\d+(?:,\\d+)*)(?:\\.\\d+)?|\\.\\d+)");

    // Unit detection patterns
    private static final Pattern ACRES_PATTERN = Pattern.compile("(?i)\\b(acres?)\\b");
    private static final Pattern GROUNDS_PATTERN = Pattern.compile("(?i)\\b(grounds?)\\b");
    private static final Pattern CENTS_PATTERN = Pattern.compile("(?i)\\b(cents?)\\b");
    private static final Pattern HECTARES_PATTERN = Pattern.compile("(?i)\\b(hectares?)\\b");
    private static final Pattern SQYD_PATTERN = Pattern.compile("(?i)\\b(sq\\.?\\s*yd[s]?|square\\s+yards?)\\b");
    private static final Pattern SQM_PATTERN = Pattern.compile("(?i)\\b(sq\\.?\\s*m(?:eters?)?|square\\s+meters?)\\b");
    private static final Pattern SQFT_PATTERN = Pattern.compile("(?i)\\b(sq\\.?\\s*ft|sft|square\\s+feet|square\\s+foot)\\b");

    // Standard Sq.Ft conversion factors
    public static final BigDecimal FACTOR_ACRE = new BigDecimal("43560");
    public static final BigDecimal FACTOR_GROUND = new BigDecimal("2400");
    public static final BigDecimal FACTOR_CENT = new BigDecimal("435.6");
    public static final BigDecimal FACTOR_HECTARE = new BigDecimal("107639.104");
    public static final BigDecimal FACTOR_SQYD = new BigDecimal("9");
    public static final BigDecimal FACTOR_SQM = new BigDecimal("10.76391");
    public static final BigDecimal FACTOR_SQFT = BigDecimal.ONE;

    /**
     * Normalized Value Response Model as specified.
     */
    public static class NormalizedValue {
        private final String rawValue;
        private final BigDecimal numericValue;
        private final String detectedUnit;
        private final BigDecimal standardSqftValue;
        private final boolean valid;

        public NormalizedValue(String rawValue, BigDecimal numericValue, String detectedUnit, BigDecimal standardSqftValue, boolean valid) {
            this.rawValue = rawValue;
            this.numericValue = numericValue;
            this.detectedUnit = detectedUnit;
            this.standardSqftValue = standardSqftValue;
            this.valid = valid;
        }

        public String getRawValue() { return rawValue; }
        public BigDecimal getNumericValue() { return numericValue; }
        public String getDetectedUnit() { return detectedUnit; }
        public BigDecimal getStandardSqftValue() { return standardSqftValue; }
        public boolean isValid() { return valid; }
    }

    /**
     * Fully normalizes an area input returning NormalizedValue with detected unit and standard Sq.Ft.
     */
    public static NormalizedValue normalizeAreaValue(String input) {
        if (input == null || input.trim().isEmpty()) {
            throw new IllegalArgumentException(VALIDATION_ERROR_MSG);
        }

        BigDecimal numeric = extractNumericValue(input);
        String unit = detectAreaUnit(input);
        BigDecimal standardSqft = convertToStandardSqft(numeric, unit);

        return new NormalizedValue(input, numeric, unit, standardSqft, true);
    }

    /**
     * Detects canonical area unit from human-entered string.
     */
    public static String detectAreaUnit(String input) {
        if (input == null) return "SQFT";
        String trimmed = input.trim();

        if (ACRES_PATTERN.matcher(trimmed).find()) {
            return "ACRES";
        }
        if (SQYD_PATTERN.matcher(trimmed).find()) {
            return "SQYD";
        }
        if (SQM_PATTERN.matcher(trimmed).find()) {
            return "SQM";
        }
        if (CENTS_PATTERN.matcher(trimmed).find()) {
            return "CENTS";
        }
        if (GROUNDS_PATTERN.matcher(trimmed).find()) {
            return "GROUNDS";
        }
        if (HECTARES_PATTERN.matcher(trimmed).find()) {
            return "HECTARES";
        }
        if (SQFT_PATTERN.matcher(trimmed).find()) {
            return "SQFT";
        }
        return "SQFT";
    }

    /**
     * Converts numeric value in detected unit to Standard Area in Sq.Ft preserving up to 3 decimal places.
     */
    public static BigDecimal convertToStandardSqft(BigDecimal numericValue, String unit) {
        if (numericValue == null) return BigDecimal.ZERO;
        String u = unit != null ? unit.toUpperCase().trim() : "SQFT";

        BigDecimal standard;
        switch (u) {
            case "ACRES":
            case "ACRE":
                standard = numericValue.multiply(FACTOR_ACRE);
                break;
            case "GROUNDS":
            case "GROUND":
                standard = numericValue.multiply(FACTOR_GROUND);
                break;
            case "CENTS":
            case "CENT":
                standard = numericValue.multiply(FACTOR_CENT);
                break;
            case "HECTARES":
            case "HECTARE":
                standard = numericValue.multiply(FACTOR_HECTARE);
                break;
            case "SQYD":
            case "SQ.YD":
                standard = numericValue.multiply(FACTOR_SQYD);
                break;
            case "SQM":
            case "SQ.M":
                standard = numericValue.multiply(FACTOR_SQM);
                break;
            case "SQFT":
            case "SQ.FT":
            default:
                standard = numericValue;
                break;
        }

        return applyDecimalPrecisionGovernance(standard);
    }

    /**
     * Normalizes a raw string input for a given placeholder key.
     */
    public static BigDecimal normalize(String key, String input) {
        if (input == null || input.trim().isEmpty()) {
            throw new IllegalArgumentException(VALIDATION_ERROR_MSG);
        }

        PlaceholderNormalizationRegistry.NormalizationType type = PlaceholderNormalizationRegistry.getNormalizationType(key);
        switch (type) {
            case AREA:
                return normalizeArea(input);
            case RATE:
                return normalizeRate(input);
            case PERCENTAGE:
                return normalizePercentage(input);
            case NUMERIC:
            default:
                return normalizeNumeric(input);
        }
    }

    public static BigDecimal normalizeArea(String input) {
        return extractNumericValue(input);
    }

    public static BigDecimal normalizeRate(String input) {
        return extractNumericValue(input);
    }

    public static BigDecimal normalizePercentage(String input) {
        return extractNumericValue(input);
    }

    public static BigDecimal normalizeNumeric(String input) {
        return extractNumericValue(input);
    }

    public static BigDecimal extractNumericValue(String input) {
        if (input == null) {
            throw new IllegalArgumentException(VALIDATION_ERROR_MSG);
        }

        String trimmed = input.trim();
        if (trimmed.isEmpty()) {
            throw new IllegalArgumentException(VALIDATION_ERROR_MSG);
        }

        Matcher matcher = NUMERIC_PATTERN.matcher(trimmed);
        if (!matcher.find()) {
            throw new IllegalArgumentException(VALIDATION_ERROR_MSG);
        }

        String matchedToken = matcher.group();
        String cleanNumberStr = matchedToken.replace(",", "").trim();

        try {
            BigDecimal bd = new BigDecimal(cleanNumberStr);
            return applyDecimalPrecisionGovernance(bd);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(VALIDATION_ERROR_MSG, e);
        }
    }

    public static BigDecimal applyDecimalPrecisionGovernance(BigDecimal value) {
        if (value == null) return BigDecimal.ZERO;
        if (value.scale() > 3) {
            return value.setScale(3, RoundingMode.HALF_UP);
        }
        return value;
    }

    public static String formatNormalizedString(BigDecimal value) {
        if (value == null) return "0";
        return value.toPlainString();
    }

    public static boolean isSupported(String key) {
        return PlaceholderNormalizationRegistry.isNumericKey(key);
    }

    public static Optional<BigDecimal> tryNormalize(String key, String input) {
        try {
            return Optional.of(normalize(key, input));
        } catch (Exception e) {
            return Optional.empty();
        }
    }

    /**
     * Dual value result containing canonical keys, raw values, numeric values,
     * detected unit, standard sqft, and alias synchronizations.
     */
    public static class DualValueResult {
        private final String canonicalKey;
        private final String rawValue;
        private final BigDecimal numericValue;
        private final String detectedUnit;
        private final BigDecimal standardSqftValue;
        private final Map<String, String> valuesToStore = new LinkedHashMap<>();

        public DualValueResult(String enteredKey, String rawValue, BigDecimal numericValue) {
            this(enteredKey, rawValue, numericValue, "SQFT", numericValue);
        }

        public DualValueResult(String enteredKey, String rawValue, BigDecimal numericValue, String detectedUnit, BigDecimal standardSqftValue) {
            this.canonicalKey = AliasResolutionEngine.resolveCanonical(enteredKey);
            this.rawValue = rawValue;
            this.numericValue = numericValue;
            this.detectedUnit = detectedUnit;
            this.standardSqftValue = standardSqftValue;

            String numericStr = formatNormalizedString(numericValue);
            String stdSqftStr = standardSqftValue != null ? formatNormalizedString(standardSqftValue) : numericStr;
            boolean isArea = PlaceholderNormalizationRegistry.isAreaKey(enteredKey);

            // 1. Entered key store
            valuesToStore.put(enteredKey, rawValue);
            valuesToStore.put(enteredKey + "_RAW", rawValue);
            valuesToStore.put(enteredKey + "_NUMERIC", numericStr);
            if (isArea) {
                valuesToStore.put(enteredKey + "_UNIT", detectedUnit);
                valuesToStore.put(enteredKey + "_STANDARD_SQFT", stdSqftStr);
            }

            // 2. Canonical key store
            valuesToStore.put(canonicalKey, rawValue);
            valuesToStore.put(canonicalKey + "_RAW", rawValue);
            valuesToStore.put(canonicalKey + "_NUMERIC", numericStr);
            if (isArea) {
                valuesToStore.put(canonicalKey + "_UNIT", detectedUnit);
                valuesToStore.put(canonicalKey + "_STANDARD_SQFT", stdSqftStr);
            }

            // 3. Alias propagation
            Set<String> aliases = AliasResolutionEngine.getAliases(canonicalKey);
            for (String alias : aliases) {
                valuesToStore.put(alias, rawValue);
                valuesToStore.put(alias + "_RAW", rawValue);
                valuesToStore.put(alias + "_NUMERIC", numericStr);
                if (isArea) {
                    valuesToStore.put(alias + "_UNIT", detectedUnit);
                    valuesToStore.put(alias + "_STANDARD_SQFT", stdSqftStr);
                }
            }
        }

        public String getCanonicalKey() { return canonicalKey; }
        public String getRawValue() { return rawValue; }
        public BigDecimal getNumericValue() { return numericValue; }
        public String getDetectedUnit() { return detectedUnit; }
        public BigDecimal getStandardSqftValue() { return standardSqftValue; }
        public Map<String, String> getValuesToStore() { return Collections.unmodifiableMap(valuesToStore); }
    }

    public static DualValueResult createDualValueResult(String key, String rawInput) {
        if (PlaceholderNormalizationRegistry.isAreaKey(key)) {
            NormalizedValue norm = normalizeAreaValue(rawInput);
            return new DualValueResult(key, rawInput, norm.getNumericValue(), norm.getDetectedUnit(), norm.getStandardSqftValue());
        }
        BigDecimal numeric = normalize(key, rawInput);
        return new DualValueResult(key, rawInput, numeric, "SQFT", numeric);
    }
}
