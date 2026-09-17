# REPORT ENGINE GOVERNANCE BASELINE (V1)
**Document Version:** 1.0.0 (FROZEN PRODUCTION BASELINE)  
**Status:** FROZEN & SEALED  
**Sole Source of Truth Template:** `official_production_valuation_report.docx`  
**Governing Codebases:** Spring Boot Backend (`com.provaluer.*`), Flutter Web/Desktop Frontend  

---

## 1. Executive Summary & Purpose
This document establishes the permanent, immutable release baseline and freeze governance rules for the ProValuer Commercial Report Generation Engine. All business logic, rounding rules, formula evaluations, placeholder heuristics, image handling, currency formatting, and keyboard navigation behaviors documented herein are **STRICTLY FROZEN**.

Any future modification that violates or alters the behaviors defined in this specification represents a regression and must trigger an automated build failure.

---

## 2. Image Governance

### 2.1 Identifier Prefix Rule
- An element or key is classified as an **IMAGE placeholder** if and only if it starts with:
  - `IMG_` (e.g., `IMG_FRONT_PAGE`, `IMG_PIC1`, `IMG_GOVT_RATE`)
  - `IMAGE_` (e.g., `IMAGE_SITE_OVERVIEW`)
- Non-prefixed drawing shapes, text boxes, and narrative descriptions containing terms like "image", "photo", or "picture" (e.g. `IMAGE_DESCRIPTION`, `PHOTO_REMARKS`, `PICTURE_CAPTION`) are strictly classified as **TEXT** and must never be treated as image upload targets.

### 2.2 AlternateContent & Drawing Preservation
- WordprocessingML paragraphs containing OpenXML drawing elements (`AlternateContent`, `w:drawing`, `wp:anchor`, `wp:inline`, `v:shape`, `w:pict`) must be preserved verbatim during run consolidation and paragraph normalization.
- In-place graphic replacement: When an uploaded image is bound to an existing drawing anchor, the engine modifies the drawing's graphic data in-place and preserves all floating coordinates, wrap types, and z-index definitions. Converting anchors to inline elements is strictly prohibited.

### 2.3 Cover / Front-Page Image Alias Parity
The following keys are guaranteed 100% functional and programmatic equivalence:
- `IMG_FRONT_PAGE`
- `IMG_COVER_PAGE`
- `COVER_IMAGE`
- `FRONT_PAGE`
- `img_front_page`
- `img_cover_page`

Uploading a picture to any of these aliases automatically binds to the front-page photograph anchor on Page 1 of the report.

### 2.4 Image Containment Rules
- All image insertions into placeholder frames must use proportional scaling to fit within the designated extent ($cx \times cy$).
- Images must never be stretched, compressed, or distorted.
- Aspect ratios must be preserved by centering the image within a crisp white bounding canvas matching the frame aspect ratio.
- No image insertion may overflow cell boundaries, trigger Word row expansion, split table rows, or corrupt layout pages.

---

## 3. Text Placeholder Governance (Hard-Stop Rule)

### 3.1 Hard-Stop Identifiers
The following tokens must immediately resolve to `fieldType = "TEXT"` and terminate type inference:
- `TEXT`
- `TEXT_001`
- `TEXT_002`
- `TEXT_003`
- `TXT`
- `TXT_001`
- `TEXT_PLACEHOLDER`
- Any key matching regex `^(TEXT|TXT)(_\d+)?$`

### 3.2 Prohibited Behaviors
- **Zero Date Inference:** Must never be converted to `DATE`, must never trigger ISO-8601 formatting, and must never display date picker or calendar dialogs.
- **Zero Image Inference:** Must never render image upload widgets or file selection buttons.
- **Zero Type Overrides:** No domain dictionary or heuristic override may alter this classification.

### 3.3 Multiline & Text Display Behavior
- Every `TEXT` placeholder in the workspace renders as multiline (`minLines >= 3`, `maxLines: null`) with no internal scrollbars.
- If a text placeholder is unpopulated, it displays as **blank** (`""`) with no placeholder delimiters (e.g. `<<TEXT_001>>` must never appear in generated documents or workspace text boxes).

---

## 4. Date Placeholder Governance

- Date inference and formatting apply strictly to explicit `DATE_*` or `*_DATE` keys (or `INSPECTION_DATE`, `DATE_OF_REPORT`).
- Input values in ISO-8601 format (`YYYY-MM-DD`) render as `DD-MMM-YYYY` (e.g., `2026-09-17` → `17-Sep-2026`).
- Date picker calendar widgets are restricted solely to date-classified fields.

---

## 5. Numeric Formula Engine Governance

