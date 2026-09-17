package com.provaluer.util;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Numeric calculation engine for template-driven formulas (<<CALC:expression>>).
 * Implements a recursive descent parser supporting +, -, *, /, (), unary minus,
 * whitespace indifference, variable resolution (e.g., N1, N2), cycle detection,
 * and clear validation error reporting.
 */
public class NumericFormulaEngine {

    private static final Pattern N_KEY_PATTERN = Pattern.compile("(?i)^N\\d+$");
    private static final Pattern CALC_KEY_PATTERN = Pattern.compile("(?i)^CALC:(.+)$");

    public static boolean isNumericInputKey(String key) {
        if (key == null) return false;
        String clean = key.replaceAll("[<>\\s]", "");
        return N_KEY_PATTERN.matcher(clean).matches();
    }

    public static boolean isFormulaCalcKey(String key) {
        if (key == null) return false;
        String clean = key.replaceAll("[<>\\s]", "");
        return CALC_KEY_PATTERN.matcher(clean).matches();
    }

    public static String extractFormulaExpression(String key) {
        if (key == null) return "";
        String clean = key.replaceAll("[<>]", "").trim();
        Matcher m = CALC_KEY_PATTERN.matcher(clean);
        if (m.matches()) {
            return m.group(1).trim();
        }
        return clean;
    }

    /**
     * Evaluation result holder with validation status, numeric value,
     * formatted string, and human-readable error messages.
     */
    public static class EvaluationResult {
        private final boolean valid;
        private final Double value;
        private final String formattedValue;
        private final String errorMessage;
        private final boolean allInputsUntouched;

        public EvaluationResult(Double value, String formattedValue) {
            this(value, formattedValue, false);
        }

        public EvaluationResult(Double value, String formattedValue, boolean allInputsUntouched) {
            this.valid = true;
            this.value = value;
            this.formattedValue = formattedValue;
            this.errorMessage = null;
            this.allInputsUntouched = allInputsUntouched;
        }

        public EvaluationResult(String errorMessage) {
            this.valid = false;
            this.value = null;
            this.formattedValue = "";
            this.errorMessage = errorMessage;
            this.allInputsUntouched = false;
        }

        public boolean isValid() { return valid; }
        public Double getValue() { return value; }
        public String getFormattedValue() { return formattedValue; }
        public String getErrorMessage() { return errorMessage; }
        public boolean isAllInputsUntouched() { return allInputsUntouched; }

        @Override
        public String toString() {
            return valid ? formattedValue : "[Error: " + errorMessage + "]";
        }
    }

    public static class FormulaException extends Exception {
        public FormulaException(String message) {
            super(message);
        }
    }

    // =========================================================================
    // TOKENIZER
    // =========================================================================

    private enum TokenType {
        NUMBER,
        VARIABLE,
        PLUS,
        MINUS,
        MULTIPLY,
        DIVIDE,
        LPAREN,
        RPAREN,
        EOF
    }

    private static class Token {
        final TokenType type;
        final String text;
        final Double numberValue;
        final int position;

        Token(TokenType type, String text, Double numberValue, int position) {
            this.type = type;
            this.text = text;
            this.numberValue = numberValue;
            this.position = position;
        }
    }

