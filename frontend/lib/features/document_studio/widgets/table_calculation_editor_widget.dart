import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../models/calculation_table_model.dart';

/// Interactive inspector editor for configuring calculation rules and summary aggregations on Word tables.
class TableCalculationEditorWidget extends StatefulWidget {
  final CalculationTableConfig config;
  final int totalColumns;
  final ValueChanged<CalculationTableConfig> onChanged;

  const TableCalculationEditorWidget({
    super.key,
    required this.config,
    required this.totalColumns,
    required this.onChanged,
  });

  @override
  State<TableCalculationEditorWidget> createState() => _TableCalculationEditorWidgetState();
}

class _TableCalculationEditorWidgetState extends State<TableCalculationEditorWidget> {
  late CalculationTableConfig _currentConfig;
  late final TextEditingController _summaryLabelCtrl;

  @override
  void initState() {
    super.initState();
    _currentConfig = widget.config;
    _summaryLabelCtrl = TextEditingController(text: _currentConfig.summaryRowLabel ?? 'Total');
  }

  @override
  void didUpdateWidget(covariant TableCalculationEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _currentConfig = widget.config;
      if (_summaryLabelCtrl.text != (_currentConfig.summaryRowLabel ?? 'Total')) {
        _summaryLabelCtrl.text = _currentConfig.summaryRowLabel ?? 'Total';
      }
    }
  }

  @override
  void dispose() {
    _summaryLabelCtrl.dispose();
    super.dispose();
  }

  void _notify(CalculationTableConfig updated) {
    setState(() => _currentConfig = updated);
    widget.onChanged(updated);
  }

  void _addRule() {
    final availableCols = List.generate(widget.totalColumns, (i) => i);
    final usedCols = _currentConfig.columnRules.map((r) => r.targetColumnIndex).toSet();
    final nextTarget = availableCols.firstWhere(
      (c) => !usedCols.contains(c),
      orElse: () => widget.totalColumns > 0 ? widget.totalColumns - 1 : 0,
    );

    final newRule = TableColumnRule(
      targetColumnIndex: nextTarget,
      formula: '',
      aggregationType: RowAggregationType.none,
      numberFormat: TableNumberFormat.decimal,
      decimalPlaces: 2,
    );

    final updated = _currentConfig.copyWith(
      columnRules: [..._currentConfig.columnRules, newRule],
    );
    _notify(updated);
  }

  void _updateRule(int index, TableColumnRule rule) {
    final rules = List<TableColumnRule>.from(_currentConfig.columnRules);
    if (index >= 0 && index < rules.length) {
      rules[index] = rule;
      _notify(_currentConfig.copyWith(columnRules: rules));
    }
  }

  void _deleteRule(int index) {
    final rules = List<TableColumnRule>.from(_currentConfig.columnRules);
    if (index >= 0 && index < rules.length) {
      rules.removeAt(index);
      _notify(_currentConfig.copyWith(columnRules: rules));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeRules = _currentConfig.columnRules;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Table Header & Badge ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.hairlineSoft),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.tealLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.table_chart_rounded, size: 20, color: AppColors.deepTeal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentConfig.tableId.isNotEmpty ? _currentConfig.tableId : 'Table Calculations',
                        style: AppTypography.bodyMdMedium(color: AppColors.ink).copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.totalColumns} Total Columns Detected',
                        style: AppTypography.caption(color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: activeRules.isNotEmpty ? AppColors.tealLight : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: activeRules.isNotEmpty ? AppColors.deepTeal.withValues(alpha: 0.3) : AppColors.hairline,
                    ),
                  ),
                  child: Text(
                    '${activeRules.length} Rules',
                    style: AppTypography.caption(
                      color: activeRules.isNotEmpty ? AppColors.deepTeal : AppColors.slate,
                    ).copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── Summary / Aggregation Row Settings ───────────────────────
          Text('SUMMARY ROW SETTINGS', style: AppTypography.caption(color: AppColors.slate).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.1)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enable Summary / Total Row', style: AppTypography.bodyMdMedium(color: AppColors.ink)),
                          const SizedBox(height: 2),
                          Text('Appends aggregate sums or averages to the table footer', style: AppTypography.caption(color: AppColors.slate)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _currentConfig.hasSummaryRow,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.deepTeal,
                      onChanged: (val) {
                        _notify(_currentConfig.copyWith(hasSummaryRow: val));
                      },
                    ),
                  ],
                ),
                if (_currentConfig.hasSummaryRow) ...[
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.hairlineSoft, height: 1),
                  const SizedBox(height: 14),
                  Text('Summary Row Label', style: AppTypography.caption(color: AppColors.slate).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _summaryLabelCtrl,
                    style: AppTypography.bodySm().copyWith(color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: 'e.g. Total / Summary',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.hairline)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.deepTeal, width: 1.5)),
                    ),
                    onChanged: (val) {
                      _notify(_currentConfig.copyWith(summaryRowLabel: val));
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('Label Column Position', style: AppTypography.caption(color: AppColors.slate).copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    key: ValueKey(_currentConfig.summaryLabelColumnIndex),
                    initialValue: _currentConfig.summaryLabelColumnIndex.clamp(0, widget.totalColumns > 0 ? widget.totalColumns - 1 : 0),
                    style: AppTypography.bodySm().copyWith(color: AppColors.ink),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.hairline)),
                    ),
                    items: List.generate(widget.totalColumns, (i) {
                      return DropdownMenuItem<int>(
                        value: i,
                        child: Text('Column $i (col_$i)'),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        _notify(_currentConfig.copyWith(summaryLabelColumnIndex: val));
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Column Calculation Rules ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('COLUMN FORMULAS', style: AppTypography.caption(color: AppColors.slate).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.1)),
              TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Rule'),
                onPressed: _addRule,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.deepTeal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (activeRules.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.functions_rounded, size: 32, color: AppColors.slate),
                    const SizedBox(height: 8),
                    Text('No Column Rules Defined', style: AppTypography.bodyMdMedium(color: AppColors.ink)),
                    const SizedBox(height: 4),
                    Text('Click "+ Add Rule" to compute values automatically.', style: AppTypography.caption(color: AppColors.stone)),
                  ],
                ),
              ),
            )
          else
            for (int i = 0; i < activeRules.length; i++) ...[
              _buildRuleCard(i, activeRules[i]),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _buildRuleCard(int index, TableColumnRule rule) {
    final formulaCtrl = TextEditingController(text: rule.formula);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rule Card Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Rule #${index + 1}',
                  style: AppTypography.caption(color: AppColors.deepTeal).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.brandRedDark),
                tooltip: 'Remove Rule',
                onPressed: () => _deleteRule(index),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Target Column Selector
          Text('Target Column (Receives Computed Output)', style: AppTypography.caption(color: AppColors.slate).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            key: ValueKey('target_col_${index}_${rule.targetColumnIndex}'),
            initialValue: rule.targetColumnIndex.clamp(0, widget.totalColumns > 0 ? widget.totalColumns - 1 : 0),
            style: AppTypography.bodySm().copyWith(color: AppColors.ink),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.hairline)),
            ),
            items: List.generate(widget.totalColumns, (i) {
              return DropdownMenuItem<int>(
                value: i,
                child: Text('Column $i (col_$i)'),
              );
            }),
            onChanged: (val) {
              if (val != null) {
                _updateRule(index, rule.copyWith(targetColumnIndex: val));
              }
            },
          ),
          const SizedBox(height: 12),

          // Formula Expression Field
          Text('Formula Expression', style: AppTypography.caption(color: AppColors.slate).copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: formulaCtrl,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'e.g. {col_0} * {col_1}',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.hairline)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.deepTeal, width: 1.5)),
            ),
            onChanged: (val) {
              _updateRule(index, rule.copyWith(formula: val));
            },
          ),
          const SizedBox(height: 6),

          // Quick Operand Insertion Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int c = 0; c < widget.totalColumns; c++) ...[
                  ActionChip(
                    label: Text('{col_$c}'),
                    labelStyle: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.deepTeal),
                    backgroundColor: AppColors.tealLight,
                    side: BorderSide.none,
                    onPressed: () {
                      final newFormula = '${rule.formula} {col_$c}'.trim();
                      formulaCtrl.text = newFormula;
                      _updateRule(index, rule.copyWith(formula: newFormula));
                    },
                  ),
                  const SizedBox(width: 4),
                ],
                for (final op in ['+', '-', '*', '/']) ...[
                  ActionChip(
                    label: Text(op),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.ink),
                    backgroundColor: AppColors.surfaceSoft,
                    side: const BorderSide(color: AppColors.hairline),
                    onPressed: () {
                      final newFormula = '${rule.formula} $op '.trim();
                      formulaCtrl.text = newFormula;
                      _updateRule(index, rule.copyWith(formula: newFormula));
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Aggregation Type & Number Format
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Summary Aggregation', style: AppTypography.caption(color: AppColors.slate).copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: ValueKey('agg_${index}_${rule.aggregationType}'),
                      initialValue: rule.aggregationType,
                      style: AppTypography.bodySm().copyWith(color: AppColors.ink),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.hairline)),
                      ),
                      items: RowAggregationType.all.map((agg) {
                        return DropdownMenuItem<String>(
                          value: agg,
                          child: Text(agg),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _updateRule(index, rule.copyWith(aggregationType: val));
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Number Format', style: AppTypography.caption(color: AppColors.slate).copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: ValueKey('fmt_${index}_${rule.numberFormat}'),
                      initialValue: rule.numberFormat,
                      style: AppTypography.bodySm().copyWith(color: AppColors.ink),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.hairline)),
                      ),
                      items: TableNumberFormat.all.map((fmt) {
                        return DropdownMenuItem<String>(
                          value: fmt,
                          child: Text(fmt),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _updateRule(index, rule.copyWith(numberFormat: val));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Decimal Places Stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Decimal Precision', style: AppTypography.bodySmMedium(color: AppColors.ink)),
                  Text('${rule.decimalPlaces} decimal places', style: AppTypography.caption(color: AppColors.slate)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: AppColors.slate),
                    onPressed: rule.decimalPlaces > 0
                        ? () => _updateRule(index, rule.copyWith(decimalPlaces: rule.decimalPlaces - 1))
                        : null,
                  ),
                  Text('${rule.decimalPlaces}', style: AppTypography.bodyMdMedium(color: AppColors.ink).copyWith(fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.deepTeal),
                    onPressed: rule.decimalPlaces < 6
                        ? () => _updateRule(index, rule.copyWith(decimalPlaces: rule.decimalPlaces + 1))
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
