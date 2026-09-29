import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../models/custom_placeholder_config.dart';

class PlaceholderEditorWidget extends StatefulWidget {
  final String placeholderKey;
  final CustomPlaceholderConfig? config;
  final ValueChanged<CustomPlaceholderConfig> onChanged;
  final VoidCallback onReset;

  const PlaceholderEditorWidget({
    super.key,
    required this.placeholderKey,
    this.config,
    required this.onChanged,
    required this.onReset,
  });

  @override
  State<PlaceholderEditorWidget> createState() => _PlaceholderEditorWidgetState();
}

class _PlaceholderEditorWidgetState extends State<PlaceholderEditorWidget> {
  late TextEditingController _labelController;
  late TextEditingController _helpTextController;
  late TextEditingController _sectionGroupController;
  late String _fieldType;
  late bool _isRequired;

  @override
  void initState() {
    super.initState();
    _initValues();
  }

  void _initValues() {
    final cfg = widget.config;
    _labelController = TextEditingController(text: cfg?.label ?? _defaultLabel(widget.placeholderKey));
    _helpTextController = TextEditingController(text: cfg?.helpText ?? '');
    _sectionGroupController = TextEditingController(text: cfg?.sectionGroup ?? '');
    _fieldType = cfg?.fieldType ?? PlaceholderFieldTypes.text;
    _isRequired = cfg?.isRequired ?? false;
  }

  @override
  void didUpdateWidget(covariant PlaceholderEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placeholderKey != widget.placeholderKey || oldWidget.config != widget.config) {
      final cfg = widget.config;
      _labelController.text = cfg?.label ?? _defaultLabel(widget.placeholderKey);
      _helpTextController.text = cfg?.helpText ?? '';
      _sectionGroupController.text = cfg?.sectionGroup ?? '';
      setState(() {
        _fieldType = cfg?.fieldType ?? PlaceholderFieldTypes.text;
        _isRequired = cfg?.isRequired ?? false;
      });
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _helpTextController.dispose();
    _sectionGroupController.dispose();
    super.dispose();
  }

  String _defaultLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  void _notifyChanged() {
    final updated = CustomPlaceholderConfig(
      label: _labelController.text.trim().isNotEmpty
          ? _labelController.text.trim()
          : _defaultLabel(widget.placeholderKey),
      helpText: _helpTextController.text.trim().isNotEmpty ? _helpTextController.text.trim() : null,
      fieldType: _fieldType,
      isRequired: _isRequired,
      sectionGroup: _sectionGroupController.text.trim().isNotEmpty
          ? _sectionGroupController.text.trim()
          : null,
    );
    widget.onChanged(updated);
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.bodySm().copyWith(color: AppColors.stone),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.deepTeal, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header / Key Banner
          _buildHeader(),
          const SizedBox(height: 20),
          Container(height: 1, color: AppColors.hairlineSoft),
          const SizedBox(height: 20),

          // 1. Question Label
          _buildFieldLabel('Question / Field Prompt', isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _labelController,
            decoration: _inputDecoration(
              hintText: 'e.g. Borrower Full Legal Name',
            ),
            style: AppTypography.bodyMd(color: AppColors.ink),
            onChanged: (_) => _notifyChanged(),
          ),
          const SizedBox(height: 18),

          // 2. Help Text / Description
          _buildFieldLabel('Helper Tooltip / Description', isRequired: false),
          const SizedBox(height: 6),
          TextFormField(
            controller: _helpTextController,
            maxLines: 2,
            decoration: _inputDecoration(
              hintText: 'Guidance text shown to users during data entry',
            ),
            style: AppTypography.bodySm().copyWith(color: AppColors.ink),
            onChanged: (_) => _notifyChanged(),
          ),
          const SizedBox(height: 18),

          // 3. Field Input Type
          _buildFieldLabel('Input Field Type', isRequired: true),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: ValueKey(_fieldType),
            initialValue: _fieldType,
            decoration: _inputDecoration(),
            dropdownColor: AppColors.surface,
            items: PlaceholderFieldTypes.all.map((type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Row(
                  children: [
                    Icon(_getTypeIcon(type), size: 16, color: AppColors.deepTeal),
                    const SizedBox(width: 8),
                    Text(type, style: AppTypography.bodyMd(color: AppColors.ink)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (newType) {
              if (newType != null) {
                setState(() => _fieldType = newType);
                _notifyChanged();
              }
            },
          ),
          const SizedBox(height: 18),

          // 4. Section Group
          _buildFieldLabel('Intake Section Group', isRequired: false),
          const SizedBox(height: 6),
          TextFormField(
            controller: _sectionGroupController,
            decoration: _inputDecoration(
              hintText: 'e.g. Property Details, Legal Description',
            ),
            style: AppTypography.bodySm().copyWith(color: AppColors.ink),
            onChanged: (_) => _notifyChanged(),
          ),
          const SizedBox(height: 20),

          // 5. Required Field Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.hairlineSoft),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mandatory Field',
                      style: AppTypography.bodyMdMedium(color: AppColors.ink),
                    ),
                    Text(
                      'Require entry before report generation',
                      style: AppTypography.caption(color: AppColors.slate),
                    ),
                  ],
                ),
                Switch(
                  value: _isRequired,
                  activeTrackColor: AppColors.tealLight,
                  activeThumbColor: AppColors.deepTeal,
                  onChanged: (val) {
                    setState(() => _isRequired = val);
                    _notifyChanged();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 6. Reset to Default Button
          OutlinedButton.icon(
            icon: const Icon(Icons.restart_alt_rounded, size: 16, color: AppColors.slate),
            label: const Text('Reset to Default Template Name'),
            onPressed: () {
              widget.onReset();
              _labelController.text = _defaultLabel(widget.placeholderKey);
              _helpTextController.clear();
              _sectionGroupController.clear();
              setState(() {
                _fieldType = PlaceholderFieldTypes.text;
                _isRequired = false;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.slate,
              side: const BorderSide(color: AppColors.hairline),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.edit_note_rounded, size: 20, color: AppColors.deepTeal),
            const SizedBox(width: 8),
            Text(
              'Field Configuration',
              style: AppTypography.heading4().copyWith(color: AppColors.ink),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.tealLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.deepTeal.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.code_rounded, size: 14, color: AppColors.deepTeal),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '<<${widget.placeholderKey}>>',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepTeal,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 14, color: AppColors.deepTeal),
                tooltip: 'Copy Key',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '<<${widget.placeholderKey}>>'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied <<${widget.placeholderKey}>> to clipboard'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          text,
          style: AppTypography.bodySm().copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: AppColors.brandRedDark, fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case PlaceholderFieldTypes.number:
        return Icons.pin_rounded;
      case PlaceholderFieldTypes.date:
        return Icons.calendar_today_rounded;
      case PlaceholderFieldTypes.dropdown:
        return Icons.list_rounded;
      case PlaceholderFieldTypes.boolean:
        return Icons.toggle_on_rounded;
      case PlaceholderFieldTypes.image:
        return Icons.image_rounded;
      default:
        return Icons.text_fields_rounded;
    }
  }
}
