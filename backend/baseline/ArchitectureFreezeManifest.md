# ARCHITECTURE FREEZE MANIFEST & GOVERNANCE COMPLIANCE SEAL

**Document Version:** 1.0  
**Status:** FROZEN & PERMANENTLY BINDING  
**Freeze Effective Date:** September 18, 2026  
**Seal Authority:** ProValuer Core Valuation Engine Architecture Governance Board  

---

## 1. FINAL METHODOLOGY DEFINITIONS

The Report Generation and Valuation Engine recognizes exactly three distinct, non-overlapping valuation methodologies:

1. **`LAND_ONLY`**:
   * **Required Directive:** `<<LAND_TABLE>>`
   * **Required Summary:** `<<VALUATION_SUMMARY_TABLE>>`
   * **Prohibited Directives:** `<<BUILDING_TABLE>>`, `<<VALUE_OF_PROPERTY_TABLE>>`, `<<COMPOSITE_PROPERTY_TABLE>>`
   * **Scope:** Open land parcels, plots, agricultural or non-agricultural vacant sites.

2. **`LAND_AND_BUILDING`**:
   * **Required Directives (in strict sequence):**
     1. `<<LAND_TABLE>>`
     2. `<<BUILDING_TABLE>>`
     3. `<<VALUE_OF_PROPERTY_TABLE>>` (MANDATORY)
     4. `<<VALUATION_SUMMARY_TABLE>>`
   * **Prohibited Directive:** `<<COMPOSITE_PROPERTY_TABLE>>`
   * **Scope:** Independent residential houses, villas, industrial sheds, commercial buildings, institutional properties.

3. **`FLAT_APARTMENT` (`COMPOSITE`)**:
   * **Required Directive:** `<<COMPOSITE_PROPERTY_TABLE>>`
   * **Required Summary:** `<<VALUATION_SUMMARY_TABLE>>`
   * **Prohibited Directives:** `<<LAND_TABLE>>`, `<<BUILDING_TABLE>>`, `<<VALUE_OF_PROPERTY_TABLE>>`
   * **Scope:** Residential flats/apartments, commercial office units, retail units, builder floors.

---

## 2. FINAL TEMPLATE STRUCTURES

Section 7 (Valuation of Property) layouts are permanently frozen as follows:

* **Land + Building Layout (`official_production_valuation_report.docx`):**
  * Heading 7.6 (`Value of the property`)
  * `<<LAND_TABLE>>` (Table 1)
  * `<<BUILDING_TABLE>>` (Table 2)
  * `<<VALUE_OF_PROPERTY_TABLE>>` (Table 3: Total Fair Value = Land + Building)
  * `<<VALUATION_SUMMARY_TABLE>>` (Table 4: Summary Table with Land, Building, and Total columns)

* **Flat / Apartment Layout (`official_flat_apartment_valuation_report.docx`):**
  * Heading 7.6 (`Value of the property`)
  * `<<COMPOSITE_PROPERTY_TABLE>>` (Composite Rate Valuation Table)
  * `<<VALUATION_SUMMARY_TABLE>>` (Parameters Summary Table)

* **Land Only Layout (`official_land_valuation_report.docx`):**
  * Heading 7.6 (`Value of the property`)
  * `<<LAND_TABLE>>`
  * `<<VALUATION_SUMMARY_TABLE>>` (Land Valuation Summary)

---

## 3. SUMMARY ROUTING RULES

Methodology is determined **ONLY** by the physical table directives present in the template. Runtime order inputs (`Property Type`, `Property Category`, `VALUATION_METHODOLOGY`) are prohibited from altering summary routing:

* If `TemplateMethodology == LAND_ONLY` $\rightarrow$ invoke `buildLandSummary(inputs)`
* If `TemplateMethodology == LAND_AND_BUILDING` $\rightarrow$ invoke `buildDynamicValuationSummaryTable(inputs)`
* If `TemplateMethodology == COMPOSITE` $\rightarrow$ invoke `buildDynamicCompositeSummaryTable(inputs)`

---

## 4. TEMPLATE UPLOAD RULES (VALIDATION F)

During template upload and revision (`TemplateProcessingService.validateDocxPackage`), five mandatory rules are strictly enforced:

* **Upload Rule 1 (Exclusivity Enforcement):** `COMPOSITE_PROPERTY_TABLE` cannot coexist with `LAND_TABLE`, `BUILDING_TABLE`, or `VALUE_OF_PROPERTY_TABLE`.
* **Upload Rule 2 (Dependency Enforcement):** `VALUE_OF_PROPERTY_TABLE` strictly requires both `LAND_TABLE` and `BUILDING_TABLE`.
* **Upload Rule 3 (Summary Table Mandate):** Every valuation template must contain `<<VALUATION_SUMMARY_TABLE>>`.
* **Upload Rule 4 (Methodology Singularity):** Every template must resolve to exactly one unambiguous valuation methodology.
* **Upload Rule 5 (Ambiguity Prohibition):** Any template with ambiguous or contradictory table configurations is immediately rejected.

