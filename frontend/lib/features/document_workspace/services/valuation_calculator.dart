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
