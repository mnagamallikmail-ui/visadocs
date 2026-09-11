import 'alias_resolution_engine.dart';
import 'placeholder_normalization_registry.dart';

/// Value Normalization Engine (Dart)
/// Extracts numeric values, detects units, and calculates standardized Area in Sq.Ft
/// preserving up to 3 decimal places without silent zero conversion.
class ValueNormalizationEngine {
  static const String validationErrorMsg = 'Numeric value could not be derived from input.';

  // Matches numbers with optional sign, optional commas, and optional decimal points
  // Negative lookbehind ensures we don't pick up trailing periods from abbreviations like "Approx."
  static final RegExp _numericPattern = RegExp(r'(?<![a-zA-Z0-9_])[-+]?(?:(?:\d+(?:,\d+)*)(?:\.\d+)?|\.\d+)');

  // Unit detection patterns
  static final RegExp _acresPattern = RegExp(r'\b(acres?)\b', caseSensitive: false);
  static final RegExp _groundsPattern = RegExp(r'\b(grounds?)\b', caseSensitive: false);
  static final RegExp _centsPattern = RegExp(r'\b(cents?)\b', caseSensitive: false);
  static final RegExp _hectaresPattern = RegExp(r'\b(hectares?)\b', caseSensitive: false);
  static final RegExp _sqydPattern = RegExp(r'\b(sq\.?\s*yd[s]?|square\s+yards?)\b', caseSensitive: false);
  static final RegExp _sqmPattern = RegExp(r'\b(sq\.?\s*m(?:eters?)?|square\s+meters?)\b', caseSensitive: false);
  static final RegExp _sqftPattern = RegExp(r'\b(sq\.?\s*ft|sft|square\s+feet|square\s+foot)\b', caseSensitive: false);

  // Conversion factors
  static const double factorAcre = 43560.0;
  static const double factorGround = 2400.0;
  static const double factorCent = 435.6;
  static const double factorHectare = 107639.104;
  static const double factorSqyd = 9.0;
  static const double factorSqm = 10.76391;

  /// Detects canonical area unit from human-entered string.
  static String detectAreaUnit(String input) {
    final trimmed = input.trim();
    if (_acresPattern.hasMatch(trimmed)) return 'ACRES';
    if (_sqydPattern.hasMatch(trimmed)) return 'SQYD';
    if (_sqmPattern.hasMatch(trimmed)) return 'SQM';
    if (_centsPattern.hasMatch(trimmed)) return 'CENTS';
    if (_groundsPattern.hasMatch(trimmed)) return 'GROUNDS';
    if (_hectaresPattern.hasMatch(trimmed)) return 'HECTARES';
    if (_sqftPattern.hasMatch(trimmed)) return 'SQFT';
    return 'SQFT';
  }

  /// Converts numeric value in detected unit to Standard Area in Sq.Ft preserving up to 3 decimal places.
  static double convertToStandardSqft(double numericValue, String unit) {
    final u = unit.toUpperCase().trim();
    double standard;
    switch (u) {
      case 'ACRES':
      case 'ACRE':
        standard = numericValue * factorAcre;
        break;
      case 'GROUNDS':
      case 'GROUND':
        standard = numericValue * factorGround;
        break;
      case 'CENTS':
      case 'CENT':
        standard = numericValue * factorCent;
        break;
      case 'HECTARES':
      case 'HECTARE':
        standard = numericValue * factorHectare;
        break;
      case 'SQYD':
      case 'SQ.YD':
        standard = numericValue * factorSqyd;
        break;
      case 'SQM':
      case 'SQ.M':
        standard = numericValue * factorSqm;
        break;
      case 'SQFT':
      case 'SQ.FT':
      default:
        standard = numericValue;
        break;
    }
    return applyDecimalPrecisionGovernance(standard);
  }

  /// Fully normalizes an area input returning NormalizedValue with detected unit and standard Sq.Ft.
  static NormalizedValue normalizeAreaValue(String input) {
    if (input.trim().isEmpty) {
      throw const FormatException(validationErrorMsg);
    }
    final numeric = extractNumericValue(input);
    final unit = detectAreaUnit(input);
    final standardSqft = convertToStandardSqft(numeric, unit);
    return NormalizedValue(
      rawValue: input,
      numericValue: numeric,
      detectedUnit: unit,
      standardSqftValue: standardSqft,
      valid: true,
    );
  }

  /// Normalizes a raw string input for a given placeholder key.
  static double normalize(String key, String input) {
    if (input.trim().isEmpty) {
      throw const FormatException(validationErrorMsg);
    }

    final type = PlaceholderNormalizationRegistry.getNormalizationType(key);
    switch (type) {
      case NormalizationType.area:
        return normalizeArea(input);
      case NormalizationType.rate:
        return normalizeRate(input);
      case NormalizationType.percentage:
        return normalizePercentage(input);
      case NormalizationType.numeric:
      case NormalizationType.text:
      default:
        return normalizeNumeric(input);
    }
  }

