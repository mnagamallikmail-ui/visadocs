class UnitConversionEngine {
  static const Map<String, double> unitFactors = {
    'SQ.FT': 1.0,
    'SQFT': 1.0,
    'SQ.FT.': 1.0,
    'SQ.M': 10.763910,
    'SQM': 10.763910,
    'SQ.M.': 10.763910,
    'SQ.YD': 9.0,
    'SQYD': 9.0,
    'SQ.YD.': 9.0,
    'ACRES': 43560.0,
    'ACRE': 43560.0,
    'CENTS': 435.6,
    'CENT': 435.6,
    'GROUNDS': 2400.0,
    'GROUND': 2400.0,
    'HECTARES': 107639.104,
    'HECTARE': 107639.104,
  };

  static double getConversionFactor(String unitName) {
    if (unitName.trim().isEmpty) return 1.0;
    return unitFactors[unitName.trim().toUpperCase()] ?? 1.0;
  }

  static double toStandardSqFt(double enteredArea, String enteredUnit) {
    final factor = getConversionFactor(enteredUnit);
    return enteredArea * factor;
  }
}
