package com.provaluer.util;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.zip.CRC32;

/**
 * Normalizer and manager for generic placeholders (<<TEXT>>, <<NUMBER>>, <<DATE>>, <<IMAGE>>, <<CHECKBOX>>).
 * Automatically resolves question labels from table cells and converts them into unique, deterministic keys
 * while preserving master/global placeholders.
 */
public class GenericPlaceholderNormalizer {

    public static final Set<String> GENERIC_TOKENS = Set.of(
            "TEXT", "NUMBER", "DATE", "IMAGE", "CHECKBOX", "MULTILINE"
    );

    public static final Set<String> MASTER_PLACEHOLDERS = Set.of(
            "REPORT_DATE",
            "REPORT_NO",
            "PROPERTY_DESCRIPTION",
            "PROPERTY_ADDRESS",
            "NAME_OF_THE_OWNER",
            "FAIR_VALUE",
            "REALIZABLE_VALUE",
            "DISTRESS_SALE_VALUE",
            "LAND_AREA",
            "PLINTH_AREA"
    );

    private static final Pattern LEADING_BULLET_PATTERN = Pattern.compile("^(?:(?:[\\-\\•\\*]|(?:\\d+|[a-zA-Z])[\\.\\)\\-])\\s*)+");
    private static final Pattern YES_NO_PATTERN = Pattern.compile("(?i)\\b(yes\\s*/\\s*no|yes/no)\\b");

    /**
     * Checks if a token matches one of the extensible generic placeholder tokens.
     */
    public static boolean isGenericPlaceholder(String token) {
        if (token == null) return false;
        String clean = token.replaceAll("[<>\\s]", "").toUpperCase();
        return GENERIC_TOKENS.contains(clean);
    }

    /**
     * Checks if a token is a master placeholder that must never be altered or deduplicated.
     */
    public static boolean isMasterPlaceholder(String token) {
        if (token == null) return false;
        String clean = token.replaceAll("[<>\\s]", "").toUpperCase();
        return MASTER_PLACEHOLDERS.contains(clean);
    }

    /**
     * Returns the generic token type (e.g. TEXT, NUMBER, DATE, IMAGE, CHECKBOX) or null if not generic.
     */
    public static String extractGenericType(String token) {
        if (token == null) return null;
        String clean = token.replaceAll("[<>\\s]", "").toUpperCase();
        return GENERIC_TOKENS.contains(clean) ? clean : null;
    }

    /**
     * Converts raw question text and occurrence index into a deterministic, human-readable key with consistent numbering.
     * Example:
     *   ("Layout Plan (Yes / No), if yes mention approval number", 1) -> "LAYOUT_PLAN_YES_NO_1"
     *   ("Building Plan (Yes / No)", 1) -> "BUILDING_PLAN_YES_NO_1"
     *   ("Remarks", 1) -> "REMARKS_1"
     *   ("Remarks", 2) -> "REMARKS_2"
     *   ("Remarks", 3) -> "REMARKS_3"
     */
    public static String normalizeQuestionToKey(String rawQuestionText, int occurrenceIndex) {
        String baseSlug = generateBaseSlug(rawQuestionText);
        return baseSlug + "_" + occurrenceIndex;
    }

