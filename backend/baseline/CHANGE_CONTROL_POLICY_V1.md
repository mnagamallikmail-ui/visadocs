# REPORT ENGINE CHANGE CONTROL POLICY (V1)
**Policy Version:** 1.0.0 (FROZEN PRODUCTION GOVERNANCE)  
**Effective Date:** 17-Sep-2026  
**Status:** ACTIVE, MANDATORY & STRICTLY ENFORCED  
**Applicability:** All contributors, developers, reviewers, and automated CI/CD build pipelines  

---

## 1. Purpose
This policy defines the formal, mandatory change management and release lockdown governance for the ProValuer Commercial Report Generation Engine. Its objective is to guarantee the absolute stability, mathematical fidelity, and visual consistency of the valuation report generation pipeline. Direct code edits without review, unverified formula modifications, unauthorized template alterations, and regression gate bypasses are strictly prohibited.

---

## 2. Scope
This policy applies to:
1. All changes touching the Report Generation Backend (`com.provaluer.*`).
2. All changes touching the Document Workspace Frontend (`document_workspace`, `document_studio`).
3. The sole source of truth template: `official_production_valuation_report.docx`.
4. The golden reference artifacts: `golden_production_report.docx` and `golden_production_report.pdf`.
5. All automated regression gates and verification test suites.

---

## 3. Governance Ownership
- **Governance Custodian:** Core Architecture & Valuation Engineering Governance Team.
- **Authority:** No pull request or merge commit affecting governance-controlled files may be merged without explicit sign-off from a designated Governance Custodian.
- **Automated Enforcement:** The CI/CD build pipeline operates `ProductionRegressionCertificationTest` on every push. A failed test represents an immediate, un-overridable build and merge block.

---

## 4. Mandatory Review Process
Every proposed modification must undergo a two-tier review:
1. **Tier 1 (Technical Code Review):** Verifies code quality, performance, null safety, and adherence to clean architecture principles.
2. **Tier 2 (Governance & Freeze Compliance Review):** Verifies that:
   - No controlled file is edited without an approved Impact Analysis.
   - All 8 governance domains (Text, Image, Date, Formula, Numeric, Rounding, Currency, Keyboard Navigation) remain intact.
   - `ProductionRegressionCertificationTest` passes with 100% green status.
   - Golden Report comparison outputs 0 structural, visual, or numerical deviations.

---

## 5. Controlled Files Inventory

The following 10 files represent the core governance perimeter. Any change to these files carries significant regression risk and requires mandatory Impact Analysis:

| Controlled File | Purpose | Risk Level | Governance Domains Affected | Regression Tests Impacted |
|---|---|---|---|---|
| `DocxTemplateEngine.java` | Core DOCX report generation, paragraph normalization, dynamic table injection, and image frame padding. | **CRITICAL** | Image, Text, Formula, Composite Table, Parameters Table, Image Boundaries | `ProductionRegressionCertificationTest`<br>`FreezeGovernanceCertificationTest`<br>`ComprehensiveRuntimeReportVerificationTest` |
| `DocxStructureParser.java` | OpenXML AST parsing, placeholder token extraction, and hard-stop field type inference. | **CRITICAL** | Text Governance, Date Governance, Image Governance | `ProductionRegressionCertificationTest`<br>`CriticalPostFormulaEngineGovernanceTest`<br>`DocxStructureParserTest` |
| `NumericFormulaEngine.java` | Mathematical expression evaluation (`CALC:`), token replacement, default N values, untouched tracking, and Rounding Approach A (HALF_UP). | **CRITICAL** | Formula Engine, Numeric Inputs, Rounding Governance | `ProductionRegressionCertificationTest`<br>`NumericFormulaEngineTest`<br>`CriticalPostFormulaEngineGovernanceTest` |
| `ValuationCalculationFormulaService.java` | Valuation business arithmetic, Composite item subtotal aggregation, and Say Value calculation. | **HIGH** | Composite Property Table, Valuation Parameters Table, Rounding Governance | `ProductionRegressionCertificationTest`<br>`FreezeGovernanceCertificationTest`<br>`ValuationEngineServiceTest` |
| `IndianNumberFormatter.java` | Indian numbering system formatter (`Rs #,##,###`). | **MEDIUM** | Currency Formatting Governance | `ProductionRegressionCertificationTest`<br>`CriticalPostFormulaEngineGovernanceTest` |
| `document_workspace_provider.dart` | Interactive workspace state management, reactive formula recomputation, and field value dispatch. | **CRITICAL** | Formula Engine, Zero Display, Keyboard Navigation, UI Synchronization | `critical_numeric_formula_engine_test.dart`<br>`placeholder_and_keyboard_governance_test.dart` |
| `workspace_view_model.dart` | View model definitions, multiline classification, generic text filtering, and image slot discrimination. | **HIGH** | Text Governance, Image Governance, UX Layout | `placeholder_and_keyboard_governance_test.dart`<br>`critical_inline_placeholder_governance_test.dart` |
| `document_input_slot_widget.dart` | Interactive text field slot, focus management, multiline ENTER handling, and TAB / Arrow traversal. | **HIGH** | Text Governance, Keyboard Navigation Governance | `placeholder_and_keyboard_governance_test.dart`<br>`phase3_2_keyboard_navigation_test.dart` |
| `inline_editable_placeholder_widget.dart` | Inline canvas editor, keyboard arrow navigation dispatch, and focus registration. | **HIGH** | Keyboard Navigation Governance, Text Display | `placeholder_and_keyboard_governance_test.dart` |
| `date_picker_helper.dart` | Date semantic classification and calendar picker invocation gating. | **MEDIUM** | Text Governance, Date Governance | `date_picker_helper_test.dart`<br>`date_field_ux_governance_widget_test.dart` |

