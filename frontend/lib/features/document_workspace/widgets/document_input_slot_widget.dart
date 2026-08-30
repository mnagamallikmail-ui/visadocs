import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../models/workspace_view_model.dart';
import '../providers/document_workspace_provider.dart';

class DocumentInputSlotWidget extends StatefulWidget {
  final InputFieldVm fieldVm;
  final bool readOnly;

  const DocumentInputSlotWidget({
    super.key,
    required this.fieldVm,
    this.readOnly = false,
  });

  @override
  State<DocumentInputSlotWidget> createState() => _DocumentInputSlotWidgetState();
}

class _DocumentInputSlotWidgetState extends State<DocumentInputSlotWidget> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final provider = context.read<DocumentWorkspaceProvider>();
    final initialValue = provider.getValue(widget.fieldVm.key);
    _controller = TextEditingController(text: initialValue);

    _controller.addListener(() {
      if (_focusNode.hasFocus) {
        provider.updateValue(widget.fieldVm.key, _controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DocumentInputSlotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final provider = context.read<DocumentWorkspaceProvider>();
    final serverValue = provider.getValue(widget.fieldVm.key);
    if (!_focusNode.hasFocus && _controller.text != serverValue) {
      _controller.text = serverValue;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, DocumentWorkspaceProvider provider) async {
    if (widget.readOnly) return;
    DateTime initial = DateTime.now();
    final currentText = _controller.text.trim();
    if (currentText.isNotEmpty) {
      final parsed = DateTime.tryParse(currentText);
      if (parsed != null) initial = parsed;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
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
      final formatted = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _controller.text = formatted;
      provider.updateValue(widget.fieldVm.key, formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentWorkspaceProvider>();
    final latestVal = provider.getValue(widget.fieldVm.key);

    // Keep controller synchronized with external updates (e.g. repeated placeholder edits in other sections)
    if (!_focusNode.hasFocus && _controller.text != latestVal) {
      _controller.text = latestVal;
    }

    final isRepeated = widget.fieldVm.isRepeated;
    final isDate = widget.fieldVm.isDate;
    final isImage = widget.fieldVm.isImage;
    final isNumber = widget.fieldVm.isNumber;

    if (isImage) {
      return _buildImageInput(context, provider);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                readOnly: widget.readOnly || isDate,
                onTap: isDate ? () => _pickDate(context, provider) : null,
                keyboardType: isNumber
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.readOnly ? AppColors.slate : AppColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter ${widget.fieldVm.questionText.isNotEmpty ? widget.fieldVm.questionText : "value"}...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.steel.withValues(alpha: 0.8),
                  ),
                  filled: true,
                  fillColor: widget.readOnly ? AppColors.surfaceSoft : Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixIcon: isDate
                      ? const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.deepTeal)
                      : (isRepeated
                          ? Tooltip(
                              message: 'Synchronized across ${widget.fieldVm.occurrences} locations in document',
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(Icons.sync_rounded, size: 15, color: AppColors.deepTeal.withValues(alpha: 0.7)),
                              ),
                            )
                          : null),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppColors.hairline, width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppColors.hairline, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppColors.deepTeal, width: 1.8),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (isRepeated) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.link_rounded, size: 11, color: AppColors.steel),
              const SizedBox(width: 3),
              Text(
                'Synced (${widget.fieldVm.occurrences}x)',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.steel,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildImageInput(BuildContext context, DocumentWorkspaceProvider provider) {
    final hasValue = _controller.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.deepTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.image_outlined, color: AppColors.deepTeal, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasValue ? 'Image Uploaded' : 'No image attached',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  widget.fieldVm.questionText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          if (!widget.readOnly)
            ElevatedButton.icon(
              onPressed: () {
                // Mock image upload representation
                _controller.text = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
                provider.updateValue(widget.fieldVm.key, _controller.text);
              },
              icon: const Icon(Icons.upload_file_rounded, size: 14),
              label: Text(hasValue ? 'Replace' : 'Upload', style: const TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
              ),
            ),
        ],
      ),
    );
  }
}
