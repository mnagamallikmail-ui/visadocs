package com.provaluer.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * High-performance, dependency-free mathematical formula evaluator and validator
 * for Document Studio calculation tables.
 */
@Service
public class FormulaExpressionEngine {

    private static final Logger log = LoggerFactory.getLogger(FormulaExpressionEngine.class);

    private static final Pattern COLUMN_REF_PATTERN = Pattern.compile("\\{col_(\\d+)\\}");
    private static final Pattern VALID_CHARS_PATTERN = Pattern.compile("^[0-9+\\-*/().\\s\\{col_\\}]+$");

    /**
     * Evaluates a row-level mathematical formula against a list of row cell values.
     *
     * @param formula        Formula expression containing column references (e.g. "{col_0} * {col_1}").
     * @param rowValues      List of raw cell values for the current row.
     * @param targetColIndex The column index where the computed result will be stored.
     * @return Computed numerical result (double).
     */
    public double evaluateRowFormula(String formula, List<?> rowValues, int targetColIndex) {
        if (formula == null || formula.trim().isEmpty()) {
            return 0.0;
        }

        // 1. Substitute column references with numerical values
        Matcher matcher = COLUMN_REF_PATTERN.matcher(formula);
        StringBuilder substituted = new StringBuilder();

        while (matcher.find()) {
            int colIdx = Integer.parseInt(matcher.group(1));
            double colVal = 0.0;

            if (rowValues != null && colIdx >= 0 && colIdx < rowValues.size()) {
                colVal = parseDoubleSafely(rowValues.get(colIdx));
            }

            matcher.appendReplacement(substituted, String.valueOf(colVal));
        }
        matcher.appendTail(substituted);

        // 2. Evaluate the arithmetic expression
        try {
            return evaluateArithmeticExpression(substituted.toString());
        } catch (Exception e) {
            log.warn("Formula evaluation error for expression '{}' at target col {}: {}", formula, targetColIndex, e.getMessage());
            return 0.0;
        }
    }

