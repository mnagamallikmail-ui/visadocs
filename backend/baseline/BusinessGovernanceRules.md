# AUTHORITATIVE BUSINESS GOVERNANCE RULES

**Version:** 1.0  
**Effective Date:** Immediate  
**Status:** PERMANENT BINDING SPECIFICATION  
**Single Source of Truth:** Business Rules Stored Under `backend/baseline/`

---

## EXECUTIVE SUMMARY

This document establishes the permanent, rule-based governance architecture for the ProValuer Report Generation Engine. 
**No DOCX or PDF file is ever treated as the source of truth.** The physical templates, methodology detection, summary table routing, calculation pipelines, and output rendering are strictly governed by the following Authoritative Business Rules.

---

## THE TWELVE AUTHORITATIVE BUSINESS RULES

### RULE 1: TEMPLATE IS THE SINGLE SOURCE OF TRUTH
Valuation methodology is determined **ONLY** by the table directives physically present inside the template file.
* **Prohibited Runtime Metadata:** The engine must **NEVER** inspect or utilize `Property Type`, `Property Category`, `VALUATION_METHODOLOGY`, `RAW_COMPOSITE_ITEMS_JSON`, database flags, order metadata, user inputs, repository state, or calculation results to determine methodology.
* The physical template alone dictates:
  1. Valuation Methodology (`LAND_ONLY`, `LAND_AND_BUILDING`, or `FLAT_APARTMENT`)
  2. Valuation Tables rendered in the document
  3. Summary Table routing (`buildLandSummary`, `buildDynamicValuationSummaryTable`, or `buildDynamicCompositeSummaryTable`)
  4. Physical document structure

### RULE 2: LAND ONLY VALUATION TEMPLATE SPECIFICATION
A Land Only valuation template:
* **Must Contain:**
  * `<<LAND_TABLE>>`
  * `<<VALUATION_SUMMARY_TABLE>>`
* **Must NOT Contain:**
  * `<<BUILDING_TABLE>>`
  * `<<VALUE_OF_PROPERTY_TABLE>>`
  * `<<COMPOSITE_PROPERTY_TABLE>>`
* **Detected Methodology:** `LAND_ONLY`

### RULE 3: LAND + BUILDING VALUATION TEMPLATE SPECIFICATION
A Land + Building valuation template:
* **Must Contain (in strict sequential order):**
  1. `<<LAND_TABLE>>`
  2. `<<BUILDING_TABLE>>`
  3. `<<VALUE_OF_PROPERTY_TABLE>>`
  4. `<<VALUATION_SUMMARY_TABLE>>`
* **Must NOT Contain:**
  * `<<COMPOSITE_PROPERTY_TABLE>>`
* **Detected Methodology:** `LAND_AND_BUILDING`

### RULE 4: VALUE_OF_PROPERTY_TABLE IS MANDATORY
In every Land + Building report, `<<VALUE_OF_PROPERTY_TABLE>>` is **MANDATORY** and **NOT OPTIONAL**.
* If `<<VALUE_OF_PROPERTY_TABLE>>` is absent, the template is non-compliant and must fail template upload certification.
* Every Land + Building report physically renders this section between the Building Table and Valuation Summary Table.

### RULE 5: PROPERTY FAIR VALUE EQUATION
For Land + Building valuation methodology, Property Fair Value is governed by the invariant:
$$\text{PROPERTY FAIR VALUE} = \text{LAND FAIR VALUE} + \text{BUILDING FAIR VALUE}$$
The `<<VALUE_OF_PROPERTY_TABLE>>` dynamically renders the components:
* Value of Land (₹)
* Value of Building (₹)
* Total Property Value (₹)

### RULE 6: FLAT / APARTMENT VALUATION TEMPLATE SPECIFICATION
A Flat / Apartment valuation template:
* **Must Contain:**
  * `<<COMPOSITE_PROPERTY_TABLE>>`
  * `<<VALUATION_SUMMARY_TABLE>>`
* **Must NOT Contain:**
  * `<<LAND_TABLE>>`
  * `<<BUILDING_TABLE>>`
  * `<<VALUE_OF_PROPERTY_TABLE>>`
* **Detected Methodology:** `FLAT_APARTMENT` (`COMPOSITE`)
* Represents: Apartment, Flat, Residential Unit, Commercial Unit, Office Unit, Shopping Unit valuations.

### RULE 7: FLAT / APARTMENT MUTUAL EXCLUSIVITY
Flat / Apartment methodology and Land + Building methodology are **MUTUALLY EXCLUSIVE**.
* If `<<COMPOSITE_PROPERTY_TABLE>>` exists in a template, then **ALL** of the following must be absent:
  * `<<LAND_TABLE>>`
  * `<<BUILDING_TABLE>>`
  * `<<VALUE_OF_PROPERTY_TABLE>>`
* Any template co-mingling `<<COMPOSITE_PROPERTY_TABLE>>` with Land or Building table placeholders is strictly invalid and must be rejected at upload.

### RULE 8: LAND AND BUILDING REALIZABLE PERCENTAGE INDEPENDENCE
In Land + Building valuations, Land Realizable Percentage and Building Realizable Percentage remain **strictly independent**:
$$\text{Total Realizable Value} = (\text{Land Value} \times \text{Land Realizable \%}) + (\text{Building Value} \times \text{Building Realizable \%})$$
Neither parameter may overwrite or hijack the other.

### RULE 9: LAND AND BUILDING DISTRESS PERCENTAGE INDEPENDENCE
In Land + Building valuations, Land Distress Percentage and Building Distress Percentage remain **strictly independent**:
$$\text{Total Distress Value} = (\text{Land Value} \times \text{Land Distress \%}) + (\text{Building Value} \times \text{Building Distress \%})$$
Neither parameter may overwrite or hijack the other.

### RULE 10: PHOTO SECTION ISOLATION FROM TOC
Photos and image paragraphs must **NEVER** appear in the Table of Contents (TOC).
* Paragraphs containing image anchors (`IMG_*`, `IMAGE_*`, `PIC_*`, `DOC_PR`) must never be formatted with Heading styles (`Heading 1`, `Heading 2`, etc.) and must never contain TOC bookmarks (`_Toc*`).

### RULE 11: PROPERTY_ADDRESS DATA PRESERVATION
`PROPERTY_ADDRESS` must **NEVER** be overwritten with blank values, empty strings, or unhydrated markers.
* The workspace-entered property address must be preserved into the valuation engine and rendered into both DOCX and PDF outputs without data loss.

### RULE 12: RATE ALIAS SUPPORT
Valuation rate aliases (`COMPOSITE_GOVT_RATE`, `govt_composite_rate`, `GOVT_COMPOSITE_RATE`, `govt_rate`) must remain backward and forward compatible.
* If a specific field is omitted from direct inputs, alias mapping and JSON sub-item extractors must resolve the rate seamlessly.

---

## CERTIFICATION & GOVERNANCE COMPLIANCE
All test suites must assert adherence to these 12 Authoritative Rules directly against programmatic outputs and physical templates. No test may assert equality against binary, visual, or golden document snapshots.
