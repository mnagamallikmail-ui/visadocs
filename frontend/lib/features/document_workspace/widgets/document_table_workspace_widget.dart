import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../document_studio/models/studio_document_model.dart';
import '../models/workspace_view_model.dart';
import '../providers/document_workspace_provider.dart';
import 'document_input_slot_widget.dart';

class DocumentTableWorkspaceWidget extends StatelessWidget {
  const DocumentTableWorkspaceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentWorkspaceProvider>();
    final vm = provider.workspaceVm;

    if (vm == null || vm.sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_outlined, size: 48, color: AppColors.steel),
            const SizedBox(height: 12),
            Text(
              'No document structure loaded',
              style: AppTypography.heading4().copyWith(color: AppColors.slate),
            ),
          ],
        ),
      );
    }

    final activeIndex = provider.activeSectionIndex.clamp(0, vm.sections.length - 1);
    final activeSection = vm.sections[activeIndex];

    return Container(
      color: AppColors.canvas,
      child: CustomScrollView(
        key: PageStorageKey<String>('section_${activeSection.sectionIndex}'),
        slivers: [
          // Section Title Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.hairline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.deepTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SECTION ${activeSection.sectionIndex + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepTeal,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        activeSection.title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (provider.isReadOnly)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'READ-ONLY',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.slate),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Standalone Paragraphs before tables
          if (activeSection.standaloneParagraphs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: activeSection.standaloneParagraphs.map((p) => _buildParagraph(p)).toList(),
                ),
              ),
            ),

          // Render Tables
          if (activeSection.tables.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 36),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tableVm = activeSection.tables[index];
                    return _buildTableCard(context, tableVm, provider.isReadOnly);
                  },
                  childCount: activeSection.tables.length,
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Center(
                  child: Text(
                    'No tables in this section',
                    style: AppTypography.bodySm().copyWith(color: AppColors.slate),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableCard(BuildContext context, TableVm tableVm, bool readOnly) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int r = 0; r < tableVm.rows.length; r++)
            _buildTableRow(context, tableVm.rows[r], r, tableVm.rows.length, readOnly),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, TableRowVm rowVm, int rowIndex, int totalRows, bool readOnly) {
    final isLast = rowIndex == totalRows - 1;

    // 1. Merged Section Sub-header Row
    if (rowVm.isSubHeader) {
      final title = rowVm.rawCells.isNotEmpty ? rowVm.rawCells.first.plainText : 'Sub-section';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          border: Border(bottom: BorderSide(color: AppColors.hairline, width: isLast ? 0 : 1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.bookmark_outline_rounded, size: 16, color: AppColors.deepTeal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Table Column Header Row
    if (rowVm.isTableHeader) {
      final cells = rowVm.rawCells;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border(bottom: BorderSide(color: AppColors.hairline, width: isLast ? 0 : 1.5)),
        ),
        child: Row(
          children: [
            if (cells.length == 3) ...[
              SizedBox(
                width: 50,
                child: Text(
                  cells[0].plainText.isNotEmpty ? cells[0].plainText : 'S.No',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 5,
                child: Text(
                  cells[1].plainText.isNotEmpty ? cells[1].plainText : 'Particulars',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 6,
                child: Text(
                  cells[2].plainText.isNotEmpty ? cells[2].plainText : 'Observed Details',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate),
                ),
              ),
            ] else if (cells.length == 2) ...[
              Expanded(
                flex: 5,
                child: Text(
                  cells[0].plainText.isNotEmpty ? cells[0].plainText : 'Particulars',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 6,
                child: Text(
                  cells[1].plainText.isNotEmpty ? cells[1].plainText : 'Details',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate),
                ),
              ),
            ] else ...[
              for (final c in cells)
                Expanded(
                  child: Text(
                    c.plainText,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate),
                  ),
                ),
            ],
          ],
        ),
      );
    }

    // 3. Question-Answer Row (3-Column Layout: [INDEX] [QUESTION] [ANSWER])
    if (rowVm.is3Column) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hairline, width: isLast ? 0 : 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // S.No
            SizedBox(
              width: 50,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  rowVm.serialNo ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Question Prompt
            Expanded(
              flex: 5,
              child: Text(
                rowVm.questionText ?? '',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Answer Input(s)
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final f in rowVm.inputFields) ...[
                    DocumentInputSlotWidget(fieldVm: f, readOnly: readOnly),
                    if (rowVm.inputFields.last != f) const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4. Question-Answer Row (2-Column Layout: [QUESTION] [ANSWER])
    if (rowVm.is2Column) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hairline, width: isLast ? 0 : 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Question Prompt
            Expanded(
              flex: 5,
              child: Text(
                rowVm.questionText ?? '',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Answer Input(s)
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final f in rowVm.inputFields) ...[
                    DocumentInputSlotWidget(fieldVm: f, readOnly: readOnly),
                    if (rowVm.inputFields.last != f) const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 5. Static Text / Irregular Row
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft.withValues(alpha: 0.4),
        border: Border(bottom: BorderSide(color: AppColors.hairline, width: isLast ? 0 : 1)),
      ),
      child: Row(
        children: [
          for (final cell in rowVm.rawCells)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  cell.plainText,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate, fontStyle: FontStyle.italic),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParagraph(StudioParagraph p) {
    final text = p.plainText.trim();
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.slate,
          height: 1.45,
        ),
      ),
    );
  }
}
