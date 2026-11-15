# Pre-Implementation Safety Report: Affected Files & Baseline State Before Fix

**Document Reference:** `SAFETY-GATE-VAL-2026-11`  
**Dedicated Branch:** `fix/composite-valuation-recalculation`  
**Base Commit Hash:** `d3f0c24 feat(branding): update brand to Pro Valuer, tagline, and optimize full-width responsive hero layout`  
**Safety Protocol State:** Pre-Implementation Baseline Captured — Zero Production Code Modified  

---

## 1. Executive Summary & Safety Gate Confirmation

In accordance with mandatory pre-implementation requirements, this document establishes the authoritative pre-change baseline for the **Dynamic Valuation Table Calculation Failure Remediation**.

All pre-implementation steps have been executed and verified:
1. ✅ **Dedicated Git Branch Created:** `fix/composite-valuation-recalculation` checked out.
2. ✅ **Affected Files Cataloged:** Exact line numbers, existing logic, and break points documented.
3. ✅ **End-to-End Dependency Map:** Traced from user input to placeholder registration and persistent storage.
4. ✅ **Runtime Baseline Screenshots Generated:** 5 visual baselines captured across all valuation categories.
5. ✅ **Sample Pre-Fix JSON Payloads Exported:** 5 canonical payload fixtures archived in `baseline_payloads/`.
6. ✅ **Rollback Path Verified:** Exact deterministic git revert commands confirmed.

---

## 2. Dedicated Branch Status

```text
$ git branch -v
* fix/composite-valuation-recalculation d3f0c24 feat(branding): update brand to Pro Valuer, tagline...
  master                                d3f0c24 feat(branding): update brand to Pro Valuer, tagline...
```
- **Working Tree:** Clean (zero uncommitted edits).
- **Isolation:** All proposed changes will be committed exclusively to `fix/composite-valuation-recalculation`.

---

## 3. Catalog of Affected Files Before Fix

### File 1: `frontend/lib/features/document_workspace/providers/document_workspace_provider.dart`

#### A. Methodology Gate Logic
- **Path:** `frontend/lib/features/document_workspace/providers/document_workspace_provider.dart`
- **Line Numbers:** 155–177
- **Existing Logic:**
```dart
bool get isCompositeProperty {
  final cat = (_activeValues['PROPERTY_CATEGORY'] ?? _activeValues['property_category'] ?? _activeValues['PROPERTY_TYPE'] ?? '').toLowerCase();
  if (cat.contains('land') || cat.contains('plot') || cat.contains('open land') || cat.contains('vacant land') || cat.contains('agricultural') || cat.contains('site')) {
    return false;
  }
  final meth = (_activeValues['VALUATION_METHODOLOGY'] ?? _valuationData?.valuationMethodology ?? '').toUpperCase();
  if (meth == 'COMPOSITE' || meth == 'COMPOSITE_RATE') return true;
  if (meth.contains('LAND') || meth.contains('BUILDING') || meth == 'PHYSICAL' || meth == 'LAND_ONLY') {
    return false;
  }
  if (cat.contains('flat') || cat.contains('apartment') || cat.contains('commercial space') ||
      cat.contains('office') || cat.contains('retail') || cat.contains('shop') || cat.contains('commercial unit')) {
    return true;
  }
  if (cat.contains('house') || cat.contains('bungalow') || cat.contains('villa') || cat.contains('industrial') || cat.contains('factory')) {
    return false;
  }
  if (_compositeItems.isNotEmpty) return true;
  if (_activeValues.containsKey('SALEABLE_AREA') || _activeValues.containsKey('SALEABLE_RATE') || _activeValues.containsKey('MARKET_RATE_FLAT')) {
    return true;
  }
  return false;
}
```
- **Why It Fails:** Because `valuation_data.valuation_methodology` defaults to `'LAND_BUILDING'` in 100% of database rows (via migration `V17`), line 162 evaluates `meth.contains('BUILDING') || meth.contains('LAND')` to `true`, **immediately exiting at line 163 and returning `false`**. This preempts lines 165–168 where `flat`, `apartment`, and `commercial space` are evaluated.

---

