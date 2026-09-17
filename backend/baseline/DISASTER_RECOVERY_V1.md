# REPORT ENGINE DISASTER RECOVERY & BASELINE RESTORATION SPECIFICATION (V1)
**Specification Version:** 1.0.0 (FROZEN PRODUCTION DISASTER RECOVERY)  
**Effective Date:** 17-Sep-2026  
**Status:** ACTIVE, CERTIFIED & RECOVERABLE  
**Canonical Template:** `official_production_valuation_report.docx`  
**Primary Archive:** `backend/baseline/`  

---

## 1. Purpose
This specification establishes the mandatory disaster recovery (DR), baseline restoration, and emergency failover protocols for the ProValuer Commercial Report Generation Engine. It ensures that any catastrophic failure—including repository corruption, binary deletion, template degradation, governance policy loss, or defective production deployment—can be remediated rapidly with zero data loss, zero mathematical deviation, and zero visual regression.

---

## 2. Recovery Governance & Ownership

| Role | Responsibility | Escalation Target |
|---|---|---|
| **Incident Commander (IC)** | Declares DR event, directs recovery scenario execution, and signs off on restoration. | Lead System Architect |
| **Governance Custodian** | Validates cryptographic checksums, template fidelity, and regression gate status. | Lead Valuation Engineer |
| **Release Engineer** | Executes Git rollback, backup restoration commands, and deployment verification. | Lead DevOps Engineer |

### Recovery Objectives & Service Level Indicators
- **Recovery Time Objective (RTO):** $\le 15\text{ minutes}$ from incident declaration to verified production redeployment.
- **Recovery Point Objective (RPO):** $0\text{ seconds}$ (Zero data drift; restored state must match the certified baseline exactly).
- **Verification Requirement:** 100% pass rate on `DisasterRecoveryCertificationTest` and `ProductionRegressionCertificationTest`.

---

## 3. Disaster Recovery Scenarios & Procedures

### Scenario 1: Repository Corruption Recovery
*Failure Condition:* Git history becomes corrupted, branch references are lost, or working tree state is unrecoverable.

**Restoration Procedure:**
1. Clone or fetch the remote canonical origin from the immutable corporate mirror:
   ```bash
   git fetch --all --tags --prune
   ```
2. Hard reset working tree to the certified immutable baseline tag `REPORT_ENGINE_BASELINE_V1`:
   ```bash
   git checkout -B main tags/REPORT_ENGINE_BASELINE_V1
   git reset --hard tags/REPORT_ENGINE_BASELINE_V1
   git clean -fdx
   ```
3. Run automated regression gate to verify codebase integrity:
   ```powershell
   ./gradlew test --tests com.provaluer.util.DisasterRecoveryCertificationTest
   ```
4. Confirm build passes with 0 failures and 0 errors.

---

### Scenario 2: Golden Artifact Deletion Recovery
*Failure Condition:* One or more of the following critical binary artifacts are deleted or corrupted:
- `backend/official_production_valuation_report.docx`
- `backend/build/golden_production_report.docx`
- `backend/build/golden_production_report.pdf`

**Restoration Procedure:**
1. Restore files immediately from the immutable `backend/baseline/` mirror:
   ```powershell
   # Restore Canonical Template
   Copy-Item "backend\baseline\official_production_valuation_report.docx" "backend\official_production_valuation_report.docx" -Force
   
   # Restore Golden Generated Artifacts
   New-Item -ItemType Directory -Force -Path "backend\build" | Out-Null
   Copy-Item "backend\baseline\golden_production_report.docx" "backend\build\golden_production_report.docx" -Force
   Copy-Item "backend\baseline\golden_production_report.pdf" "backend\build\golden_production_report.pdf" -Force
   ```
2. Validate SHA-256 cryptographic hashes:
   ```powershell
   Get-FileHash -Algorithm SHA256 "backend\official_production_valuation_report.docx", "backend\build\golden_production_report.docx", "backend\build\golden_production_report.pdf"
   ```
   *Expected Hashes:*
   - `official_production_valuation_report.docx`: `A13949299698F460B2988670B60DCD525EAAA70DEC9866DFDC2688963C421FC1`
   - `golden_production_report.docx`: `C6EE0D9C2FD107801D0880F262A576EDBF281B271E0A390D820DFEFC631686B3`
   - `golden_production_report.pdf`: `9E3F0ABF1B88EF58AE35B6A93F29D57DECED8B4300529F9E73472C1A2C22FC64`