    private static List<Token> tokenize(String expr) throws FormulaException {
        List<Token> tokens = new ArrayList<>();
        if (expr == null || expr.trim().isEmpty()) {
            throw new FormulaException("Invalid expression: Empty formula expression");
        }

        int i = 0;
        int len = expr.length();

        while (i < len) {
            char c = expr.charAt(i);

            // 1. Whitespace: ignored
            if (Character.isWhitespace(c)) {
                i++;
                continue;
            }

            // 2. Operators & Parentheses
            if (c == '+') {
                tokens.add(new Token(TokenType.PLUS, "+", null, i));
                i++;
            } else if (c == '-') {
                tokens.add(new Token(TokenType.MINUS, "-", null, i));
                i++;
            } else if (c == '*') {
                tokens.add(new Token(TokenType.MULTIPLY, "*", null, i));
                i++;
            } else if (c == '/') {
                tokens.add(new Token(TokenType.DIVIDE, "/", null, i));
                i++;
            } else if (c == '(') {
                tokens.add(new Token(TokenType.LPAREN, "(", null, i));
                i++;
            } else if (c == ')') {
                tokens.add(new Token(TokenType.RPAREN, ")", null, i));
                i++;
            }
            // 3. Numbers (integers or decimals)
            else if (Character.isDigit(c) || (c == '.' && i + 1 < len && Character.isDigit(expr.charAt(i + 1)))) {
                int start = i;
                boolean hasDot = (c == '.');
                i++;
                while (i < len && (Character.isDigit(expr.charAt(i)) || (!hasDot && expr.charAt(i) == '.'))) {
                    if (expr.charAt(i) == '.') hasDot = true;
                    i++;
                }
                String numStr = expr.substring(start, i);
                try {
                    double val = Double.parseDouble(numStr);
                    tokens.add(new Token(TokenType.NUMBER, numStr, val, start));
                } catch (NumberFormatException e) {
                    throw new FormulaException("Invalid expression: Malformed number '" + numStr + "' at position " + start);
                }
            }
            // 4. Variables (e.g., N1, N2, or alphanumeric identifiers)
            else if (Character.isLetter(c) || c == '_') {
                int start = i;
                i++;
                while (i < len && (Character.isLetterOrDigit(expr.charAt(i)) || expr.charAt(i) == '_')) {
                    i++;
                }
                String varName = expr.substring(start, i);
                tokens.add(new Token(TokenType.VARIABLE, varName, null, start));
            } else {
                throw new FormulaException("Invalid expression: Unexpected character '" + c + "' at position " + i);
            }
        }

        tokens.add(new Token(TokenType.EOF, "", null, len));
        return tokens;
    }

    // =========================================================================
    // VARIABLE EXTRACTION
    // =========================================================================

    /**
     * Extracts all variable identifiers referenced in the expression.
     */
    public static Set<String> extractVariables(String expr) {
        Set<String> vars = new LinkedHashSet<>();
        try {
            List<Token> tokens = tokenize(expr);
            for (Token t : tokens) {
                if (t.type == TokenType.VARIABLE) {
                    vars.add(t.text.toUpperCase());
                }
            }
        } catch (Exception ignored) {
            // Fallback regex if tokenizer fails on invalid syntax
            Matcher m = Pattern.compile("(?i)[A-Za-z_][A-Za-z0-9_]*").matcher(expr);
            while (m.find()) {
                vars.add(m.group(0).toUpperCase());
            }
        }
        return vars;
    }

    // =========================================================================
    // PARSER & EVALUATOR
    // =========================================================================

    private static class Parser {
        private final List<Token> tokens;
        private final Map<String, Double> resolvedVariables;
        private int current = 0;

        Parser(List<Token> tokens, Map<String, Double> resolvedVariables) {
            this.tokens = tokens;
            this.resolvedVariables = resolvedVariables;
        }

        double parse() throws FormulaException {
            double result = expression();
            if (!isAtEnd()) {
                Token t = peek();
                if (t.type == TokenType.RPAREN) {
                    throw new FormulaException("Mismatched parentheses: Unexpected ')' at position " + t.position);
                }
                throw new FormulaException("Invalid expression: Unexpected token '" + t.text + "' at position " + t.position);
            }
            return result;
        }

        // expression = term (('+' | '-') term)*
        private double expression() throws FormulaException {
            double left = term();

            while (match(TokenType.PLUS, TokenType.MINUS)) {
                Token operator = previous();
                double right = term();
                if (operator.type == TokenType.PLUS) {
                    left = left + right;
                } else {
                    left = left - right;
                }
            }

            return left;
        }

        // term = factor (('*' | '/') factor)*
        private double term() throws FormulaException {
            double left = factor();

            while (match(TokenType.MULTIPLY, TokenType.DIVIDE)) {
                Token operator = previous();
                double right = factor();
                if (operator.type == TokenType.MULTIPLY) {
                    left = left * right;
                } else {
                    if (Math.abs(right) < 1e-15 || Double.isNaN(right) || Double.isInfinite(right)) {
                        throw new FormulaException("Division by zero");
                    }
                    left = left / right;
                }
            }

            return left;
        }

