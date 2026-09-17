# REGRESSION GATE & TEMPORARY VALIDATION POLICY SPECIFICATION
**Specification Version:** 1.1.0  
**Effective Date:** 17-Sep-2026  
**Status:** ACTIVE & MANDATORY  
**Repository Location:** `golden/REGRESSION_GATE_SPECIFICATION.md`  

---

## 1. Context & Temporary Policy
Following the formal revocation of `golden_production_report.docx` and `golden_production_report.pdf` (see `REVOCATION_NOTICE_V1.md`), regression validation must **NOT** compare newly generated reports against the revoked files.

Until a new golden report is manually approved, automated validation operates under the **Temporary Regression Baseline Policy**.

---

## 2. Temporary Validation Perimeter
All automated CI/CD builds, pull requests, and commit checks must validate against:

1. **Governance Rules:**
   - Text hard-stop rule: `TEXT*` and `TXT*` keys strictly resolve to `TEXT`, never `DATE` or `IMAGE`.
   - Image prefix rule: `IMG_*` and `IMAGE_*` keys strictly resolve to `IMAGE`.
   - Caption disambiguation: descriptive notes containing "image" remain `TEXT`.
   - Alias parity: `IMG_FRONT_PAGE`, `IMG_COVER_PAGE`, `COVER_IMAGE` bind to Page 1 anchor.
2. **Structural Rules:**
   - OpenXML DOM tree integrity without broken runs or corrupted tags.
   - Preservation of `AlternateContent`, `Anchor`, `Inline`, and `Drawing` elements.
   - Table cell and row invariants (`w:cantSplit`).
3. **Placeholder Rules:**
   - Unpopulated placeholders resolve to empty string (`""`), never leaking raw tokens (`<<...>>`).
4. **Formula & Calculation Rules:**
   - Numeric inputs `N\d+` default internally to `0.0`.
   - Untouched inputs evaluate with `allInputsUntouched = true` and display blank (`""`).
   - Genuine mathematical zero ($500 - 500 = 0$) displays `0` (or `Rs 0`).
   - Government Value remains exact to the rupee (never rounded).
   - Approach A (HALF_UP) rounding applies to Realizable, Distress, and Insurable values.
5. **Image Containment Rules:**
   - Aspect ratio strictly preserved on white canvas.
   - Dimension capped at 1600px.
   - Zero overflow outside placeholder frame ($cx \le 2743200$, $cy \le 1828800$).
   - Zero table cell distortion or row expansion.
6. **Table Existence & Content Rules:**
   - Composite Property Valuation Table present with Main Unit, Interior Works, Parking, and Fair Value rows.
   - Valuation Parameters Summary Table present with Fair, Realizable, Distress, Government, and Insurable values.
   - Uniform Indian currency formatting (`Rs #,##,###`).

---

## 3. Re-enabling Binary Comparison Gate
Once a replacement report is generated and passes manual inspection:
1. Candidate DOCX and PDF are copied into `golden/` as the new golden artifacts.
2. New SHA-256 hashes are recorded in `BASELINE_INVENTORY.md`.
3. Binary golden comparison gates are re-activated to enforce bit-level and visual layout parity.
