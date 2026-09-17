# FORMAL REVOCATION NOTICE: CURRENT GENERATED GOLDEN ARTIFACTS
**Notice Identifier:** `REVOCATION_NOTICE_V1`  
**Effective Date:** 17-Sep-2026  
**Status:** ACTIVE, OFFICIALLY REVOKED & RECORDED  
**Authority:** Governance Custodian & Core Valuation Architecture Board  

---

## 1. Revoked Artifacts
The following generated artifacts are hereby formally **REVOKED**, **STRIPPED OF CERTIFIED STATUS**, and marked **DO NOT USE FOR VALIDATION**:

| Revoked Artifact | File Size | SHA-256 Checksum | Previous Location | Revocation Status |
|---|---|---|---|---|
| `golden_production_report.docx` | 1,635,614 bytes | `C6EE0D9C2FD107801D0880F262A576EDBF281B271E0A390D820DFEFC631686B3` | `backend/baseline/golden_production_report.docx`<br>`backend/build/golden_production_report.docx` | **REVOKED (NOT CERTIFIED)** |
| `golden_production_report.pdf` | 1,621,002 bytes | `9E3F0ABF1B88EF58AE35B6A93F29D57DECED8B4300529F9E73472C1A2C22FC64` | `backend/baseline/golden_production_report.pdf`<br>`backend/build/golden_production_report.pdf` | **REVOKED (NOT CERTIFIED)** |

---

## 2. Reason for Revocation
Following thorough manual and visual validation of the generated documents, the artifacts above failed to meet the required production standard. The generated documents exhibit severe visual, structural, and content defects that prevent them from serving as the golden baseline.

### Observed Report Defects:
1. **Incorrect Table Placement:** Valuation tables injected into unintended sections, perturbing flow.
2. **Blank Mandatory Fields:** Critical valuation attributes left empty despite available inputs.
3. **Duplicate Valuation Sections:** Redundant valuation tables and certification paragraphs appearing twice.
4. **Content Contamination Across Properties:** Residual text and metadata from other property configurations leaking into the report.
5. **Incomplete Valuation Summaries:** Summaries omitting required line items or parameters.
6. **Layout & Flow Inconsistencies:** Abnormal spacing, unexpected page breaks, and visual misalignment.

---

## 3. Governance Rules That Remain Valid & Certified
The revocation applies **strictly to the generated report files**. All core governance rules, mathematical specifications, and process controls remain 100% active, certified, and binding:

- ✅ **Governance Documentation:** **CERTIFIED** (`REPORT_ENGINE_GOVERNANCE_V1.md`)
- ✅ **Process Lockdown & Change Control:** **CERTIFIED** (`CHANGE_CONTROL_POLICY_V1.md`)
- ✅ **Disaster Recovery Protocols:** **CERTIFIED** (`DISASTER_RECOVERY_V1.md`)
- ✅ **Regression Gates & Structural Rules:** **CERTIFIED** (`ProductionRegressionCertificationTest`)
- ✅ **Sole Source of Truth:** `official_production_valuation_report.docx` remains the sole, authoritative source of truth.

---

## 4. Temporary Regression Baseline Policy
Until a replacement golden report is formally inspected, validated, and approved:
- Automated tests and CI/CD gates must **NOT** treat `golden_production_report.docx` or `golden_production_report.pdf` as authoritative comparison baselines.
- Automated validation must rely temporarily on:
  1. Governance rules (Text hard-stop, image prefixing, etc.)
  2. Structural OpenXML rules (valid hierarchy, no broken runs)
  3. Placeholder classification rules (TEXT != DATE/IMAGE)
  4. Formula arithmetic rules (Approach A HALF_UP rounding, untouched blanks)
  5. Image containment rules (aspect ratio preservation, no overflow)
  6. Table existence rules (Composite Property Table and Valuation Parameters Table present)

---

## 5. Replacement Golden Report Requirements
Before any newly generated report can be elevated to Golden Baseline status, it must satisfy all 8 mandatory certification criteria:

- [ ] **1. No Blank Mandatory Fields:** All required valuation parameters, borrower details, property addresses, and valuer remarks must be properly substituted.
- [ ] **2. Correct Table Locations:** Composite Property Valuation Table and Valuation Parameters Summary Table must render in their designated sections.
- [ ] **3. Correct Valuation Summaries:** All totals, subtotals, and parameter amounts must match exact valuation arithmetic without omissions.
- [ ] **4. Zero Cross-Property Contamination:** No residual data, incorrect property sub-types, or unrelated property text.
- [ ] **5. Correct Page Structure & Layout:** Clean page breaks, consistent headers/footers, and no table splits across pages.
- [ ] **6. Currency Formatting Validated:** Strict `Rs #,##,###` Indian number system formatting across all values.
- [ ] **7. Manual Visual Inspection Completed:** Formal line-by-line inspection signed off by a human valuation reviewer.
- [ ] **8. Governance Review Completed:** Dual sign-off from Lead Architecture and Lead Valuation Engineer.

---

## 6. Replacement Workflow

```
official_production_valuation_report.docx (Sole Source of Truth)
            ↓
Fix Report Defects (Surgical resolution of table placement, blanks, duplicates)
            ↓
Generate New Report (Candidate DOCX & Candidate PDF)
            ↓
Manual Validation (Line-by-line data verification)
            ↓
Visual Review (Layout, typography, table alignment inspection)
            ↓
Governance Review (Compliance check against REPORT_ENGINE_GOVERNANCE_V1.md)
            ↓
Approval (Sign-off by Governance Custodian)
            ↓
Create New Golden DOCX (Registered with new SHA-256 hash)
            ↓
Create New Golden PDF (Registered with new SHA-256 hash)
            ↓
Update Regression Baseline (Re-enable automated golden binary comparison)
            ↓
Re-Certify Production (New production seal issued)
```

**Current Operational Status:** `NEW GOLDEN REPORT PENDING`
