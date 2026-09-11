package com.provaluer.util;

import java.util.*;

/**
 * Resolves placeholder aliases to their canonical keys and provides
 * bidirectional lookup between canonical keys and aliases.
 */
public class AliasResolutionEngine {

    public static final String CANONICAL_SALEABLE_AREA = "SALEABLE_AREA";
    public static final String CANONICAL_MARKET_RATE_FLAT = "MARKET_RATE_FLAT";

    private static final Map<String, String> ALIAS_TO_CANONICAL = new HashMap<>();
    private static final Map<String, Set<String>> CANONICAL_TO_ALIASES = new HashMap<>();

    static {
        // Area Aliases
        registerAliasGroup(CANONICAL_SALEABLE_AREA, Arrays.asList(
                "SUPER_BUILT_UP_AREA",
                "PROPERTY_AREA_SFT",
                "SBUA",
                "FLAT_AREA",
                "SALEABLE_AREA_SQFT"
        ));

        // Rate Aliases
        registerAliasGroup(CANONICAL_MARKET_RATE_FLAT, Arrays.asList(
                "COMPOSITE_RATE",
                "CURRENT_MARKET_RATE",
                "FLAT_MARKET_RATE",
                "BUILDING_MARKET_RATE"
        ));
    }

    private static void registerAliasGroup(String canonical, List<String> aliases) {
        String upperCanonical = canonical.toUpperCase();
        ALIAS_TO_CANONICAL.put(upperCanonical, upperCanonical);

        Set<String> aliasSet = CANONICAL_TO_ALIASES.computeIfAbsent(upperCanonical, k -> new LinkedHashSet<>());
        for (String alias : aliases) {
            String upperAlias = alias.toUpperCase();
            ALIAS_TO_CANONICAL.put(upperAlias, upperCanonical);
            aliasSet.add(upperAlias);
        }
    }

    /**
     * Resolves any alias to its canonical key.
     * If the key is not an alias, returns the key itself (in upper case).
     */
    public static String resolveCanonical(String key) {
        if (key == null) return null;
        String clean = key.trim().toUpperCase()
                .replaceAll("^<<", "")
                .replaceAll(">>$", "");

        String suffix = "";
        if (clean.endsWith("_RAW")) {
            clean = clean.substring(0, clean.length() - 4);
            suffix = "_RAW";
        } else if (clean.endsWith("_NUMERIC")) {
            clean = clean.substring(0, clean.length() - 8);
            suffix = "_NUMERIC";
        }

        String canonical = ALIAS_TO_CANONICAL.getOrDefault(clean, clean);
        return canonical + suffix;
    }

    /**
     * Returns the set of all aliases for the given key (resolving canonical first).
     */
    public static Set<String> getAliases(String key) {
        if (key == null) return Collections.emptySet();
        String canonical = resolveCanonical(key);
        if (canonical.endsWith("_RAW") || canonical.endsWith("_NUMERIC")) {
            canonical = canonical.replaceAll("_(RAW|NUMERIC)$", "");
        }
        return CANONICAL_TO_ALIASES.getOrDefault(canonical, Collections.emptySet());
    }

    /**
     * Returns canonical key and all aliases for a key.
     */
    public static Set<String> getAllKnownKeys(String key) {
        if (key == null) return Collections.emptySet();
        String canonical = resolveCanonical(key);
        String baseCanonical = canonical.replaceAll("_(RAW|NUMERIC)$", "");

        Set<String> all = new LinkedHashSet<>();
        all.add(baseCanonical);
        all.addAll(getAliases(baseCanonical));
        return all;
    }

    public static boolean isAliasOf(String key, String canonicalTarget) {
        if (key == null || canonicalTarget == null) return false;
        String resolvedKey = resolveCanonical(key).replaceAll("_(RAW|NUMERIC)$", "");
        String resolvedTarget = resolveCanonical(canonicalTarget).replaceAll("_(RAW|NUMERIC)$", "");
        return resolvedKey.equalsIgnoreCase(resolvedTarget);
    }
}