        // factor = ('+' | '-') factor | primary (Unary plus/minus support)
        private double factor() throws FormulaException {
            if (match(TokenType.MINUS)) {
                return -factor();
            }
            if (match(TokenType.PLUS)) {
                return factor();
            }
            return primary();
        }

        // primary = NUMBER | VARIABLE | '(' expression ')'
        private double primary() throws FormulaException {
            if (match(TokenType.NUMBER)) {
                return previous().numberValue;
            }

            if (match(TokenType.VARIABLE)) {
                String varName = previous().text.toUpperCase();
                if (!resolvedVariables.containsKey(varName)) {
                    throw new FormulaException("Unknown variable: " + previous().text);
                }
                Double val = resolvedVariables.get(varName);
                if (val == null) {
                    throw new FormulaException("Unknown variable: " + previous().text + " has null or empty value");
                }
                return val;
            }

            if (match(TokenType.LPAREN)) {
                int openPos = previous().position;
                double val = expression();
                if (!match(TokenType.RPAREN)) {
                    throw new FormulaException("Mismatched parentheses: Missing closing ')' for '(' at position " + openPos);
                }
                return val;
            }

            Token currentToken = peek();
            if (currentToken.type == TokenType.EOF) {
                throw new FormulaException("Invalid expression: Unexpected end of expression");
            }
            throw new FormulaException("Invalid expression: Unexpected token '" + currentToken.text + "' at position " + currentToken.position);
        }

        private boolean match(TokenType... types) {
            for (TokenType type : types) {
                if (check(type)) {
                    advance();
                    return true;
                }
            }
            return false;
        }

        private boolean check(TokenType type) {
            if (isAtEnd()) return type == TokenType.EOF;
            return peek().type == type;
        }

        private Token advance() {
            if (!isAtEnd()) current++;
            return previous();
        }

        private boolean isAtEnd() {
            return peek().type == TokenType.EOF;
        }

        private Token peek() {
            return tokens.get(current);
        }

        private Token previous() {
            return tokens.get(current - 1);
        }
    }

    // =========================================================================
    // PUBLIC EVALUATION API
    // =========================================================================

    /**
     * Evaluates a mathematical expression against a map of string values (e.g. inputs).
     */
    public static EvaluationResult evaluate(String expression, Map<String, String> inputs) {
        if (expression == null || expression.trim().isEmpty()) {
            return new EvaluationResult("Invalid expression: Empty formula expression");
        }

        try {
            List<Token> tokens = tokenize(expression.trim());

            // Build map of required variables
            Map<String, Double> resolved = new LinkedHashMap<>();
            int totalVariables = 0;
            int untouchedVariables = 0;

            for (Token t : tokens) {
                if (t.type == TokenType.VARIABLE) {
                    totalVariables++;
                    String vName = t.text;
                    String upperVName = vName.toUpperCase();

                    // Lookup in inputs with multiple case fallback
                    String rawStr = null;
                    if (inputs != null) {
                        if (inputs.containsKey(vName)) rawStr = inputs.get(vName);
                        else if (inputs.containsKey(upperVName)) rawStr = inputs.get(upperVName);
                        else if (inputs.containsKey(vName.toLowerCase())) rawStr = inputs.get(vName.toLowerCase());
                    }

                    if (rawStr == null || rawStr.trim().isEmpty()) {
                        // DECISION 2 & ISSUE 1: N1, N2... internally default to 0.0
                        if (isNumericInputKey(upperVName)) {
                            resolved.put(upperVName, 0.0);
                            untouchedVariables++;
                        } else {
                            return new EvaluationResult("Unknown variable: " + vName);
                        }
                    } else {
                        // Clean currency/commas
                        String cleaned = rawStr.replaceAll("[₹,\\s]", "").trim();
                        try {
                            double parsed = Double.parseDouble(cleaned);
                            resolved.put(upperVName, parsed);
                        } catch (NumberFormatException e) {
                            return new EvaluationResult("Unknown variable: " + vName + " contains non-numeric value '" + rawStr + "'");
                        }
                    }
                }
            }

            boolean allUntouched = totalVariables > 0 && untouchedVariables == totalVariables;

            Parser parser = new Parser(tokens, resolved);
            double val = parser.parse();

            if (Double.isNaN(val) || Double.isInfinite(val)) {
                return new EvaluationResult("Division by zero");
            }

            String formatted = formatResult(val);
            return new EvaluationResult(val, formatted, allUntouched);

        } catch (FormulaException fe) {
            return new EvaluationResult(fe.getMessage());
        } catch (Exception e) {
            return new EvaluationResult("Invalid expression: " + e.getMessage());
        }
    }

