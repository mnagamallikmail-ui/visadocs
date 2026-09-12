import '../../../utils/indian_currency_to_words.dart';
import '../../../utils/indian_number_formatter.dart';
import '../../../utils/unit_conversion_engine.dart';
import '../models/valuation_models.dart';
import 'value_normalization_engine.dart';

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
    final cat = item.itemCategory.toUpperCase();
    if (cat == 'MAIN_UNIT') {
      item.amount = item.quantity * item.rate;
      final cost = item.constructionCost > 0 ? item.constructionCost : 2000.0;
      final life = item.totalLife > 0 ? item.totalLife : 60.0;
      final age = item.buildingAge >= 0 ? item.buildingAge : 0.0;

      // Formula: Depreciation = Area * Construction Cost * 90% * (Age / Total Life)
      final depr = (item.quantity * cost * 0.90 * (age / life)).roundToDouble();
      item.depreciationAmount = depr;
      if (item.amount > 0) {
        item.depreciationPercentage = (depr / item.amount) * 100.0;
      } else {
        item.depreciationPercentage = 0.0;
      }
      item.fairValue = item.amount - depr;
    } else if (cat == 'PARKING') {
      // Formula: Parking Amount = Quantity * Rate, Fair Value = Amount - Depreciation
      if (item.rate > 0) {
        item.amount = item.quantity * item.rate;
      }
      if (item.depreciationAmount > 0) {
        if (item.amount > 0) {
          item.depreciationPercentage = (item.depreciationAmount / item.amount) * 100.0;
        }
      } else if (item.depreciationPercentage > 0) {
        item.depreciationAmount = item.amount * (item.depreciationPercentage / 100.0);
      }
      item.fairValue = item.amount - item.depreciationAmount;
    } else {
      // Interior Work: User entered amount/rate & user entered or percentage depreciation
      if (item.rate > 0) {
        item.amount = item.quantity * item.rate;
      } else if (item.amount > 0 && item.quantity > 0) {
        item.rate = item.amount / item.quantity;
      }
      final mode = item.depreciationMode.toUpperCase();
      if ((mode == 'DIRECT_AMOUNT' || item.depreciationPercentage == 0) && item.depreciationAmount > 0) {
        final depr = item.depreciationAmount;
        if (item.amount > 0) {
          item.depreciationPercentage = (depr / item.amount) * 100.0;
        } else {
          item.depreciationPercentage = 0.0;
        }
      } else {
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
    // 1. Ensure explicit MAIN_UNIT exists without invalid fallbacks
    ValuationCompositeItemModel? mainUnit;
    for (final item in compositeItems) {
      if (item.itemCategory.toUpperCase() == 'MAIN_UNIT') {
        mainUnit = item;
        break;
      }
    }
    if (mainUnit == null) {
      mainUnit = ValuationCompositeItemModel(
        orderId: data.orderId,
        itemCategory: 'MAIN_UNIT',
        description: 'Main Unit / Flat',
        enteredUnit: 'Sq.Ft',
        quantity: 1000.0,
        rate: 0.0,
        constructionCost: data.compositeConstructionCost > 0 ? data.compositeConstructionCost : 2000.0,
        buildingAge: data.compositeBuildingAge,
        totalLife: data.compositeBuildingTotalLife > 0 ? data.compositeBuildingTotalLife : 60.0,
        sortOrder: 0,
      );
      compositeItems.insert(0, mainUnit);
    }

    double totalAmount = 0.0;
    double totalDepreciation = 0.0;
    double totalFairValue = 0.0;

    double mainUnitAmount = 0.0;
    double mainUnitDepreciation = 0.0;
    double mainUnitFairValue = 0.0;
    double mainUnitArea = 0.0;
    double mainUnitCost = data.compositeConstructionCost > 0 ? data.compositeConstructionCost : 2000.0;

    double totalInteriorAmount = 0.0;
    double totalInteriorDepr = 0.0;
    double totalInteriorFair = 0.0;

    double totalParkingAmount = 0.0;
    double totalParkingDepr = 0.0;
    double totalParkingFair = 0.0;

    double totalInsurableInteriors = 0.0;

    for (final item in compositeItems) {
      calculateCompositeItem(item);
      totalAmount += item.amount;
      totalDepreciation += item.depreciationAmount;
      totalFairValue += item.fairValue;

      final cat = item.itemCategory.toUpperCase();
      if (cat == 'MAIN_UNIT') {
        mainUnitArea = item.quantity;
        mainUnitCost = item.constructionCost;
        mainUnitAmount = item.amount;
        mainUnitDepreciation = item.depreciationAmount;
        mainUnitFairValue = item.fairValue;

        data.compositeBuildingAge = item.buildingAge;
        data.compositeBuildingTotalLife = item.totalLife;
        data.compositeConstructionCost = item.constructionCost;
        data.compositeBuildingDepreciationPct = item.depreciationPercentage;
      } else if (cat == 'PARKING') {
        totalParkingAmount += item.amount;
        totalParkingDepr += item.depreciationAmount;
        totalParkingFair += item.fairValue;
      } else {
        totalInteriorAmount += item.amount;
        totalInteriorDepr += item.depreciationAmount;
        totalInteriorFair += item.fairValue;
        if (item.isInsurable) {
          totalInsurableInteriors += item.amount;
        }
      }
    }

    data.unitAmount = mainUnitAmount;
    data.mainUnitDepreciation = mainUnitDepreciation;
    data.mainUnitFairValue = mainUnitFairValue;

    data.totalInteriorAmount = totalInteriorAmount;
    data.totalInteriorDepreciation = totalInteriorDepr;
    data.totalInteriorFairValue = totalInteriorFair;

    data.totalParkingAmount = totalParkingAmount;
    data.totalParkingDepreciation = totalParkingDepr;
    data.totalParkingFairValue = totalParkingFair;

    data.totalAmount = totalAmount;
    data.totalDepreciation = totalDepreciation;
    data.totalFairValue = totalFairValue;
    data.rawFairValue = totalFairValue;

    // Apply approved ProValuer Say Value rounding engine to totalFairValue
    final sayFairValue = computeSayValue(totalFairValue);
    data.sayFairValue = sayFairValue;

    // Fair Value consumes Say Value for presentation & downstream calculations
    data.fairValue = sayFairValue;

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

    // LEVEL 1: TOTAL_FAIR_VALUE (Mathematical valuation, no rounding)
    final totalFair = totalLand + totalBuilding;
    data.totalFairValue = totalFair;
    data.rawFairValue = totalFair;

    // LEVEL 2: SAY_VALUE = computeSayValue(TOTAL_FAIR_VALUE)
    final sayVal = computeSayValue(totalFair);
    data.sayFairValue = sayVal;

    // FAIR_VALUE must always equal SAY_VALUE for report display
    data.fairValue = sayVal;

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
      // LEVEL 1: TOTAL_FAIR_VALUE (Mathematical valuation result, no rounding)
      final totalFair = (data.totalFairValue > 0) ? data.totalFairValue : data.rawFairValue;
      final totalFairStr = IndianNumberFormatter.format(totalFair);
      final totalFairWords = IndianCurrencyToWords.convertToWords(totalFair);
      final numericTotalFair = ValueNormalizationEngine.formatNormalizedString(totalFair);

      map['total_fair_value'] = totalFairStr;
      map['total_fair_value_words'] = totalFairWords;
      map['total_fair_value_numeric'] = numericTotalFair;
      map['raw_fair_value'] = totalFairStr;
      map['raw_fair_value_words'] = totalFairWords;

      // LEVEL 2: SAY_VALUE = computeSayValue(TOTAL_FAIR_VALUE)
      final sayVal = computeSayValue(totalFair);
      final sayValStr = IndianNumberFormatter.format(sayVal);
      final sayValWords = IndianCurrencyToWords.convertToWords(sayVal);
      final numericSayVal = ValueNormalizationEngine.formatNormalizedString(sayVal);

      map['say_value'] = sayValStr;
      map['say_value_words'] = sayValWords;
      map['say_fair_value'] = sayValStr;
      map['say_fair_value_words'] = sayValWords;
      map['report_fair_value'] = sayValStr;
      map['report_fair_value_words'] = sayValWords;

      // UNIFIED REPORT-FACING VALUATION: All aliases MUST equal SAY_VALUE
      map['fair_value'] = sayValStr;
      map['fair_value_words'] = sayValWords;
      map['fair_value_numeric'] = numericSayVal;
      map['market_value'] = sayValStr;
      map['market_value_words'] = sayValWords;
      map['property_value'] = sayValStr;
      map['property_value_words'] = sayValWords;
      map['final_value'] = sayValStr;
      map['final_value_words'] = sayValWords;
      map['valuation_amount'] = sayValStr;
      map['valuation_amount_words'] = sayValWords;
      map['opinion_of_value'] = sayValStr;
      map['opinion_of_value_words'] = sayValWords;
      map['recommended_value'] = sayValStr;
      map['recommended_value_words'] = sayValWords;

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
      map['composite_building_age'] = data.compositeBuildingAge.toStringAsFixed(0);
      map['composite_building_age_display'] = '${data.compositeBuildingAge} Years';
      map['composite_building_total_life'] = data.compositeBuildingTotalLife.toStringAsFixed(0);
      map['composite_building_total_life_display'] = '${data.compositeBuildingTotalLife} Years';
      map['composite_building_depreciation_pct'] = '${data.compositeBuildingDepreciationPct.toStringAsFixed(1)}%';
      map['total_interior_amount'] = IndianNumberFormatter.format(data.totalInteriorAmount);
      map['total_interior_depreciation'] = IndianNumberFormatter.format(data.totalInteriorDepreciation);
      map['total_interior_fair_value'] = IndianNumberFormatter.format(data.totalInteriorFairValue);
      map['interior_amount'] = map['total_interior_amount']!;
      map['interior_depreciation'] = map['total_interior_depreciation']!;
      map['interior_fair_value'] = map['total_interior_fair_value']!;

      map['total_parking_amount'] = IndianNumberFormatter.format(data.totalParkingAmount);
      map['total_parking_depreciation'] = IndianNumberFormatter.format(data.totalParkingDepreciation);
      map['total_parking_fair_value'] = IndianNumberFormatter.format(data.totalParkingFairValue);
      map['parking_amount'] = map['total_parking_amount']!;
      map['parking_depreciation'] = map['total_parking_depreciation']!;
      map['parking_fair_value'] = map['total_parking_fair_value']!;

      map['total_amount'] = IndianNumberFormatter.format(data.totalAmount);
      map['total_amount_numeric'] = ValueNormalizationEngine.formatNormalizedString(data.totalAmount);
      map['total_depreciation'] = IndianNumberFormatter.format(data.totalDepreciation);
      map['total_depreciation_numeric'] = ValueNormalizationEngine.formatNormalizedString(data.totalDepreciation);
      map['total_fair_value'] = IndianNumberFormatter.format(data.totalFairValue);
      map['total_fair_value_numeric'] = ValueNormalizationEngine.formatNormalizedString(data.totalFairValue);

      // Explicitly locate MAIN_UNIT. NEVER fallback to compositeItems.first or another category
      ValuationCompositeItemModel? mainUnit;
      for (final item in compositeItems) {
        if (item.itemCategory.toUpperCase() == 'MAIN_UNIT') {
          mainUnit = item;
          break;
        }
      }
      mainUnit ??= ValuationCompositeItemModel(
        orderId: data.orderId,
        itemCategory: 'MAIN_UNIT',
        description: 'Main Unit / Flat',
        enteredUnit: 'Sq.Ft',
        quantity: 1000.0,
        rate: 0.0,
        constructionCost: data.compositeConstructionCost > 0 ? data.compositeConstructionCost : 2000.0,
        buildingAge: data.compositeBuildingAge,
        totalLife: data.compositeBuildingTotalLife > 0 ? data.compositeBuildingTotalLife : 60.0,
        sortOrder: 0,
      );

      final areaStr = mainUnit.quantity.toString();
      final numericAreaStr = ValueNormalizationEngine.formatNormalizedString(mainUnit.quantity);
      map['saleable_area'] = areaStr;
      map['saleable_area_raw'] = areaStr;
      map['saleable_area_numeric'] = numericAreaStr;
      map['saleable_area_unit'] = mainUnit.enteredUnit;
      map['saleable_area_standard_sqft'] = numericAreaStr;
      map['super_built_up_area'] = areaStr;
      map['super_built_up_area_raw'] = areaStr;
      map['super_built_up_area_numeric'] = numericAreaStr;
      map['super_built_up_area_unit'] = mainUnit.enteredUnit;
      map['super_built_up_area_standard_sqft'] = numericAreaStr;
      map['property_area_sft'] = areaStr;
      map['property_area_sft_raw'] = areaStr;
      map['property_area_sft_numeric'] = numericAreaStr;
      map['property_area_sft_unit'] = mainUnit.enteredUnit;
      map['property_area_sft_standard_sqft'] = numericAreaStr;
      map['sbua'] = areaStr;
      map['sbua_raw'] = areaStr;
      map['sbua_numeric'] = numericAreaStr;
      map['sbua_unit'] = mainUnit.enteredUnit;
      map['sbua_standard_sqft'] = numericAreaStr;
      map['flat_area'] = areaStr;
      map['flat_area_raw'] = areaStr;
      map['flat_area_numeric'] = numericAreaStr;
      map['flat_area_unit'] = mainUnit.enteredUnit;
      map['flat_area_standard_sqft'] = numericAreaStr;
      map['composite_area'] = '$areaStr ${mainUnit.enteredUnit}';

      final rateStr = IndianNumberFormatter.format(mainUnit.rate);
      final numericRateStr = ValueNormalizationEngine.formatNormalizedString(mainUnit.rate);
      map['market_rate_flat'] = rateStr;
      map['market_rate_flat_raw'] = rateStr;
      map['market_rate_flat_numeric'] = numericRateStr;
      map['composite_rate'] = rateStr;
      map['composite_rate_raw'] = rateStr;
      map['composite_rate_numeric'] = numericRateStr;
      map['current_market_rate'] = rateStr;
      map['current_market_rate_raw'] = rateStr;
      map['current_market_rate_numeric'] = numericRateStr;
      map['flat_market_rate'] = rateStr;
      map['flat_market_rate_raw'] = rateStr;
      map['flat_market_rate_numeric'] = numericRateStr;
      map['building_market_rate'] = rateStr;
      map['building_market_rate_raw'] = rateStr;
      map['building_market_rate_numeric'] = numericRateStr;

      final amountStr = IndianNumberFormatter.format(mainUnit.amount);
      final numericAmountStr = ValueNormalizationEngine.formatNormalizedString(mainUnit.amount);
      map['unit_amount'] = amountStr;
      map['unit_amount_numeric'] = numericAmountStr;
      map['flat_value'] = amountStr;
      map['main_unit_amount'] = amountStr;
      map['composite_amount'] = amountStr;

      final deprStr = IndianNumberFormatter.format(mainUnit.depreciationAmount);
      map['main_unit_depreciation'] = deprStr;
      map['composite_depreciation'] = deprStr;

      final fairStr = IndianNumberFormatter.format(mainUnit.fairValue);
      final numericFairStr = ValueNormalizationEngine.formatNormalizedString(mainUnit.fairValue);
      map['main_unit_fair_value'] = fairStr;
      map['main_unit_fair_value_numeric'] = numericFairStr;
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

      // LEVEL 1: TOTAL_FAIR_VALUE (Actual mathematical valuation result, no rounding)
      final totalFair = (data.totalFairValue > 0)
          ? data.totalFairValue
          : (data.totalLandValue + data.totalBuildingValue);
      final totalFairStr = IndianNumberFormatter.format(totalFair);
      final totalFairWords = IndianCurrencyToWords.convertToWords(totalFair);
      final numericTotalFair = ValueNormalizationEngine.formatNormalizedString(totalFair);

      map['total_fair_value'] = totalFairStr;
      map['total_fair_value_words'] = totalFairWords;
      map['total_fair_value_numeric'] = numericTotalFair;
      map['raw_fair_value'] = totalFairStr;
      map['raw_fair_value_words'] = totalFairWords;

      // LEVEL 2: SAY_VALUE = computeSayValue(TOTAL_FAIR_VALUE)
      final sayVal = computeSayValue(totalFair);
      final sayValStr = IndianNumberFormatter.format(sayVal);
      final sayValWords = IndianCurrencyToWords.convertToWords(sayVal);
      final numericSayVal = ValueNormalizationEngine.formatNormalizedString(sayVal);

      map['say_value'] = sayValStr;
      map['say_value_words'] = sayValWords;
      map['say_fair_value'] = sayValStr;
      map['say_fair_value_words'] = sayValWords;
      map['report_fair_value'] = sayValStr;
      map['report_fair_value_words'] = sayValWords;

      // UNIFIED REPORT-FACING VALUATION: All aliases MUST equal SAY_VALUE
      map['fair_value'] = sayValStr;
      map['fair_value_words'] = sayValWords;
      map['fair_value_numeric'] = numericSayVal;
      map['market_value'] = sayValStr;
      map['market_value_words'] = sayValWords;
      map['property_value'] = sayValStr;
      map['property_value_words'] = sayValWords;
      map['final_value'] = sayValStr;
      map['final_value_words'] = sayValWords;
      map['valuation_amount'] = sayValStr;
      map['valuation_amount_words'] = sayValWords;
      map['opinion_of_value'] = sayValStr;
      map['opinion_of_value_words'] = sayValWords;
      map['recommended_value'] = sayValStr;
      map['recommended_value_words'] = sayValWords;

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

    // Statutory Guideline Variance & 20% Justification (Phase 4A Deliverable 6.4)
    final effectiveFair = isComposite
        ? (data.sayFairValue > 0 ? data.sayFairValue : computeSayValue(data.rawFairValue))
        : (data.sayLandValue > 0 || data.sayBuildingValue > 0
            ? (data.sayLandValue + data.sayBuildingValue)
            : data.fairValue);
    final effectiveGovt = data.governmentValue > 0
        ? data.governmentValue
        : (data.landGovernmentValue + data.buildingGovernmentValue);

    if (effectiveGovt > 0) {
      final variancePct = ((effectiveFair - effectiveGovt) / effectiveGovt) * 100.0;
      map['variance_percentage'] = '${variancePct.toStringAsFixed(2)}%';
      String justification;
      if (variancePct >= 20.0) {
        justification = 'The assessed Fair Market Value of ₹ ${IndianNumberFormatter.format(effectiveFair)} is ${variancePct.toStringAsFixed(2)}% higher than the Statutory Guideline Value of ₹ ${IndianNumberFormatter.format(effectiveGovt)} due to superior location advantages, commercial absorption rates, premium micro-market infrastructure, and higher prevailing transaction prices compared to historical government registration values.';
      } else if (variancePct <= -20.0) {
        justification = 'The assessed Fair Market Value of ₹ ${IndianNumberFormatter.format(effectiveFair)} is ${variancePct.abs().toStringAsFixed(2)}% lower than the Statutory Guideline Value due to physical encumbrances, shape irregularity, access constraints, or distressed localized demand.';
      } else {
        justification = 'The assessed Fair Market Value is broadly in alignment with prevailing government guideline rates with a standard variation of ${variancePct.toStringAsFixed(2)}%.';
      }
      map['20%_more'] = justification;
      map['20%_less'] = justification;
      map['variance_justification'] = justification;
      map['govt_variance_note'] = justification;
    } else {
      map['variance_percentage'] = '0.00%';
      const fallbackNote = 'Statutory guideline valuation baseline not established.';
      map['20%_more'] = fallbackNote;
      map['20%_less'] = fallbackNote;
      map['variance_justification'] = fallbackNote;
      map['govt_variance_note'] = fallbackNote;
    }

    // Add uppercase aliases
    final uppercaseMap = <String, String>{};
    for (final e in map.entries) {
      uppercaseMap[e.key.toUpperCase()] = e.value;
    }
    map.addAll(uppercaseMap);

    return map;
  }

  /// Authoritative Say Value Rounding Governance:
  /// Round to nearest ₹ 10,000 for values in Lakhs and Crores (>= ₹ 10,000).
  /// Examples:
  /// - ₹ 81,22,000 -> ₹ 81,20,000
  /// - ₹ 1,47,86,000 -> ₹ 1,47,90,000
  /// - ₹ 2,83,42,000 -> ₹ 2,83,40,000
  static double computeSayValue(double value) {
    if (value <= 0) return 0.0;
    if (value >= 10000.0) {
      return (value / 10000.0).roundToDouble() * 10000.0;
    } else {
      return (value / 1000.0).roundToDouble() * 1000.0;
    }
  }
}