---

## 5. RENDERING RULES

* **Dynamic Table Insertion:** Dynamic valuation and summary tables are inserted immediately after their respective directive paragraphs, inheriting template cell borders, fonts, and shading.
* **CantSplit Protection:** Multi-row photo grid and dynamic summary tables enforce `<w:cantSplit/>` on table rows to prevent intra-element page splits.
* **Container Bounds & Padding:** Uploaded images are padded to fit target placeholder bounding boxes while maintaining camera sensor aspect ratio (max dimension 1600px).
* **Elimination of Golden Parity:** Output validation is performed strictly against structural invariants, schema correctness, and business rules. No DOCX or PDF file is used as a golden comparison baseline.

---

## 6. PLACEHOLDER RULES

* **Hard-Stop TEXT Rule:** Placeholders starting with `TEXT`, `TEXT_`, `TXT`, `TXT_` are permanently classified as `TEXT`. They are never inferred as `DATE` or `IMAGE`.
* **Prefix Rule:** Only keys prefixed with `IMG_` or `IMAGE_` qualify as `IMAGE`.
* **Address Preservation:** `PROPERTY_ADDRESS` and `property_address` must never be overwritten with empty strings or default placeholders during payload generation.
* **Rate Alias Support:** Valuation rate aliases (`COMPOSITE_GOVT_RATE`, `govt_composite_rate`, `govt_rate`) remain fully supported across database syncing and report rendering.
* **Zero Phantom Directives:** Generated reports must contain 0 unhydrated `<<...>>` placeholders.

---

## 7. CALCULATION RULES

* **Property Fair Value Equation:**  
  $$\text{PROPERTY FAIR VALUE} = \text{LAND FAIR VALUE} + \text{BUILDING FAIR VALUE}$$
* **Realizable Percentage Independence:**  
  $$\text{Total Realizable} = (\text{Land Value} \times \text{Land Realizable \%}) + (\text{Building Value} \times \text{Building Realizable \%})$$
* **Distress Percentage Independence:**  
  $$\text{Total Distress} = (\text{Land Value} \times \text{Land Distress \%}) + (\text{Building Value} \times \text{Building Distress \%})$$
* **Rounding Approach A (HALF_UP):**
  * Values $< 1\text{ Crore}$ round to the nearest ₹1,000.
  * Values $\ge 1\text{ Crore}$ round to the nearest ₹10,000.
  * Government Value and Fair Value are exact and never rounded.
* **Currency Formatting:** All financial amounts format in Indian numbering format with `'Rs '` prefix.

---

## 8. PHOTO RULES

* **TOC Isolation:** Image paragraphs and photo grids must never be styled with Heading styles (`Heading 1`, `Heading 2`, `Heading 3`) and must never contain `_Toc*` bookmarks.
* **Section Confinement:** Site photographs (`IMG_PIC1` through `IMG_PIC8`) must render solely inside Section 8 ("Property Photographs").
* **Cover Photo:** The cover photograph (`IMG_FRONT_PAGE`) renders on Page 1 within its dedicated drawing container.

---

## 9. GOVERNANCE DOCUMENTS

The canonical sources of truth residing under `backend/baseline/` are:
1. `BusinessGovernanceRules.md`
2. `TemplateGovernanceRules.md`
3. `MethodologyGovernanceRules.md`
4. `RenderingCertificationRules.md`
5. `PlaceholderGovernanceRules.md`
6. `CalculationGovernanceRules.md`
7. `ArchitectureFreezeManifest.md` (This document)

---

## 10. CERTIFICATION SUITES

The seven official certification test suites enforcing this freeze:
1. `TemplateGovernanceCertificationTest`
2. `TemplateLibraryCertificationTest`
3. `FreezeGovernanceCertificationTest`
4. `ProductionRegressionCertificationTest`
5. `RegressionRemediationValidationTest`
6. `RealTemplateCertificationTest`
7. `DisasterRecoveryCertificationTest`

---

## 11. RULE TRACEABILITY MATRIX

