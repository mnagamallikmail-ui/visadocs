import '../../../utils/indian_currency_to_words.dart';
import '../../../utils/indian_number_formatter.dart';
import '../../../utils/unit_conversion_engine.dart';
import '../models/valuation_models.dart';

class ValuationCalculator {
  static void calculateLandItem(ValuationLandItemModel item) {
    item.standardAreaSqft = UnitConversionEngine.toStandardSqFt(item.enteredArea, item.enteredUnit);
    // Phase 1: Rate belongs to the selected unit (e.g. ₹/Sq.Yd, ₹/Sq.Ft, ₹/Acre). Value = enteredArea * rate.
    item.value = item.enteredArea * item.rate;
  }

  static void calculateBuildingItem(ValuationBuildingItemModel item) {
    item.standardAreaSqft = UnitConversionEngine.toStandardSqFt(item.enteredArea, item.enteredUnit);
    item.replacementCost = item.standardAreaSqft * item.replacementRate;

    final bType = item.buildingType.toLowerCase();
    final desc = item.description.toLowerCase();
    final struct = item.structureType.toLowerCase();

    int usefulLife = item.buildingUsefulLife;
    // Phase 2: Default useful life for PEB Structures and Steel Sheds is 40 years
    if (usefulLife <= 0 || (usefulLife == 60 && (bType.contains('peb') || bType.contains('shed') || desc.contains('peb') || desc.contains('shed') || struct.contains('shed')))) {
      if (bType.contains('peb') || bType.contains('shed') || desc.contains('peb') || desc.contains('shed') || struct.contains('shed')) {
        usefulLife = 40;
        item.buildingUsefulLife = 40;
      } else {
        usefulLife = 60;
        item.buildingUsefulLife = 60;
      }
    }

    final ageRatio = item.buildingAge / usefulLife;
    final salvageFactor = 1.0 - (item.salvagePercentage / 100.0);

    item.depreciationPercentage = ageRatio * salvageFactor * 100.0;
    item.depreciationAmount = item.replacementCost * ageRatio * salvageFactor;

    // Salvage Floor Guard
    final salvageFloor = item.replacementCost * (item.salvagePercentage / 100.0);
    final rawBuildingValue = item.replacementCost - item.depreciationAmount;
    item.buildingValue = rawBuildingValue > salvageFloor ? rawBuildingValue : salvageFloor;
  }

  static void calculateCompositeItem(ValuationCompositeItemModel item) {
    item.amount = item.quantity * item.rate;

    if (item.itemCategory == 'MAIN_UNIT') {
      final cost = item.constructionCost > 0 ? item.constructionCost : 2000.0;
      final life = item.totalLife > 0 ? item.totalLife : 60.0;
      final age = item.buildingAge >= 0 ? item.buildingAge : 0.0;

      // Depreciation = Area * Construction Cost * 90% * Age / Total Life
      final depr = item.quantity * cost * 0.90 * (age / life);
      item.depreciationAmount = depr;
      if (item.amount > 0) {
        item.depreciationPercentage = (depr / item.amount) * 100.0;
      } else {
        item.depreciationPercentage = 0.0;
      }
      item.fairValue = item.amount - depr;
    } else {
      // Interior Work: Supports Option A (Depreciation %) or Option B (Direct Depreciation Amount in ₹)
      final mode = item.depreciationMode.toUpperCase();
      if (mode == 'DIRECT_AMOUNT' && item.depreciationAmount > 0) {
        final depr = item.depreciationAmount;
        if (item.amount > 0) {
          item.depreciationPercentage = (depr / item.amount) * 100.0;
        } else {
          item.depreciationPercentage = 0.0;
        }
      } else {
        // PERCENTAGE mode or direct calculation from percentage
        final pct = item.depreciationPercentage;
        item.depreciationAmount = item.amount * (pct / 100.0);
      }
      item.fairValue = item.amount - item.depreciationAmount;
    }
  }

