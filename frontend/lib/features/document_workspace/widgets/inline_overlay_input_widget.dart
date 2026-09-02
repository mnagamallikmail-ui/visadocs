import 'dart:convert';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/indian_number_formatter.dart';
import '../../document_studio/models/visual_preview_model.dart';
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
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _floatingOverlayEntry;
  late final TextEditingController _controller;
  bool _isFloatingOpen = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DocumentWorkspaceProvider>();
    _controller = TextEditingController(text: provider.getValue(widget.placeholder.key));
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
    _removeFloatingOverlay();
    _controller.dispose();
    super.dispose();
  }

  String _inferFieldType(String key) {
    final upper = key.toUpperCase();
    if (upper.startsWith('IMG_') || upper.endsWith('_IMAGE') || upper.contains('PHOTO') || upper.contains('SIGNATURE')) {
      return 'IMAGE';
    }
    if (upper.contains('DATE')) {
      return 'DATE';
    }
    if (upper.contains('AREA') || upper.contains('RATE') || upper.contains('VALUE') ||
        upper.contains('AMOUNT') || upper.contains('FEE') || upper.contains('TOTAL') ||
        upper.contains('PRICE') || upper.contains('PERCENT') || upper.contains('RATIO') || upper.startsWith('NUM_')) {
      return 'NUMBER';
    }
    return 'TEXT';
  }

  void _showFloatingOverlay() {
    if (widget.readOnly || _isFloatingOpen) return;

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
              width: math.max(size.width, 280.0).clamp(220.0, 480.0),
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 4),
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.surface,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.deepTeal, width: 1.5),
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
                                color: AppColors.tealLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.placeholder.key,
                                style: GoogleFonts.robotoMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deepTeal,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.slate),
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
                              style: AppTypography.caption(color: AppColors.slate),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _commitAndCloseFloating,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.deepTeal,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Done', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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

  void _removeFloatingOverlay() {
    _floatingOverlayEntry?.remove();
    _floatingOverlayEntry = null;
    if (mounted) {
      setState(() => _isFloatingOpen = false);
    }
  }

  Widget _buildFloatingFieldInput(DocumentWorkspaceProvider provider) {
    final type = _inferFieldType(widget.placeholder.key);
    final isNumber = type == 'NUMBER';

    return TextField(
      controller: _controller,
      autofocus: true,
      maxLines: isNumber ? 1 : 4,
      minLines: 1,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.multiline,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceSoft,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.deepTeal, width: 1.5),
        ),
        hintText: 'Enter value for ${widget.placeholder.key}...',
        hintStyle: AppTypography.bodySm().copyWith(color: AppColors.slate),
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
    final effectiveWidth = math.max(naturalWidth, 180.0);
    final effectiveHeight = math.max(naturalHeight, 26.0);

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
                        : (isHovered ? AppColors.surfaceSoft : Colors.white.withValues(alpha: 0.95))),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isFocused
                      ? AppColors.deepTeal
                      : (isHovered ? AppColors.deepTeal.withValues(alpha: 0.6) : AppColors.hairlineSoft),
                  width: isFocused ? 1.5 : 1.0,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: AppColors.deepTeal.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                currentValue.isNotEmpty ? currentValue : widget.placeholder.key,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: currentValue.isNotEmpty ? AppColors.ink : AppColors.slate,
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
    final hasValue = currentValue.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hasValue ? currentValue : widget.placeholder.key,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                color: hasValue ? AppColors.ink : AppColors.slate.withValues(alpha: 0.7),
                fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!widget.readOnly && !isFocused)
            Icon(Icons.edit_outlined, size: 11, color: AppColors.slate.withValues(alpha: 0.6)),
        ],
      ),
    );
  }

  Future<void> _handleDatePicker(String currentValue, DocumentWorkspaceProvider provider) async {
    if (widget.readOnly) return;

    DateTime initialDate = DateTime.tryParse(currentValue) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.deepTeal,
              onPrimary: Colors.white,
              onSurface: AppColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      _controller.text = formatted;
      provider.updateValue(widget.placeholder.key, formatted);
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
