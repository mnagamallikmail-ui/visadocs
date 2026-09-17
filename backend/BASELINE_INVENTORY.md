# OFFICIAL GOVERNANCE BASELINE INVENTORY
**Inventory Version:** 1.1.0  
**Effective Date:** 17-Sep-2026  
**Status:** ACTIVE GOVERNANCE REPOSITORY  
**Location:** `golden/`  

---

## 1. Production Source of Truth Template

| Artifact | Canonical Path | Size | SHA-256 Checksum | Certification Status |
|---|---|---|---|---|
| `official_production_valuation_report.docx` | `backend/official_production_valuation_report.docx` | 1,530,900 bytes | `A13949299698F460B2988670B60DCD525EAAA70DEC9866DFDC2688963C421FC1` | **CERTIFIED SOLE SOURCE OF TRUTH** |

---

## 2. Generated Report Status (Revocation Log)

| Artifact | File Size | SHA-256 Checksum | Current Status | Notes |
|---|---|---|---|---|
| `golden_production_report.docx` | 1,635,614 bytes | `C6EE0D9C2FD107801D0880F262A576EDBF281B271E0A390D820DFEFC631686B3` | **REVOKED (NOT CERTIFIED)** | Fails visual inspection (table placement, blank fields, duplicates). |
| `golden_production_report.pdf` | 1,621,002 bytes | `9E3F0ABF1B88EF58AE35B6A93F29D57DECED8B4300529F9E73472C1A2C22FC64` | **REVOKED (NOT CERTIFIED)** | Fails visual inspection. |

**Replacement Status:** `NEW GOLDEN REPORT PENDING MANUAL APPROVAL`

---

## 3. Governance Baseline Documents in `golden/`

| Document | Purpose | Governance Status |
|---|---|---|
| `REPORT_ENGINE_GOVERNANCE_V1.md` | Core specification for all 8 governance domains | **CERTIFIED** |
| `CHANGE_CONTROL_POLICY_V1.md` | Change management and review controls | **CERTIFIED** |
| `DISASTER_RECOVERY_V1.md` | DR scenarios and restoration runbooks | **CERTIFIED** |
| `PRODUCTION_SIGNOFF_V1.md` | Formal sign-off record and status tracker | **CERTIFIED (GOLDEN REPORT REVOKED)** |
| `REPORT_ENGINE_MAINTENANCE_CHARTER_V1.md` | Operational decision rights and audit cadence | **CERTIFIED** |
| `REVOCATION_NOTICE_V1.md` | Formal revocation declaration and replacement criteria | **CERTIFIED & ACTIVE** |
| `REGRESSION_GATE_SPECIFICATION.md` | Specification of active automated build gates | **CERTIFIED** |
| `GOVERNANCE_SEAL.md` | Governance state summary and seal declaration | **CERTIFIED** |

---

## 4. Controlled Files Perimeter
The 10 controlled files remain subject to the Change Control Policy:
1. `DocxTemplateEngine.java`
2. `DocxStructureParser.java`
3. `NumericFormulaEngine.java`
4. `ValuationCalculationFormulaService.java`
5. `IndianNumberFormatter.java`
6. `document_workspace_provider.dart`
7. `workspace_view_model.dart`
8. `document_input_slot_widget.dart`
9. `inline_editable_placeholder_widget.dart`
10. `date_picker_helper.dart`
