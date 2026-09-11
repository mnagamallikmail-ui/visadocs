package com.provaluer.service;

import com.provaluer.util.AliasResolutionEngine;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

public class AliasResolutionEngineTest {

    @Test
    @DisplayName("Alias Resolution maps all area aliases to canonical SALEABLE_AREA")
    public void testAreaAliasResolution() {
        assertEquals("SALEABLE_AREA", AliasResolutionEngine.resolveCanonical("SUPER_BUILT_UP_AREA"));
        assertEquals("SALEABLE_AREA", AliasResolutionEngine.resolveCanonical("PROPERTY_AREA_SFT"));
        assertEquals("SALEABLE_AREA", AliasResolutionEngine.resolveCanonical("SBUA"));
        assertEquals("SALEABLE_AREA", AliasResolutionEngine.resolveCanonical("FLAT_AREA"));
        assertEquals("SALEABLE_AREA", AliasResolutionEngine.resolveCanonical("SALEABLE_AREA_SQFT"));
        assertEquals("SALEABLE_AREA", AliasResolutionEngine.resolveCanonical("SALEABLE_AREA"));
    }

    @Test
    @DisplayName("Alias Resolution maps all rate aliases to canonical MARKET_RATE_FLAT")
    public void testRateAliasResolution() {
        assertEquals("MARKET_RATE_FLAT", AliasResolutionEngine.resolveCanonical("COMPOSITE_RATE"));
        assertEquals("MARKET_RATE_FLAT", AliasResolutionEngine.resolveCanonical("CURRENT_MARKET_RATE"));
        assertEquals("MARKET_RATE_FLAT", AliasResolutionEngine.resolveCanonical("FLAT_MARKET_RATE"));
        assertEquals("MARKET_RATE_FLAT", AliasResolutionEngine.resolveCanonical("BUILDING_MARKET_RATE"));
        assertEquals("MARKET_RATE_FLAT", AliasResolutionEngine.resolveCanonical("MARKET_RATE_FLAT"));
    }

    @Test
    @DisplayName("Alias Resolution preserves _RAW and _NUMERIC suffixes")
    public void testSuffixPreservation() {
        assertEquals("SALEABLE_AREA_RAW", AliasResolutionEngine.resolveCanonical("SUPER_BUILT_UP_AREA_RAW"));
        assertEquals("SALEABLE_AREA_NUMERIC", AliasResolutionEngine.resolveCanonical("SBUA_NUMERIC"));
        assertEquals("MARKET_RATE_FLAT_RAW", AliasResolutionEngine.resolveCanonical("COMPOSITE_RATE_RAW"));
        assertEquals("MARKET_RATE_FLAT_NUMERIC", AliasResolutionEngine.resolveCanonical("CURRENT_MARKET_RATE_NUMERIC"));
    }

    @Test
    @DisplayName("Retrieval of all aliases and known keys for a canonical group")
    public void testAliasGroupRetrieval() {
        Set<String> areaAliases = AliasResolutionEngine.getAliases("SALEABLE_AREA");
        assertTrue(areaAliases.contains("SUPER_BUILT_UP_AREA"));
        assertTrue(areaAliases.contains("PROPERTY_AREA_SFT"));
        assertTrue(areaAliases.contains("SBUA"));
        assertTrue(areaAliases.contains("FLAT_AREA"));
        assertTrue(areaAliases.contains("SALEABLE_AREA_SQFT"));

        Set<String> rateAliases = AliasResolutionEngine.getAliases("MARKET_RATE_FLAT");
        assertTrue(rateAliases.contains("COMPOSITE_RATE"));
        assertTrue(rateAliases.contains("CURRENT_MARKET_RATE"));
        assertTrue(rateAliases.contains("FLAT_MARKET_RATE"));
        assertTrue(rateAliases.contains("BUILDING_MARKET_RATE"));
    }
}
