class IndianCurrencyToWords {
  static const List<String> _units = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen'
  ];

  static const List<String> _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  static String convertToWords(num? amount) {
    if (amount == null || amount == 0) {
      return 'Rupees Zero Only';
    }

    final isNegative = amount < 0;
    final absVal = amount.abs();
    final rupees = absVal.truncate();
    final paise = ((absVal - rupees) * 100).round();

    final buffer = StringBuffer();
    if (isNegative) {
      buffer.write('Minus ');
    }

    buffer.write('Rupees ');

    if (rupees > 0) {
      buffer.write(_convertNumber(rupees));
    } else {
      buffer.write('Zero');
    }

    if (paise > 0) {
      buffer.write(' and ${_convertTwoDigits(paise)} Paise');
    }

    buffer.write(' Only');

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _convertNumber(int n) {
    if (n == 0) return '';

    final buffer = StringBuffer();

    // Crores (1,00,00,000)
    final crore = n ~/ 10000000;
    final remCrore = n % 10000000;
    if (crore > 0) {
      buffer.write('${_convertNumber(crore)} Crore ');
    }

    // Lakhs (1,00,000)
    final lakh = remCrore ~/ 100000;
    final remLakh = remCrore % 100000;
    if (lakh > 0) {
      buffer.write('${_convertTwoDigits(lakh)} Lakh ');
    }

    // Thousands (1,000)
    final thousand = remLakh ~/ 1000;
    final remThousand = remLakh % 1000;
    if (thousand > 0) {
      buffer.write('${_convertTwoDigits(thousand)} Thousand ');
    }

    // Hundreds (100)
    final hundred = remThousand ~/ 100;
    final remHundred = remThousand % 100;
    if (hundred > 0) {
      buffer.write('${_units[hundred]} Hundred ');
    }

    // Tens and units
    if (remHundred > 0) {
      buffer.write('${_convertTwoDigits(remHundred)} ');
    }

    return buffer.toString().trim();
  }

  static String _convertTwoDigits(int n) {
    if (n < 20) {
      return _units[n];
    }
    final ten = n ~/ 10;
    final unit = n % 10;
    if (unit > 0) {
      return '${_tens[ten]} ${_units[unit]}';
    } else {
      return _tens[ten];
    }
  }
}