### 5.1 Syntax & Supported Operators
- Formula expressions follow the syntax `<<CALC:expression>>`.
- Supported mathematical operators: `+`, `-`, `*`, `/`, `(`, `)`.
- Token support: Variable identifiers including numeric input keys (e.g., `N1`, `N2`, `N3`...), area keys (`SALEABLE_AREA`), rate keys (`COMPOSITE_RATE`), and standard constants.

### 5.2 Default N Behavior
- Numeric input slots (`N1`, `N2`, `N3`...) internally default to `0.0`.
- In the interactive user workspace, untouched numeric inputs display as **blank** (`""`) so the user is presented with a clean authoring surface.

### 5.3 Untouched-Input & Calculated Zero Display Governance
- **Untouched Inputs:** If all input variables referenced by a formula are untouched (empty/blank in the workspace), the formula engine marks `allInputsUntouched = true` and the formula field displays as **blank** (`""`).
- **Genuine Mathematical Zero:** If the user has entered inputs and the formula legitimately evaluates to zero (e.g., $500 - 500 = 0$), the formula engine marks `allInputsUntouched = false` and displays **`0`** (or **`Rs 0`** for currency). A genuine mathematical zero must never be displayed as blank.

---

## 6. Rounding Governance (Approach A – True Rounding / HALF_UP)

### 6.1 Rounding Thresholds
- **Lakhs ($< ₹ 1\text{ Crore}$):** Round to the nearest **₹ 1,000** using `RoundingMode.HALF_UP`.
  - Example: ₹ 95,22,650 $\rightarrow$ **₹ 95,23,000**
  - Example: ₹ 95,22,200 $\rightarrow$ **₹ 95,22,000**
- **Crores ($\ge ₹ 1\text{ Crore}$):** Round to the nearest **₹ 10,000** using `RoundingMode.HALF_UP`.
  - Example: ₹ 1,70,48,900 $\rightarrow$ **₹ 1,70,50,000**
  - Example: ₹ 1,70,42,350 $\rightarrow$ **₹ 1,70,40,000**
  - Example: ₹ 12,75,38,900 $\rightarrow$ **₹ 12,75,40,000**

### 6.2 Scope of Application
Rounding Approach A applies **STRICTLY AND ONLY** to:
1. `Realizable Value` (`REALIZABLE_VALUE`)
2. `Distress Sale Value` (`DISTRESS_SALE_VALUE`)
3. `Distress Value` (`DISTRESS_VALUE`)
4. `Insurable Value` (`INSURABLE_VALUE`)

### 6.3 Explicit Exclusions
Rounding Approach A must **NEVER** be applied to:
- `Government Value` (`GOVERNMENT_VALUE` / `GOVT_VALUE`): Must remain exact to the rupee as legally recorded in guideline registries.
- `Fair Value` (`FAIR_VALUE` / `RAW_FAIR_VALUE`): Raw valuation sum remains exact. Say Value rounding is handled independently as a dedicated separate field.

---

## 7. Currency Formatting Governance

- All currency amounts across the Workspace, generated DOCX, and generated PDF must use consistent Indian numbering system formatting prefixed by `Rs `.
- Standard Format: `Rs #,##,###`
- Reference Examples:
  - `Rs 95,22,200`
  - `Rs 1,70,50,000`
  - `Rs 12,75,40,000`
  - `Rs 0`

---

## 8. Keyboard Navigation Governance

Keyboard interactions in the Document Workspace must operate according to the following specification:

| Shortcut | Target Element | Action / Behavior |
|---|---|---|
| `TAB` | Editable placeholder | Focus advances to the next placeholder in document order |
| `SHIFT + TAB` | Editable placeholder | Focus retreats to the previous placeholder in document order |
| `ARROW DOWN` | Single-line field | Focus advances to the next editable placeholder |
| `ARROW DOWN` | Multiline field | Advances cursor within text; if cursor is on the **last line**, advances focus to the next editable placeholder |
| `ARROW UP` | Single-line field | Focus retreats to the previous editable placeholder |
| `ARROW UP` | Multiline field | Retreats cursor within text; if cursor is on the **first line**, retreats focus to the previous editable placeholder |
| `ENTER` | Single-line field | Commits edit and advances focus to the next placeholder |
| `ENTER` | Multiline field | Inserts a newline character (`\n`) without moving focus |

---

## 9. Image Boundary Governance

When inserting user-uploaded photos into DOCX/PDF placeholders:
- **Aspect Ratio:** The original aspect ratio must be preserved exactly.
- **No Stretching / Distortion:** Anamorphic scaling is prohibited.
- **No Overflow:** Rendered graphics must never exceed the placeholder boundary ($cx, cy$).
- **No Table Expansion:** Table cells hosting images must not expand horizontally or vertically.
- **No Row Splitting:** Table rows must maintain `w:cantSplit` properties.
- **No Page Corruption:** Floating anchors must retain page coordinate bounds.