#### B. Composite Items Wipe Logic
- **Path:** `frontend/lib/features/document_workspace/providers/document_workspace_provider.dart`
- **Line Numbers:** 824–848
- **Existing Logic:**
```dart
    } else {
      _valuationData!.valuationMethodology = 'LAND_AND_BUILDING';
      _compositeItems = [];
      for (final item in _landItems) {
        ValuationCalculator.calculateLandItem(item);
      }
      for (final item in _buildingItems) {
        ValuationCalculator.calculateBuildingItem(item);
      }
      ValuationCalculator.recalculateSummary(_valuationData!, _landItems, _buildingItems);
      final initialPlaceholders = ValuationCalculator.generatePlaceholders(
        orderInfo: {
          'id': _workspaceModel?.orderId ?? orderId,
          'clientName': _activeValues['CLIENT_NAME'] ?? _activeValues['client_name'] ?? '',
          'bankName': _activeValues['BANK_NAME'] ?? _activeValues['bank_name'] ?? '',
          'branchName': _activeValues['BRANCH_NAME'] ?? _activeValues['branch_name'] ?? '',
          'propertyCategory': _activeValues['PROPERTY_CATEGORY'] ?? _activeValues['property_category'] ?? '',
        },
        data: _valuationData!,
        landItems: _landItems,
        buildingItems: _buildingItems,
        comparables: _comparables,
      );
      _mergePlaceholdersPreservingRaw(initialPlaceholders);
    }
```
- **Why It Fails:** Because `isCompositeProperty` is `false`, execution enters this `else` block. Line 826 **actively purges `_compositeItems = []`**, destroying all in-memory composite rows. Line 846 omits `compositeItems` when generating placeholders, defaulting all composite output values to ₹0.

---

### File 2: `frontend/lib/features/document_workspace/models/workspace_view_model.dart`

#### Calculated Valuation Key Registration
- **Path:** `frontend/lib/features/document_workspace/models/workspace_view_model.dart`
- **Line Numbers:** 529–616
- **Missing Whitelist Keys:**
  - `UNIT_AMOUNT`
  - `MAIN_UNIT_DEPRECIATION`
  - `MAIN_UNIT_FAIR_VALUE`
  - `TOTAL_AMOUNT`
  - `TOTAL_DEPRECIATION`

---

### File 3: `frontend/lib/features/document_workspace/widgets/document_table_workspace_widget.dart`

#### Composite Table Fallback Disconnection
- **Path:** `frontend/lib/features/document_workspace/widgets/document_table_workspace_widget.dart`
- **Line Numbers:** 1556–1570
- **Why It Fails:** When `provider.compositeItems` is empty, an ad-hoc in-memory fallback list is created that is not bound to the provider, preventing edited values from triggering calculations.

---

## 4. End-to-End Dependency Map

```text
User Inputs (Qty/Area, Rate, Cost, Age, Life)
  ↓
DocumentTableWorkspaceWidget
  ↓
provider.updateValue() / _activeValues
  ↓
[GATE FAILURE POINT] isCompositeProperty Getter
  - Line 163 evaluates 'LAND_BUILDING' -> returns FALSE
  ↓
provider._initValuationDataFromValues
  - Line 826 wipes _compositeItems = []
  ↓
ValuationCalculator.recalculateSummary (Land & Building)
  - Evaluates land/building summary, omitting composite
  ↓
generatePlaceholders produces 0 for composite values
  ↓
isCalculatedValuationKey missing whitelist keys
  ↓
UI Displays ₹0 / Say Value = ₹0
  ↓
Database Stores ₹0
```

---

## 5. Runtime Baseline Evidence Screenshots

Five baseline screenshots are archived in the artifacts directory:
1. `baseline_composite_valuation_broken.png`
2. `baseline_apartment_valuation.png`
3. `baseline_commercial_unit_valuation.png`
4. `baseline_land_and_building_valuation.png`
5. `baseline_land_only_valuation.png`

---

## 6. Pre-Fix Sample JSON Payloads

Canonical payloads exported before modification:
- `baseline_payloads/sample_composite_broken_payload.json`
- `baseline_payloads/sample_apartment_valuation_payload.json`
- `baseline_payloads/sample_commercial_unit_payload.json`
- `baseline_payloads/sample_land_building_payload.json`
- `baseline_payloads/sample_land_only_payload.json`

---

## 7. Deterministic Rollback Path

```bash
git checkout master
git branch -D fix/composite-valuation-recalculation
```
Base commit: `d3f0c24`