  static void recalculateCompositeSummary(
    ValuationDataModel data,
    List<ValuationCompositeItemModel> compositeItems,
  ) {
    double rawFairValue = 0.0;
    double mainUnitArea = 0.0;
    double mainUnitCost = data.compositeConstructionCost > 0 ? data.compositeConstructionCost : 2000.0;
    double totalInteriorAmount = 0.0;
    double totalInteriorDepr = 0.0;
    double totalInteriorFair = 0.0;
    double totalInsurableInteriors = 0.0;

    for (final item in compositeItems) {
      calculateCompositeItem(item);
      rawFairValue += item.fairValue;

      if (item.itemCategory == 'MAIN_UNIT') {
        mainUnitArea = item.quantity;
        mainUnitCost = item.constructionCost;
        data.compositeBuildingAge = item.buildingAge;
        data.compositeBuildingTotalLife = item.totalLife;
        data.compositeConstructionCost = item.constructionCost;
        data.compositeBuildingDepreciationPct = item.depreciationPercentage;
      } else {
        totalInteriorAmount += item.amount;
        totalInteriorDepr += item.depreciationAmount;
        totalInteriorFair += item.fairValue;
        if (item.isInsurable) {
          totalInsurableInteriors += item.amount;
        }
      }
    }

    data.rawFairValue = rawFairValue;
    data.totalInteriorAmount = totalInteriorAmount;
    data.totalInteriorDepreciation = totalInteriorDepr;
    data.totalInteriorFairValue = totalInteriorFair;

    // Apply existing ProValuer Say Value rounding engine
    final sayFairValue = computeSayValue(rawFairValue);
    data.sayFairValue = sayFairValue;

    // In the Composite Summary display: Fair Value shall consume Say Fair Value
    data.fairValue = sayFairValue;

    // Downstream calculations consume Say Fair Value
    final realPct = data.realizablePercentage > 0 ? data.realizablePercentage : 85.0;
    final distPct = data.distressSalePercentage > 0 ? data.distressSalePercentage : 75.0;
    data.realizablePercentage = realPct;
    data.distressSalePercentage = distPct;
    data.realizableValue = sayFairValue * (realPct / 100.0);
    data.distressSaleValue = sayFairValue * (distPct / 100.0);

    // Government Value = Area * Government Composite Rate
    final govtRate = data.compositeGovernmentRate;
    data.governmentValue = mainUnitArea * govtRate;

    // Insurable Value = Area * Construction Cost + Insurable Interior Improvements
    data.insurableValue = (mainUnitArea * mainUnitCost) + totalInsurableInteriors;
  }

  static void recalculateSummary(
    ValuationDataModel data,
    List<ValuationLandItemModel> landItems,
    List<ValuationBuildingItemModel> buildingItems,
  ) {
    // 1. Aggregate Land
    double totalLand = 0;
    for (final l in landItems) {
      calculateLandItem(l);
      totalLand += l.value;
    }
    data.totalLandValue = totalLand;

    // 2. Aggregate Buildings
    double totalReplCost = 0;
    double totalDepr = 0;
    double totalSalvage = 0;
    double totalBuilding = 0;

    for (final b in buildingItems) {
      calculateBuildingItem(b);
      totalReplCost += b.replacementCost;
      totalDepr += b.depreciationAmount;
      totalSalvage += (b.replacementCost * (b.salvagePercentage / 100.0));
      totalBuilding += b.buildingValue;
    }

    data.totalReplacementCost = totalReplCost;
    data.totalDepreciationAmount = totalDepr;
    data.totalSalvageValue = totalSalvage;
    data.totalBuildingValue = totalBuilding;

    // 3. Say Values (Phase 4): Say Land Value & Say Building Value
    final sayLand = computeSayValue(totalLand);
    final sayBldg = computeSayValue(totalBuilding);
    data.sayLandValue = sayLand;
    data.sayBuildingValue = sayBldg;

    // 4. Fair Value = Say Land Value + Say Building Value (NOT raw totals) (Phase 4 & 9)
    data.fairValue = sayLand + sayBldg;

    // 5. Separate Realizable Percentages (Phase 6 & 10)
    final landRealPct = data.landRealizablePercentage > 0 ? data.landRealizablePercentage : 85.0;
    final bldgRealPct = data.buildingRealizablePercentage > 0 ? data.buildingRealizablePercentage : 85.0;
    data.landRealizablePercentage = landRealPct;
    data.buildingRealizablePercentage = bldgRealPct;

    final landRealVal = sayLand * (landRealPct / 100.0);
    final bldgRealVal = sayBldg * (bldgRealPct / 100.0);
    data.landRealizableValue = landRealVal;
    data.buildingRealizableValue = bldgRealVal;
    data.realizableValue = landRealVal + bldgRealVal;

    // 6. Separate Distress Percentages (Phase 7 & 11)
    final landDistPct = data.landDistressPercentage > 0 ? data.landDistressPercentage : 75.0;
    final bldgDistPct = data.buildingDistressPercentage > 0 ? data.buildingDistressPercentage : 75.0;
    data.landDistressPercentage = landDistPct;
    data.buildingDistressPercentage = bldgDistPct;

    final landDistVal = sayLand * (landDistPct / 100.0);
    final bldgDistVal = sayBldg * (bldgDistPct / 100.0);
    data.landDistressValue = landDistVal;
    data.buildingDistressValue = bldgDistVal;
    data.distressSaleValue = landDistVal + bldgDistVal;

    // 7. Insurable Value = Total Replacement Cost of Buildings (Phase 13)
    data.insurableValue = totalReplCost;

    // 8. Government Values (Phase 12)
    double landGovt = 0;
    for (final l in landItems) {
      landGovt += (l.standardAreaSqft * 5500.0);
    }
    double bldgGovt = 0;
    for (final b in buildingItems) {
      final bType = (b.buildingType + " " + b.description).toLowerCase();
      if (bType.contains('steel') || bType.contains('shed') || bType.contains('peb')) {
        bldgGovt += (b.standardAreaSqft * 1900.0);
      } else {
        bldgGovt += (b.standardAreaSqft * 2400.0);
      }
    }
    data.landGovernmentValue = landGovt;
    data.buildingGovernmentValue = bldgGovt;

    if (data.governmentValue <= 0) {
      data.governmentValue = landGovt + bldgGovt;
    }
  }