3. Execute `DisasterRecoveryCertificationTest` to certify restored state.

---

### Scenario 3: Failed Production Deployment
*Failure Condition:* A newly deployed release in production displays broken table layouts, truncated valuations, or missing images.

**Restoration Procedure:**
1. **Identify Faulty Release:** Inspect application startup banner or query health endpoint `/api/actuator/info` for active Git commit and version tag.
2. **Execute Rollback:** Instantly pull the current container/pod traffic and redeploy the baseline tag container:
   ```bash
   git checkout tags/REPORT_ENGINE_BASELINE_V1
   docker build -t provaluer-backend:baseline .
   docker stop provaluer-production-backend
   docker run -d --name provaluer-production-backend -p 8080:8080 provaluer-backend:baseline
   ```
3. **Verify Restored Endpoint:** Run live smoke test on report generation endpoint `/api/orders/{id}/generate-report` and verify PDF byte stream response.
4. **Log Incident Report:** Open formal P1 Incident ticket with root cause analysis.

---

### Scenario 4: Corrupted Template Recovery
*Failure Condition:* `official_production_valuation_report.docx` has been edited in Word or modified by an unauthorized script, altering paragraph structure, table bookmarks, or drawing anchors.

**Restoration Procedure:**
1. **Detect Corruption:** Check template SHA-256 hash against baseline:
   ```powershell
   $hash = (Get-FileHash -Algorithm SHA256 "backend\official_production_valuation_report.docx").Hash
   if ($hash -ne "A13949299698F460B2988670B60DCD525EAAA70DEC9866DFDC2688963C421FC1") {
       Write-Warning "TEMPLATE CORRUPTION DETECTED! Current Hash: $hash"
   }
   ```
2. **Restore Template:**
   ```powershell
   Copy-Item "backend\baseline\official_production_valuation_report.docx" "backend\official_production_valuation_report.docx" -Force
   ```
3. **Verify Structural Counts:**
   - Total Tables: 8 (7 body + 1 header)
   - Distinct Placeholders: 75
   - Image Anchors: 14 (100% Page 1 preservation)
   - Image DocPr Elements: 9

---

### Scenario 5: Governance Document Loss Recovery
*Failure Condition:* `REPORT_ENGINE_GOVERNANCE_V1.md` or `CHANGE_CONTROL_POLICY_V1.md` is deleted or corrupted.

**Restoration Procedure:**
1. Restore specifications from the baseline archive:
   ```powershell
   Copy-Item "backend\baseline\REPORT_ENGINE_GOVERNANCE_V1.md" "REPORT_ENGINE_GOVERNANCE_V1.md" -Force
   Copy-Item "backend\baseline\CHANGE_CONTROL_POLICY_V1.md" "CHANGE_CONTROL_POLICY_V1.md" -Force
   Copy-Item "backend\baseline\REPORT_ENGINE_GOVERNANCE_V1.md" "backend\REPORT_ENGINE_GOVERNANCE_V1.md" -Force
   Copy-Item "backend\baseline\CHANGE_CONTROL_POLICY_V1.md" "backend\CHANGE_CONTROL_POLICY_V1.md" -Force
   ```
2. Validate SHA-256 checksums match the baseline record.

---

### Scenario 6: Broken Report Generation Failover
*Failure Condition:* The engine generates reports missing the Composite Property Table, Valuation Parameters Table, or front page image, or image boundary overflow is detected.

**Restoration Procedure:**
1. Run diagnostic regression gate to isolate failing domain:
   ```powershell
   ./gradlew test --tests com.provaluer.util.ProductionRegressionCertificationTest
   ```
2. Locate specific failure domain in test output (e.g. `[REGRESSION VIOLATION - DOMAIN 3]`).
3. Revert unreviewed changes in the identified controlled file:
   ```bash
   git checkout tags/REPORT_ENGINE_BASELINE_V1 -- backend/src/main/java/com/provaluer/util/DocxTemplateEngine.java
   ```
4. Re-run `./gradlew test --tests com.provaluer.util.ProductionRegressionCertificationTest` until 100% green.

---