    /**
     * Evaluates a column aggregation function over a collection of data rows.
     *
     * @param aggregationType Aggregation function ("SUM", "AVG", "MIN", "MAX").
     * @param dataRows        List of data rows (each row containing a list of cell values).
     * @param columnIndex     The column index to aggregate.
     * @return The aggregated numerical result.
     */
    public double evaluateAggregation(String aggregationType, List<? extends List<?>> dataRows, int columnIndex) {
        if (aggregationType == null || "NONE".equalsIgnoreCase(aggregationType.trim()) || dataRows == null || dataRows.isEmpty()) {
            return 0.0;
        }

        List<Double> values = new ArrayList<>();
        for (List<?> row : dataRows) {
            if (row != null && columnIndex >= 0 && columnIndex < row.size()) {
                values.add(parseDoubleSafely(row.get(columnIndex)));
            }
        }

        if (values.isEmpty()) {
            return 0.0;
        }

        String agg = aggregationType.toUpperCase().trim();
        switch (agg) {
            case "SUM":
                return values.stream().mapToDouble(Double::doubleValue).sum();

            case "AVG":
            case "AVERAGE":
                return values.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);

            case "MIN":
                return values.stream().mapToDouble(Double::doubleValue).min().orElse(0.0);

            case "MAX":
                return values.stream().mapToDouble(Double::doubleValue).max().orElse(0.0);

            default:
                log.warn("Unknown aggregation type: {}", aggregationType);
                return 0.0;
        }
    }

    /**
     * Validates a formula expression against table bounds, syntax, and self-referencing constraints.
     *
     * @param formula        The formula string.
     * @param targetColIndex The target column receiving the result.
     * @param totalColumns   The total number of columns in the table.
     * @throws IllegalArgumentException if the formula is invalid.
     */
    public void validateFormula(String formula, int targetColIndex, int totalColumns) {
        if (formula == null || formula.trim().isEmpty()) {
            throw new IllegalArgumentException("Formula must not be empty");
        }

        if (targetColIndex < 0 || targetColIndex >= totalColumns) {
            throw new IllegalArgumentException("Target column index " + targetColIndex + " is out of bounds (0-" + (totalColumns - 1) + ")");
        }

        // 1. Character safety check
        if (!VALID_CHARS_PATTERN.matcher(formula).matches()) {
            throw new IllegalArgumentException("Formula contains invalid characters. Allowed: numbers, operators (+ - * /), parentheses, and {col_X} tokens");
        }

        // 2. Column references inspection
        Matcher matcher = COLUMN_REF_PATTERN.matcher(formula);
        boolean hasTokens = false;

        while (matcher.find()) {
            hasTokens = true;
            int refIdx = Integer.parseInt(matcher.group(1));

            if (refIdx < 0 || refIdx >= totalColumns) {
                throw new IllegalArgumentException("Referenced column {col_" + refIdx + "} is out of bounds (0-" + (totalColumns - 1) + ")");
            }

            if (refIdx == targetColIndex) {
                throw new IllegalArgumentException("Self-referencing formula detected: Target column " + targetColIndex + " cannot reference itself");
            }
        }

        if (!hasTokens) {
            throw new IllegalArgumentException("Formula must contain at least one valid column reference (e.g. {col_0})");
        }

        // 3. Parentheses balance test
        int openParen = 0;
        for (char c : formula.toCharArray()) {
            if (c == '(') openParen++;
            if (c == ')') openParen--;
            if (openParen < 0) {
                throw new IllegalArgumentException("Unbalanced closing parenthesis in formula: " + formula);
            }
        }
        if (openParen != 0) {
            throw new IllegalArgumentException("Unclosed parenthesis in formula: " + formula);
        }
    }

    /**
     * Safely converts any object or string into a double, coercing null/blank/non-numeric values to 0.0.
     */
    public double parseDoubleSafely(Object val) {
        if (val == null) {
            return 0.0;
        }
        if (val instanceof Number) {
            return ((Number) val).doubleValue();
        }

        String str = val.toString().trim()
                .replaceAll("[,\\s₹$€£]", ""); // Strip currency symbols, commas, and whitespace

        if (str.isEmpty()) {
            return 0.0;
        }

        try {
            return Double.parseDouble(str);
        } catch (NumberFormatException e) {
            return 0.0;
        }
    }

    /**
     * In-memory arithmetic evaluator implementing the classic Shunting-Yard Algorithm
     * with zero-division protection.
     */
    private double evaluateArithmeticExpression(String expression) {
        char[] tokens = expression.toCharArray();

        Deque<Double> values = new ArrayDeque<>();
        Deque<Character> operators = new ArrayDeque<>();

        for (int i = 0; i < tokens.length; i++) {
            if (Character.isWhitespace(tokens[i])) {
                continue;
            }

            // Parse numbers (including floating point)
            if (Character.isDigit(tokens[i]) || tokens[i] == '.') {
                StringBuilder sbuf = new StringBuilder();
                while (i < tokens.length && (Character.isDigit(tokens[i]) || tokens[i] == '.')) {
                    sbuf.append(tokens[i++]);
                }
                i--;
                values.push(Double.parseDouble(sbuf.toString()));
            } else if (tokens[i] == '(') {
                operators.push(tokens[i]);
            } else if (tokens[i] == ')') {
                while (!operators.isEmpty() && operators.peek() != '(') {
                    values.push(applyOperator(operators.pop(), values.pop(), values.pop()));
                }
                if (!operators.isEmpty()) {
                    operators.pop();
                }
            } else if (tokens[i] == '+' || tokens[i] == '-' || tokens[i] == '*' || tokens[i] == '/') {
                while (!operators.isEmpty() && hasPrecedence(tokens[i], operators.peek())) {
                    values.push(applyOperator(operators.pop(), values.pop(), values.pop()));
                }
                operators.push(tokens[i]);
            }
        }

        while (!operators.isEmpty()) {
            values.push(applyOperator(operators.pop(), values.pop(), values.pop()));
        }

        return values.isEmpty() ? 0.0 : values.pop();
    }

    private boolean hasPrecedence(char op1, char op2) {
        if (op2 == '(' || op2 == ')') {
            return false;
        }
        return (op1 != '*' && op1 != '/') || (op2 != '+' && op2 != '-');
    }

    private double applyOperator(char op, double b, double a) {
        switch (op) {
            case '+':
                return a + b;
            case '-':
                return a - b;
            case '*':
                return a * b;
            case '/':
                if (Math.abs(b) < 1e-9) {
                    log.warn("Division by zero encountered in formula evaluation. Coercing to 0.0");
                    return 0.0;
                }
                return a / b;
            default:
                return 0.0;
        }
    }
}