---

## 10. Baseline Inventory

The frozen production baseline established from `official_production_valuation_report.docx` comprises the following verified parameters:

| Baseline Parameter | Measured Baseline Value | Verification Method |
|---|---|---|
| **1. Template File Size** | **1,530,900 bytes** | File System Inspection |
| **2. Golden DOCX Size** | **1,635,614 bytes** | File System Inspection |
| **3. Golden PDF Size** | **1,621,002 bytes** | File System Inspection |
| **4. Golden PDF Page Count** | **25 pages** | Apache PDFBox / FOP Engine |
| **5. Total Distinct Placeholders** | **75 placeholders** | Full OpenXML DOM Traversal |
| **6. Image Placeholders Detected** | **9 placeholders** (`IMG_FRONT_PAGE`, `IMG_PIC1`..`8`) | Drawing DocPr & Text Inspection |
| **7. Formula Placeholders (CALC)** | **0 in static template** (dynamically evaluated) | Parser Inspection |
| **8. Total Static Tables** | **8 tables** (7 main document body, 1 header) | OpenXML `w:tbl` finder |
| **9. Composite Property Valuation Table** | **ACTIVE & VERIFIED** (7 columns, dynamic generation) | DOCX/PDF Content Search |
| **10. Valuation Parameters Table** | **ACTIVE & VERIFIED** (Summary table present) | DOCX/PDF Content Search |
| **11. Front-Page Anchor Drawings** | **14 anchors** (100% preserved on Page 1) | OpenXML `wp:anchor` finder |
| **12. Total Image Anchors Detected** | **14 anchor frames** | Docx4j `ClassFinder(Anchor.class)` |

---

## 11. Proof of Freeze Point & Integrity Verification

### 11.1 Artifact Storage Locations
1. **Golden Template:**
   - Permanent Canonical Path: `backend/official_production_valuation_report.docx`
   - Baseline Backup Path: `backend/baseline/official_production_valuation_report.docx`
2. **Golden Generated DOCX:**
   - Canonical Path: `backend/build/golden_production_report.docx`
   - Baseline Backup Path: `backend/baseline/golden_production_report.docx`
3. **Golden Generated PDF:**
   - Canonical Path: `backend/build/golden_production_report.pdf`
   - Baseline Backup Path: `backend/baseline/golden_production_report.pdf`
4. **Governance Specification:**
   - Root Path: `REPORT_ENGINE_GOVERNANCE_V1.md`
   - Backend Mirror Path: `backend/REPORT_ENGINE_GOVERNANCE_V1.md`

### 11.2 Cryptographic Checksums (SHA-256) & Revocation Status
Baseline binary artifacts and revocation status:

| Artifact | File Size | SHA-256 Cryptographic Hash | Status |
|---|---|---|---|
| `official_production_valuation_report.docx` | 1,530,900 bytes | `A13949299698F460B2988670B60DCD525EAAA70DEC9866DFDC2688963C421FC1` | **CERTIFIED SOLE SOURCE OF TRUTH** |
| `golden_production_report.docx` | 1,635,614 bytes | `C6EE0D9C2FD107801D0880F262A576EDBF281B271E0A390D820DFEFC631686B3` | **REVOKED (NOT CERTIFIED - DO NOT USE)** |
| `golden_production_report.pdf` | 1,621,002 bytes | `9E3F0ABF1B88EF58AE35B6A93F29D57DECED8B4300529F9E73472C1A2C22FC64` | **REVOKED (NOT CERTIFIED - DO NOT USE)** |

*Note on Revocation:* Per `REVOCATION_NOTICE_V1.md`, `golden_production_report.docx` and `golden_production_report.pdf` are REVOKED due to output defects (table placement, blank fields, duplicates). `official_production_valuation_report.docx` remains the sole production source of truth. Replacement report approval is pending manual visual review.

### 11.3 Temporary Regression Baseline Policy
Until a replacement golden report is approved, automated validation operates against governance, structural, placeholder, formula, image, and table existence rules. Automated tests must NOT compare against the revoked golden artifacts. The build **MUST FAIL** if:
- Composite Property Valuation Table is missing or malformed.
- Valuation Parameters Table is missing or malformed.
- `IMG_FRONT_PAGE` or any of the 14 Page-1 anchors are stripped.
- Any `TEXT` placeholder is classified as `DATE` or `IMAGE`.
- Any image exceeds placeholder bounds or distorts aspect ratio.
- Indian currency formatting deviates from `Rs #,##,###`.
- Rounding fails to adhere to Approach A (HALF_UP).
