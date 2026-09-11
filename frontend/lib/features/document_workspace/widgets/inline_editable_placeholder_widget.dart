import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/indian_number_formatter.dart';

import '../models/workspace_view_model.dart';
import '../providers/document_workspace_provider.dart';
import '../services/placeholder_registry.dart';

/// Document-native inline editable placeholder widget with keyboard-first navigation.
///
/// Supports Read Mode (default lightweight text), Edit-On-Focus Mode (dynamic reflow),
/// and comprehensive keyboard traversal (Enter/Tab = commit+next, Shift+Tab = commit+prev, Esc = cancel).
class InlineEditablePlaceholderWidget extends StatefulWidget {
  final String? instanceId;
  final InputFieldVm fieldVm;
  final bool readOnly;
  final TextStyle? textStyle;

  const InlineEditablePlaceholderWidget({
    super.key,
    this.instanceId,
    required this.fieldVm,
    this.readOnly = false,
    this.textStyle,
  });

  @override
  State<InlineEditablePlaceholderWidget> createState() => _InlineEditablePlaceholderWidgetState();
}

class _InlineEditablePlaceholderWidgetState extends State<InlineEditablePlaceholderWidget> {
  bool _isEditing = false;
  bool _isHovered = false;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _originalValue = '';

  String get effectiveId => widget.instanceId ?? widget.fieldVm.key;

