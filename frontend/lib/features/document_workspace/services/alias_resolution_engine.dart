/// Alias Resolution Engine (Dart)
/// Resolves placeholder aliases to canonical keys and synchronizes alias sets.
class AliasResolutionEngine {
  static const String canonicalSaleableArea = 'SALEABLE_AREA';
  static const String canonicalMarketRateFlat = 'MARKET_RATE_FLAT';

  static final Map<String, String> _aliasToCanonical = {
    'SALEABLE_AREA': canonicalSaleableArea,
    'SUPER_BUILT_UP_AREA': canonicalSaleableArea,
    'PROPERTY_AREA_SFT': canonicalSaleableArea,
    'SBUA': canonicalSaleableArea,
    'FLAT_AREA': canonicalSaleableArea,
    'SALEABLE_AREA_SQFT': canonicalSaleableArea,

    'MARKET_RATE_FLAT': canonicalMarketRateFlat,
    'COMPOSITE_RATE': canonicalMarketRateFlat,
    'CURRENT_MARKET_RATE': canonicalMarketRateFlat,
    'FLAT_MARKET_RATE': canonicalMarketRateFlat,
    'BUILDING_MARKET_RATE': canonicalMarketRateFlat,
  };

  static final Map<String, Set<String>> _canonicalToAliases = {
    canonicalSaleableArea: {
      'SUPER_BUILT_UP_AREA',
      'PROPERTY_AREA_SFT',
      'SBUA',
      'FLAT_AREA',
      'SALEABLE_AREA_SQFT',
    },
    canonicalMarketRateFlat: {
      'COMPOSITE_RATE',
      'CURRENT_MARKET_RATE',
      'FLAT_MARKET_RATE',
      'BUILDING_MARKET_RATE',
    },
  };

  /// Resolves any alias to its canonical key. Preserves _RAW or _NUMERIC suffix.
  static String resolveCanonical(String key) {
    final clean = key
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'^<<'), '')
        .replaceAll(RegExp(r'>>$'), '');

    String suffix = '';
    String base = clean;
    if (clean.endsWith('_RAW')) {
      base = clean.substring(0, clean.length - 4);
      suffix = '_RAW';
    } else if (clean.endsWith('_NUMERIC')) {
      base = clean.substring(0, clean.length - 8);
      suffix = '_NUMERIC';
    }

    final canonical = _aliasToCanonical[base] ?? base;
    return canonical + suffix;
  }

  /// Returns the set of aliases for a canonical key.
  static Set<String> getAliases(String key) {
    final canonical = resolveCanonical(key).replaceAll(RegExp(r'_(RAW|NUMERIC)$'), '');
    return _canonicalToAliases[canonical] ?? const {};
  }

  /// Returns canonical key and all aliases.
  static Set<String> getAllKnownKeys(String key) {
    final canonical = resolveCanonical(key).replaceAll(RegExp(r'_(RAW|NUMERIC)$'), '');
    final all = <String>{canonical};
    all.addAll(getAliases(canonical));
    return all;
  }

  static bool isAliasOf(String key, String canonicalTarget) {
    final resolvedKey = resolveCanonical(key).replaceAll(RegExp(r'_(RAW|NUMERIC)$'), '');
    final resolvedTarget = resolveCanonical(canonicalTarget).replaceAll(RegExp(r'_(RAW|NUMERIC)$'), '');
    return resolvedKey.toUpperCase() == resolvedTarget.toUpperCase();
  }
}
