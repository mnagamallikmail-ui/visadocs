# AUTHORITATIVE CALCULATION GOVERNANCE RULES

**Version:** 1.0  
**Effective Date:** Immediate  
**Status:** PERMANENT BINDING SPECIFICATION  
**Scope:** Valuation Calculations, Percentages, and Formatting

---

## 1. CORE VALUATION FORMULAS

### Land + Building Summation (Rule 5)
$$\text{Property Fair Value} = \text{Land Fair Value} + \text{Building Fair Value}$$

### Flat / Apartment Valuation
$$\text{Composite Fair Value} = \text{Main Unit Value} + \text{Interior Works Value} + \text{Car Parking Value} + \sum(\text{Additional Items})$$

---

## 2. REALIZABLE & DISTRESS PERCENTAGE INDEPENDENCE (RULES 8 & 9)

### Realizable Value Formula
$$\text{Realizable Value} = (\text{Land Value} \times \text{Land Realizable \%}) + (\text{Building Value} \times \text{Building Realizable \%})$$
* Default Land Realizable: 85% (if unspecified)
* Default Building Realizable: 85% (if unspecified)
* Modifying Land Realizable % does **not** alter Building Realizable %, and vice versa.

### Distress Sale Value Formula
$$\text{Distress Sale Value} = (\text{Land Value} \times \text{Land Distress \%}) + (\text{Building Value} \times \text{Building Distress \%})$$
* Default Land Distress: 75% (if unspecified)
* Default Building Distress: 75% (if unspecified)
* Modifying Land Distress % does **not** alter Building Distress %, and vice versa.

---

## 3. ROUNDING & CURRENCY FORMATTING RULES

* **Approach A Rounding:** Numeric values are rounded using `RoundingMode.HALF_UP` to the nearest whole integer or thousand as configured.
* **Currency Prefix:** Valuation amounts must be prefixed with `Rs ` or `₹ ` uniformly.
* **Indian Numbering System Format:** Numbers greater than 999 must follow the Indian formatting system (e.g., `88,80,000` instead of `8,880,000`).
* **Untouched Blanks Policy:** Inputs that were not provided by the user must not force synthetic non-zero calculations unless an explicit fallback default rule applies.
