# FREEZE PROTECTED FILE INVENTORY
## PROVALUER COMMERCIAL REPORT GENERATION & VALUATION ENGINE

**Document Version:** 1.0  
**Effective Date:** September 18, 2026  
**Protection Level:** TIER 1 - IMMUTABLE ARCHITECTURE BASELINE  
**Authority:** ProValuer Core Architecture Governance Board  

---

## 1. PURPOSE & PROTECTION POLICY

This inventory defines the definitive catalog of **Freeze Protected Files**. These files represent the canonical source of truth for all business rules, template schemas, methodology detection heuristics, calculation invariants, and output rendering standards. 

Under the Architecture Freeze Governance Mandate:
* **No modification** may be made to any file listed herein without completing the formal 5-step [Governance Change Checklist](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/GovernanceChangeChecklist.md).
* **Direct commits** or automated code modifications targeting these files are strictly prohibited.
* Automated CI/CD gates via [`ArchitectureFreezeComplianceTest`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/src/test/java/com/provaluer/util/ArchitectureFreezeComplianceTest.java) continuously verify the existence, structural integrity, and non-corruption of every listed artifact.

---

## 2. PROTECTED GOVERNANCE SPECIFICATIONS

The following markdown specifications define the permanent binding rules of the engine:

| # | File Name | Location | Scope & Invariants Protected |
|---|---|---|---|
| 1 | [`MASTER_GOVERNANCE_SPECIFICATION.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/MASTER_GOVERNANCE_SPECIFICATION.md) | `backend/baseline/` | Master Consolidation Specification defining platform overview, methodologies, rules 1–12, freeze policy, and production templates. |
| 2 | [`ArchitectureFreezeManifest.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/ArchitectureFreezeManifest.md) | `backend/baseline/` | Formal architecture freeze declaration, 14-section compliance seal, and Rule Traceability Matrix. |
| 3 | [`BusinessGovernanceRules.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/BusinessGovernanceRules.md) | `backend/baseline/` | The 12 Canonical Business Rules governing methodology, exclusivity, calculations, and placeholders. |
| 4 | [`TemplateGovernanceRules.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/TemplateGovernanceRules.md) | `backend/baseline/` | Canonical template catalog, Section 7 table sequencing, and Upload Rules 1–5. |
| 5 | [`MethodologyGovernanceRules.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/MethodologyGovernanceRules.md) | `backend/baseline/` | Template-driven methodology detection heuristics and strict prohibition of runtime metadata influence. |
| 6 | [`RenderingCertificationRules.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/RenderingCertificationRules.md) | `backend/baseline/` | OpenXML styling standards, container boundary containment, `cantSplit` protection, and TOC photo isolation. |
| 7 | [`PlaceholderGovernanceRules.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/PlaceholderGovernanceRules.md) | `backend/baseline/` | Hard-stop `TEXT` rule, `PROPERTY_ADDRESS` preservation mandate, rate alias mappings, and zero phantom placeholders. |
| 8 | [`CalculationGovernanceRules.md`](file:///d:/Demo/Visadocs/ProValuer%20Commercial/backend/baseline/CalculationGovernanceRules.md) | `backend/baseline/` | Property Fair Value equation, Land/Building Realizable and Distress % independence, and Rounding Approach A. |

---

## 3. PROTECTED PRODUCTION TEMPLATES (CANONICAL & BASELINE MIRRORS)

The physical Microsoft Word template files are frozen under Option A Binary Immutability:

| # | Template File Name | Production Location | Baseline Recovery Mirror | Methodology |
|---|---|---|---|---|
| 1 | `official_land_valuation_report.docx` | `backend/official_land_valuation_report.docx` | `backend/baseline/official_land_valuation_report.docx` | `LAND_ONLY` |
| 2 | `official_production_valuation_report.docx` | `backend/official_production_valuation_report.docx` | `backend/baseline/official_production_valuation_report.docx` | `LAND_AND_BUILDING` |
| 3 | `official_flat_apartment_valuation_report.docx` | `backend/official_flat_apartment_valuation_report.docx` | `backend/baseline/official_flat_apartment_valuation_report.docx` | `FLAT_APARTMENT` (`COMPOSITE`) |

---

## 4. INTEGRITY ENFORCEMENT GATE

Any pull request, commit, or branch where any of the above 11 artifacts is missing, renamed, or corrupted will immediately fail the build via:
```bash
./gradlew test --tests "com.provaluer.util.ArchitectureFreezeComplianceTest"
```