---

## 6. Mandatory Regression Validation
Prior to opening any pull request or executing any release merge, the developer must execute:
1. **Backend Regression Certification:**
   ```powershell
   ./gradlew test --tests com.provaluer.util.ProductionRegressionCertificationTest --info
   ```
   *Requirement:* 9 of 9 test gates must pass. Zero failures. Zero errors.
2. **Frontend Governance Suite:**
   ```powershell
   flutter test test/placeholder_and_keyboard_governance_test.dart test/critical_numeric_formula_engine_test.dart
   ```
   *Requirement:* 23 of 23 test gates must pass. Zero failures. Zero errors.

---

## 7. Merge Blockers (Zero-Tolerance Gate)
A pull request or merge commit **MUST BE AUTOMATICALLY REJECTED** if any of the following conditions are met:

1. **Regression Gate Failure:** `ProductionRegressionCertificationTest` fails on any domain.
2. **Temporary Regression Baseline Policy Note:** Until a replacement golden report is approved per `REVOCATION_NOTICE_V1.md`, validation enforces structural and rule-based invariants rather than binary matching against revoked files.
3. **Anchor Count Deviation:** Number of Page 1 anchors deviates from 14.
4. **Table Disappearance:** Composite Property Valuation Table or Valuation Parameters Summary Table is missing.
5. **TEXT Classification Violation:** Any `TEXT*` or `TXT*` key resolves to `DATE` or `IMAGE`.
6. **IMAGE Classification Violation:** Any `IMG_*` key resolves to `TEXT`, or narrative notes resolve to `IMAGE`.
7. **Currency Deviation:** Formatting does not start with `Rs ` or deviates from `Rs #,##,###`.
8. **Formula Deviation:** Untouched inputs display `0` instead of blank (`""`), or mathematically calculated zero displays blank.
9. **Government Value Rounding:** Government Value is rounded in violation of the exact guideline rule.
10. **Image Boundary Overflow:** Uploaded photos exceed placeholder bounds ($cx \le 2743200$, $cy \le 1828800$), distort aspect ratio, or cause row expansion.
11. **Keyboard Navigation Breakdown:** `TAB`, `SHIFT+TAB`, `ARROW DOWN`, `ARROW UP`, or multiline `ENTER` fail navigation invariants.

---

## 8. Feature Request Workflow

No direct coding is permitted. Every new feature must progress strictly through the following stages:

```
+-------------------------------------------------------------------------+
|                        FEATURE REQUEST WORKFLOW                         |
+-------------------------------------------------------------------------+
|  1. Feature Request            Formal ticket created with business rationale
|         ↓
|  2. Requirements Analysis      Verify against REPORT_ENGINE_GOVERNANCE_V1.md
|         ↓
|  3. Implementation Plan        Architectural blueprint and proposed changes
|         ↓
|  4. Impact Analysis            Identify affected controlled files
|         ↓
|  5. Regression Risk Assessment Risk matrix and test mitigation strategy
|         ↓
|  6. Governance Approval        Sign-off by Governance Custodian
|         ↓
|  7. Implementation             Code written strictly to approved plan
|         ↓
|  8. Regression Test Execution  Execute full certification test suites
|         ↓
|  9. Golden Report Validation   Confirm 100% parity with golden baseline
|         ↓
| 10. Merge Approval             Reviewer sign-off & CI/CD gate pass
|         ↓
| 11. Release Deployment         Tagged and deployed per Versioning Policy
+-------------------------------------------------------------------------+
```

---

## 9. Bug Fix Workflow

Direct coding without root cause investigation is strictly prohibited:

```
+-------------------------------------------------------------------------+
|                           BUG FIX WORKFLOW                              |
+-------------------------------------------------------------------------+
|  1. Bug Report                 Document observed symptom and reproducer
|         ↓
|  2. Root Cause Analysis (RCA)  Determine exact failure mechanism
|         ↓
|  3. Files Impacted             Map against Controlled Files Inventory
|         ↓
|  4. Regression Risk Assessment Verify potential impact on other 7 domains
|         ↓
|  5. Fix Proposal               Minimal, non-invasive remediation plan
|         ↓
|  6. Approval                   Approval by Governance Custodian
|         ↓
|  7. Implementation             Surgical code fix (CHANGE NOTHING ELSE)
|         ↓
|  8. Regression Test Execution  Validate fix and run full regression suite
|         ↓
|  9. Golden Report Validation   Verify no visual or layout regression
|         ↓
| 10. Merge & Tag                Merge into main with patch increment
+-------------------------------------------------------------------------+
```

