import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../models/workspace_view_model.dart';
import '../providers/document_workspace_provider.dart';
import 'document_input_slot_widget.dart';

class DocumentTableWorkspaceWidget extends StatefulWidget {
  const DocumentTableWorkspaceWidget({super.key});

  @override
  State<DocumentTableWorkspaceWidget> createState() => _DocumentTableWorkspaceWidgetState();
}

class _DocumentTableWorkspaceWidgetState extends State<DocumentTableWorkspaceWidget> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _sectionKeys = [];
  bool _isProgrammaticScroll = false;
  int _lastDispatchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollSpy);

    // Listen for sidebar click-to-scroll requests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DocumentWorkspaceProvider>();
      provider.scrollToSectionRequested.addListener(_onScrollRequested);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollSpy);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollRequested() {
    final provider = context.read<DocumentWorkspaceProvider>();
    final targetIndex = provider.scrollToSectionRequested.value;
    if (targetIndex == null) return;

    if (provider.scrollMode == DocumentScrollMode.continuous) {
      _scrollToSectionIndex(targetIndex);
    }
  }

  void _scrollToSectionIndex(int index) {
    if (index < 0 || index >= _sectionKeys.length) return;
    final key = _sectionKeys[index];
    final context = key.currentContext;
    if (context != null) {
      _isProgrammaticScroll = true;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
        alignment: 0.02, // Align near top of viewport with comfortable margin
      ).then((_) {
        // Allow user scrolling spy to resume after animation finishes
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _isProgrammaticScroll = false;
          }
        });
      });
    }
  }

  void _handleScrollSpy() {
    if (_isProgrammaticScroll) return;
    final provider = context.read<DocumentWorkspaceProvider>();
    if (provider.scrollMode != DocumentScrollMode.continuous) return;
    if (_sectionKeys.isEmpty) return;

    int activeIdx = 0;
    const double viewportOffsetTolerance = 140.0;

    for (int i = 0; i < _sectionKeys.length; i++) {
      final key = _sectionKeys[i];
      final keyContext = key.currentContext;
      if (keyContext != null) {
        final renderBox = keyContext.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final position = renderBox.localToGlobal(Offset.zero);
          // If the section top is above or near the top of the viewport
          if (position.dy <= viewportOffsetTolerance) {
            activeIdx = i;
          }
        }
      }
    }

    if (activeIdx != _lastDispatchedIndex && activeIdx != provider.activeSectionIndex) {
      _lastDispatchedIndex = activeIdx;
      provider.setActiveSectionIndex(activeIdx);
    }
  }

  void _ensureKeysSize(int sectionCount) {
    while (_sectionKeys.length < sectionCount) {
      _sectionKeys.add(GlobalKey());
    }
    while (_sectionKeys.length > sectionCount) {
      _sectionKeys.removeLast();
    }
  }

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

    _ensureKeysSize(vm.sections.length);

    if (provider.scrollMode == DocumentScrollMode.sectionBySection) {
      // ─── Single Section Mode ──────────────────────────────────────────
      final activeIndex = provider.activeSectionIndex.clamp(0, vm.sections.length - 1);
      final activeSection = vm.sections[activeIndex];

      return Container(
        color: AppColors.canvas,
        child: CustomScrollView(
          key: PageStorageKey<String>('single_section_${activeSection.sectionIndex}'),
          slivers: [
            SliverToBoxAdapter(
              child: _buildSectionHeaderCard(activeSection, provider.isReadOnly, isContinuous: false),
            ),
            if (activeSection.orderedBlocks.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 36),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final block = activeSection.orderedBlocks[index];
                      if (block is TableBlockVm) {
                        return _buildTableCard(context, block.table, provider.isReadOnly);
                      } else if (block is ParagraphBlockWrapperVm) {
                        return _buildParagraphBlock(context, block.block, provider.isReadOnly);
                      }
                      return const SizedBox.shrink();
                    },
                    childCount: activeSection.orderedBlocks.length,
                  ),
                ),
              )
            else
              _buildEmptySectionMessage(),
          ],
        ),
      );
    }

    // ─── Continuous Document Mode (All Sections in Single Scroll Viewport) ──
    return Container(
      color: AppColors.canvas,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 60),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int sIdx = 0; sIdx < vm.sections.length; sIdx++) ...[
                  // Section Anchor & Header
                  Container(
                    key: _sectionKeys[sIdx],
                    child: _buildSectionHeaderCard(
                      vm.sections[sIdx],
                      provider.isReadOnly,
                      isContinuous: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Render Section Blocks
                  if (vm.sections[sIdx].orderedBlocks.isNotEmpty)
                    for (final block in vm.sections[sIdx].orderedBlocks) ...[
                      if (block is TableBlockVm)
                        _buildTableCard(context, block.table, provider.isReadOnly)
                      else if (block is ParagraphBlockWrapperVm)
                        _buildParagraphBlock(context, block.block, provider.isReadOnly),
                    ]
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Center(
                        child: Text(
                          'No editable items in this section',
                          style: AppTypography.bodySm().copyWith(color: AppColors.slate),
                        ),
                      ),
                    ),

                  if (sIdx < vm.sections.length - 1) ...[
                    const SizedBox(height: 16),
                    // Visual Page/Section Break Divider
                    Row(
                      children: [
                        Expanded(child: Container(height: 1, color: AppColors.hairline)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.steel),
                              const SizedBox(width: 4),
                              Text(
                                'CONTINUE TO SECTION ${sIdx + 2}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.steel,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: Container(height: 1, color: AppColors.hairline)),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeaderCard(SectionVm section, bool isReadOnly, {required bool isContinuous}) {
    return Container(
      margin: EdgeInsets.only(bottom: isContinuous ? 8 : 16, top: isContinuous ? 8 : 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.deepTeal.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
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
              'SECTION ${section.sectionIndex + 1}',
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
              section.title,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          if (isReadOnly)
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
    );
  }

  Widget _buildEmptySectionMessage() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Text(
            'No editable elements in this section',
            style: AppTypography.bodySm().copyWith(color: AppColors.slate),
          ),
        ),
      ),
    );
  }

  Widget _buildParagraphBlock(BuildContext context, ParagraphBlockVm block, bool readOnly) {
    // If paragraph has NO inputs, render styled static paragraph text
    if (!block.hasInputs) {
      final text = block.staticText ?? '';
      if (text.isEmpty || text.length <= 1 || text == '_' || text == 'n' || text == 'r') {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.slate,
              height: 1.45,
            ),
          ),
        ),
      );
    }

    // Paragraph WITH inputs (Rendered as clean editable fields with humanized labels)
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < block.inputFields.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            if (block.inputFields[i].fieldType != 'IMAGE') ...[
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.deepTeal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      block.inputFields[i].questionText,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            DocumentInputSlotWidget(
              fieldVm: block.inputFields[i],
              readOnly: readOnly,
            ),
          ],
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
}
