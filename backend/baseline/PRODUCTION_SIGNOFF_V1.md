# PRODUCTION SIGN-OFF & GOVERNANCE SEAL (V1)
**Document Version:** 1.1.0 (RESTRUCTURED GOVERNANCE SEAL)  
**Effective Date:** 17-Sep-2026  
**Status:** GOVERNANCE CERTIFIED | CURRENT GOLDEN REPORT REVOKED | NEW GOLDEN REPORT PENDING  
**Sole Source of Truth Template:** `official_production_valuation_report.docx`  

---

## 1. System Metadata & Identification

| Metadata Attribute | Approved Production Value |
|---|---|
| **System Name** | ProValuer Commercial Report Generation Engine |
| **Scope** | Complete End-to-End Valuation Report Pipeline (Spring Boot Backend + Flutter Workspace) |
| **Approved Version** | `REPORT_ENGINE_V1.0.0` |
| **Baseline Version** | `REPORT_ENGINE_BASELINE_V1` |
| **Governance Version** | `REPORT_ENGINE_GOVERNANCE_V1` |
| **Release Date** | 17-Sep-2026 |
| **Governance Documentation Status** | **CERTIFIED** |
| **Process Lockdown Status** | **CERTIFIED** |
| **Disaster Recovery Status** | **CERTIFIED** |
| **Regression Gate Status** | **CERTIFIED** |
| **Current Golden Report Status** | **REVOKED (NOT CERTIFIED - DO NOT USE FOR VALIDATION)** |
| **New Golden Report Status** | **PENDING MANUAL APPROVAL** |
| **Sole Source of Truth Template** | `official_production_valuation_report.docx` |

---

## 2. Formal System Certifications

### 1. Composite Property Valuation Table
*Certification Statement:*  
The Composite Property Valuation Table specifications and generation rules are certified active. It enforces the full valuation formula chain: Main Unit Amount + Interior Works Amount + Parking Amount - Depreciation = Raw Fair Value, with exact subtotal hierarchy and dedicated rows for Main Unit, Interior Works, and Parking.

### 2. Valuation Parameters Table
*Certification Statement:*  
The Valuation Parameters Summary Table specifications are certified active. It requires Fair Value, Realizable Value, Distress Sale Value, Government Value, and Insurable Value without omissions or field truncation.

### 3. Formula Engine
*Certification Statement:*  
The Formula Expression Engine (`NumericFormulaEngine`) is certified operational. Numeric inputs (`N1`, `N2`...) internally default to `0.0` and display blank (`""`) when untouched. Genuine mathematical zeros ($500 - 500 = 0$) display as `0` / `Rs 0`. Approach A (HALF_UP) rounding is strictly applied to Realizable, Distress, and Insurable values, while Government Value remains exact to the rupee.

### 4. Currency Formatting
*Certification Statement:*  
Currency rendering is certified uniform. All financial sums are prefixed with `Rs ` and formatted per the Indian numbering system (e.g. `Rs 95,22,200`, `Rs 1,70,50,000`, `Rs 12,75,40,000`), with zero variance between interactive UI, DOCX, and PDF.

### 5. Image Governance
*Certification Statement:*  
Image placeholder detection is certified restricted to `IMG_*` and `IMAGE_*` prefixes. OpenXML drawing structures (`AlternateContent`, `wp:anchor`, `wp:inline`, `w:drawing`) are preserved verbatim. Full alias parity across `IMG_FRONT_PAGE`, `IMG_COVER_PAGE`, and `COVER_IMAGE` is certified active on Page 1.

### 6. Text Governance (Hard-Stop Rule)
*Certification Statement:*  
Text placeholders (`TEXT`, `TEXT_001`..`003`, `TXT`, `TXT_001`, `TEXT_PLACEHOLDER`, `^(TEXT|TXT)(_\d+)?$`) are certified under the absolute hard-stop rule. They immediately resolve to `fieldType = "TEXT"` with zero date inference, zero image inference, and zero calendar picker dialogs.

### 7. Date Governance
*Certification Statement:*  
Date handling is certified restricted to explicit `DATE_*` placeholders, rendering ISO dates (`YYYY-MM-DD`) in standard `DD-MMM-YYYY` format with isolated calendar widget binding.

### 8. Keyboard Navigation Governance
*Certification Statement:*  
Keyboard navigation within the interactive Document Workspace is certified fully compliant. `TAB` and `SHIFT+TAB` advance and retreat focus; `ARROW DOWN` and `ARROW UP` traverse multiline boundaries at top/bottom text lines; and `ENTER` correctly inserts newlines in multiline fields while advancing single-line fields.