    /**
     * Generates a clean, upper-case alphanumeric slug from arbitrary question text.
     */
    public static String generateBaseSlug(String raw) {
        if (raw == null || raw.trim().isEmpty()) {
            return "FIELD";
        }

        String text = raw.trim();

        // 1. Strip leading numbering or bullets like "14.b) ", "1. ", "a) ", "- "
        Matcher bulletMatcher = LEADING_BULLET_PATTERN.matcher(text);
        if (bulletMatcher.find()) {
            text = text.substring(bulletMatcher.end()).trim();
        }

        // 2. Standardize common phrases (e.g. Yes / No -> YES_NO)
        text = YES_NO_PATTERN.matcher(text).replaceAll("YES_NO");

        // 3. Replace all non-alphanumeric characters with underscores
        text = text.replaceAll("[^a-zA-Z0-9]+", "_");

        // 4. Collapse consecutive underscores and trim
        text = text.replaceAll("_+", "_");
        text = text.replaceAll("^_|_$", "").toUpperCase(Locale.ROOT);

        if (text.isEmpty()) {
            return "FIELD";
        }

        // 5. Length bounding (cap at 60 chars so key with suffix easily fits standard DB & display constraints)
        if (text.length() > 60) {
            String prefix = text.substring(0, 60);
            // Snap to last underscore if possible
            int lastUnderscore = prefix.lastIndexOf('_');
            if (lastUnderscore >= 20) {
                prefix = prefix.substring(0, lastUnderscore);
            }
            CRC32 crc = new CRC32();
            crc.update(raw.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            String hashTail = String.format("%04X", (crc.getValue() & 0xFFFF));
            text = prefix + "_" + hashTail;
        }

        return text;
    }

    /**
     * Data holder for a normalized placeholder substitution.
     */
    public static class NormalizedField {
        private final String key;
        private final String originalQuestionText;
        private final String genericType;
        private final int occurrenceIndex;
        private final String cellContext;

        public NormalizedField(String key, String originalQuestionText, String genericType, int occurrenceIndex, String cellContext) {
            this.key = key;
            this.originalQuestionText = originalQuestionText;
            this.genericType = genericType;
            this.occurrenceIndex = occurrenceIndex;
            this.cellContext = cellContext;
        }

        public String getKey() { return key; }
        public String getOriginalQuestionText() { return originalQuestionText; }
        public String getGenericType() { return genericType; }
        public int getOccurrenceIndex() { return occurrenceIndex; }
        public String getCellContext() { return cellContext; }
    }

    /**
     * Report summarizing the analysis of generic placeholders in a template.
     */
    public static class TemplateAnalysisReport {
        private int totalGeneratedFields = 0;
        private final Map<String, Integer> fieldsByType = new LinkedHashMap<>();
        private final Map<String, List<String>> duplicateQuestions = new LinkedHashMap<>();
        private final Set<String> masterPlaceholders = new LinkedHashSet<>();
        private final List<NormalizedField> generatedFields = new ArrayList<>();

        public void recordGeneratedField(NormalizedField field, String baseSlug) {
            generatedFields.add(field);
            totalGeneratedFields++;
            fieldsByType.merge(field.getGenericType(), 1, Integer::sum);

            duplicateQuestions.computeIfAbsent(baseSlug, k -> new ArrayList<>()).add(field.getKey());
        }

        public void recordMasterPlaceholder(String masterKey) {
            masterPlaceholders.add(masterKey);
        }

        public int getTotalGeneratedFields() { return totalGeneratedFields; }
        public Map<String, Integer> getFieldsByType() { return Collections.unmodifiableMap(fieldsByType); }
        public Set<String> getMasterPlaceholders() { return Collections.unmodifiableSet(masterPlaceholders); }
        public List<NormalizedField> getGeneratedFields() { return Collections.unmodifiableList(generatedFields); }

        /**
         * Maps generated placeholder keys to their authoritative original generic types
         * (Priority 0 Governance: Original Placeholder Type strictly wins over generated slugs).
         */
        public Map<String, String> toExplicitTypeOverrides() {
            Map<String, String> overrides = new LinkedHashMap<>();
            for (NormalizedField field : generatedFields) {
                if (field.getKey() != null && field.getGenericType() != null) {
                    overrides.put(field.getKey().toUpperCase().trim(), field.getGenericType().toUpperCase().trim());
                }
            }
            return Collections.unmodifiableMap(overrides);
        }

        /**
         * Produces the structured text report for logs and debugging.
         */
        public String toFormattedReport() {
            StringBuilder sb = new StringBuilder();
            sb.append("\n=======================================================\n");
            sb.append("Template Analysis Report\n");
            sb.append("=======================================================\n");
            sb.append("Generated Fields: ").append(totalGeneratedFields).append("\n\n");

            for (Map.Entry<String, Integer> entry : fieldsByType.entrySet()) {
                sb.append(entry.getKey()).append(" Fields: ").append(entry.getValue()).append("\n");
            }

            // Report duplicate questions
            boolean hasDuplicates = false;
            StringBuilder dupSb = new StringBuilder();
            for (Map.Entry<String, List<String>> entry : duplicateQuestions.entrySet()) {
                if (entry.getValue().size() > 1) {
                    hasDuplicates = true;
                    dupSb.append("\n").append(entry.getKey()).append(" (")
                          .append(entry.getValue().size()).append(" occurrences):\n");
                    for (String key : entry.getValue()) {
                        dupSb.append("  → ").append(key).append("\n");
                    }
                }
            }

            if (hasDuplicates) {
                sb.append("\nDuplicate Questions:").append(dupSb);
            }

            if (!masterPlaceholders.isEmpty()) {
                sb.append("\nMaster Placeholders Preserved:\n");
                for (String master : masterPlaceholders) {
                    sb.append("  • ").append(master).append("\n");
                }
            }
            sb.append("=======================================================\n");
            return sb.toString();
        }
    }
}
