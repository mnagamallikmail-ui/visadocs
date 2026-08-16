import 'package:flutter/foundation.dart';

/// Supported mathematical aggregation functions for summary/footer rows.
class RowAggregationType {
  RowAggregationType._();

  static const String none = 'NONE';
  static const String sum = 'SUM';
  static const String average = 'AVERAGE';
  static const String min = 'MIN';
  static const String max = 'MAX';

  static const List<String> all = [
    none,
    sum,
    average,
    min,
    max,
  ];
}

/// Supported display formats for computed numeric output.
class TableNumberFormat {
  TableNumberFormat._();

  static const String decimal = 'DECIMAL';
  static const String currencyInr = 'CURRENCY_INR';
  static const String percentage = 'PERCENTAGE';
  static const String integer = 'INTEGER';

  static const List<String> all = [
    decimal,
    currencyInr,
    percentage,
    integer,
  ];
}

/// Rule defining an arithmetic formula and aggregation for a specific table column.
class TableColumnRule {
  final int targetColumnIndex;
  final String formula;
  final String aggregationType;
  final String numberFormat;
  final int decimalPlaces;

  const TableColumnRule({
    required this.targetColumnIndex,
    this.formula = '',
    this.aggregationType = RowAggregationType.none,
    this.numberFormat = TableNumberFormat.decimal,
    this.decimalPlaces = 2,
  });

  factory TableColumnRule.fromJson(Map<String, dynamic> json) {
    return TableColumnRule(
      targetColumnIndex: json['targetColumnIndex'] as int? ?? 0,
      formula: json['formula'] as String? ?? '',
      aggregationType: json['aggregationType'] as String? ?? RowAggregationType.none,
      numberFormat: json['numberFormat'] as String? ?? TableNumberFormat.decimal,
      decimalPlaces: json['decimalPlaces'] as int? ?? 2,
    );
  }

  Map<String, dynamic> toJson() => {
        'targetColumnIndex': targetColumnIndex,
        'formula': formula.trim(),
        'aggregationType': aggregationType,
        'numberFormat': numberFormat,
        'decimalPlaces': decimalPlaces,
      };

  TableColumnRule copyWith({
    int? targetColumnIndex,
    String? formula,
    String? aggregationType,
    String? numberFormat,
    int? decimalPlaces,
  }) {
    return TableColumnRule(
      targetColumnIndex: targetColumnIndex ?? this.targetColumnIndex,
      formula: formula ?? this.formula,
      aggregationType: aggregationType ?? this.aggregationType,
      numberFormat: numberFormat ?? this.numberFormat,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
    );
  }

  /// Whether this column has an active arithmetic formula.
  bool get hasFormula => formula.trim().isNotEmpty;

  /// Whether this column has an active summary aggregation.
  bool get isAggregationEnabled =>
      aggregationType.toUpperCase() != RowAggregationType.none;

  /// Validates whether the target column index is within table bounds.
  bool isValidTargetColumn(int maxColumns) {
    return targetColumnIndex >= 0 && targetColumnIndex < maxColumns;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableColumnRule &&
          runtimeType == other.runtimeType &&
          targetColumnIndex == other.targetColumnIndex &&
          formula == other.formula &&
          aggregationType == other.aggregationType &&
          numberFormat == other.numberFormat &&
          decimalPlaces == other.decimalPlaces;

  @override
  int get hashCode =>
      targetColumnIndex.hashCode ^
      formula.hashCode ^
      aggregationType.hashCode ^
      numberFormat.hashCode ^
      decimalPlaces.hashCode;

  @override
  String toString() {
    return 'TableColumnRule(col: $targetColumnIndex, formula: "$formula", agg: $aggregationType, fmt: $numberFormat, dec: $decimalPlaces)';
  }
}

/// Root configuration model for calculation tables and formula evaluation.
class CalculationTableConfig {
  final String tableId;
  final int headerRowCount;
  final bool hasSummaryRow;
  final String? summaryRowLabel;
  final int summaryLabelColumnIndex;
  final List<TableColumnRule> columnRules;

  const CalculationTableConfig({
    required this.tableId,
    this.headerRowCount = 1,
    this.hasSummaryRow = false,
    this.summaryRowLabel = 'Total',
    this.summaryLabelColumnIndex = 0,
    this.columnRules = const [],
  });

  factory CalculationTableConfig.fromJson(Map<String, dynamic> json) {
    return CalculationTableConfig(
      tableId: json['tableId'] as String? ?? '',
      headerRowCount: json['headerRowCount'] as int? ?? 1,
      hasSummaryRow: json['hasSummaryRow'] as bool? ?? false,
      summaryRowLabel: json['summaryRowLabel'] as String? ?? 'Total',
      summaryLabelColumnIndex: json['summaryLabelColumnIndex'] as int? ?? 0,
      columnRules: (json['columnRules'] as List<dynamic>?)
              ?.map((r) => TableColumnRule.fromJson(r as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'tableId': tableId,
        'headerRowCount': headerRowCount,
        'hasSummaryRow': hasSummaryRow,
        if (summaryRowLabel != null) 'summaryRowLabel': summaryRowLabel!.trim(),
        'summaryLabelColumnIndex': summaryLabelColumnIndex,
        'columnRules': columnRules.map((r) => r.toJson()).toList(),
      };

  CalculationTableConfig copyWith({
    String? tableId,
    int? headerRowCount,
    bool? hasSummaryRow,
    String? summaryRowLabel,
    int? summaryLabelColumnIndex,
    List<TableColumnRule>? columnRules,
  }) {
    return CalculationTableConfig(
      tableId: tableId ?? this.tableId,
      headerRowCount: headerRowCount ?? this.headerRowCount,
      hasSummaryRow: hasSummaryRow ?? this.hasSummaryRow,
      summaryRowLabel: summaryRowLabel ?? this.summaryRowLabel,
      summaryLabelColumnIndex:
          summaryLabelColumnIndex ?? this.summaryLabelColumnIndex,
      columnRules: columnRules ?? this.columnRules,
    );
  }

  /// Retrieves the column rule for a specific column index if defined.
  TableColumnRule? getRuleForColumn(int columnIndex) {
    for (final rule in columnRules) {
      if (rule.targetColumnIndex == columnIndex) {
        return rule;
      }
    }
    return null;
  }

  /// Whether this table configuration contains any active calculation rules.
  bool get hasActiveRules =>
      columnRules.any((r) => r.hasFormula || r.isAggregationEnabled);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculationTableConfig &&
          runtimeType == other.runtimeType &&
          tableId == other.tableId &&
          headerRowCount == other.headerRowCount &&
          hasSummaryRow == other.hasSummaryRow &&
          summaryRowLabel == other.summaryRowLabel &&
          summaryLabelColumnIndex == other.summaryLabelColumnIndex &&
          listEquals(columnRules, other.columnRules);

  @override
  int get hashCode =>
      tableId.hashCode ^
      headerRowCount.hashCode ^
      hasSummaryRow.hashCode ^
      (summaryRowLabel?.hashCode ?? 0) ^
      summaryLabelColumnIndex.hashCode ^
      Object.hashAll(columnRules);

  @override
  String toString() {
    return 'CalculationTableConfig(tableId: $tableId, headerRows: $headerRowCount, summaryRow: $hasSummaryRow, rules: ${columnRules.length})';
  }
}