---

## 10. Versioning Governance

The report generation engine follows SemVer-aligned Governance Versioning:

### 10.1 Version Format
`REPORT_ENGINE_V<MAJOR>.<MINOR>.<PATCH>` (Baseline: `REPORT_ENGINE_BASELINE_V1` / `1.0.0`)

### 10.2 Release Criteria
- **Patch Release (`V1.0.X`):**
  - Bug fixes, internal performance optimizations, dependency updates that do not alter report layout, formulas, or placeholder contracts.
  - Golden DOCX and PDF must remain 100% identical.
- **Minor Release (`V1.X.0`):**
  - Backward-compatible additions (e.g. new optional placeholders, new valuation methodologies that do not alter existing composite reports).
  - Existing Golden DOCX and PDF must remain 100% backward compatible.
- **Major Release (`V2.0.0`):**
  - Fundamental template redesign, major OpenXML schema overhaul, or structural banking requirement changes.
  - Requires creating a new Golden Template, new Golden Baseline artifacts, and a formal `REPORT_ENGINE_GOVERNANCE_V2.md`.

---

## 11. Release Approval Workflow

Every deployment to Staging or Production requires complete verification of the formal Release Checklist. **Any unchecked box blocks the release.**

### Release Approval Checklist
- [ ] **Composite Property Valuation Table:** Verified present with Main Unit, Interior Works, Parking, and Fair Value rows.
- [ ] **Valuation Parameters Table:** Verified present with Fair, Realizable, Distress, Government, and Insurable values.
- [ ] **Front Page Image:** Verified present on Page 1 anchor with full alias parity.
- [ ] **Government Image:** Verified present and scaled within bounds.
- [ ] **Site Photos:** Verified present with letterboxing and aspect ratio preserved.
- [ ] **Formula Engine:** Verified reactive calculation with untouched blank display and genuine zero preservation.
- [ ] **Currency Formatting:** Uniform `Rs #,##,###` across Workspace, DOCX, and PDF.
- [ ] **Rounding Governance:** Approach A (HALF_UP) verified for Realizable, Distress, and Insurable; Government Value exact.
- [ ] **TEXT Governance:** Hard-stop rule verified; zero date or image widgets on text slots.
- [ ] **Image Governance:** Containment verified; no table row expansion or overflow.
- [ ] **Keyboard Navigation:** TAB, SHIFT+TAB, UP, DOWN, ENTER verified across all inputs.
- [ ] **Replacement Golden DOCX:** Manual visual inspection completed and approved (previous report REVOKED).
- [ ] **Replacement Golden PDF:** Manual visual inspection completed and approved (previous report REVOKED).

---

## 12. Rollback Governance

If an unexpected anomaly or regression is detected in production post-deployment, the following rollback protocol must be executed immediately:

1. **Step 1 – Incident Identification:** Identify the release tag and commit hash causing the regression.
2. **Step 2 – Git Tag Restoration:** Roll back production deployment to the last known green baseline tag (e.g., `REPORT_ENGINE_BASELINE_V1`).
   ```bash
   git checkout tags/REPORT_ENGINE_BASELINE_V1
   ```
3. **Step 3 – Golden DOCX Restoration:** Restore the canonical template and golden DOCX from `backend/baseline/golden_production_report.docx`.
4. **Step 4 – Golden PDF Restoration:** Restore the canonical golden PDF from `backend/baseline/golden_production_report.pdf`.
5. **Step 5 – Regression Gate Verification:** Execute `./gradlew test --tests com.provaluer.util.ProductionRegressionCertificationTest` to confirm 100% green status on the restored state.
6. **Step 6 – Redeployment:** Redeploy the verified baseline to production and issue an Incident Root Cause notice.

---

## 13. Emergency Fix Process (Hotfix)

In the event of a critical production blocker requiring a hotfix:
1. An emergency hotfix branch (`hotfix/issue-description`) must be branched directly from the current production tag.
2. The change must be restricted strictly to the minimal necessary code lines (*CHANGE NOTHING ELSE*).
3. The hotfix must include a dedicated regression test case verifying the fix and confirming that none of the 8 governance domains are breached.
4. `ProductionRegressionCertificationTest` must be executed locally and in CI.
5. Emergency sign-off from at least one Governance Custodian is required before merging.
6. A patch release tag (`V1.0.X`) must be created immediately upon merge.

---

## 14. Permanent Freeze Declaration

By order of Project Governance:
> **No change to any of the 10 governance-controlled files may be merged without:**
> 1. Documented Root Cause Analysis.
> 2. Documented Impact Analysis.
> 3. Documented Regression Risk Assessment.
> 4. 100% Pass of `ProductionRegressionCertificationTest`.
> 5. 100% Pass of Golden Report Comparison (`current_report.*` == `golden_production_report.*`).
> 6. Recorded Reviewer & Governance Custodian Approval.

This change control policy is active and permanently binding.
