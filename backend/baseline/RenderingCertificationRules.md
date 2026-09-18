# AUTHORITATIVE RENDERING CERTIFICATION RULES

**Version:** 1.0  
**Effective Date:** Immediate  
**Status:** PERMANENT BINDING SPECIFICATION  
**Scope:** DOCX and PDF Output Rendering & Structure

---

## 1. DYNAMIC TABLE RENDERING RULES

All dynamically injected tables (`LAND_TABLE`, `BUILDING_TABLE`, `VALUE_OF_PROPERTY_TABLE`, `COMPOSITE_PROPERTY_TABLE`, `VALUATION_SUMMARY_TABLE`) must comply with the following:
* **Fixed Column Layout:** Enforced via `w:tblLayout w:type="fixed"` to prevent horizontal overflow in PDF conversion.
* **Unified Aesthetics:** 
  * Header banner styled in `#003366` dark navy with white bold text.
  * Border thickness: single 4 dxa `#CCCCCC`.
  * Proper cell margins (top/bottom 100 dxa, left/right 150 dxa).
* **Deterministic Row Ordering:**
  * In Composite Table: Main Unit -> Interior Works & Woodwork -> Covered Car Parking Space -> Subtotals.
  * In Property Value Table: Value of Land -> Value of Building -> Total Property Value.
* **Spacing paragraphs:** Automated addition of spacing paragraphs (`createTableSpacingParagraph()`) after dynamic tables to ensure clean visual flow.

---

## 2. IMAGE & PHOTO PLACEMENT RULES

* **Anchor Count Rule:** The canonical report contains exactly 14 drawing anchors (`Anchor.class`), including the Page 1 cover drawing image (`IMG_FRONT_PAGE`).
* **Container Containment Rule:** Images inserted into the document must be scaled proportionally and contained within table cell / paragraph layout boundaries. No image may bleed off page margins.
* **TOC Photo Isolation Rule (Rule 10):**
  * Image paragraphs must never inherit heading styles (`Heading 1`, `Heading 2`, etc.).
  * Image paragraphs must never contain bookmark starts/ends with `_Toc*` IDs.
  * Photo sections must never appear in the generated Table of Contents.

---

## 3. PDF RENDERING FIDELITY RULES

* **Multi-Page Completeness:** The generated PDF must contain all document pages (minimum 5 pages for complete production reports, typically 25–26 pages).
* **Parity with DOCX:** All text, numbers, calculations, table contents, and images rendered in the DOCX must appear faithfully in the converted PDF.
* **No Truncation or Clipping:** Tables and text boxes must render fully without text clipping.

---

## 4. ELIMINATION OF GOLDEN DOCUMENT COMPARISON

* **Strict Prohibition:** Regression and certification tests must **NEVER** assert equality, diffs, or parity against pre-baked golden binary files (`golden_production_report.docx` or `golden_production_report.pdf`).
* **Rule-Based Validation:** Verification is conducted purely against rule assertions:
  * Table presence and headers
  * Zero unresolved placeholders (`<<...>>`)
  * Minimum page counts
  * Correct calculated figures and currency formatting