| Rule ID | Rule Description | Baseline Source | Test Suite | Test Method | Pass/Fail |
|---|---|---|---|---|---|
| **Rule 1** | Template is Single Source of Truth | `BusinessGovernanceRules.md` | `TemplateGovernanceCertificationTest` | `testValidationA_TemplateMethodologyDetection`<br>`testValidationE_RuntimeCodeInspection` | **PASS** |
| **Rule 2** | `LAND_ONLY` Specification | `BusinessGovernanceRules.md` | `TemplateLibraryCertificationTest`<br>`TemplateGovernanceCertificationTest` | `testMandatoryValidationC_LandOnlyTemplateCertification`<br>`testValidationB_LandOnlyTemplateRendering` | **PASS** |
| **Rule 3** | `LAND_AND_BUILDING` Specification | `BusinessGovernanceRules.md` | `TemplateLibraryCertificationTest`<br>`TemplateGovernanceCertificationTest` | `testMandatoryValidationB_LandAndBuildingTemplateCertification`<br>`testValidationC_LandBuildingTemplateRendering` | **PASS** |
| **Rule 4** | `VALUE_OF_PROPERTY_TABLE` Mandatory | `BusinessGovernanceRules.md` | `TemplateLibraryCertificationTest` | `testMandatoryValidationB_LandAndBuildingTemplateCertification`<br>`testMandatoryValidationF_TemplateUploadGovernance` | **PASS** |
| **Rule 5** | Fair Value = Land + Bldg Fair Value | `BusinessGovernanceRules.md` | `TemplateGovernanceCertificationTest`<br>`FreezeGovernanceCertificationTest` | `testValidationC_LandBuildingTemplateRendering`<br>`testProductionReportGenerationAndCertification` | **PASS** |
| **Rule 6** | `FLAT_APARTMENT` Specification | `BusinessGovernanceRules.md` | `TemplateLibraryCertificationTest`<br>`TemplateGovernanceCertificationTest` | `testMandatoryValidationA_FlatApartmentTemplateCertification`<br>`testValidationD_CompositeTemplateRendering` | **PASS** |
| **Rule 7** | Flat / Apartment Mutual Exclusivity | `BusinessGovernanceRules.md` | `TemplateLibraryCertificationTest` | `testMandatoryValidationD_TemplateExclusivityCertification`<br>`testMandatoryValidationF_TemplateUploadGovernance` | **PASS** |
| **Rule 8** | Realizable Percentage Independence | `BusinessGovernanceRules.md` | `FreezeGovernanceCertificationTest`<br>`RegressionRemediationValidationTest` | `testCriticalFormulaEngine`<br>`testValidationE_CompositeSummaryPopulated` | **PASS** |
| **Rule 9** | Distress Percentage Independence | `BusinessGovernanceRules.md` | `FreezeGovernanceCertificationTest`<br>`RegressionRemediationValidationTest` | `testCriticalFormulaEngine`<br>`testValidationE_CompositeSummaryPopulated` | **PASS** |
| **Rule 10** | Photos Never Appear in TOC | `BusinessGovernanceRules.md` | `RegressionRemediationValidationTest` | `testValidationC_SitePhotographs` | **PASS** |
| **Rule 11** | `PROPERTY_ADDRESS` Data Preservation | `BusinessGovernanceRules.md` | `RegressionRemediationValidationTest`<br>`ProductionRegressionCertificationTest` | `testValidationA_PropertyAddressPreserved`<br>`testRuleBasedReportCertification` | **PASS** |
| **Rule 12** | Rate Alias Support | `BusinessGovernanceRules.md` | `RegressionRemediationValidationTest`<br>`ProductionRegressionCertificationTest` | `testValidationB_CompositeGovtRatePersistence`<br>`testRegressionDomain3CompositePropertyTable` | **PASS** |

---

## 12. APPROVED PRODUCTION TEMPLATES

The canonical templates certified for production are:
1. `official_production_valuation_report.docx` (`LAND_AND_BUILDING`)
2. `official_flat_apartment_valuation_report.docx` (`FLAT_APARTMENT`)
3. `official_land_valuation_report.docx` (`LAND_ONLY`)

Baseline disaster recovery mirrors are stored under `backend/baseline/`.

---

## 13. FREEZE DATE

* **Freeze Date:** September 18, 2026
* **Architecture State:** PERMANENTLY FROZEN. All active defects, regressions, and golden document dependencies are eradicated.

---

## 14. FUTURE CHANGE PROCESS

Any proposed change to the valuation engine, template catalog, calculation pipelines, or summary routing must follow the mandatory 4-tier change protocol:

1. **Step 1: Baseline Governance Document Update:**  
   Amend the relevant governance specification (`BusinessGovernanceRules.md`, `TemplateGovernanceRules.md`, etc.) under `backend/baseline/`.
2. **Step 2: Certification Suite Update:**  
   Write or amend the rule-based unit/integration tests in `com.provaluer.util.*` to reflect the updated business requirements before touching code.
3. **Step 3: Rule Traceability Matrix Update:**  
   Update the Traceability Matrix in `ArchitectureFreezeManifest.md` mapping the new rule to its test methods.
4. **Step 4: Implementation & 100% Zero-Failure Verification:**  
   Execute full test suite run across all seven certification suites. Zero tolerance for regression. Update `ArchitectureFreezeManifest.md` revision history.
