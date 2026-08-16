import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_components.dart';
import 'models/studio_document_model.dart';
import 'models/calculation_table_model.dart';
import 'providers/document_studio_provider.dart';
import 'widgets/placeholder_editor_widget.dart';
import 'widgets/table_calculation_editor_widget.dart';

class DocumentStudioScreen extends StatefulWidget {
  final int templateId;
  final String? templateName;

  const DocumentStudioScreen({
    super.key,
    required this.templateId,
    this.templateName,
  });

  @override
  State<DocumentStudioScreen> createState() => _DocumentStudioScreenState();
}

class _DocumentStudioScreenState extends State<DocumentStudioScreen> {
  late final DocumentStudioProvider _provider;
  String _activeTypeFilter = 'ALL';
  bool _isRecentlyPublished = false;

  @override
  void initState() {
    super.initState();
    _provider = DocumentStudioProvider();
    _provider.loadTemplateStructure(widget.templateId);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final success = await _provider.saveConfig(widget.templateId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document Studio configuration saved'),
          backgroundColor: AppColors.deepTeal,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.errorMessage ?? 'Failed to save configuration'),
          backgroundColor: AppColors.brandRedDark,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handlePublish() async {
    final shouldPublish = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.publish_rounded, color: AppColors.deepTeal, size: 22),
            const SizedBox(width: 10),
            Text(
              'Publish Template Questions?',
              style: AppTypography.heading4().copyWith(color: AppColors.ink),
            ),
          ],
        ),
        content: Text(
          'This will synchronize Document Studio questions into the Client Intake questionnaire dictionary and update the live form schema.',
          style: AppTypography.bodySm().copyWith(color: AppColors.slate, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: AppTypography.bodyMdMedium(color: AppColors.slate)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (shouldPublish != true) return;

    final success = await _provider.publishToIntake(widget.templateId);
    if (!mounted) return;

    if (success) {
      setState(() => _isRecentlyPublished = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Questionnaire published successfully'),
          backgroundColor: AppColors.successAccent,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.errorMessage ?? 'Failed to publish questionnaire'),
          backgroundColor: AppColors.brandRedDark,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<DocumentStudioProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: AppColors.canvas,
            appBar: _buildAppBar(context, provider),
            body: Builder(
              builder: (context) {
                if (provider.isLoading) {
                  return _buildLoadingState();
                }

                if (provider.errorMessage != null) {
                  return _buildErrorState(provider);
                }

                if (!provider.hasDocument) {
                  return _buildEmptyState();
                }

                return Row(
                  children: [
                    // Main Document Canvas Viewport
                    Expanded(
                      flex: 7,
                      child: _buildDocumentCanvas(provider),
                    ),

                    // Vertical Divider
                    Container(width: 1, color: AppColors.hairline),

                    // Right Tri-Mode Inspector Panel
                    SizedBox(
                      width: 380,
                      child: _buildInspectorPanel(provider),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, DocumentStudioProvider provider) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.hairline, height: 1),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
        tooltip: 'Back to Admin',
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.deepTeal.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_stories_outlined, color: AppColors.deepTeal, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Document Studio',
                  style: AppTypography.caption(color: AppColors.deepTeal).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.templateName != null ? 'Template #${widget.templateId}: ${widget.templateName}' : 'Template #${widget.templateId}',
            style: AppTypography.heading4().copyWith(color: AppColors.ink),
          ),
          if (provider.isDirty) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Unsaved Changes',
                    style: AppTypography.caption(color: AppColors.ink).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_isRecentlyPublished) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.successAccent.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.successAccent),
                  const SizedBox(width: 6),
                  Text(
                    'Published',
                    style: AppTypography.caption(color: AppColors.ink).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (provider.isDirty) ...[
          ElevatedButton.icon(
            icon: provider.isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded, size: 16),
            label: Text(provider.isSaving ? 'Saving...' : 'Save Changes'),
            onPressed: provider.isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Publish to Intake Action Button
        OutlinedButton.icon(
          icon: provider.isPublishing
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deepTeal),
                )
              : const Icon(Icons.publish_rounded, size: 16),
          label: Text(provider.isPublishing ? 'Publishing...' : 'Publish to Intake'),
          onPressed: (provider.isPublishing || provider.isLoading) ? null : _handlePublish,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.deepTeal,
            side: BorderSide(color: AppColors.deepTeal.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.slate),
          tooltip: 'Reload Structure',
          onPressed: () => provider.loadTemplateStructure(widget.templateId),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.deepTeal),
          const SizedBox(height: 16),
          Text(
            'Parsing OpenXML Document Structure...',
            style: AppTypography.bodyMdMedium(color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Extracting sections, tables, typography, and placeholder tokens',
            style: AppTypography.bodySm().copyWith(color: AppColors.slate),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(DocumentStudioProvider provider) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.errorBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: AppColors.brandRedDark, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Document Studio',
              style: AppTypography.heading4().copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'An unknown error occurred.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm().copyWith(color: AppColors.slate, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              onPressed: () => provider.loadTemplateStructure(widget.templateId),
              style: AppComponents.primaryButton,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: AppComponents.emptyState(
        icon: Icons.description_outlined,
        title: 'Empty Document Structure',
        description: 'The template contains no sections or text elements to display.',
        primaryButtonText: 'Reload',
        onPrimaryAction: () => _provider.loadTemplateStructure(widget.templateId),
      ),
    );
  }

  Widget _buildDocumentCanvas(DocumentStudioProvider provider) {
    final model = provider.documentModel!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 820),
          padding: const EdgeInsets.fromLTRB(48, 56, 48, 56),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.hairline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document Canvas Header Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DOCUMENT PREVIEW',
                    style: AppTypography.caption(color: AppColors.slate).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    '${model.sections.length} Sections • ${model.placeholdersSummary.length} Placeholders',
                    style: AppTypography.caption(color: AppColors.steel),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: AppColors.hairlineSoft),
              const SizedBox(height: 32),

              // Render Sections
              for (int i = 0; i < model.sections.length; i++) ...[
                _buildSectionItem(i, model.sections[i], provider),
                if (i < model.sections.length - 1) ...[
                  const SizedBox(height: 32),
                  Container(height: 1, color: AppColors.hairlineSoft),
                  const SizedBox(height: 32),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionItem(int sectionIndex, StudioSection section, DocumentStudioProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.hairlineSoft),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bookmark_outline_rounded, size: 16, color: AppColors.deepTeal),
              const SizedBox(width: 8),
              Text(
                section.title,
                style: AppTypography.bodyMdMedium(color: AppColors.ink).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section Elements
        for (int eIdx = 0; eIdx < section.elements.length; eIdx++) ...[
          if (section.elements[eIdx] is StudioParagraph)
            _buildParagraph(section.elements[eIdx] as StudioParagraph, provider)
          else if (section.elements[eIdx] is StudioTable)
            _buildTable('tbl_${sectionIndex}_$eIdx', section.elements[eIdx] as StudioTable, provider),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildParagraph(StudioParagraph paragraph, DocumentStudioProvider provider) {
    TextAlign align = TextAlign.left;
    if (paragraph.alignment == 'CENTER') align = TextAlign.center;
    if (paragraph.alignment == 'RIGHT') align = TextAlign.right;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text.rich(
        TextSpan(
          children: paragraph.runs.map((run) => _buildRunSpan(run, provider)).toList(),
        ),
        textAlign: align,
      ),
    );
  }

  InlineSpan _buildRunSpan(StudioRun run, DocumentStudioProvider provider) {
    if (run.isImage) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_outlined, size: 16, color: AppColors.slate),
              const SizedBox(width: 6),
              Text('Image Slot', style: AppTypography.caption(color: AppColors.slate)),
            ],
          ),
        ),
      );
    }

    if (run.isPlaceholder && run.placeholderKey != null) {
      final isSelected = provider.selectedPlaceholderKey?.toUpperCase() == run.placeholderKey!.toUpperCase();

      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onTap: () {
            if (isSelected) {
              provider.clearSelection();
            } else {
              provider.selectPlaceholder(run.placeholderKey!);
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.deepTeal : AppColors.tealLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.deepTealPressed : AppColors.deepTeal.withValues(alpha: 0.3),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.deepTeal.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tag_rounded,
                    size: 13,
                    color: isSelected ? Colors.white : AppColors.deepTeal,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    run.text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.deepTeal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Color textColor = AppColors.ink;
    if (run.fontColor != null && run.fontColor!.startsWith('#') && run.fontColor!.length == 7) {
      try {
        textColor = Color(int.parse(run.fontColor!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return TextSpan(
      text: run.text,
      style: TextStyle(
        fontSize: run.fontSizePt > 0 ? run.fontSizePt : 11.0,
        fontWeight: run.isBold ? FontWeight.w700 : FontWeight.w400,
        fontStyle: run.isItalic ? FontStyle.italic : FontStyle.normal,
        color: textColor,
        height: 1.6,
      ),
    );
  }

  Widget _buildTable(String tableId, StudioTable table, DocumentStudioProvider provider) {
    if (table.rows.isEmpty) return const SizedBox.shrink();

    final isSelected = provider.selectedTableId == tableId;
    final tableConfig = provider.getTableConfig(tableId);
    final hasDynamicRules = tableConfig?.hasActiveRules ?? false;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (isSelected) {
            provider.clearSelection();
          } else {
            provider.selectTable(tableId);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.tealLight.withValues(alpha: 0.3) : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.deepTeal : (hasDynamicRules ? AppColors.deepTeal.withValues(alpha: 0.4) : AppColors.hairline),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.deepTeal.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dynamic Table Header Badge if formulas are configured
              if (hasDynamicRules || isSelected)
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.tealLight,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.deepTeal.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.functions_rounded, size: 12, color: AppColors.deepTeal),
                            const SizedBox(width: 4),
                            Text(
                              'fx Dynamic Table',
                              style: AppTypography.caption(color: AppColors.deepTeal).copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        tableId,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.slate),
                      ),
                    ],
                  ),
                ),

              // OpenXML Rendered Table Structure
              Table(
                border: TableBorder.all(color: AppColors.hairline, width: 1),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: table.rows.map((row) {
                  return TableRow(
                    decoration: BoxDecoration(
                      color: row.rowIndex == 0 ? AppColors.surfaceSoft : Colors.transparent,
                    ),
                    children: row.cells.map((cell) {
                      if (cell.isVerticalMergeContinuation) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          color: AppColors.surfaceSoft.withValues(alpha: 0.5),
                          child: Center(
                            child: Text('↑ Merged', style: AppTypography.caption(color: AppColors.stone)),
                          ),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (cell.colSpan > 1) ...[
                              Text('Span: ${cell.colSpan} cols', style: AppTypography.caption(color: AppColors.steel)),
                              const SizedBox(height: 4),
                            ],
                            for (final cp in cell.paragraphs)
                              _buildParagraph(cp, provider),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInspectorPanel(DocumentStudioProvider provider) {
    // Mode C: Table Calculation Inspector
    if (provider.selectedTableId != null) {
      final selectedTableId = provider.selectedTableId!;
      final currentConfig = provider.getTableConfig(selectedTableId) ??
          CalculationTableConfig(
            tableId: selectedTableId,
            headerRowCount: 1,
            hasSummaryRow: false,
          );

      // Compute max columns from table
      int totalColumns = 4;
      if (provider.documentModel != null) {
        for (final section in provider.documentModel!.sections) {
          for (int eIdx = 0; eIdx < section.elements.length; eIdx++) {
            final elem = section.elements[eIdx];
            if (elem is StudioTable && elem.rows.isNotEmpty) {
              totalColumns = elem.rows.first.cells.length;
              break;
            }
          }
        }
      }

      return Column(
        children: [
          // Sub-header to go back to catalog
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSoft,
              border: Border(bottom: BorderSide(color: AppColors.hairlineSoft)),
            ),
            child: Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.deepTeal),
                  label: const Text('Back to Catalog'),
                  onPressed: () => provider.clearSelection(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.deepTeal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                ),
                const Spacer(),
                Text(
                  selectedTableId,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.slate),
                ),
              ],
            ),
          ),

          // Table Calculation Form
          Expanded(
            child: TableCalculationEditorWidget(
              config: currentConfig,
              totalColumns: totalColumns,
              onChanged: (updatedConfig) {
                provider.updateTableConfig(updatedConfig);
              },
            ),
          ),
        ],
      );
    }

    // Mode B: Placeholder Field Inspector
    if (provider.selectedPlaceholderKey != null) {
      final selectedKey = provider.selectedPlaceholderKey!;
      final currentConfig = provider.getPlaceholderConfig(selectedKey);

      return Column(
        children: [
          // Sub-header to go back to catalog
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSoft,
              border: Border(bottom: BorderSide(color: AppColors.hairlineSoft)),
            ),
            child: Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.deepTeal),
                  label: const Text('All Placeholders'),
                  onPressed: () => provider.clearSelection(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.deepTeal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                ),
                const Spacer(),
                Text(
                  '${provider.documentModel?.getPlaceholderCount(selectedKey) ?? 1}x occurrences',
                  style: AppTypography.caption(color: AppColors.slate),
                ),
              ],
            ),
          ),

          // Editor Form Widget
          Expanded(
            child: PlaceholderEditorWidget(
              placeholderKey: selectedKey,
              config: currentConfig,
              onChanged: (newConfig) {
                provider.updatePlaceholderConfig(selectedKey, newConfig);
              },
              onReset: () {
                provider.resetPlaceholderConfig(selectedKey);
              },
            ),
          ),
        ],
      );
    }

    // Mode A: Default Catalog List View
    final summary = provider.documentModel!.placeholdersSummary;
    final filtered = _activeTypeFilter == 'ALL'
        ? summary
        : summary.where((p) => p.type.toUpperCase() == _activeTypeFilter).toList();

    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.manage_search_rounded, size: 20, color: AppColors.deepTeal),
                    const SizedBox(width: 8),
                    Text('Placeholders Catalog', style: AppTypography.heading4().copyWith(color: AppColors.ink)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.length} total keys extracted from template',
                  style: AppTypography.caption(color: AppColors.slate),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.hairlineSoft),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: ['ALL', 'TEXT', 'NUMBER', 'DATE', 'IMAGE'].map((filter) {
                final isSel = _activeTypeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSel,
                    onSelected: (_) => setState(() => _activeTypeFilter = filter),
                    selectedColor: AppColors.tealLight,
                    checkmarkColor: AppColors.deepTeal,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? AppColors.deepTeal : AppColors.slate,
                    ),
                    side: BorderSide(
                      color: isSel ? AppColors.deepTeal : AppColors.hairline,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Container(height: 1, color: AppColors.hairlineSoft),

          // Placeholder Items List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('No placeholders found in this category', style: AppTypography.bodySm().copyWith(color: AppColors.stone)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isSelected = provider.selectedPlaceholderKey?.toUpperCase() == item.key.toUpperCase();
                      final effectiveLabel = provider.getEffectiveLabel(item.key);
                      final hasCustomConfig = provider.getPlaceholderConfig(item.key) != null;

                      return InkWell(
                        onTap: () {
                          if (isSelected) {
                            provider.clearSelection();
                          } else {
                            provider.selectPlaceholder(item.key);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.tealLight : AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.deepTeal : AppColors.hairlineSoft,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '<<${item.key}>>',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  if (hasCustomConfig) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.tealLight,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.deepTeal.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        'Custom',
                                        style: AppTypography.caption(color: AppColors.deepTeal).copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.hairline),
                                    ),
                                    child: Text(
                                      '${item.occurrences}x',
                                      style: AppTypography.caption(color: AppColors.slate).copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      effectiveLabel,
                                      style: AppTypography.bodySm().copyWith(
                                        color: hasCustomConfig ? AppColors.ink : AppColors.slate,
                                        fontSize: 12,
                                        fontWeight: hasCustomConfig ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.type,
                                    style: AppTypography.caption(color: AppColors.steel).copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
