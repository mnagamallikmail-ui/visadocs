/// Numeric calculation engine for template-driven formulas (<<CALC:expression>>).
/// Implements a recursive descent parser supporting +, -, *, /, (), unary minus,
/// whitespace indifference, variable resolution (e.g., N1, N2), cycle detection,
/// and clear validation error reporting.
class NumericFormulaEngine {
  static final RegExp _nKeyPattern = RegExp(r'^N\d+$', caseSensitive: false);
  static final RegExp _calcKeyPattern = RegExp(r'^CALC:(.+)$', caseSensitive: false);

  static bool isNumericInputKey(String key) {
    final clean = key.replaceAll(RegExp(r'[<>\s]'), '');
    return _nKeyPattern.hasMatch(clean);
  }

  static bool isFormulaCalcKey(String key) {
    final clean = key.replaceAll(RegExp(r'[<>\s]'), '');
    return _calcKeyPattern.hasMatch(clean);
  }

  static String extractFormulaExpression(String key) {
    final clean = key.replaceAll(RegExp(r'[<>]'), '').trim();
    final match = _calcKeyPattern.firstMatch(clean);
    if (match != null) {
      return (match.group(1) ?? '').trim();
    }
    return clean;
  }

  /// Extracts all variable identifiers referenced in the expression.
  static Set<String> extractVariables(String expr) {
    final vars = <String>{};
    try {
      final tokens = _tokenize(expr);
      for (final t in tokens) {
        if (t.type == _TokenType.variable) {
          vars.add(t.text.toUpperCase());
        }
      }
    } catch (_) {
      final matches = RegExp(r'[A-Za-z_][A-Za-z0-9_]*').allMatches(expr);
      for (final m in matches) {
        vars.add((m.group(0) ?? '').toUpperCase());
      }
    }
    return vars;
  }

  /// Evaluates an expression against a map of string values (e.g. activeValues).
  static FormulaEvaluationResult evaluate(String expression, Map<String, String> inputs) {
    if (expression.trim().isEmpty) {
      return const FormulaEvaluationResult.error('Invalid expression: Empty formula expression');
    }

    try {
      final tokens = _tokenize(expression.trim());

      final resolved = <String, double>{};
      int totalVarCount = 0;
      int untouchedVarCount = 0;

      for (final t in tokens) {
        if (t.type == _TokenType.variable) {
          totalVarCount++;
          final vName = t.text;
          final upperVName = vName.toUpperCase();

          String? rawStr;
          if (inputs.containsKey(vName)) {
            rawStr = inputs[vName];
          } else if (inputs.containsKey(upperVName)) {
            rawStr = inputs[upperVName];
          } else if (inputs.containsKey(vName.toLowerCase())) {
            rawStr = inputs[vName.toLowerCase()];
          }

          if (rawStr == null || rawStr.trim().isEmpty) {
            untouchedVarCount++;
            if (_nKeyPattern.hasMatch(upperVName)) {
              resolved[upperVName] = 0.0;
              continue;
            }
            return FormulaEvaluationResult.error('Unknown variable: $vName');
          }

          final cleaned = rawStr.replaceAll(RegExp(r'[₹,\s]'), '').trim();
          final parsed = double.tryParse(cleaned);
          if (parsed == null) {
            return FormulaEvaluationResult.error("Unknown variable: $vName contains non-numeric value '$rawStr'");
          }
          resolved[upperVName] = parsed;
        }
      }

      final allUntouched = totalVarCount > 0 && totalVarCount == untouchedVarCount;

      final parser = _Parser(tokens, resolved);
      final val = parser.parse();

      if (val.isNaN || val.isInfinite) {
        return const FormulaEvaluationResult.error('Division by zero');
      }

      final formatted = formatResult(val);
      return FormulaEvaluationResult.success(val, formatted, allInputsUntouched: allUntouched);
    } on _FormulaException catch (fe) {
      return FormulaEvaluationResult.error(fe.message);
    } catch (e) {
      return FormulaEvaluationResult.error('Invalid expression: $e');
    }
  }

