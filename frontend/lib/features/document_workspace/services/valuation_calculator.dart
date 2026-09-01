import '../../../utils/indian_currency_to_words.dart';
import '../../../utils/indian_number_formatter.dart';
import '../../../utils/unit_conversion_engine.dart';
import '../models/valuation_models.dart';

class ValuationCalculator {
  static void calculateLandItem(ValuationLandItemModel item) {
    item.standardAreaSqft = UnitConversionEngine.toStandardSqFt(item.enteredArea, item.enteredUnit);
    item.value = item.standardAreaSqft * item.rate;
  }

  static void calculateBuildingItem(ValuationBuildingItemModel item) {
    item.standardAreaSqft = UnitConversionEngine.toStandardSqFt(item.enteredArea, item.enteredUnit);
    item.replacementCost = item.standardAreaSqft * item.replacementRate;

    final usefulLife = item.buildingUsefulLife > 0 ? item.buildingUsefulLife : 60;
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

    // 3. Fair Value = Total Land + Total Building
    data.fairValue = totalLand + totalBuilding;

    // 4. Realizable Value
    data.realizableValue = data.fairValue * (data.realizablePercentage / 100.0);

    // 5. Distress Sale Value
    data.distressSaleValue = data.fairValue * (data.distressSalePercentage / 100.0);

    // 6. Insurable Value = Total Replacement Cost (Excluding Land)
    data.insurableValue = totalReplCost;
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

    // Building
    map['total_replacement_cost'] = IndianNumberFormatter.format(data.totalReplacementCost);
    map['total_replacement_cost_words'] = IndianCurrencyToWords.convertToWords(data.totalReplacementCost);
    map['total_depreciation_amount'] = IndianNumberFormatter.format(data.totalDepreciationAmount);
    map['total_depreciation_amount_words'] = IndianCurrencyToWords.convertToWords(data.totalDepreciationAmount);
    map['total_salvage_value'] = IndianNumberFormatter.format(data.totalSalvageValue);
    map['total_salvage_value_words'] = IndianCurrencyToWords.convertToWords(data.totalSalvageValue);
    map['total_building_value'] = IndianNumberFormatter.format(data.totalBuildingValue);
    map['total_building_value_words'] = IndianCurrencyToWords.convertToWords(data.totalBuildingValue);

    // Valuation Summary
    map['fair_value'] = IndianNumberFormatter.format(data.fairValue);
    map['fair_value_words'] = IndianCurrencyToWords.convertToWords(data.fairValue);
    map['realizable_percentage'] = '${data.realizablePercentage.toStringAsFixed(1)}%';
    map['realizable_value'] = IndianNumberFormatter.format(data.realizableValue);
    map['realizable_value_words'] = IndianCurrencyToWords.convertToWords(data.realizableValue);
    map['distress_sale_percentage'] = '${data.distressSalePercentage.toStringAsFixed(1)}%';
    map['distress_sale_value'] = IndianNumberFormatter.format(data.distressSaleValue);
    map['distress_sale_value_words'] = IndianCurrencyToWords.convertToWords(data.distressSaleValue);

    // Insurable Value (Business Rule: Total Building Replacement Cost)
    final insurable = data.insurableValue > 0 ? data.insurableValue : data.totalReplacementCost;
    map['insurable_value'] = IndianNumberFormatter.format(insurable);
    map['insurable_value_words'] = IndianCurrencyToWords.convertToWords(insurable);

    // Government Value (Independent Guideline / Statutory Value)
    map['government_value'] = IndianNumberFormatter.format(data.governmentValue);
    map['government_value_words'] = IndianCurrencyToWords.convertToWords(data.governmentValue);

    // Say Value (Presentation Value: Rounded Fair Value to nearest Lakh if >= 1 Crore)
    final sayVal = computeSayValue(data.fairValue);
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

  /// Presentation Say Value: Rounded Fair Value to nearest Lakh when Fair Value >= 1 Crore.
  static double computeSayValue(double fairValue) {
    if (fairValue >= 10000000.0) {
      return (fairValue / 100000.0).roundToDouble() * 100000.0;
    }
    return fairValue;
  }
}
