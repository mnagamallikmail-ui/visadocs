class IndianNumberFormatter {
  static String format(num? value, {bool includeDecimals = false}) {
    if (value == null) return '0';
    
    final isNegative = value < 0;
    final absVal = value.abs();
    
    final integerPart = absVal.truncate();
    final decimalPart = ((absVal - integerPart) * 100).round();
    
    final intStr = integerPart.toString();
    final len = intStr.length;
    
    String formatted;
    if (len <= 3) {
      formatted = intStr;
    } else {
      final lastThree = intStr.substring(len - 3);
      final remaining = intStr.substring(0, len - 3);
      
      final remBuffer = StringBuffer();
      int count = 0;
      for (int i = remaining.length - 1; i >= 0; i--) {
        remBuffer.write(remaining[i]);
        count++;
        if (count % 2 == 0 && i > 0) {
          remBuffer.write(',');
        }
      }
      final reversedRem = remBuffer.toString().split('').reversed.join('');
      formatted = '$reversedRem,$lastThree';
    }
    
    if (isNegative) {
      formatted = '-$formatted';
    }
    
    if (includeDecimals && decimalPart > 0) {
      formatted = '$formatted.${decimalPart.toString().padLeft(2, '0')}';
    }
    
    return formatted;
  }
}