  /// Applies Decision 1 Rounding Governance (Approach A: True Rounding HALF_UP):
  /// - Lakhs (< 1,00,00,000): Round to nearest ₹1,000
  /// - Crores (>= 1,00,00,000): Round to nearest ₹10,000
  /// Apply ONLY to:
  /// - Realizable Value
  /// - Distress Sale Value
  /// - Distress Value
  /// - Insurable Value
  /// DO NOT APPLY TO:
  /// - Government Value (must remain exact)
  /// - Fair Value
  static double applyRoundingGovernance(String fieldKey, double value) {
    if (value <= 0) return 0.0;
    final lower = fieldKey.toLowerCase();

    // Never apply to government value or fair value
    if (lower.contains('government') || lower.contains('guideline') || lower.contains('fair')) {
      return value;
    }

    final isTarget = lower.contains('realizable') ||
        lower.contains('distress') ||
        lower.contains('insurable');

    if (!isTarget) {
      return value;
    }

    const double oneCrore = 10000000.0;
    const double tenThousand = 10000.0;
    const double oneThousand = 1000.0;

    if (value >= oneCrore) {
      return (value / tenThousand).roundToDouble() * tenThousand;
    } else {
      return (value / oneThousand).roundToDouble() * oneThousand;
    }
  }

  /// Formats evaluated numeric value cleanly:
  /// e.g. 9522200.0 -> "9522200", 150.0 -> "150", 12.345 -> "12.345"
  static String formatResult(double val) {
    if (val.isNaN || val.isInfinite) return '';
    if ((val - val.roundToDouble()).abs() < 1e-9) {
      return val.round().toString();
    }
    String s = val.toStringAsFixed(6);
    // Strip trailing zeros and possible trailing dot
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  /// Detects if circular dependencies exist among formula definitions.
  static String? detectCircularDependencies(Map<String, String> formulas) {
    if (formulas.isEmpty) return null;

    final graph = <String, Set<String>>{};
    for (final entry in formulas.entries) {
      var node = entry.key.toUpperCase().replaceAll(RegExp(r'[<>]'), '').trim();
      if (node.startsWith('CALC:')) node = node.substring(5);
      graph[node] = extractVariables(entry.value);
    }

    final visited = <String>{};
    final recStack = <String>{};

    for (final node in graph.keys) {
      if (_checkCycle(node, graph, visited, recStack)) {
        return "Circular dependency detected involving formula '$node'";
      }
    }
    return null;
  }

  static bool _checkCycle(String node, Map<String, Set<String>> graph, Set<String> visited, Set<String> recStack) {
    if (recStack.contains(node)) return true;
    if (visited.contains(node)) return false;

    visited.add(node);
    recStack.add(node);

    final neighbors = graph[node];
    if (neighbors != null) {
      for (final neighbor in neighbors) {
        if (_checkCycle(neighbor, graph, visited, recStack)) {
          return true;
        }
      }
    }

    recStack.remove(node);
    return false;
  }

  // =========================================================================
  // TOKENIZER
  // =========================================================================

  static List<_Token> _tokenize(String expr) {
    final tokens = <_Token>[];
    if (expr.trim().isEmpty) {
      throw _FormulaException('Invalid expression: Empty formula expression');
    }

    int i = 0;
    final len = expr.length;

    while (i < len) {
      final c = expr[i];

      // Whitespace
      if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
        i++;
        continue;
      }

      // Operators & Parens
      if (c == '+') {
        tokens.add(_Token(_TokenType.plus, '+', null, i));
        i++;
      } else if (c == '-') {
        tokens.add(_Token(_TokenType.minus, '-', null, i));
        i++;
      } else if (c == '*') {
        tokens.add(_Token(_TokenType.multiply, '*', null, i));
        i++;
      } else if (c == '/') {
        tokens.add(_Token(_TokenType.divide, '/', null, i));
        i++;
      } else if (c == '(') {
        tokens.add(_Token(_TokenType.lParen, '(', null, i));
        i++;
      } else if (c == ')') {
        tokens.add(_Token(_TokenType.rParen, ')', null, i));
        i++;
      } else if (RegExp(r'[0-9]').hasMatch(c) || (c == '.' && i + 1 < len && RegExp(r'[0-9]').hasMatch(expr[i + 1]))) {
        final start = i;
        bool hasDot = (c == '.');
        i++;
        while (i < len && (RegExp(r'[0-9]').hasMatch(expr[i]) || (!hasDot && expr[i] == '.'))) {
          if (expr[i] == '.') hasDot = true;
          i++;
        }
        final numStr = expr.substring(start, i);
        final val = double.tryParse(numStr);
        if (val == null) {
          throw _FormulaException("Invalid expression: Malformed number '$numStr' at position $start");
        }
        tokens.add(_Token(_TokenType.number, numStr, val, start));
      } else if (RegExp(r'[A-Za-z_]').hasMatch(c)) {
        final start = i;
        i++;
        while (i < len && RegExp(r'[A-Za-z0-9_]').hasMatch(expr[i])) {
          i++;
        }
        final varName = expr.substring(start, i);
        tokens.add(_Token(_TokenType.variable, varName, null, start));
      } else {
        throw _FormulaException("Invalid expression: Unexpected character '$c' at position $i");
      }
    }

    tokens.add(_Token(_TokenType.eof, '', null, len));
    return tokens;
  }
}

