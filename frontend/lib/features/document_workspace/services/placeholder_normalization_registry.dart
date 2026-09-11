/// Placeholder Normalization Registry (Dart)
/// Categorizes placeholders into Area, Rate, Percentage, Numeric, and Text.
enum NormalizationType {
  area,
  rate,
  percentage,
  numeric,
  text,
}

class PlaceholderNormalizationRegistry {
  static const Set<String> _areaKeys = {
    'SALEABLE_AREA',
    'SUPER_BUILT_UP_AREA',
    'PROPERTY_AREA_SFT',
    'SBUA',
    'FLAT_AREA',
    'LAND_AREA',
    'PLOT_AREA',
    'BUILTUP_AREA',
    'SALEABLE_AREA_SQFT',
  };

  static const Set<String> _rateKeys = {
    'MARKET_RATE_FLAT',
    'COMPOSITE_RATE',
    'CURRENT_MARKET_RATE',
    'FLAT_MARKET_RATE',
    'BUILDING_MARKET_RATE',
    'LAND_RATE',
    'GOVERNMENT_RATE',
    'GUIDELINE_RATE',
    'COMPOSITE_GOVERNMENT_RATE',
    'REPLACEMENT_COST',
    'REPLACEMENT_RATE',
  };

  static const Set<String> _percentageKeys = {
    'REALIZABLE_PERCENTAGE',
    'DISTRESS_SALE_PERCENTAGE',
    'LAND_REALIZABLE_PERCENTAGE',
    'BUILDING_REALIZABLE_PERCENTAGE',
    'LAND_DISTRESS_PERCENTAGE',
    'BUILDING_DISTRESS_PERCENTAGE',
    'DEFAULT_SALVAGE_PERCENTAGE',
    'SALVAGE_PERCENTAGE',
    'COMPOSITE_BUILDING_DEPRECIATION_PCT',
    'DEPRECIATION_PERCENTAGE',
  };

  static const Set<String> _numericKeys = {
    'TOTAL_LIFE',
    'BUILDING_AGE',
    'COMPOSITE_BUILDING_AGE',
    'COMPOSITE_BUILDING_TOTAL_LIFE',
    'GOVERNMENT_VALUE',
    'COMPOSITE_CONSTRUCTION_COST',
    'SAY_VALUE',
    'FAIR_VALUE',
    'REALIZABLE_VALUE',
    'DISTRESS_SALE_VALUE',
    'INSURABLE_VALUE',
  };

  static NormalizationType getNormalizationType(String key) {
    final cleanKey = key
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'^<<'), '')
        .replaceAll(RegExp(r'>>$'), '')
        .replaceAll(RegExp(r'_(RAW|NUMERIC)$'), '');

    if (_areaKeys.contains(cleanKey)) {
      return NormalizationType.area;
    }
    if (_rateKeys.contains(cleanKey)) {
      return NormalizationType.rate;
    }
    if (_percentageKeys.contains(cleanKey)) {
      return NormalizationType.percentage;
    }
    if (_numericKeys.contains(cleanKey)) {
      return NormalizationType.numeric;
    }
    return NormalizationType.text;
  }

  static bool isAreaKey(String key) => getNormalizationType(key) == NormalizationType.area;
  static bool isRateKey(String key) => getNormalizationType(key) == NormalizationType.rate;
  static bool isPercentageKey(String key) => getNormalizationType(key) == NormalizationType.percentage;
  static bool isNumericKey(String key) {
    final type = getNormalizationType(key);
    return type != NormalizationType.text;
  }

  static Set<String> get areaKeys => Set.unmodifiable(_areaKeys);
  static Set<String> get rateKeys => Set.unmodifiable(_rateKeys);
  static Set<String> get percentageKeys => Set.unmodifiable(_percentageKeys);
}
