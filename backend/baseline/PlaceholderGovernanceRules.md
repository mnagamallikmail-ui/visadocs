# AUTHORITATIVE PLACEHOLDER GOVERNANCE RULES

**Version:** 1.0  
**Effective Date:** Immediate  
**Status:** PERMANENT BINDING SPECIFICATION  
**Scope:** Placeholder Resolution, Normalization, and Field Typing

---

## 1. HARD-STOP TEXT CLASSIFICATION RULE

* Placeholders named `TEXT`, `TEXT_*`, `TXT`, `TXT_*`, `TEXT_PLACEHOLDER`, `TEXT_99`, `REMARKS`, `OBSERVATION_*` must **ALWAYS** classify as `TEXT`.
* Under no circumstances may generic narrative placeholders be inferred as `DATE` or `IMAGE`.
* Image prefixes (`IMG_`, `IMAGE_`, `PIC_`) strictly classify as `IMAGE`.
* Date suffixes (`_DATE`, `DATE_*`) classify as `DATE` only if not explicitly matching generic text patterns.

---

## 2. PROPERTY_ADDRESS DATA INTEGRITY RULE (RULE 11)

* `PROPERTY_ADDRESS` and its aliases (`property_address`, `Property_Address`, `PROP_ADDRESS`) must **NEVER** be overwritten with empty strings `""` or null.
* Workspace inputs saved in the database or order context must flow directly into the template engine and appear in the generated output.
* Unhydrated placeholder leakage is strictly prohibited.

---

## 3. COMPOSITE GOVT RATE ALIAS SUPPORT (RULE 12)

The engine must support seamless resolution across all authorized aliases:
* `COMPOSITE_GOVT_RATE`
* `govt_composite_rate`
* `GOVT_COMPOSITE_RATE`
* `govt_rate`
* `GOVT_RATE`

If none are directly provided in flat input maps, the engine must extract the rate from `RAW_COMPOSITE_ITEMS_JSON` sub-items or government guideline valuation fields.

---

## 4. ZERO UNRESOLVED PLACEHOLDERS POLICY

In final production reports:
* Regular expressions searching for unhydrated directives `<<[A-Za-z0-9_]+>>` in `word/document.xml` must return **exactly 0 matches**.
* Any leftover placeholder directive indicates data hydration failure and will cause immediate test failure.