// =========================================================================
// DATA STRUCTURES & PARSER
// =========================================================================

enum _TokenType { number, variable, plus, minus, multiply, divide, lParen, rParen, eof }

class _Token {
  final _TokenType type;
  final String text;
  final double? numberValue;
  final int position;

  _Token(this.type, this.text, this.numberValue, this.position);
}

class _FormulaException implements Exception {
  final String message;
  _FormulaException(this.message);

  @override
  String toString() => message;
}

class _Parser {
  final List<_Token> tokens;
  final Map<String, double> resolvedVariables;
  int _current = 0;

  _Parser(this.tokens, this.resolvedVariables);

  double parse() {
    final result = _expression();
    if (!_isAtEnd()) {
      final t = _peek();
      if (t.type == _TokenType.rParen) {
        throw _FormulaException("Mismatched parentheses: Unexpected ')' at position ${t.position}");
      }
      throw _FormulaException("Invalid expression: Unexpected token '${t.text}' at position ${t.position}");
    }
    return result;
  }

  double _expression() {
    double left = _term();

    while (_match([_TokenType.plus, _TokenType.minus])) {
      final op = _previous();
      final right = _term();
      if (op.type == _TokenType.plus) {
        left = left + right;
      } else {
        left = left - right;
      }
    }

    return left;
  }

  double _term() {
    double left = _factor();

    while (_match([_TokenType.multiply, _TokenType.divide])) {
      final op = _previous();
      final right = _factor();
      if (op.type == _TokenType.multiply) {
        left = left * right;
      } else {
        if (right.abs() < 1e-15 || right.isNaN || right.isInfinite) {
          throw _FormulaException('Division by zero');
        }
        left = left / right;
      }
    }

    return left;
  }

  double _factor() {
    if (_match([_TokenType.minus])) {
      return -_factor();
    }
    if (_match([_TokenType.plus])) {
      return _factor();
    }
    return _primary();
  }

  double _primary() {
    if (_match([_TokenType.number])) {
      return _previous().numberValue!;
    }

    if (_match([_TokenType.variable])) {
      final varToken = _previous();
      final varName = varToken.text.toUpperCase();
      if (!resolvedVariables.containsKey(varName)) {
        throw _FormulaException('Unknown variable: ${varToken.text}');
      }
      return resolvedVariables[varName]!;
    }

    if (_match([_TokenType.lParen])) {
      final openPos = _previous().position;
      final val = _expression();
      if (!_match([_TokenType.rParen])) {
        throw _FormulaException("Mismatched parentheses: Missing closing ')' for '(' at position $openPos");
      }
      return val;
    }

    final currentToken = _peek();
    if (currentToken.type == _TokenType.eof) {
      throw _FormulaException('Invalid expression: Unexpected end of expression');
    }
    throw _FormulaException("Invalid expression: Unexpected token '${currentToken.text}' at position ${currentToken.position}");
  }

  bool _match(List<_TokenType> types) {
    for (final type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }
    return false;
  }

  bool _check(_TokenType type) {
    if (_isAtEnd()) return type == _TokenType.eof;
    return _peek().type == type;
  }

  _Token _advance() {
    if (!_isAtEnd()) _current++;
    return _previous();
  }

  bool _isAtEnd() => _peek().type == _TokenType.eof;
  _Token _peek() => tokens[_current];
  _Token _previous() => tokens[_current - 1];
}

class FormulaEvaluationResult {
  final bool isValid;
  final double? value;
  final String formattedValue;
  final String? errorMessage;
  final bool allInputsUntouched;

  const FormulaEvaluationResult.success(this.value, this.formattedValue, {this.allInputsUntouched = false})
      : isValid = true,
        errorMessage = null;

  const FormulaEvaluationResult.error(this.errorMessage)
      : isValid = false,
        value = null,
        formattedValue = '',
        allInputsUntouched = false;

  @override
  String toString() => isValid ? formattedValue : '[Error: $errorMessage]';
}
