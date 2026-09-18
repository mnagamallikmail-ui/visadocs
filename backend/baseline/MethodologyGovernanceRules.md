# AUTHORITATIVE METHODOLOGY GOVERNANCE RULES

**Version:** 1.0  
**Effective Date:** Immediate  
**Status:** PERMANENT BINDING SPECIFICATION  
**Scope:** Valuation Methodology Detection & Summary Table Routing

---

## 1. METHODOLOGY DETERMINATION PRINCIPLES

1. **Single Source of Truth:** Methodology is determined **exclusively** from placeholders physically scanned inside the WordprocessingML document parts (`word/document.xml`, headers, and footers).
2. **Strict Exclusion of Runtime Metadata:**
   * `VALUATION_METHODOLOGY` in input maps or requests is completely ignored for template routing.
   * `PROPERTY_CATEGORY` or `PROPERTY_TYPE` is completely ignored for template routing.
   * Order metadata, repository state, and raw JSON payloads are completely ignored for template routing.
3. **No Dynamic Hijacking:** A template containing Land directives will **never** be dynamically mutated or hijacked to render Composite tables or Composite summaries, regardless of runtime inputs.

---

## 2. METHODOLOGY DETECTION LOGIC

```
Placeholders Scanned:
  hasComposite     = contains(COMPOSITE_PROPERTY_TABLE | DYNAMIC_COMPOSITE_PROPERTY_TABLE | COMPOSITE_TABLE)
  hasBuilding      = contains(BUILDING_TABLE | DYNAMIC_BUILDING_TABLE)
  hasPropertyValue = contains(VALUE_OF_PROPERTY_TABLE | PROPERTY_VALUE_TABLE | VALUE_OF_THE_PROPERTY_TABLE)
  hasLand          = contains(LAND_TABLE | DYNAMIC_LAND_TABLE)

Detection Resolution:
  IF hasComposite:
      RETURN TemplateMethodology.COMPOSITE (FLAT_APARTMENT)
  ELSE IF (hasBuilding OR hasPropertyValue):
      RETURN TemplateMethodology.LAND_AND_BUILDING
  ELSE IF hasLand:
      RETURN TemplateMethodology.LAND_ONLY
  ELSE:
      RETURN TemplateMethodology.LAND_AND_BUILDING (Default Fallback)
```

---

## 3. SUMMARY ROUTING GOVERNANCE

When resolving the directive `<<VALUATION_SUMMARY_TABLE>>`:

| Detected Methodology | Method Invoked | Rendered Output | Key Components |
|---|---|---|---|
| `COMPOSITE` (`FLAT_APARTMENT`) | `buildDynamicCompositeSummaryTable()` | Valuation Parameters Summary | Fair Value, Realizable Value, Distress Sale Value, Government Value, Insurable Value |
| `LAND_ONLY` | `buildLandSummary()` | Land Valuation Summary | Land Fair Value, Land Realizable Value, Land Distress Sale Value, Land Government Value |
| `LAND_AND_BUILDING` | `buildDynamicValuationSummaryTable()` | Valuation Parameters Summary | Combined Fair Value, Realizable Value, Distress Sale Value, Government Value, Insurable Value |

---

## 4. REGRESSION VERIFICATION & NON-HIJACKING TEST
All test suites must verify that providing contradictory inputs (e.g. passing `VALUATION_METHODOLOGY=COMPOSITE` to `official_production_valuation_report.docx`) does **not** alter methodology detection or summary routing.
