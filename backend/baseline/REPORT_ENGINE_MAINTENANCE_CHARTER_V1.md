# REPORT ENGINE MAINTENANCE CHARTER & ANNUAL GOVERNANCE POLICY (V1)
**Charter Version:** 1.0.0 (FROZEN PRODUCTION CHARTER)  
**Effective Date:** 17-Sep-2026  
**Status:** ACTIVE, MANDATORY & PERMANENTLY BINDING  
**Applicability:** Governance Board, Engineering Leads, DevOps, QA, Product Management  

---

## 1. Governance Authority & Decision Rights

To ensure that the report generation engine cannot be degraded by ad-hoc changes or organizational turnover, decision rights are formally allocated as follows:

| Decision Scope | Approval Authority Required | Quorum & Voting Rule |
|---|---|---|
| **Code Modifications** (to 10 Controlled Files) | Core Architecture Lead + Lead Valuation Engineer | Unanimous dual approval required. |
| **Production Releases** | Release Engineering Lead + Lead QA Engineer | Requires 100% pass on Release Checklist. |
| **Baseline Modifications** (Golden DOCX/PDF) | Governance Board (Architect, Product Owner, Valuation Lead) | Unanimous 3-party approval after formal impact audit. |
| **Template Alterations** (`official_production_valuation_report.docx`) | Chief Valuation Architect | Written authorization with full regression suite run. |
| **Emergency Hotfixes** | Incident Commander + Architecture Lead | Dual sign-off followed by retrospective within 48h. |

---

## 2. Operational Governance Cadence

The health and compliance of the report generation engine are maintained through regular, scheduled governance activities:

| Activity | Frequency | Responsible Role | Deliverable |
|---|---|---|---|
| **Regression Gate Execution** | Every Build / Commit | Automated CI/CD Pipeline | Green build verification log. |
| **Controlled Files Audit** | Bi-weekly | Security & Governance Lead | Git commit diff audit against 10 controlled files. |
| **Disaster Recovery Drill** | Monthly | DevOps & Release Engineering | Simulated restoration and test pass log. |
| **Quarterly Governance Review** | Quarterly | Full Governance Board | Health scorecard & compliance certification. |
| **Annual Governance Overhaul** | Annually (September) | Executive Governance Committee | Formal Annual Review Sign-off. |

---

## 3. Disaster Recovery & Drill Schedule

Monthly disaster recovery drills must be executed during low-traffic maintenance windows according to the runbooks in [DISASTER_RECOVERY_V1.md](file:///d:/Demo/Visadocs/ProValuer%20Commercial/DISASTER_RECOVERY_V1.md):
1. **Drill 1 (Template Recovery):** Deliberately simulate template deletion and verify restoration from `backend/baseline/`.
2. **Drill 2 (Checksum Verification):** Verify SHA-256 hashes of all 6 baseline artifacts.
3. **Drill 3 (Automated DR Gate):** Execute `./gradlew test --tests com.provaluer.util.DisasterRecoveryCertificationTest` and archive logs.
4. **Drill 4 (Rollback Rehearsal):** Validate container rollback to `REPORT_ENGINE_BASELINE_V1` in staging environment.

---

## 4. Annual Governance Review Procedure

Every 12 months, the Governance Board must conduct a formal, end-to-end review of the valuation engine across the following 7 dimensions:

### 1. Business Rules Audit
- Review Indian banking guidelines (IBA / SARFAESI / NHB regulations) for changes in mandatory valuation parameters.
- Verify whether additional bank-specific summary rows are required without perturbing the baseline composite table.

### 2. Formula Engine Audit
- Verify mathematical correctness of `NumericFormulaEngine`.
- Review rounding threshold performance (Lakhs vs Crores) against real-world portfolio valuation datasets.

### 3. Currency Formatting Audit
- Verify Indian numbering system formatting (`Rs #,##,###`).
- Confirm zero currency display (`Rs 0`) and blank display for untouched inputs.

### 4. Image Governance Audit
- Audit image upload aspect ratio preservation across modern high-resolution camera devices (e.g. 50MP, 108MP phone cameras).
- Confirm zero image overflow or table cell distortion in generated PDFs.

### 5. Template Governance Audit
- Verify that `official_production_valuation_report.docx` remains identical to canonical baseline.
- Audit Page 1 anchor drawings to ensure all 14 frames remain intact.

### 6. Disaster Recovery Audit
- Review offsite backup storage locations, S3 object locks, and retention policies.
- Audit RTO ($\le 15\text{ min}$) and RPO ($0\text{ sec}$) compliance logs.

### 7. Regression Suite Audit
- Review test coverage in `ProductionRegressionCertificationTest` and `DisasterRecoveryCertificationTest`.
- Ensure new test cases are added for any edge case discovered during production operations.

---

## 5. Review Triggers (Ad-Hoc Governance Review)
In addition to the scheduled annual review, an extraordinary governance review is automatically triggered by any of the following events:
1. Any production P1 incident involving the report generation engine.
2. Any banking regulator update affecting valuation report format requirements.
3. Any upgrade to major framework dependencies (e.g., Spring Boot major version, Docx4j major version, Java LTS upgrade).
4. Any failure of an automated monthly disaster recovery drill.

---

## 6. Maintenance Charter Declaration

This Maintenance Charter is permanently binding on all engineering and product teams supporting the ProValuer Commercial platform. No exception to these policies may be granted without unanimous written consent from the Governance Board.