  static final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static String formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = _months[dt.month - 1];
    final year = dt.year.toString();
    return '$day-$month-$year'; // Strict dd-MMM-yyyy format
  }

  static DateTime? parseFlexibleDate(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;

    final parts = trimmed.split('-');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final mStr = parts[1].toLowerCase();
      final y = int.tryParse(parts[2]);
      if (d != null && y != null) {
        for (int i = 0; i < _months.length; i++) {
          if (_months[i].toLowerCase() == mStr) {
            return DateTime(y, i + 1, d);
          }
        }
      }
    }
    return null;
  }

  String _normalizeValue(String val) {
    if (widget.fieldVm.isDate && val.isNotEmpty) {
      final parsed = parseFlexibleDate(val);
      if (parsed != null) {
        return formatDate(parsed);
      }
    }
    if (widget.fieldVm.isNumber && val.isNotEmpty) {
      final clean = val.replaceAll(',', '').replaceAll('₹', '').trim();
      final numVal = num.tryParse(clean);
      if (numVal != null) {
        final hasDecimal = clean.contains('.');
        final formatted = IndianNumberFormatter.format(numVal, includeDecimals: hasDecimal);
        return widget.fieldVm.isCurrency ? '₹ $formatted' : formatted;
      }
    }
    return val;
  }

  @override
  void initState() {
    super.initState();
    final provider = context.read<DocumentWorkspaceProvider>();
    final initial = _normalizeValue(provider.getValue(widget.fieldVm.key));
    _originalValue = initial;
    _controller = TextEditingController(text: initial);
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _commitAndExitEditMode();
      }
    });

    // Register with centralized PlaceholderRegistry for keyboard-first traversal
    provider.placeholderRegistry.register(
      PlaceholderRegistration(
        id: effectiveId,
        key: widget.fieldVm.key,
        onActivate: _enterEditMode,
        onDeactivate: _commitAndExitEditMode,
        getContext: () => context,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant InlineEditablePlaceholderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing) {
      final provider = context.read<DocumentWorkspaceProvider>();
      final serverVal = _normalizeValue(provider.getValue(widget.fieldVm.key));
      if (_controller.text != serverVal) {
        _controller.text = serverVal;
        _originalValue = serverVal;
      }
    }
  }

  @override
  void dispose() {
    try {
      final provider = context.read<DocumentWorkspaceProvider>();
      provider.placeholderRegistry.unregister(effectiveId);
    } catch (_) {}
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _enterEditMode() {
    if (widget.readOnly) return;
    final provider = context.read<DocumentWorkspaceProvider>();
    provider.placeholderRegistry.setActive(effectiveId);

    _originalValue = _controller.text;
    setState(() {
      _isEditing = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    });
  }

  void _commitAndExitEditMode({bool navigateNext = false, bool navigatePrevious = false}) {
    if (!_isEditing) return;
    final provider = context.read<DocumentWorkspaceProvider>();
    final normalized = _normalizeValue(_controller.text);
    _controller.text = normalized;
    _originalValue = normalized;
    provider.updateValue(widget.fieldVm.key, normalized);

    if (mounted) {
      setState(() {
        _isEditing = false;
        _isHovered = false;
      });
    }

    if (navigateNext) {
      provider.placeholderRegistry.next(effectiveId);
    } else if (navigatePrevious) {
      provider.placeholderRegistry.previous(effectiveId);
    } else {
      if (provider.placeholderRegistry.activeId == effectiveId) {
        provider.placeholderRegistry.setActive(null);
      }
    }
  }

  void _cancelEditMode() {
    if (!_isEditing) return;
    final provider = context.read<DocumentWorkspaceProvider>();
    _controller.text = _originalValue;
    provider.updateValue(widget.fieldVm.key, _originalValue);
    if (mounted) {
      setState(() {
        _isEditing = false;
        _isHovered = false;
      });
    }
    if (provider.placeholderRegistry.activeId == effectiveId) {
      provider.placeholderRegistry.setActive(null);
    }
  }

  Future<void> _pickDate(BuildContext context, DocumentWorkspaceProvider provider) async {
    if (widget.readOnly) return;
    DateTime initial = DateTime.now();
    final currentText = _controller.text.trim();
    if (currentText.isNotEmpty) {
      final parsed = parseFlexibleDate(currentText);
      if (parsed != null) initial = parsed;
    }

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.workspaceCorporateNavy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.fieldVm.questionText.isNotEmpty ? widget.fieldVm.questionText : 'Select Date',
                        style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.workspacePrimaryText),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.workspaceSecondaryText),
                      onPressed: () => Navigator.of(ctx).pop(null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 20, color: AppColors.workspaceBorder),
                Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.workspaceCorporateNavy,
                      onPrimary: Colors.white,
                      onSurface: AppColors.workspacePrimaryText,
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: initial,
                    firstDate: DateTime(1970),
                    lastDate: DateTime(2050),
                    onDateChanged: (selectedDate) {
                      Navigator.of(ctx).pop(selectedDate);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) {
      final formatted = formatDate(picked);
      _controller.text = formatted;
      _originalValue = formatted;
      provider.updateValue(widget.fieldVm.key, formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentWorkspaceProvider>();
    final val = _normalizeValue(provider.getValue(widget.fieldVm.key));
    final isEmpty = val.trim().isEmpty;

    final baseStyle = widget.textStyle ??
        GoogleFonts.montserrat(
          fontSize: 13,
          color: AppColors.workspacePrimaryText,
          height: 1.5,
        );

    return Focus(
      canRequestFocus: false,
      onKeyEvent: (node, event) {
        if (!_isEditing) return KeyEventResult.ignored;

        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.tab) {
            final isShift = HardwareKeyboard.instance.isShiftPressed;
            if (isShift) {
              _commitAndExitEditMode(navigatePrevious: true);
            } else {
              _commitAndExitEditMode(navigateNext: true);
            }
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter && !widget.fieldVm.isMultiline) {
            _commitAndExitEditMode(navigateNext: true);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _cancelEditMode();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: _isEditing ? _buildEditMode(context, provider, baseStyle) : _buildReadMode(context, provider, val, isEmpty, baseStyle),
    );
  }

  /// ─── READ MODE: Lightweight Styled Text Widget ─────────────────────────────
  Widget _buildReadMode(BuildContext context, DocumentWorkspaceProvider provider, String val, bool isEmpty, TextStyle baseStyle) {
    final isRepeated = widget.fieldVm.isRepeated;
    final isDate = widget.fieldVm.isDate;

    final displayPrompt = isEmpty
        ? (widget.fieldVm.questionText.isNotEmpty ? widget.fieldVm.questionText : widget.fieldVm.key)
        : val;

    final promptStyle = isEmpty
        ? baseStyle.copyWith(
            color: AppColors.workspaceSecondaryText.withValues(alpha: 0.8),
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          )
        : baseStyle.copyWith(
            color: AppColors.workspaceCorporateNavy,
            fontWeight: FontWeight.w700,
          );

    return MouseRegion(
      cursor: widget.readOnly ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          if (widget.readOnly) return;
          if (isDate) {
            _pickDate(context, provider);
          } else {
            _enterEditMode();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.5),
          decoration: BoxDecoration(
            color: _isHovered && !widget.readOnly
                ? AppColors.workspaceCorporateNavy.withValues(alpha: 0.08)
                : (isEmpty ? AppColors.workspaceCanvas : AppColors.workspaceCorporateNavy.withValues(alpha: 0.035)),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _isHovered && !widget.readOnly
                  ? AppColors.primaryBlue
                  : (isEmpty
                      ? AppColors.workspaceBorder
                      : AppColors.workspaceCorporateNavy.withValues(alpha: 0.25)),
              width: 1.0,
            ),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                isEmpty ? '[ $displayPrompt ]' : displayPrompt,
                style: promptStyle,
              ),
              if (isDate && !widget.readOnly) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 11,
                  color: isEmpty ? AppColors.workspaceSecondaryText : AppColors.workspaceCorporateNavy,
                ),
              ],
              if (isRepeated) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Synchronized across ${widget.fieldVm.occurrences} locations in document',
                  child: const Icon(
                    Icons.sync_rounded,
                    size: 11,
                    color: AppColors.workspaceSecondaryText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// ─── EDIT MODE: Auto-Sizing Active Text Field with Visual Active Indicator ──
  Widget _buildEditMode(BuildContext context, DocumentWorkspaceProvider provider, TextStyle baseStyle) {
    // Measure dynamic width so the input expands naturally as user types
    final textToMeasure = _controller.text.isEmpty ? widget.fieldVm.questionText : _controller.text;
    final painter = TextPainter(
      text: TextSpan(text: textToMeasure, style: baseStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final dynamicWidth = (painter.width + 32).clamp(80.0, 520.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1.0),
      width: dynamicWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332563EB), // Subtle blue focus glow
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        style: baseStyle.copyWith(
          color: AppColors.workspacePrimaryText,
          fontWeight: FontWeight.w600,
        ),
        keyboardType: widget.fieldVm.isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        onChanged: (newText) {
          provider.updateValue(widget.fieldVm.key, newText);
          setState(() {}); // Re-measure dynamic width for instant reflow
        },
        onFieldSubmitted: (_) => _commitAndExitEditMode(navigateNext: true),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.workspaceCorporateNavy, width: 1.5),
          ),
        ),
      ),
    );
  }
}
