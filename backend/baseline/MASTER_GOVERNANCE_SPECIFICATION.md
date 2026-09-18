# MASTER GOVERNANCE SPECIFICATION
## PROVALUER COMMERCIAL REPORT GENERATION & VALUATION ENGINE
### AUTHORITATIVE ARCHITECTURE FREEZE SPECIFICATION

**Document Version:** 1.0  
**Effective Date:** September 18, 2026  
**Governance Status:** PERMANENTLY FROZEN & BINDING  
**Authority:** ProValuer Core Architecture Governance Board  
**Storage Location:** `backend/baseline/MASTER_GOVERNANCE_SPECIFICATION.md`  

---

## SECTION 1: SYSTEM OVERVIEW

### 1.1 Purpose of Report Generation Platform
The ProValuer Commercial Report Generation Platform is an enterprise-grade valuation engine designed to ingest structured property data, execute rigorous valuation and depreciation calculations, and generate client-ready valuation reports in both Microsoft Word (`.docx`) and Adobe PDF (`.pdf`) formats. The platform serves financial institutions, certified valuation professionals, and enterprise auditors, requiring zero data loss, exact currency formatting, and strict legal-grade document layouts.

### 1.2 Purpose of Template-Driven Architecture
Prior architectures suffered from tight coupling between runtime metadata and document generation logic, leading to template hijacking, data loss, and phantom placeholder leakage. The **Template-Driven Architecture** establishes the physical template file as the **Single Source of Truth**:
* The placeholders and table directives physically present in the uploaded `.docx` template dictate the valuation methodology, the dynamic valuation tables rendered, and the summary table routing.
* The engine operates as a pure, deterministic document compiler that renders exactly what the template dictates without second-guessing or overriding template structure via database flags or user inputs.

### 1.3 Purpose of Certification Framework
The Certification Framework provides continuous, zero-tolerance regression protection. Rather than relying on fragile binary, visual, or golden document snapshot comparisons (which break on harmless metadata or font variations), the platform enforces **Rule-Based Baseline Certification**:
* All seven certification suites validate compliance directly against authoritative business rules, schema integrity, and structural invariants.
* Any violation of methodology exclusivity, calculation independence, placeholder preservation, or TOC image isolation immediately fails the build.

---

## SECTION 2: AUTHORITATIVE SOURCES OF TRUTH

The authoritative baseline governance specification comprises the following documents stored under `backend/baseline/`:

