import 'dart:convert';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/indian_number_formatter.dart';
import '../../../utils/date_picker_helper.dart';
import '../../document_studio/models/visual_preview_model.dart';
import '../models/document_workspace_model.dart';
import '../providers/document_workspace_provider.dart';

/// Two-State Inline Document Input Widget.
/// - State A: Compact Inline Box (Matches document bounds, ellipsis for long values).
/// - State B: Expanded Floating Editor (OverlayEntry, minWidth: 220, maxWidth: 480, multiline).
class InlineOverlayInputWidget extends StatefulWidget {
  final VisualPlaceholderModel placeholder;
  final NormalizedRectModel rect;
  final double containerWidth;
  final double containerHeight;
  final bool readOnly;

  const InlineOverlayInputWidget({
    super.key,
    required this.placeholder,
    required this.rect,
    required this.containerWidth,
    required this.containerHeight,
    this.readOnly = false,
  });

  @override
  State<InlineOverlayInputWidget> createState() => _InlineOverlayInputWidgetState();
}

class _InlineOverlayInputWidgetState extends State<InlineOverlayInputWidget> {
  bool _isFloatingOpen = false;
  OverlayEntry? _floatingOverlayEntry;
  final LayerLink _layerLink = LayerLink();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<DocumentWorkspaceProvider>();
    final curVal = provider.getValue(widget.placeholder.key);
    if (!_isFloatingOpen && curVal != _controller.text) {
      _controller.text = curVal;
    }
  }

  @override
  void didUpdateWidget(InlineOverlayInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final provider = context.read<DocumentWorkspaceProvider>();
    final curVal = provider.getValue(widget.placeholder.key);
    if (!_isFloatingOpen && curVal != _controller.text) {
      _controller.text = curVal;
    }
  }

  @override
  void dispose() {
    _removeFloatingOverlay(updateState: false);
    _controller.dispose();
    super.dispose();
  }

  String _inferFieldType(String key) {
    final clean = key.replaceAll('<<', '').replaceAll('>>', '').trim().toUpperCase();
    if (clean == 'COMPOSITE_PROPERTY_TABLE' ||
        clean == 'DYNAMIC_COMPOSITE_PROPERTY_TABLE' ||
        clean == 'COMPOSITE_TABLE') {
      return 'COMPOSITE_TABLE';
    }
    if (clean.startsWith('IMG_') || clean.endsWith('_IMAGE') || clean.contains('PHOTO') || clean.contains('SIGNATURE')) {
      return 'IMAGE';
    }
    if (DatePickerHelper.isDateKey(clean)) {
      return 'DATE';
    }
    if (clean.contains('AREA') || clean.contains('RATE') || clean.contains('VALUE') ||
        clean.contains('AMOUNT') || clean.contains('FEE') || clean.contains('TOTAL') ||
        clean.contains('PRICE') || clean.contains('PERCENT') || clean.contains('RATIO') || clean.startsWith('NUM_')) {
      return 'NUMBER';
    }
    return 'TEXT';
  }

  void _showFloatingOverlay() {
    if (widget.readOnly || _isFloatingOpen || _inferFieldType(widget.placeholder.key) == 'COMPOSITE_TABLE') return;

    final provider = context.read<DocumentWorkspaceProvider>();
    provider.setFocusedKey(widget.placeholder.key);
    final rawVal = provider.getValue(widget.placeholder.key);
    final isNumber = _inferFieldType(widget.placeholder.key) == 'NUMBER';
    if (isNumber && rawVal.trim().isNotEmpty) {
      final clean = rawVal.replaceAll(',', '').trim();
      final numVal = num.tryParse(clean);
      _controller.text = numVal != null ? IndianNumberFormatter.format(numVal, includeDecimals: clean.contains('.')) : rawVal;
    } else {
      _controller.text = rawVal;
    }

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final cardWidth = (size.width > 280 ? size.width : 320.0).clamp(280.0, 480.0);

    _floatingOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Fullscreen transparent barrier to detect outside taps
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _commitAndCloseFloating,
                child: Container(color: Colors.transparent),
              ),
            ),

            // Floating Card Anchored via CompositedTransformFollower
            Positioned(
              width: cardWidth,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 4),
                child: Material(
                  elevation: 0,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: cardWidth,
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.workspaceBorder),
                      boxShadow: AppShadows.subtleElevated,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.workspaceSegmentBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.placeholder.key,
                                style: AppTypography.workspaceMicro(
                                  color: AppColors.workspaceCorporateNavy,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.workspaceSecondaryText),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _commitAndCloseFloating,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildFloatingFieldInput(provider),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Press outside or checkmark to commit',
                              style: AppTypography.workspaceMicro(color: AppColors.workspaceSecondaryText),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _commitAndCloseFloating,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.workspaceCorporateNavy,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Done',
                                      style: AppTypography.workspaceButton(color: Colors.white, weight: FontWeight.w700).copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_floatingOverlayEntry!);
    setState(() => _isFloatingOpen = true);
  }

  void _commitAndCloseFloating() {
    if (!_isFloatingOpen) return;
    final provider = context.read<DocumentWorkspaceProvider>();
    final isNumber = _inferFieldType(widget.placeholder.key) == 'NUMBER';
    String textToCommit = _controller.text;
    if (isNumber && textToCommit.trim().isNotEmpty) {
      final clean = textToCommit.replaceAll(',', '').trim();
      final numVal = num.tryParse(clean);
      if (numVal != null) {
        textToCommit = IndianNumberFormatter.format(numVal, includeDecimals: clean.contains('.'));
      }
    }
    provider.updateValue(widget.placeholder.key, textToCommit);
    provider.setFocusedKey(null);
    _removeFloatingOverlay();
  }

  void _removeFloatingOverlay({bool updateState = true}) {
    _floatingOverlayEntry?.remove();
    _floatingOverlayEntry = null;
    if (updateState && mounted) {
      setState(() => _isFloatingOpen = false);
    } else {
      _isFloatingOpen = false;
    }
  }

  Widget _buildFloatingFieldInput(DocumentWorkspaceProvider provider) {
    // <<TEXT>> placeholders must always render as a blank, multiline, auto-expanding
    // text area with no assumptions, no hints, and no helper text.
    // MULTILINE RULE: all TEXT-type fields support multiline / ALT+ENTER / unlimited narrative.
    return TextFormField(
      controller: _controller,
      autofocus: true,
      minLines: 3,
      maxLines: null, // auto-expanding, unlimited
      style: AppTypography.workspaceInput(),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.workspaceSegmentBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.workspaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.0),
        ),
        // No hintText — <<TEXT>> must render a completely blank text input area.
      ),
      onChanged: (val) {
        provider.updateValue(widget.placeholder.key, val);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentWorkspaceProvider>();
    final fieldType = _inferFieldType(widget.placeholder.key);
    final currentValue = provider.getValue(widget.placeholder.key);

    // Scaled viewport geometry
    final left = widget.rect.x * widget.containerWidth;
    final top = widget.rect.y * widget.containerHeight;
    final naturalWidth = widget.rect.w * widget.containerWidth;
    final naturalHeight = widget.rect.h * widget.containerHeight;

    // Minimum width of 180px for standard inline rendering
    final lineCount = currentValue.split('\n').length;
    final effectiveWidth = math.max(naturalWidth, 180.0);
    final effectiveHeight = math.max(naturalHeight, 26.0 * math.max(1, lineCount));

    final isHovered = provider.hoveredKey == widget.placeholder.key;
    final isFocused = provider.focusedKey == widget.placeholder.key || _isFloatingOpen;

    return Positioned(
      left: left,
      top: top - 2,
      width: effectiveWidth,
      height: effectiveHeight,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: MouseRegion(
          onEnter: (_) => provider.setHoveredKey(widget.placeholder.key),
          onExit: (_) => provider.setHoveredKey(null),
          child: GestureDetector(
            onTap: () {
              if (fieldType == 'DATE') {
                _handleDatePicker(currentValue, provider);
              } else if (fieldType == 'IMAGE') {
                _handleImageUpload(provider);
              } else if (fieldType == 'COMPOSITE_TABLE') {
                provider.setViewMode(WorkspaceViewMode.tableEdit);
              } else {
                _showFloatingOverlay();
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: widget.readOnly
                    ? Colors.transparent
                    : (isFocused
                        ? Colors.white
                        : (isHovered ? AppColors.workspaceSegmentBg : AppColors.workspaceCanvas)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFocused
                      ? AppColors.primaryBlue
                      : (isHovered ? AppColors.workspaceBorder : AppColors.workspaceBorder),
                  width: 1.0,
                ),
                boxShadow: isFocused
                    ? const [
                        BoxShadow(
                          color: AppColors.workspaceFocusGlow,
                          blurRadius: 3,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: _buildCompactInlineDisplay(fieldType, currentValue, isFocused),
            ),
          ),
        ),
      ),
    );
  }

  /// State A: Compact Inline Box
  Widget _buildCompactInlineDisplay(String fieldType, String currentValue, bool isFocused) {
    if (fieldType == 'COMPOSITE_TABLE') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          children: [
            const Icon(Icons.apartment_rounded, size: 14, color: Color(0xFF3494BA)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Composite Property Table',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3494BA),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!widget.readOnly)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3494BA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'Open',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF3494BA)),
                ),
              ),
          ],
        ),
      );
    }

    if (fieldType == 'IMAGE') {
      final hasImage = currentValue.isNotEmpty;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          children: [
            Icon(
              hasImage ? Icons.image_rounded : Icons.add_photo_alternate_outlined,
              size: 14,
              color: hasImage ? AppColors.successAccent : AppColors.deepTeal,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hasImage ? 'Image Attached' : widget.placeholder.key,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: hasImage ? AppColors.successAccent : AppColors.deepTeal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!widget.readOnly)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.deepTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  hasImage ? 'Replace' : 'Upload',
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.deepTeal),
                ),
              ),
          ],
        ),
      );
    }

    if (fieldType == 'DATE') {
      final hasValue = currentValue.isNotEmpty;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? currentValue : 'dd-MMM-yyyy',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                  color: hasValue ? AppColors.ink : AppColors.slate.withValues(alpha: 0.6),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.deepTeal),
          ],
        ),
      );
    }

    // TEXT / NUMBER Compact Display
    // GOVERNANCE: When the field is empty, render a blank box — never show the key
    // name, placeholder description, helper text, or any auto-generated content.
    final hasValue = currentValue.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: hasValue
                ? Text(
                    currentValue,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  )
                : const SizedBox.shrink(), // Blank — no key name, no hint, no assumptions.
          ),
          if (!widget.readOnly && !isFocused)
            Icon(Icons.edit_outlined, size: 11, color: AppColors.slate.withValues(alpha: 0.6)),
        ],
      ),
    );
  }

  Future<void> _handleDatePicker(String currentValue, DocumentWorkspaceProvider provider) async {
    if (widget.readOnly) return;

    final title = widget.placeholder.questionText?.isNotEmpty == true
        ? widget.placeholder.questionText!
        : widget.placeholder.key;
    final picked = await DatePickerHelper.showAppDatePicker(
      context: context,
      title: title,
      currentValue: currentValue,
    );

    if (picked != null) {
      _controller.text = picked;
      provider.updateValue(widget.placeholder.key, picked);
    }
  }

  Future<void> _handleImageUpload(DocumentWorkspaceProvider provider) async {
    if (widget.readOnly) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          final base64Str = "data:image/png;base64,${base64Encode(file.bytes!)}";
          provider.updateValue(widget.placeholder.key, base64Str);
        }
      }
    } catch (e) {
      // Picker cancelled or unsupported
    }
  }
}
