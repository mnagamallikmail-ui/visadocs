# GOVERNANCE CHANGE CHECKLIST
## MANDATORY PROTOCOL FOR PROVALUER COMMERCIAL ENGINE EVOLUTION

**Document Version:** 1.0  
**Effective Date:** September 18, 2026  
**Enforcement Level:** STRICT / ZERO TOLERANCE  
**Authority:** ProValuer Core Architecture Governance Board  

---

## 1. APPLICABILITY & MANDATE

This checklist is **MANDATORY** before any developer, architect, or maintainer makes any code or template change affecting:

* [ ] **Valuation Methodology Definitions** (`LAND_ONLY`, `LAND_AND_BUILDING`, `FLAT_APARTMENT`)
* [ ] **Physical Template Structures & Section 7 Sequencing**
* [ ] **Placeholder Definitions & Inference Rules** (e.g., `TEXT`, `IMAGE`, `DATE`)
* [ ] **Valuation Calculation Formulas & Rounding Rules**
* [ ] **Summary Table Routing Logic** (`buildLandSummary`, `buildDynamicValuationSummaryTable`, `buildDynamicCompositeSummaryTable`)
* [ ] **Template Upload Validation Rules** (`Upload Rules 1–5`)
* [ ] **Photo Containerization & TOC Isolation Rules**

**RULE:** No Pull Request may be reviewed, approved, or merged if any checklist item remains unchecked or unverified.

---

## 2. THE 5-STAGE GOVERNANCE CHANGE CHECKLIST

### STAGE 1: BASELINE GOVERNANCE SPECIFICATION UPDATE
Before touching any Java or template files, update the canonical specifications under `backend/baseline/`:
* [ ] Identify which baseline documents are affected (`BusinessGovernanceRules.md`, `TemplateGovernanceRules.md`, `MethodologyGovernanceRules.md`, `RenderingCertificationRules.md`, `PlaceholderGovernanceRules.md`, `CalculationGovernanceRules.md`).
* [ ] Formulate exact rule wording changes with formal mathematical formulas, layout diagrams, and schema definitions.
* [ ] Ensure the proposed change introduces zero conflicting rules with existing invariant rules (especially Rule 1 Single Source of Truth, Rule 7 Exclusivity, and Rule 11 Address Preservation).
* [ ] Update [`MASTER_GOVERNANCE_SPECIFICATION.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/MASTER_GOVERNANCE_SPECIFICATION.md).

### STAGE 2: CERTIFICATION TEST SUITE UPDATE (TDD ENFORCEMENT)
Before modifying production implementation:
* [ ] Update or create rule-based test methods in `com.provaluer.util.*` asserting the new or amended business rules.
* [ ] Verify that no new test depends on golden documents, binary snapshots, PDF visual page snapshots, or hardcoded file hashes.
* [ ] Run the test suite to confirm the new assertions properly fail against the existing unchanged code (asserting test validity).

### STAGE 3: RULE TRACEABILITY MATRIX UPDATE
* [ ] Update the Rule Traceability Matrix in [`ArchitectureFreezeManifest.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/ArchitectureFreezeManifest.md) and [`MASTER_GOVERNANCE_SPECIFICATION.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/MASTER_GOVERNANCE_SPECIFICATION.md).
* [ ] Ensure every new/modified rule has:
  * Unique Rule ID
  * Formal Rule Description
  * Canonical Governance File citation
  * Test Suite class name
  * Test Method name
  * Specific Validation Logic description

### STAGE 4: IMPLEMENTATION & 100% REGRESSION PASS
* [ ] Implement the code changes in `com.provaluer.*` adhering strictly to clean architecture and existing design tokens.
* [ ] Execute all 8 certification suites:
  ```powershell
  ./gradlew test --tests "com.provaluer.util.TemplateGovernanceCertificationTest" `
                 --tests "com.provaluer.util.TemplateLibraryCertificationTest" `
                 --tests "com.provaluer.util.FreezeGovernanceCertificationTest" `
                 --tests "com.provaluer.util.ProductionRegressionCertificationTest" `
                 --tests "com.provaluer.util.RegressionRemediationValidationTest" `
                 --tests "com.provaluer.util.RealTemplateCertificationTest" `
                 --tests "com.provaluer.util.DisasterRecoveryCertificationTest" `
                 --tests "com.provaluer.util.ArchitectureFreezeComplianceTest"
  ```
* [ ] Confirm **100% PASS (BUILD SUCCESSFUL, 0 failures, 0 errors)**.

### STAGE 5: ARCHITECTURE FREEZE MANIFEST & CHANGE LOG SIGN-OFF
* [ ] Log the complete modification details in [`ArchitectureChangeLog.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/ArchitectureChangeLog.md).
* [ ] Submit Pull Request with the completed checklist attached.
* [ ] Obtain formal review and sign-off from the Lead Architecture Governance Officer.

---

## 3. SIGN-OFF BLOCK

```
Change ID: __________________________________________________
Title: ______________________________________________________
Author: _____________________________________________________
Reviewing Architect: ________________________________________
Date of Sign-off: ___________________________________________
CI/CD Verification Run URL: _________________________________
Status: [ ] APPROVED  [ ] REJECTED (Deficiencies Noted)
```