### Scenario 7: Failed Regression Gate Investigation Workflow
*Failure Condition:* CI/CD pipeline triggers automated build failure during PR checks.

**Investigation & Root Cause Workflow:**
```
CI/CD Pipeline Failure
      ↓
Inspect Gradle Test Report (build/reports/tests/test/index.html)
      ↓
Identify Failed Gate ([GATE-1] through [GATE-8] or [GOLDEN GATE])
      ↓
Check Git Diff against controlled files (git diff HEAD~1)
      ↓
Is change authorized by an approved Feature Request / Bug Fix Plan?
├── NO  → Immediately revert commit. Reject PR.
└── YES → Analyze violation mechanism:
          - Did placeholder type change?
          - Did rounding threshold shift?
          - Did image pad dimension alter?
      ↓
Remediate code to comply with REPORT_ENGINE_GOVERNANCE_V1.md
      ↓
Re-run local regression suite until 100% passing
```

---

### Scenario 8: Defective Merge Recovery
*Failure Condition:* Defective commit was merged into `main` after passing shallow review.

**Restoration Procedure:**
1. Isolate the defective merge commit: `git log -n 5 --oneline`
2. Create a clean revert commit:
   ```bash
   git revert -m 1 <MERGE_COMMIT_HASH> -m "REVERT: Defective merge violating Report Engine Governance"
   git push origin main
   ```
3. Verify that `main` returns to 100% green status via CI build.

---

## 4. Offsite Backup Governance

To safeguard against total data center or filesystem loss, the following permanent backup strategy is enforced:

### Protected Artifacts
1. `official_production_valuation_report.docx` (Canonical Word template)
2. `golden_production_report.docx` (Golden generated DOCX)
3. `golden_production_report.pdf` (Golden generated PDF)
4. `REPORT_ENGINE_GOVERNANCE_V1.md` (Governance specification)
5. `CHANGE_CONTROL_POLICY_V1.md` (Change control policy)
6. `DISASTER_RECOVERY_V1.md` (Disaster recovery specification)

### Backup Schedule & Retention
- **Backup Frequency:** Continuous synchronization on every Git tag; nightly offsite snapshot to geo-redundant object storage (`s3://provaluer-governance-backup/baseline/`).
- **Retention Policy:** Immutable versioning with WORM (Write Once, Read Many) object lock enabled. Permanent retention (never expire).
- **Storage Locations:**
  - Local Mirror: `backend/baseline/`
  - Secondary Mirror: Corporate Git Tag Archive (`tags/REPORT_ENGINE_BASELINE_V1`)
  - Remote Offsite: Encrypted cloud object storage with SHA-256 metadata verification.
- **Recovery Verification Schedule:** Automated monthly DR drill executing full restoration and certification test suite.

---

## 5. Summary of Checksums & Baseline Constants

```
+---------------------------------------------------------------------------------------------------------+
|                                    BASELINE CRYPTOGRAPHIC INVENTORY                                     |
+---------------------------------------------------------------------------------------------------------+
| File: official_production_valuation_report.docx                                                         |
| Status: CERTIFIED SOLE SOURCE OF TRUTH                                                                  |
| SHA-256: A13949299698F460B2988670B60DCD525EAAA70DEC9866DFDC2688963C421FC1                             |
| Size: 1,530,900 bytes                                                                                   |
|                                                                                                         |
| File: golden_production_report.docx                                                                     |
| Status: REVOKED (Output defects - replacement report pending manual approval)                           |
| SHA-256: C6EE0D9C2FD107801D0880F262A576EDBF281B271E0A390D820DFEFC631686B3                             |
| Size: 1,635,614 bytes                                                                                   |
|                                                                                                         |
| File: golden_production_report.pdf                                                                      |
| Status: REVOKED (Output defects - replacement report pending manual approval)                           |
| SHA-256: 9E3F0ABF1B88EF58AE35B6A93F29D57DECED8B4300529F9E73472C1A2C22FC64                             |
| Size: 1,621,002 bytes                                                                                   |
|                                                                                                         |
| Canonical Template Tables: 8                                                                            |
| Anchors on Page 1: 14                                                                                   |
+---------------------------------------------------------------------------------------------------------+
```

This disaster recovery specification is certified active, tested, and permanently binding. Per REVOCATION_NOTICE_V1.md, golden_production_report.* are revoked until replacement approval.