    /**
     * DECISION 1: ROUNDING GOVERNANCE
     * Applies Approach A - True Rounding (HALF_UP):
     * - Lakhs (>= 1,00,000 to < 1,00,00,000): Round to nearest ₹ 1,000
     * - Crores (>= 1,00,00,000): Round to nearest ₹ 10,000
     * - Apply ONLY to: REALIZABLE_VALUE, DISTRESS_SALE_VALUE, DISTRESS_VALUE, INSURABLE_VALUE
     * - DO NOT APPLY TO: GOVERNMENT_VALUE, FAIR_VALUE
     */
    public static double applyRoundingGovernance(String fieldKey, double value) {
        if (fieldKey == null || value <= 0) return value;
        String upper = fieldKey.toUpperCase().replaceAll("[<>]", "").trim();

        // Strict target check
        boolean isTargetField = upper.equals("REALIZABLE_VALUE")
                || upper.equals("DISTRESS_SALE_VALUE")
                || upper.equals("DISTRESS_VALUE")
                || upper.equals("INSURABLE_VALUE");

        if (!isTargetField) {
            return value; // Government Value & Fair Value are NEVER rounded here
        }

        if (value >= 10_000_000.0) { // Crores: nearest 10,000
            return Math.round(value / 10000.0) * 10000.0;
        } else if (value >= 100_000.0) { // Lakhs: nearest 1,000
            return Math.round(value / 1000.0) * 1000.0;
        }
        return value;
    }

    /**
     * Formats evaluated numeric value cleanly:
     * e.g. 9522200.0 -> "9522200", 150.0 -> "150", 12.345 -> "12.345"
     */
    public static String formatResult(double val) {
        if (Double.isNaN(val) || Double.isInfinite(val)) {
            return "";
        }
        // Snap near-integers
        if (Math.abs(val - Math.round(val)) < 1e-9) {
            return String.valueOf(Math.round(val));
        }

        BigDecimal bd = BigDecimal.valueOf(val).setScale(6, RoundingMode.HALF_UP).stripTrailingZeros();
        return bd.toPlainString();
    }

    // =========================================================================
    // CIRCULAR DEPENDENCY DETECTION
    // =========================================================================

    /**
     * Detects if circular dependencies exist among formula definitions.
     * @param formulas Map of formula key (e.g. CALC:A) to its formula expression
     * @return error message if circular dependency found, null if clean
     */
    public static String detectCircularDependencies(Map<String, String> formulas) {
        if (formulas == null || formulas.isEmpty()) return null;

        Map<String, Set<String>> graph = new HashMap<>();
        for (Map.Entry<String, String> entry : formulas.entrySet()) {
            String node = entry.getKey().toUpperCase().replaceAll("[<>]", "").trim();
            if (node.startsWith("CALC:")) node = node.substring(5);

            Set<String> deps = extractVariables(entry.getValue());
            graph.put(node, deps);
        }

        Set<String> visited = new HashSet<>();
        Set<String> recStack = new HashSet<>();

        for (String node : graph.keySet()) {
            if (checkCycle(node, graph, visited, recStack)) {
                return "Circular dependency detected involving formula '" + node + "'";
            }
        }
        return null;
    }

    private static boolean checkCycle(String node, Map<String, Set<String>> graph, Set<String> visited, Set<String> recStack) {
        if (recStack.contains(node)) return true;
        if (visited.contains(node)) return false;

        visited.add(node);
        recStack.add(node);

        Set<String> neighbors = graph.get(node);
        if (neighbors != null) {
            for (String neighbor : neighbors) {
                if (checkCycle(neighbor, graph, visited, recStack)) {
                    return true;
                }
            }
        }

        recStack.remove(node);
        return false;
    }
}