  static double normalizeArea(String input) => extractNumericValue(input);
  static double normalizeRate(String input) => extractNumericValue(input);
  static double normalizePercentage(String input) => extractNumericValue(input);
  static double normalizeNumeric(String input) => extractNumericValue(input);

  /// Extracts numeric value preserving up to 3 decimal places.
  /// If input contains more than 3 decimal places, rounds to 3 decimal places (HALF_UP).
  static double extractNumericValue(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const FormatException(validationErrorMsg);
    }

    final match = _numericPattern.firstMatch(trimmed);
    if (match == null) {
      throw const FormatException(validationErrorMsg);
    }

    final cleanStr = match.group(0)!.replaceAll(',', '').trim();
    final parsed = double.tryParse(cleanStr);
    if (parsed == null) {
      throw const FormatException(validationErrorMsg);
    }

    return applyDecimalPrecisionGovernance(parsed);
  }

  /// Preserves up to 3 decimal places; rounds beyond 3 decimals using HALF_UP.
  static double applyDecimalPrecisionGovernance(double value) {
    final fixed3Str = value.toStringAsFixed(3);
    return double.parse(fixed3Str);
  }

  /// Formats normalized double into standard string (e.g. 1000 -> "1000", 1000.125 -> "1000.125")
  static String formatNormalizedString(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    String s = value.toStringAsFixed(3);
    while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// Safely attempts normalization returning null if extraction fails.
  static double? tryNormalize(String key, String input) {
    try {
      return normalize(key, input);
    } catch (_) {
      return null;
    }
  }

  /// Creates a DualValueResult given a key and raw input.
  static DualValueResult createDualValueResult(String key, String rawInput) {
    if (PlaceholderNormalizationRegistry.isAreaKey(key)) {
      final norm = normalizeAreaValue(rawInput);
      return DualValueResult(
        enteredKey: key,
        rawValue: rawInput,
        numericValue: norm.numericValue,
        detectedUnit: norm.detectedUnit,
        standardSqftValue: norm.standardSqftValue,
      );
    }
    final numeric = normalize(key, rawInput);
    return DualValueResult(
      enteredKey: key,
      rawValue: rawInput,
      numericValue: numeric,
      detectedUnit: 'SQFT',
      standardSqftValue: numeric,
    );
  }
}

/// Normalized Value Response Model
class NormalizedValue {
  final String rawValue;
  final double numericValue;
  final String detectedUnit;
  final double standardSqftValue;
  final boolean valid;

  NormalizedValue({
    required this.rawValue,
    required this.numericValue,
    required this.detectedUnit,
    required this.standardSqftValue,
    this.valid = true,
  });
}

typedef boolean = bool;

/// Dual value result containing canonical keys, raw values, numeric values,
/// detected unit, standard sqft, and alias synchronizations.
class DualValueResult {
  final String enteredKey;
  final String canonicalKey;
  final String rawValue;
  final double numericValue;
  final String detectedUnit;
  final double standardSqftValue;
  final Map<String, String> valuesToStore = {};

  DualValueResult({
    required this.enteredKey,
    required this.rawValue,
    required this.numericValue,
    required this.detectedUnit,
    required this.standardSqftValue,
  }) : canonicalKey = AliasResolutionEngine.resolveCanonical(enteredKey) {
    final numericStr = ValueNormalizationEngine.formatNormalizedString(numericValue);
    final stdSqftStr = ValueNormalizationEngine.formatNormalizedString(standardSqftValue);
    final isArea = PlaceholderNormalizationRegistry.isAreaKey(enteredKey);

    // 1. Entered key store
    valuesToStore[enteredKey] = rawValue;
    valuesToStore['${enteredKey}_RAW'] = rawValue;
    valuesToStore['${enteredKey}_NUMERIC'] = numericStr;
    if (isArea) {
      valuesToStore['${enteredKey}_UNIT'] = detectedUnit;
      valuesToStore['${enteredKey}_STANDARD_SQFT'] = stdSqftStr;
    }

    // 2. Canonical key store
    valuesToStore[canonicalKey] = rawValue;
    valuesToStore['${canonicalKey}_RAW'] = rawValue;
    valuesToStore['${canonicalKey}_NUMERIC'] = numericStr;
    if (isArea) {
      valuesToStore['${canonicalKey}_UNIT'] = detectedUnit;
      valuesToStore['${canonicalKey}_STANDARD_SQFT'] = stdSqftStr;
    }

    // 3. Alias propagation
    final aliases = AliasResolutionEngine.getAliases(canonicalKey);
    for (final alias in aliases) {
      valuesToStore[alias] = rawValue;
      valuesToStore['${alias}_RAW'] = rawValue;
      valuesToStore['${alias}_NUMERIC'] = numericStr;
      if (isArea) {
        valuesToStore['${alias}_UNIT'] = detectedUnit;
        valuesToStore['${alias}_STANDARD_SQFT'] = stdSqftStr;
      }
    }
  }
}
