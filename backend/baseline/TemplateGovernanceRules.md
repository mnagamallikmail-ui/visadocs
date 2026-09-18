# AUTHORITATIVE TEMPLATE GOVERNANCE RULES

**Version:** 1.0  
**Effective Date:** Immediate  
**Status:** PERMANENT BINDING SPECIFICATION  
**Scope:** Physical Template Catalog & Template Upload Pipeline

---

## 1. CANONICAL PRODUCTION TEMPLATE CATALOG

The physical template library consists of three authoritative canonical production templates:

| Template Name | Valuation Methodology | Required Table Directives | Prohibited Directives |
|---|---|---|---|
| `official_production_valuation_report.docx` | `LAND_AND_BUILDING` | `<<LAND_TABLE>>`<br>`<<BUILDING_TABLE>>`<br>`<<VALUE_OF_PROPERTY_TABLE>>`<br>`<<VALUATION_SUMMARY_TABLE>>` | `<<COMPOSITE_PROPERTY_TABLE>>` |
| `official_flat_apartment_valuation_report.docx` | `FLAT_APARTMENT` (`COMPOSITE`) | `<<COMPOSITE_PROPERTY_TABLE>>`<br>`<<VALUATION_SUMMARY_TABLE>>` | `<<LAND_TABLE>>`<br>`<<BUILDING_TABLE>>`<br>`<<VALUE_OF_PROPERTY_TABLE>>` |
| `official_land_valuation_report.docx` | `LAND_ONLY` | `<<LAND_TABLE>>`<br>`<<VALUATION_SUMMARY_TABLE>>` | `<<BUILDING_TABLE>>`<br>`<<VALUE_OF_PROPERTY_TABLE>>`<br>`<<COMPOSITE_PROPERTY_TABLE>>` |

---

## 2. VALUATION SECTION ELEMENT SEQUENCING

### Land + Building Sequential Layout (Section 7)
In `official_production_valuation_report.docx`, valuation tables must follow this exact physical sequence:
1. Heading 7.6 (`Value of the property`)
2. `<<LAND_TABLE>>`
3. `<<BUILDING_TABLE>>`
4. `<<VALUE_OF_PROPERTY_TABLE>>`
5. `<<VALUATION_SUMMARY_TABLE>>`

### Flat / Apartment Sequential Layout (Section 7)
In `official_flat_apartment_valuation_report.docx`, valuation tables must follow this exact physical sequence:
1. Heading 7.6 (`Value of the property`)
2. `<<COMPOSITE_PROPERTY_TABLE>>`
3. `<<VALUATION_SUMMARY_TABLE>>`

### Land Only Sequential Layout (Section 7)
In `official_land_valuation_report.docx`, valuation tables must follow this exact physical sequence:
1. Heading 7.6 (`Value of the property`)
2. `<<LAND_TABLE>>`
3. `<<VALUATION_SUMMARY_TABLE>>`

---

## 3. TEMPLATE UPLOAD GOVERNANCE RULES (MANDATORY VALIDATION F)

During template upload (and revision upload via `TemplateProcessingService.validateDocxPackage`), the package is validated against 5 mandatory rules:

* **UPLOAD RULE 1 (Exclusivity Enforcement):**  
  `COMPOSITE_PROPERTY_TABLE` cannot coexist with `LAND_TABLE`, `BUILDING_TABLE`, or `VALUE_OF_PROPERTY_TABLE`. Any co-mingling causes immediate upload rejection (`IllegalArgumentException`).

* **UPLOAD RULE 2 (Dependency Enforcement):**  
  `VALUE_OF_PROPERTY_TABLE` strictly requires both `LAND_TABLE` and `BUILDING_TABLE`. It cannot exist in isolation.

* **UPLOAD RULE 3 (Summary Table Mandate):**  
  Every valuation template must contain `<<VALUATION_SUMMARY_TABLE>>`.

* **UPLOAD RULE 4 (Methodology Singularity):**  
  Every template must resolve to exactly one valuation methodology (`LAND_ONLY`, `LAND_AND_BUILDING`, or `FLAT_APARTMENT`).

* **UPLOAD RULE 5 (Ambiguity Prohibition):**  
  Upload must fail if the placeholder configuration cannot resolve to an unambiguous methodology.

---

## 4. IMMUTABILITY & VERSIONING GOVERNANCE

* **Option A Binary Immutability:** Updating metadata in the database never alters or mutates the physical bytes of the uploaded `.docx` template.
* **Disaster Recovery Recoverability:** Every canonical production template has an identical baseline mirror in `backend/baseline/`.
