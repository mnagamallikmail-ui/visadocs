import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/indian_number_formatter.dart';
import '../../../utils/date_picker_helper.dart';

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

  static String formatDate(DateTime dt) => DatePickerHelper.formatDate(dt);

  static DateTime? parseFlexibleDate(String input) => DatePickerHelper.parseFlexibleDate(input);

  String _normalizeValue(String val) {
    if (widget.fieldVm.isDate && val.isNotEmpty) {
      final parsed = DatePickerHelper.parseFlexibleDate(val);
      if (parsed != null) {
        return DatePickerHelper.formatDate(parsed);
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

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DocumentWorkspaceProvider>();
    final pVal = provider.getValue(widget.fieldVm.key);
    final raw = pVal.isNotEmpty ? pVal : widget.fieldVm.currentValue;
    final initial = _normalizeValue(raw);
    _originalValue = initial;
    _controller = TextEditingController(text: initial);
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing && !_isNavigating) {
        _commitAndExitEditMode();
      }
    });

    _focusNode.onKeyEvent = (node, event) {
      if (!_isEditing) return KeyEventResult.ignored;

      if (event is KeyDownEvent) {
        final isShift = HardwareKeyboard.instance.isShiftPressed;
        final isAlt = HardwareKeyboard.instance.isAltPressed;

        // TAB / SHIFT+TAB: Document-order placeholder navigation
        if (event.logicalKey == LogicalKeyboardKey.tab) {
          _commitAndExitEditMode(navigateNext: !isShift, navigatePrevious: isShift);
          return KeyEventResult.handled;
        }

        // ALT + ENTER: Always creates new line in text placeholders
        if (event.logicalKey == LogicalKeyboardKey.enter && isAlt) {
          _insertNewline(provider);
          return KeyEventResult.handled;
        }

        // ENTER: Creates new line in multiline text, submits in pure number fields
        if (event.logicalKey == LogicalKeyboardKey.enter && !isAlt) {
          if (widget.fieldVm.isNumber) {
            _commitAndExitEditMode(navigateNext: true);
            return KeyEventResult.handled;
          } else {
            _insertNewline(provider);
            return KeyEventResult.handled;
          }
        }

        // UP ARROW: Moves cursor to previous line; if already on FIRST line -> moves to PREVIOUS placeholder
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          final pos = _controller.selection.baseOffset >= 0 ? _controller.selection.baseOffset : _controller.text.length;
          final firstNl = _controller.text.indexOf('\n');
          if (firstNl == -1 || pos <= firstNl) {
            _commitAndExitEditMode(navigatePrevious: true);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored; // Normal multiline movement within textbox
        }

        // DOWN ARROW: Moves cursor to next line; if already on LAST line -> moves to NEXT placeholder
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          final pos = _controller.selection.baseOffset >= 0 ? _controller.selection.baseOffset : _controller.text.length;
          final lastNl = _controller.text.lastIndexOf('\n');
          if (lastNl == -1 || pos > lastNl) {
            _commitAndExitEditMode(navigateNext: true);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored; // Normal multiline movement within textbox
        }

        if (event.logicalKey == LogicalKeyboardKey.escape) {
          _cancelEditMode();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    // Register with centralized PlaceholderRegistry for keyboard-first traversal
    provider.placeholderRegistry.register(
      PlaceholderRegistration(
        id: effectiveId,
        key: widget.fieldVm.key,
        onActivate: () {
          if (widget.fieldVm.isDate) {
            _pickDate(context, provider);
          } else {
            _enterEditMode();
          }
        },
        onDeactivate: _commitAndExitEditMode,
        getContext: () => context,
      ),
    );
  }

  void _insertNewline(DocumentWorkspaceProvider provider) {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, '\n');
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + 1),
    );
    provider.updateValue(widget.fieldVm.key, newText);
    setState(() {});
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

  DocumentWorkspaceProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<DocumentWorkspaceProvider>();
  }

  @override
  void dispose() {
    try {
      _provider?.placeholderRegistry.unregister(effectiveId);
    } catch (_) {}
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _enterEditMode() {
    if (widget.readOnly) return;
    final provider = context.read<DocumentWorkspaceProvider>();
    if (widget.fieldVm.isDate) {
      _pickDate(context, provider);
      return;
    }
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

    _isNavigating = true;
    try {
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
    } finally {
      _isNavigating = false;
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
    final title = widget.fieldVm.questionText.isNotEmpty
        ? widget.fieldVm.questionText
        : DocumentWorkspaceVm.toHumanizedLabel(widget.fieldVm.key);
    final picked = await DatePickerHelper.showAppDatePicker(
      context: context,
      title: title,
      currentValue: _controller.text,
    );

    if (picked != null) {
      _controller.text = picked;
      _originalValue = picked;
      provider.updateValue(widget.fieldVm.key, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentWorkspaceProvider>();
    final pVal = provider.getValue(widget.fieldVm.key);
    final raw = pVal.isNotEmpty ? pVal : widget.fieldVm.currentValue;
    final val = _normalizeValue(raw);
    final isEmpty = val.trim().isEmpty;

    final baseStyle = widget.textStyle ??
        GoogleFonts.montserrat(
          fontSize: 13,
          color: AppColors.workspacePrimaryText,
          height: 1.5,
        );

    return Focus(
      canRequestFocus: widget.fieldVm.isDate,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && widget.fieldVm.isDate) {
          if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space) {
            _pickDate(context, provider);
            return KeyEventResult.handled;
          }
        }
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
          if (event.logicalKey == LogicalKeyboardKey.enter && widget.fieldVm.isNumber) {
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

    // GOVERNANCE (DEFECT 13): Empty TEXT placeholders must render a blank, clickable
    // area with NO generated labels, no questionText, no key name, no hints.
    // Only DATE fields may show a format indicator as it is an operational cue.
    final promptStyle = isEmpty
        ? baseStyle.copyWith(
            color: AppColors.workspaceSecondaryText.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
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
              if (!isEmpty)
                Text(val, style: promptStyle),
              // DATE: show a minimal format cue only — never show key name or questionText.
              if (isEmpty && isDate)
                Text(
                  'dd-MMM-yyyy',
                  style: promptStyle,
                ),
              // All other empty TEXT fields: blank — SizedBox provides minimum tap target.
              if (isEmpty && !isDate)
                const SizedBox(width: 40, height: 16),
              if (isDate && !widget.readOnly) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _pickDate(context, provider),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 11,
                    color: isEmpty ? AppColors.workspaceSecondaryText : AppColors.workspaceCorporateNavy,
                  ),
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
    // Measure dynamic width from the actual typed content across all lines.
    final textToMeasure = _controller.text.isEmpty ? '' : _controller.text;
    final lines = textToMeasure.isEmpty ? [''] : textToMeasure.split('\n');
    double maxLineWidth = 0.0;
    for (final line in lines) {
      final p = TextPainter(
        text: TextSpan(text: line.isEmpty ? ' ' : line, style: baseStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      if (p.width > maxLineWidth) maxLineWidth = p.width;
    }
    final dynamicWidth = textToMeasure.isEmpty ? 140.0 : (maxLineWidth + 40).clamp(120.0, 720.0);

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
        keyboardType: widget.fieldVm.isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.multiline,
        minLines: 1,
        maxLines: null, // Auto-growing dynamic height with unlimited vertical expansion
        scrollPhysics: const NeverScrollableScrollPhysics(), // Full text always visible, no internal scrollbar
        onChanged: (newText) {
          provider.updateValue(widget.fieldVm.key, newText);
          setState(() {}); // Re-measure dynamic width and height for instant reflow
        },
        onFieldSubmitted: widget.fieldVm.isNumber ? (_) => _commitAndExitEditMode(navigateNext: true) : null,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