1. [`BusinessGovernanceRules.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/BusinessGovernanceRules.md): The 12 Canonical Business Rules governing methodology, exclusivity, calculations, and placeholders.
2. [`TemplateGovernanceRules.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/TemplateGovernanceRules.md): Approved template library catalog, Section 7 table sequencing, and Upload Rules 1–5.
3. [`MethodologyGovernanceRules.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/MethodologyGovernanceRules.md): Methodology detection precedence and strict exclusion of runtime metadata.
4. [`RenderingCertificationRules.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/RenderingCertificationRules.md): OpenXML rendering standards, container containment, table styling, and TOC isolation.
5. [`PlaceholderGovernanceRules.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/PlaceholderGovernanceRules.md): Hard-stop `TEXT` classification, `PROPERTY_ADDRESS` preservation, and alias mapping.
6. [`CalculationGovernanceRules.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/CalculationGovernanceRules.md): Property Fair Value equation, percentage independence, and Rounding Approach A.
7. [`ArchitectureFreezeManifest.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/ArchitectureFreezeManifest.md): Architecture freeze declaration, approved production templates, and future change protocols.

> **BINDING MANDATE:** These artifacts are the **ONLY** approved sources of truth for the platform. No DOCX, PDF, database record, external document, or runtime metadata may supersede or override these specifications.

---

## SECTION 3: VALUATION METHODOLOGIES

The platform formally defines and supports exactly three valuation methodologies:

### 3.1 `LAND_ONLY`
* **Applicability:** Vacant land plots, open ground, agricultural/non-agricultural parcels.
* **Required Physical Directives:**
  * `<<LAND_TABLE>>`
  * `<<VALUATION_SUMMARY_TABLE>>`
* **Prohibited Directives:**
  * `<<BUILDING_TABLE>>`
  * `<<VALUE_OF_PROPERTY_TABLE>>`
  * `<<COMPOSITE_PROPERTY_TABLE>>`

### 3.2 `LAND_AND_BUILDING`
* **Applicability:** Independent houses, commercial buildings, industrial factories, institutional campuses.
* **Required Physical Directives (in strict sequential order):**
  1. `<<LAND_TABLE>>`
  2. `<<BUILDING_TABLE>>`
  3. `<<VALUE_OF_PROPERTY_TABLE>>` (MANDATORY)
  4. `<<VALUATION_SUMMARY_TABLE>>`
* **Prohibited Directives:**
  * `<<COMPOSITE_PROPERTY_TABLE>>`

### 3.3 `FLAT_APARTMENT` (`COMPOSITE`)
* **Applicability:** Residential apartments/flats, commercial office units, builder floors, retail shop units.
* **Required Physical Directives:**
  * `<<COMPOSITE_PROPERTY_TABLE>>`
  * `<<VALUATION_SUMMARY_TABLE>>`
* **Prohibited Directives:**
  * `<<LAND_TABLE>>`
  * `<<BUILDING_TABLE>>`
  * `<<VALUE_OF_PROPERTY_TABLE>>`

---

## SECTION 4: METHODOLOGY RULES

### 4.1 Single Source of Truth
Valuation methodology is determined **SOLEY AND EXCLUSIVELY** from table directives physically scanned from the template file.

### 4.2 Prohibited Runtime Metadata
Under no circumstances may runtime metadata influence, dictate, or override methodology detection or table generation. The engine is strictly prohibited from inspecting:
* `Property Type` (e.g., "Flat", "Apartment", "Residential Unit")
* `Property Category` (e.g., "Flat", "Residential")
* `VALUATION_METHODOLOGY` (runtime parameter or database field)
* `RAW_COMPOSITE_ITEMS_JSON` (presence or absence of JSON items)
* Database flags, user role flags, or order metadata

---

## SECTION 5: EXCLUSIVITY RULES

Flat / Apartment methodology and Land + Building methodology are **STRICTLY MUTUALLY EXCLUSIVE**:

$$\text{If } <<\text{COMPOSITE\_PROPERTY\_TABLE}>> \text{ exists, then:}$$
$$\begin{cases}
<<\text{LAND\_TABLE}>> & \text{PROHIBITED} \\
<<\text{BUILDING\_TABLE}>> & \text{PROHIBITED} \\
<<\text{VALUE\_OF\_PROPERTY\_TABLE}>> & \text{PROHIBITED}
\end{cases}$$

Conversely, if any of `<<LAND_TABLE>>`, `<<BUILDING_TABLE>>`, or `<<VALUE_OF_PROPERTY_TABLE>>` exist, `<<COMPOSITE_PROPERTY_TABLE>>` is strictly prohibited. Co-mingling causes immediate template upload rejection (`Upload Rule 1`).

---

## SECTION 6: SUMMARY ROUTING RULES

Summary table generation is routed deterministically based on the template-derived methodology:

* **`LAND_ONLY`** $\longrightarrow$ invokes `buildLandSummary(inputs)`  
  * Displays: Land Fair Value, Land Realizable Value, Land Distress Sale Value, Land Government Value.
* **`LAND_AND_BUILDING`** $\longrightarrow$ invokes `buildDynamicValuationSummaryTable(inputs)`  
  * Displays: Valuation Parameters across Land (₹), Building (₹), and Total (₹) columns.
* **`FLAT_APARTMENT`** $\longrightarrow$ invokes `buildDynamicCompositeSummaryTable(inputs)`  
  * Displays: Single-column composite valuation parameters (Fair Value, Realizable, Distress, Govt, Insurable).

---

## SECTION 7: CALCULATION GOVERNANCE

### 7.1 Property Fair Value Equation
For Land + Building valuations, total Property Fair Value is governed by the invariant summation:
$$\text{PROPERTY FAIR VALUE} = \text{LAND FAIR VALUE} + \text{BUILDING FAIR VALUE}$$
Rendered dynamically in the mandatory `<<VALUE_OF_PROPERTY_TABLE>>`.

### 7.2 Realizable Percentage Independence
Land Realizable % and Building Realizable % remain strictly independent parameters:
$$\text{Total Realizable Value} = (\text{Land Value} \times \text{Land Realizable \%}) + (\text{Building Value} \times \text{Building Realizable \%})$$
Neither parameter may overwrite, inherit from, or hijack the other.

### 7.3 Distress Percentage Independence
Land Distress % and Building Distress % remain strictly independent parameters:
$$\text{Total Distress Value} = (\text{Land Value} \times \text{Land Distress \%}) + (\text{Building Value} \times \text{Building Distress \%})$$
Neither parameter may overwrite, inherit from, or hijack the other.

### 7.4 Rounding Governance (Approach A - HALF_UP)
* Amounts $< 1\text{ Crore}$ round to the nearest ₹1,000.
* Amounts $\ge 1\text{ Crore}$ round to the nearest ₹10,000.
* Government Value and Fair Value are exact and must never be rounded.
* All financial values render in Indian Numbering Format prefixed with `'Rs '` (e.g., `Rs 75,48,000`).

---

## SECTION 8: PLACEHOLDER GOVERNANCE

### 8.1 Property Address Preservation
`PROPERTY_ADDRESS` and `property_address` must **NEVER** be overwritten with blank values, empty strings, or unhydrated markers. The user-entered workspace address must flow unimpeded into the generated DOCX and PDF.

### 8.2 Rate Alias Support
Valuation rate aliases must remain backward and forward compatible:
* `COMPOSITE_GOVT_RATE` $\longleftrightarrow$ `govt_composite_rate` $\longleftrightarrow$ `GOVT_COMPOSITE_RATE` $\longleftrightarrow$ `govt_rate`
* Aliases must synchronize to `ValuationData.compositeGovernmentRate` and produce non-zero Government Values.

### 8.3 Hard-Stop TEXT Rule
Placeholders starting with `TEXT`, `TEXT_`, `TXT`, `TXT_` are permanently classified as `TEXT`. They are never inferred as `DATE` or `IMAGE`. Only keys with `IMG_` or `IMAGE_` prefixes classify as `IMAGE`.

### 8.4 Zero Phantom Directives
Generated reports must contain **ZERO** unresolved `<<...>>` placeholders.

---

## SECTION 9: PHOTO GOVERNANCE

### 9.1 Table of Contents Isolation
Photos and photo paragraphs must **NEVER** appear in the Table of Contents (TOC):
* Paragraphs containing image anchors must never use Heading styles (`Heading 1`, `Heading 2`, `Heading 3`).
* Paragraphs containing image anchors must never contain `_Toc*` bookmarks.

### 9.2 Section Confinement
* Site photographs (`IMG_PIC1` through `IMG_PIC8`) reside exclusively inside Section 8 ("Property Photographs").
* Front cover photo (`IMG_FRONT_PAGE`) renders exclusively within the dedicated Page 1 drawing container.

---

## SECTION 10: TEMPLATE UPLOAD GOVERNANCE

Every template uploaded or revised via `TemplateProcessingService.validateDocxPackage` is validated against five mandatory rules:

* **Upload Rule 1 (Exclusivity Enforcement):** `COMPOSITE_PROPERTY_TABLE` cannot coexist with `LAND_TABLE`, `BUILDING_TABLE`, or `VALUE_OF_PROPERTY_TABLE`. Any violation causes immediate upload rejection.
* **Upload Rule 2 (Dependency Enforcement):** `VALUE_OF_PROPERTY_TABLE` strictly requires both `LAND_TABLE` and `BUILDING_TABLE`.
* **Upload Rule 3 (Summary Table Mandate):** Every valuation template must contain `<<VALUATION_SUMMARY_TABLE>>`.
* **Upload Rule 4 (Methodology Singularity):** Every template must resolve to exactly one unambiguous methodology (`LAND_ONLY`, `LAND_AND_BUILDING`, or `FLAT_APARTMENT`).
* **Upload Rule 5 (Ambiguity Prohibition):** Templates with contradictory or partial placeholder combinations (such as Land + Building without Value of Property Table) are rejected.

---

## SECTION 11: CERTIFICATION SUITES

Seven official, rule-based certification test suites enforce compliance:

1. `com.provaluer.util.TemplateGovernanceCertificationTest`
2. `com.provaluer.util.TemplateLibraryCertificationTest`
3. `com.provaluer.util.FreezeGovernanceCertificationTest`
4. `com.provaluer.util.ProductionRegressionCertificationTest`
5. `com.provaluer.util.RegressionRemediationValidationTest`
6. `com.provaluer.util.RealTemplateCertificationTest`
7. `com.provaluer.util.DisasterRecoveryCertificationTest`

---

## SECTION 12: RULE TRACEABILITY MATRIX

| Rule ID | Rule Description | Canonical Source | Test Suite | Test Method | Validation Logic | Status |
|---|---|---|---|---|---|---|
| **Rule 1** | Template Single Source of Truth | `BusinessGovernanceRules.md` | `TemplateGovernanceCertificationTest` | `testValidationA_TemplateMethodologyDetection`<br>`testValidationE_RuntimeCodeInspection` | Derives methodology exclusively from scanned table markers; verifies zero runtime metadata checks in engine source code. | **PASS** |
| **Rule 2** | `LAND_ONLY` Specification | `BusinessGovernanceRules.md` | `TemplateLibraryCertificationTest`<br>`TemplateGovernanceCertificationTest` | `testMandatoryValidationC_LandOnlyTemplateCertification`<br>`testValidationB_LandOnlyTemplateRendering` | Asserts presence of `<<LAND_TABLE>>` and `<<VALUATION_SUMMARY_TABLE>>`; verifies Land Summary rendering; confirms composite suppression. | **PASS** |
| **Rule 3** | `LAND_AND_BUILDING` Specification | `BusinessGovernanceRules.md` | `TemplateLibraryCertificationTest`<br>`TemplateGovernanceCertificationTest` | `testMandatoryValidationB_LandAndBuildingTemplateCertification`<br>`testValidationC_LandBuildingTemplateRendering` | Asserts presence of all 4 tables in strict sequence; verifies Land + Building summary table rendering with 3 columns. | **PASS** |
| **Rule 4** | `VALUE_OF_PROPERTY_TABLE` Mandatory | `BusinessGovernanceRules.md` | `TemplateLibraryCertificationTest` | `testMandatoryValidationB_LandAndBuildingTemplateCertification`<br>`testMandatoryValidationF_TemplateUploadGovernance` | Rejects templates omitting `<<VALUE_OF_PROPERTY_TABLE>>` at upload; validates physical inclusion in production template. | **PASS** |
| **Rule 5** | Fair Value Summation Invariant | `BusinessGovernanceRules.md` | `TemplateGovernanceCertificationTest`<br>`FreezeGovernanceCertificationTest` | `testValidationC_LandBuildingTemplateRendering`<br>`testProductionReportGenerationAndCertification` | Verifies $\text{Total Fair Value} = \text{Land} + \text{Building}$ dynamically in rendered XML and PDF output. | **PASS** |
| **Rule 6** | `FLAT_APARTMENT` Specification | `BusinessGovernanceRules.md` | `TemplateLibraryCertificationTest`<br>`TemplateGovernanceCertificationTest` | `testMandatoryValidationA_FlatApartmentTemplateCertification`<br>`testValidationD_CompositeTemplateRendering` | Asserts presence of `<<COMPOSITE_PROPERTY_TABLE>>` and `<<VALUATION_SUMMARY_TABLE>>`; verifies composite summary routing. | **PASS** |
| **Rule 7** | Flat / Apartment Mutual Exclusivity | `BusinessGovernanceRules.md` | `TemplateLibraryCertificationTest` | `testMandatoryValidationD_TemplateExclusivityCertification`<br>`testMandatoryValidationF_TemplateUploadGovernance` | Enforces zero co-mingling of composite and land/building markers across template catalog and upload validation. | **PASS** |
| **Rule 8** | Realizable % Independence | `BusinessGovernanceRules.md` | `FreezeGovernanceCertificationTest`<br>`RegressionRemediationValidationTest` | `testCriticalFormulaEngine`<br>`testValidationE_CompositeSummaryPopulated` | Tests independent parameter application without overwrite across formula engine and generated summary tables. | **PASS** |
| **Rule 9** | Distress % Independence | `BusinessGovernanceRules.md` | `FreezeGovernanceCertificationTest`<br>`RegressionRemediationValidationTest` | `testCriticalFormulaEngine`<br>`testValidationE_CompositeSummaryPopulated` | Tests independent distress percentage calculations without cross-contamination. | **PASS** |
| **Rule 10** | Photos Absent from TOC | `BusinessGovernanceRules.md` | `RegressionRemediationValidationTest` | `testValidationC_SitePhotographs` | Traverses DOCX paragraphs styled with TOC styles and asserts zero embedded drawing shapes or photos. | **PASS** |
| **Rule 11** | `PROPERTY_ADDRESS` Data Preservation | `BusinessGovernanceRules.md` | `RegressionRemediationValidationTest`<br>`ProductionRegressionCertificationTest` | `testValidationA_PropertyAddressPreserved`<br>`testRuleBasedReportCertification` | Asserts workspace address reaches engine without being overwritten; verifies address text in generated DOCX/PDF. | **PASS** |
| **Rule 12** | Valuation Rate Alias Support | `BusinessGovernanceRules.md` | `RegressionRemediationValidationTest`<br>`ProductionRegressionCertificationTest` | `testValidationB_CompositeGovtRatePersistence`<br>`testRegressionDomain3CompositePropertyTable` | Verifies `COMPOSITE_GOVT_RATE` persistence to `ValuationData` entity and computes non-zero government valuation. | **PASS** |

---

## SECTION 13: FREEZE POLICY

### 13.1 Architecture Freeze Mandate
The ProValuer Commercial Report Generation Architecture is declared **PERMANENTLY FROZEN**. No developer, pull request, or maintenance task may alter:
* Valuation methodology definitions
* Template structural layouts or sequencing
* Summary routing rules
* Calculation formulas or rounding governance
* Template upload validation rules
* Placeholder inference or alias mapping

### 13.2 Mandatory 4-Tier Change Protocol
In the event that business requirements mandate a future change, the following 4-tier process is legally binding before any source code is modified:
1. **Tier 1 - Baseline Governance Document Update:**  
   Update the relevant specification (`BusinessGovernanceRules.md`, `TemplateGovernanceRules.md`, etc.) under `backend/baseline/`.
2. **Tier 2 - Certification Suite Test Update:**  
   Write or amend rule-based tests in `com.provaluer.util.*` to assert the new requirements.
3. **Tier 3 - Rule Traceability Matrix Update:**  
   Update the Traceability Matrix in `ArchitectureFreezeManifest.md` and `MASTER_GOVERNANCE_SPECIFICATION.md`.
4. **Tier 4 - Execution & 100% Zero-Tolerance Verification:**  
   Run the complete certification test suite. Every test must pass with 0 failures before code changes may be approved for merge.

---

## SECTION 14: APPROVED PRODUCTION TEMPLATES

The canonical production templates officially approved and certified under this freeze are:

1. **`official_land_valuation_report.docx`**
   * **Methodology:** `LAND_ONLY`
   * **Location:** `backend/official_land_valuation_report.docx`
   * **Mirror Backup:** `backend/baseline/official_land_valuation_report.docx`

2. **`official_production_valuation_report.docx`**
   * **Methodology:** `LAND_AND_BUILDING`
   * **Location:** `backend/official_production_valuation_report.docx`
   * **Mirror Backup:** `backend/baseline/official_production_valuation_report.docx`

3. **`official_flat_apartment_valuation_report.docx`**
   * **Methodology:** `FLAT_APARTMENT` (`COMPOSITE`)
   * **Location:** `backend/official_flat_apartment_valuation_report.docx`
   * **Mirror Backup:** `backend/baseline/official_flat_apartment_valuation_report.docx`