### 9. Image Boundary Governance
*Certification Statement:*  
Image insertion boundary containment is certified across 6 distinct geometry classes (Portrait, Landscape, Square, Cover, Site, Government Scan). Proportional scaling within white bounding canvases maintains exact aspect ratios with zero stretching, zero distortion, zero cell overflow, zero table row expansion, and zero page corruption.

### 10. Disaster Recovery
*Certification Statement:*  
Disaster recovery procedures are certified complete, tested, and self-healing. Restorations under repository corruption, artifact deletion, deployment failure, and template degradation are validated with RTO $\le 15\text{ minutes}$ and RPO $= 0$.

### 11. Regression Certification
*Certification Statement:*  
Automated CI/CD regression gates are certified active. Until a new golden report passes visual review, regression testing validates against governance, structural, placeholder, formula, image, and table existence rules.

---

## 3. Accepted Baseline Inventory & Revocation Status

| Artifact Name | Path / Mirror | File Size | SHA-256 Checksum | Certification Status |
|---|---|---|---|---|
| `official_production_valuation_report.docx` | `backend/official_production_valuation_report.docx`<br>`backend/baseline/official_production_valuation_report.docx` | 1,530,900 bytes | `A13949299698F460B2988670B60DCD525EAAA70DEC9866DFDC2688963C421FC1` | **CERTIFIED SOLE SOURCE OF TRUTH** |
| `golden_production_report.docx` | `backend/build/golden_production_report.docx`<br>`backend/baseline/golden_production_report.docx` | 1,635,614 bytes | `C6EE0D9C2FD107801D0880F262A576EDBF281B271E0A390D820DFEFC631686B3` | **REVOKED (NOT CERTIFIED - DO NOT USE)** |
| `golden_production_report.pdf` | `backend/build/golden_production_report.pdf`<br>`backend/baseline/golden_production_report.pdf` | 1,621,002 bytes | `9E3F0ABF1B88EF58AE35B6A93F29D57DECED8B4300529F9E73472C1A2C22FC64` | **REVOKED (NOT CERTIFIED - DO NOT USE)** |
| `REPORT_ENGINE_GOVERNANCE_V1.md` | `golden/REPORT_ENGINE_GOVERNANCE_V1.md` | 12,050 bytes | `41A3CCB4E6AE60B3B8AC42A2A90620C1DF82AB6436E27B1742C051C961316793` | **CERTIFIED** |
| `CHANGE_CONTROL_POLICY_V1.md` | `golden/CHANGE_CONTROL_POLICY_V1.md` | 15,292 bytes | `44A814CBFBAD5706C2382CA3350E31742999B86FC422BB5163EAB01B74707584` | **CERTIFIED** |
| `DISASTER_RECOVERY_V1.md` | `golden/DISASTER_RECOVERY_V1.md` | 12,582 bytes | `982CD8773858DE496E9B1F92F1189C9C95D4C056A3358C052F61E9853B7C6EC3` | **CERTIFIED** |
| `REVOCATION_NOTICE_V1.md` | `golden/REVOCATION_NOTICE_V1.md` | - | - | **CERTIFIED & ACTIVE** |

---

## 4. Governance Status Summary

- [x] **Governance Documentation:** **CERTIFIED**
- [x] **Process Lockdown:** **CERTIFIED**
- [x] **Disaster Recovery:** **CERTIFIED**
- [x] **Regression Gate:** **CERTIFIED (Rules-Based)**
- [x] **Canonical Template:** `official_production_valuation_report.docx` **SOLE SOURCE OF TRUTH**
- [x] **Previous Golden Report:** `golden_production_report.*` **REVOKED**
- [x] **Replacement Golden Report:** **PENDING MANUAL APPROVAL**

---

## 5. Formal Governance Seal

```
===================================================================================
                               GOVERNANCE SEAL
===================================================================================
System:                 ProValuer Commercial Report Generation Engine
Sole Source of Truth:   official_production_valuation_report.docx
Governance Documents:   CERTIFIED & LOCKED
Process Controls:       CERTIFIED & LOCKED
Disaster Recovery:      CERTIFIED & TESTED
Regression Gates:       CERTIFIED (Temporary Rules Baseline Active)
Golden Report Status:   REVOKED (Replacement Report Pending Manual Approval)
Repository:             golden/
Date:                   17-Sep-2026
===================================================================================
```