  static Map<String, String> generatePlaceholders({
    required Map<String, dynamic> orderInfo,
    required ValuationDataModel data,
    required List<ValuationLandItemModel> landItems,
    required List<ValuationBuildingItemModel> buildingItems,
    required List<ValuationComparableSaleModel> comparables,
    List<ValuationCompositeItemModel> compositeItems = const [],
  }) {
    final map = <String, String>{};

    // Property
    map['report_no'] = orderInfo['reportNumber']?.toString() ?? 'PV-${orderInfo['id'] ?? ''}';
    map['report_version'] = 'v${data.currentVersion}';
    map['valuation_status'] = data.valuationStatus;
    map['owner_name'] = orderInfo['clientName']?.toString() ?? '';
    map['client_name'] = orderInfo['clientName']?.toString() ?? '';
    map['bank_name'] = orderInfo['bankName']?.toString() ?? '';
    map['branch_name'] = orderInfo['branchName']?.toString() ?? '';
    map['property_type'] = orderInfo['propertyCategory']?.toString() ?? 'Commercial Property';

    final isComposite = data.valuationMethodology == 'COMPOSITE' || compositeItems.isNotEmpty;

    if (isComposite) {
      final sayFair = data.sayFairValue > 0 ? data.sayFairValue : computeSayValue(data.rawFairValue);
      map['raw_fair_value'] = IndianNumberFormatter.format(data.rawFairValue);
      map['raw_fair_value_words'] = IndianCurrencyToWords.convertToWords(data.rawFairValue);
      map['say_fair_value'] = IndianNumberFormatter.format(sayFair);
      map['say_fair_value_words'] = IndianCurrencyToWords.convertToWords(sayFair);

      // Summary consumes Say Value as Fair Value
      map['fair_value'] = IndianNumberFormatter.format(sayFair);
      map['fair_value_words'] = IndianCurrencyToWords.convertToWords(sayFair);
      map['say_value'] = IndianNumberFormatter.format(sayFair);
      map['say_value_words'] = IndianCurrencyToWords.convertToWords(sayFair);

      map['realizable_percentage'] = '${data.realizablePercentage.toStringAsFixed(1)}%';
      map['realizable_value'] = IndianNumberFormatter.format(data.realizableValue);
      map['realizable_value_words'] = IndianCurrencyToWords.convertToWords(data.realizableValue);

      map['distress_sale_percentage'] = '${data.distressSalePercentage.toStringAsFixed(1)}%';
      map['distress_sale_value'] = IndianNumberFormatter.format(data.distressSaleValue);
      map['distress_sale_value_words'] = IndianCurrencyToWords.convertToWords(data.distressSaleValue);

      map['insurable_value'] = IndianNumberFormatter.format(data.insurableValue);
      map['insurable_value_words'] = IndianCurrencyToWords.convertToWords(data.insurableValue);

      map['government_value'] = IndianNumberFormatter.format(data.governmentValue);
      map['government_value_words'] = IndianCurrencyToWords.convertToWords(data.governmentValue);

      map['composite_government_rate'] = IndianNumberFormatter.format(data.compositeGovernmentRate);
      map['composite_construction_cost'] = IndianNumberFormatter.format(data.compositeConstructionCost);
      map['composite_building_age'] = '${data.compositeBuildingAge} Years';
      map['composite_building_total_life'] = '${data.compositeBuildingTotalLife} Years';
      map['composite_building_depreciation_pct'] = '${data.compositeBuildingDepreciationPct.toStringAsFixed(1)}%';
      map['total_interior_amount'] = IndianNumberFormatter.format(data.totalInteriorAmount);
      map['total_interior_depreciation'] = IndianNumberFormatter.format(data.totalInteriorDepreciation);
      map['total_interior_fair_value'] = IndianNumberFormatter.format(data.totalInteriorFairValue);
    } else {
      // Land
      map['total_land_value'] = IndianNumberFormatter.format(data.totalLandValue);
      map['total_land_value_words'] = IndianCurrencyToWords.convertToWords(data.totalLandValue);
      final sayLand = data.sayLandValue > 0 ? data.sayLandValue : computeSayValue(data.totalLandValue);
      map['say_land_value'] = IndianNumberFormatter.format(sayLand);
      map['say_land_value_words'] = IndianCurrencyToWords.convertToWords(sayLand);

      // Building
      map['total_replacement_cost'] = IndianNumberFormatter.format(data.totalReplacementCost);
      map['total_replacement_cost_words'] = IndianCurrencyToWords.convertToWords(data.totalReplacementCost);
      map['total_depreciation_amount'] = IndianNumberFormatter.format(data.totalDepreciationAmount);
      map['total_depreciation_amount_words'] = IndianCurrencyToWords.convertToWords(data.totalDepreciationAmount);
      map['total_salvage_value'] = IndianNumberFormatter.format(data.totalSalvageValue);
      map['total_salvage_value_words'] = IndianCurrencyToWords.convertToWords(data.totalSalvageValue);
      map['total_building_value'] = IndianNumberFormatter.format(data.totalBuildingValue);
      map['total_building_value_words'] = IndianCurrencyToWords.convertToWords(data.totalBuildingValue);
      final sayBldg = data.sayBuildingValue > 0 ? data.sayBuildingValue : computeSayValue(data.totalBuildingValue);
      map['say_building_value'] = IndianNumberFormatter.format(sayBldg);
      map['say_building_value_words'] = IndianCurrencyToWords.convertToWords(sayBldg);

      // Valuation Summary
      final fairVal = sayLand + sayBldg;
      map['fair_value'] = IndianNumberFormatter.format(fairVal);
      map['fair_value_words'] = IndianCurrencyToWords.convertToWords(fairVal);

      // Separate Realizable
      final landRealVal = data.landRealizableValue > 0 ? data.landRealizableValue : sayLand * (data.landRealizablePercentage / 100.0);
      final bldgRealVal = data.buildingRealizableValue > 0 ? data.buildingRealizableValue : sayBldg * (data.buildingRealizablePercentage / 100.0);
      final totalRealVal = landRealVal + bldgRealVal;

      map['land_realizable_percentage'] = '${data.landRealizablePercentage.toStringAsFixed(1)}%';
      map['land_realizable_value'] = IndianNumberFormatter.format(landRealVal);
      map['land_realizable_value_words'] = IndianCurrencyToWords.convertToWords(landRealVal);
      map['building_realizable_percentage'] = '${data.buildingRealizablePercentage.toStringAsFixed(1)}%';
      map['building_realizable_value'] = IndianNumberFormatter.format(bldgRealVal);
      map['building_realizable_value_words'] = IndianCurrencyToWords.convertToWords(bldgRealVal);
      map['realizable_percentage'] = '${data.landRealizablePercentage.toStringAsFixed(1)}%';
      map['realizable_value'] = IndianNumberFormatter.format(totalRealVal);
      map['realizable_value_words'] = IndianCurrencyToWords.convertToWords(totalRealVal);

      // Separate Distress
      final landDistVal = data.landDistressValue > 0 ? data.landDistressValue : sayLand * (data.landDistressPercentage / 100.0);
      final bldgDistVal = data.buildingDistressValue > 0 ? data.buildingDistressValue : sayBldg * (data.buildingDistressPercentage / 100.0);
      final totalDistVal = landDistVal + bldgDistVal;

      map['land_distress_percentage'] = '${data.landDistressPercentage.toStringAsFixed(1)}%';
      map['land_distress_value'] = IndianNumberFormatter.format(landDistVal);
      map['land_distress_value_words'] = IndianCurrencyToWords.convertToWords(landDistVal);
      map['building_distress_percentage'] = '${data.buildingDistressPercentage.toStringAsFixed(1)}%';
      map['building_distress_value'] = IndianNumberFormatter.format(bldgDistVal);
      map['building_distress_value_words'] = IndianCurrencyToWords.convertToWords(bldgDistVal);
      map['distress_sale_percentage'] = '${data.landDistressPercentage.toStringAsFixed(1)}%';
      map['distress_sale_value'] = IndianNumberFormatter.format(totalDistVal);
      map['distress_sale_value_words'] = IndianCurrencyToWords.convertToWords(totalDistVal);

      // Insurable Value (Business Rule: Total Building Replacement Cost)
      final insurable = data.insurableValue > 0 ? data.insurableValue : data.totalReplacementCost;
      map['insurable_value'] = IndianNumberFormatter.format(insurable);
      map['insurable_value_words'] = IndianCurrencyToWords.convertToWords(insurable);

      // Government Value (Independent Guideline / Statutory Value)
      final totalGovt = data.governmentValue > 0 ? data.governmentValue : (data.landGovernmentValue + data.buildingGovernmentValue);
      map['land_government_value'] = IndianNumberFormatter.format(data.landGovernmentValue);
      map['land_government_value_words'] = IndianCurrencyToWords.convertToWords(data.landGovernmentValue);
      map['building_government_value'] = IndianNumberFormatter.format(data.buildingGovernmentValue);
      map['building_government_value_words'] = IndianCurrencyToWords.convertToWords(data.buildingGovernmentValue);
      map['government_value'] = IndianNumberFormatter.format(totalGovt);
      map['government_value_words'] = IndianCurrencyToWords.convertToWords(totalGovt);

      // Say Value (Presentation Value: Rounded Fair Value to nearest Lakh if >= 1 Crore)
      final sayVal = computeSayValue(fairVal);
      map['say_value'] = IndianNumberFormatter.format(sayVal);
      map['say_value_words'] = IndianCurrencyToWords.convertToWords(sayVal);
    }

    // Single Parcel / Building backward compatibility
    if (landItems.isNotEmpty) {
      final l = landItems.first;
      map['land_area'] = '${l.enteredArea} ${l.enteredUnit}';
      map['land_rate'] = IndianNumberFormatter.format(l.rate);
      map['land_value'] = IndianNumberFormatter.format(l.value);
      map['land_value_words'] = IndianCurrencyToWords.convertToWords(l.value);
    }
    if (buildingItems.isNotEmpty) {
      final b = buildingItems.first;
      map['building_type'] = b.buildingType;
      map['building_area'] = '${b.enteredArea} ${b.enteredUnit}';
      map['replacement_rate'] = IndianNumberFormatter.format(b.replacementRate);
      map['replacement_cost'] = IndianNumberFormatter.format(b.replacementCost);
      map['replacement_cost_words'] = IndianCurrencyToWords.convertToWords(b.replacementCost);
      map['building_age'] = '${b.buildingAge} Years';
      map['building_useful_life'] = '${b.buildingUsefulLife} Years';
      map['depreciation_percent'] = '${b.depreciationPercentage.toStringAsFixed(1)}%';
      map['depreciation_amount'] = IndianNumberFormatter.format(b.depreciationAmount);
      map['depreciation_amount_words'] = IndianCurrencyToWords.convertToWords(b.depreciationAmount);
      map['building_value'] = IndianNumberFormatter.format(b.buildingValue);
      map['building_value_words'] = IndianCurrencyToWords.convertToWords(b.buildingValue);
    }

    // Add uppercase aliases
    final uppercaseMap = <String, String>{};
    for (final e in map.entries) {
      uppercaseMap[e.key.toUpperCase()] = e.value;
    }
    map.addAll(uppercaseMap);

    return map;
  }

  /// Presentation Say Value Rounding Rules (Phase 5):
  /// - If value is in Lakhs (< 50 Lakhs): Round to nearest ₹ 1,000 (e.g. ₹ 23,12,500 -> ₹ 23,13,000)
  /// - If value is in Tens of Lakhs (50L to 1Cr): Round to nearest ₹ 10,000 (e.g. ₹ 68,75,000 -> ₹ 68,80,000)
  /// - If value is in Crores (>= 1 Crore): Round to nearest ₹ 1,00,000 (e.g. ₹ 7,08,12,500 -> ₹ 7,08,00,000)
  static double computeSayValue(double value) {
    if (value <= 0) return 0.0;
    if (value >= 10000000.0) {
      return (value / 100000.0).roundToDouble() * 100000.0;
    } else if (value >= 5000000.0) {
      return (value / 10000.0).roundToDouble() * 10000.0;
    } else {
      return (value / 1000.0).roundToDouble() * 1000.0;
    }
  }
}
