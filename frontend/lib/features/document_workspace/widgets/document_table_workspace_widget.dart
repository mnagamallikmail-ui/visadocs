import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/indian_number_formatter.dart';
import '../../../utils/indian_currency_to_words.dart';
import '../models/workspace_view_model.dart';
import '../providers/document_workspace_provider.dart';
import 'document_input_slot_widget.dart';

class DocumentTableWorkspaceWidget extends StatefulWidget {
  const DocumentTableWorkspaceWidget({super.key});

  @override
  State<DocumentTableWorkspaceWidget> createState() => _DocumentTableWorkspaceWidgetState();
}

class _DocumentTableWorkspaceWidgetState extends State<DocumentTableWorkspaceWidget> {
  static const List<String> _landUnits = ['Sq.Ft', 'Sq.Yards', 'Cents', 'Gunthas', 'Acres', 'Sq.M'];
  static const List<String> _buildingTypes = [
    'RCC Residential',
    'RCC Commercial',
    'Industrial Building',
    'Warehouse',
    'Steel Shed',
    'PEB Structure'
  ];
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
      return Container(
        color: AppColors.canvas,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description_outlined, size: 48, color: AppColors.steel),
              const SizedBox(height: 12),
              Text(
                'Document Workspace Ready',
                style: AppTypography.heading4().copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                'Select an order to begin data entry or review document inputs.',
                style: AppTypography.bodySm().copyWith(color: AppColors.slate),
              ),
            ],
          ),
        ),
      );
    }

    _ensureKeysSize(vm.sections.length);

    // ─── Section-by-Section Mode (Paged Viewport) ───────────────────────────
    if (provider.scrollMode == DocumentScrollMode.sectionBySection) {
      final activeIndex = provider.activeSectionIndex.clamp(0, vm.sections.length - 1);
      final activeSection = vm.sections[activeIndex];

      return Container(
        color: AppColors.canvas,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                    child: _buildSectionHeaderCard(activeSection, provider.isReadOnly, isContinuous: false),
                  ),
                ),
              ),
            ),
            if (activeSection.orderedBlocks.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 36),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final block = activeSection.orderedBlocks[index];
                      return _buildSectionBlock(context, block, provider);
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
                      _buildSectionBlock(context, block, provider),
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

  Widget _buildSectionBlock(BuildContext context, SectionBlockVm block, DocumentWorkspaceProvider provider) {
    if (block is TableBlockVm) {
      return _buildTableCard(context, block.table, provider.isReadOnly);
    } else if (block is ParagraphBlockWrapperVm) {
      return _buildParagraphBlock(context, block.block, provider.isReadOnly);
    } else if (block is ValuationLandBlockVm) {
      return _buildInlineLandSection(context, provider);
    } else if (block is ValuationBuildingBlockVm) {
      return _buildInlineBuildingSection(context, provider);
    } else if (block is ValuationComparableBlockVm) {
      return _buildInlineComparablesSection(context, provider);
    } else if (block is ValuationPropertyBlockVm) {
      return _buildInlinePropertySection(context, provider);
    } else if (block is ValuationSummaryBlockVm) {
      return _buildInlineSummarySection(context, provider);
    }
    return const SizedBox.shrink();
  }

  // ─── Inline Valuation: LAND_TABLE (Interactive Editor) ──────────────────────
  Widget _buildInlineLandSection(BuildContext context, DocumentWorkspaceProvider provider) {
    final landItems = provider.landItems;
    final data = provider.valuationData;
    final isReadOnly = provider.isReadOnly;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.deepTeal.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.deepTeal.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.landscape_rounded, color: AppColors.deepTeal, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'VALUE OF LAND',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.deepTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('<<LAND_TABLE>>', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.deepTeal)),
                    ),
                  ],
                ),
                if (!isReadOnly)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('+ Add Parcel'),
                    onPressed: () => provider.addLandItem(),
                  ),
              ],
            ),
          ),

          // Scrollable Table Content (Interactive Editor)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 960,
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: AppColors.surfaceSoft,
                    child: Row(
                      children: const [
                        SizedBox(width: 44, child: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                        Expanded(flex: 4, child: Text('Description / Plot No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Area (Sq.Ft)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Rate (₹/Unit)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 3, child: Text('Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
                        SizedBox(width: 44),
                      ],
                    ),
                  ),

                  // Dynamic Rows
                  if (landItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      alignment: Alignment.center,
                      child: Text(
                        'No land parcels recorded. Click "+ Add Parcel" above to add records.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ...landItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairlineSoft))),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text(
                              '${idx + 1}',
                              style: GoogleFonts.firaCode(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              initialValue: item.description.isNotEmpty ? item.description : (item.surveyNo.isNotEmpty ? 'Plot (Sy.No.${item.surveyNo})' : ''),
                              enabled: !isReadOnly,
                              decoration: const InputDecoration(
                                hintText: 'e.g. Commercial Plot (Sy.No.42/A)',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onChanged: (val) {
                                item.description = val;
                                provider.recalculateValuation();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: item.enteredArea > 0 ? IndianNumberFormatter.format(item.enteredArea, includeDecimals: item.enteredArea % 1 != 0) : '',
                              enabled: !isReadOnly,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: '0',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onChanged: (val) {
                                item.enteredArea = double.tryParse(val.replaceAll(',', '').trim()) ?? 0;
                                provider.recalculateValuation();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _landUnits.contains(item.enteredUnit) ? item.enteredUnit : 'Sq.Ft',
                              items: _landUnits.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 11)))).toList(),
                              onChanged: isReadOnly ? null : (val) {
                                if (val != null) {
                                  item.enteredUnit = val;
                                  provider.recalculateValuation();
                                }
                              },
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Text(
                              IndianNumberFormatter.format(item.standardAreaSqft, includeDecimals: true),
                              style: GoogleFonts.firaCode(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: item.rate > 0 ? IndianNumberFormatter.format(item.rate, includeDecimals: item.rate % 1 != 0) : '',
                              enabled: !isReadOnly,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: '₹ / ${item.enteredUnit}',
                                isDense: true,
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onChanged: (val) {
                                item.rate = double.tryParse(val.replaceAll(',', '').trim()) ?? 0;
                                provider.recalculateValuation();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '₹ ${IndianNumberFormatter.format(item.value)}',
                              style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            child: isReadOnly
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.brandRedDark),
                                    onPressed: () => provider.removeLandItem(idx),
                                  ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Total & Say Rows
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(9)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL LAND VALUE', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    Text(
                      '₹ ${IndianNumberFormatter.format(data?.totalLandValue ?? 0)}',
                      style: GoogleFonts.firaCode(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SAY LAND VALUE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                    Text(
                      '₹ ${IndianNumberFormatter.format(data?.sayLandValue ?? 0)}',
                      style: GoogleFonts.firaCode(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Inline Valuation: BUILDING_TABLE (Interactive Editor) ──────────────────
  Widget _buildInlineBuildingSection(BuildContext context, DocumentWorkspaceProvider provider) {
    final buildingItems = provider.buildingItems;
    final data = provider.valuationData;
    final isReadOnly = provider.isReadOnly;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.deepTeal.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.deepTeal.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.apartment_rounded, color: AppColors.deepTeal, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'VALUE OF BUILDING',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.deepTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('<<BUILDING_TABLE>>', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.deepTeal)),
                    ),
                  ],
                ),
                if (!isReadOnly)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('+ Add Structure'),
                    onPressed: () => provider.addBuildingItem(),
                  ),
              ],
            ),
          ),

          // Scrollable Table Content (Interactive Editor)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1120,
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: AppColors.surfaceSoft,
                    child: Row(
                      children: const [
                        SizedBox(width: 44, child: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                        Expanded(flex: 3, child: Text('Description / Structure', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Building Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Area (Sq.Ft)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Rate (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Repl Cost (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 1, child: Text('Age', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 1, child: Text('Life', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 1, child: Text('Dep %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Depr (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Net Value (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
                        SizedBox(width: 44),
                      ],
                    ),
                  ),

                  // Dynamic Rows
                  if (buildingItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      alignment: Alignment.center,
                      child: Text(
                        'No building structures recorded. Click "+ Add Structure" above to add records.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ...buildingItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairlineSoft))),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text(
                              '${idx + 1}',
                              style: GoogleFonts.firaCode(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: item.description.isNotEmpty ? item.description : (item.structureType.isNotEmpty ? item.structureType : 'Structure ${idx + 1}'),
                              enabled: !isReadOnly,
                              decoration: const InputDecoration(
                                hintText: 'e.g. Ground Floor RCC',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onChanged: (val) {
                                item.description = val;
                                provider.recalculateValuation();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _buildingTypes.contains(item.buildingType) ? item.buildingType : 'RCC Commercial',
                              items: _buildingTypes.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: isReadOnly ? null : (val) {
                                if (val != null) {
                                  item.buildingType = val;
                                  provider.recalculateValuation();
                                }
                              },
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: item.enteredArea > 0 ? IndianNumberFormatter.format(item.enteredArea, includeDecimals: item.enteredArea % 1 != 0) : '',
                              enabled: !isReadOnly,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: '0',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onChanged: (val) {
                                item.enteredArea = double.tryParse(val.replaceAll(',', '').trim()) ?? 0;
                                provider.recalculateValuation();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: item.replacementRate > 0 ? IndianNumberFormatter.format(item.replacementRate, includeDecimals: item.replacementRate % 1 != 0) : '',
                              enabled: !isReadOnly,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: '0',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onChanged: (val) {
                                item.replacementRate = double.tryParse(val.replaceAll(',', '').trim()) ?? 0;
                                provider.recalculateValuation();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹ ${IndianNumberFormatter.format(item.replacementCost)}',
                              style: GoogleFonts.firaCode(fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: item.buildingAge > 0 ? item.buildingAge.toString() : '',
                              enabled: !isReadOnly,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '0',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              ),
                              onChanged: (val) {
                                item.buildingAge = double.tryParse(val.replaceAll(',', '').trim()) ?? 0;
                                provider.recalculateValuation();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: item.buildingUsefulLife > 0 ? item.buildingUsefulLife.toString() : '60',
                              enabled: !isReadOnly,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '60',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              ),
                              onChanged: (val) {
                                item.buildingUsefulLife = int.tryParse(val.replaceAll(',', '').trim()) ?? 60;
                                provider.recalculateValuation();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${item.depreciationPercentage.toStringAsFixed(1)}%',
                              style: GoogleFonts.firaCode(fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹ ${IndianNumberFormatter.format(item.depreciationAmount)}',
                              style: GoogleFonts.firaCode(fontSize: 11, color: AppColors.brandRedDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹ ${IndianNumberFormatter.format(item.buildingValue)}',
                              style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            child: isReadOnly
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.brandRedDark),
                                    onPressed: () => provider.removeBuildingItem(idx),
                                  ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Total & Say Rows
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(9)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL BUILDING VALUE', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    Text(
                      '₹ ${IndianNumberFormatter.format(data?.totalBuildingValue ?? 0)}',
                      style: GoogleFonts.firaCode(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SAY BUILDING VALUE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                    Text(
                      '₹ ${IndianNumberFormatter.format(data?.sayBuildingValue ?? 0)}',
                      style: GoogleFonts.firaCode(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Inline Valuation: COMPARABLES_TABLE (Interactive Editor) ────────────────
  Widget _buildInlineComparablesSection(BuildContext context, DocumentWorkspaceProvider provider) {
    final comparables = provider.comparables;
    final isReadOnly = provider.isReadOnly;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.deepTeal.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.deepTeal.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.compare_arrows_rounded, color: AppColors.deepTeal, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'COMPARABLE SALES GRID',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.deepTeal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('<<COMPARABLES_TABLE>>', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.deepTeal)),
                    ),
                  ],
                ),
                if (!isReadOnly)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('+ Add Comparable'),
                    onPressed: () => provider.addComparableItem(),
                  ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 850,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: AppColors.surfaceSoft,
                    child: Row(
                      children: const [
                        SizedBox(width: 44, child: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                        Expanded(flex: 4, child: Text('Location / Property Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Area (Sq.Ft)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Rate / Sq.Ft (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 3, child: Text('Sale Value (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
                        SizedBox(width: 44),
                      ],
                    ),
                  ),
                  if (comparables.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      alignment: Alignment.center,
                      child: Text(
                        'No comparable sales recorded. Click "+ Add Comparable" above to add records.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ...comparables.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairlineSoft))),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text('${idx + 1}', style: GoogleFonts.firaCode(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted), textAlign: TextAlign.center),
                          ),
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              initialValue: item.location,
                              enabled: !isReadOnly,
                              decoration: const InputDecoration(
                                hintText: 'Location / Survey / Plot reference',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onChanged: (val) {
                                item.location = val;
                                provider.recalculateValuation();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: item.enteredArea > 0 ? IndianNumberFormatter.format(item.enteredArea, includeDecimals: item.enteredArea % 1 != 0) : '',
                              enabled: !isReadOnly,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: '0',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onChanged: (val) {
                                item.enteredArea = double.tryParse(val.replaceAll(',', '').trim()) ?? 0;
                                item.saleValue = item.enteredArea * item.rate;
                                provider.recalculateValuation();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: item.rate > 0 ? IndianNumberFormatter.format(item.rate, includeDecimals: item.rate % 1 != 0) : '',
                              enabled: !isReadOnly,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: '0',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onChanged: (val) {
                                item.rate = double.tryParse(val.replaceAll(',', '').trim()) ?? 0;
                                item.saleValue = item.enteredArea * item.rate;
                                provider.recalculateValuation();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '₹ ${IndianNumberFormatter.format(item.saleValue)}',
                              style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            child: isReadOnly
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.brandRedDark),
                                    onPressed: () => provider.removeComparableItem(idx),
                                  ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Inline Valuation: VALUE OF THE PROPERTY TABLE (Preserved Calculation) ───
  Widget _buildInlinePropertySection(BuildContext context, DocumentWorkspaceProvider provider) {
    final data = provider.valuationData;
    final landVal = data?.sayLandValue != null && data!.sayLandValue > 0 ? data.sayLandValue : (data?.totalLandValue ?? 0.0);
    final bldgVal = data?.sayBuildingValue != null && data!.sayBuildingValue > 0 ? data.sayBuildingValue : (data?.totalBuildingValue ?? 0.0);
    final fairVal = data?.fairValue ?? 0.0;
    final sayVal = data?.fairValue ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'VALUE OF THE PROPERTY',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('<<PROPERTY_VALUE_TABLE>>', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(5.5),
                1: FlexColumnWidth(4.5),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: AppColors.surfaceSoft, border: Border(bottom: BorderSide(color: AppColors.hairlineSoft))),
                  children: [
                    Padding(padding: const EdgeInsets.all(10), child: Text('Particulars', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold))),
                    Padding(padding: const EdgeInsets.all(10), child: Text('Amount (₹)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ),
                TableRow(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairlineSoft))),
                  children: [
                    Padding(padding: const EdgeInsets.all(10), child: Text('Value of Land (Say Land)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
                    Padding(padding: const EdgeInsets.all(10), child: Text('₹ ${IndianNumberFormatter.format(landVal)}', style: GoogleFonts.firaCode(fontSize: 14, fontWeight: FontWeight.bold))),
                  ],
                ),
                TableRow(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairlineSoft))),
                  children: [
                    Padding(padding: const EdgeInsets.all(10), child: Text('Value of Buildings (Say Bldg)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
                    Padding(padding: const EdgeInsets.all(10), child: Text('₹ ${IndianNumberFormatter.format(bldgVal)}', style: GoogleFonts.firaCode(fontSize: 14, fontWeight: FontWeight.bold))),
                  ],
                ),
                TableRow(
                  decoration: BoxDecoration(color: AppColors.surfaceSoft, border: const Border(bottom: BorderSide(color: AppColors.hairlineSoft))),
                  children: [
                    Padding(padding: const EdgeInsets.all(10), child: Text('Total', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary))),
                    Padding(padding: const EdgeInsets.all(10), child: Text('₹ ${IndianNumberFormatter.format(fairVal)}', style: GoogleFonts.firaCode(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary))),
                  ],
                ),
                TableRow(
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05)),
                  children: [
                    Padding(padding: const EdgeInsets.all(10), child: Text('Say', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink))),
                    Padding(padding: const EdgeInsets.all(10), child: Text('₹ ${IndianNumberFormatter.format(sayVal)}', style: GoogleFonts.firaCode(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.successAccent))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Inline Valuation: 4-Column VALUATION SUMMARY & CONTROLS ───────────────
  Widget _buildInlineSummarySection(BuildContext context, DocumentWorkspaceProvider provider) {
    final data = provider.valuationData;
    if (data == null) return const SizedBox.shrink();
    final isReadOnly = provider.isReadOnly;

    final insurableVal = data.insurableValue > 0 ? data.insurableValue : data.totalReplacementCost;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.deepTeal.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.deepTeal.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.successAccent, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'SUMMARY OF VALUATION',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.deepTeal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('<<VALUATION_SUMMARY_TABLE>>', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.deepTeal)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Summary Controls (Separate Realizable %, Separate Distress %, Statutory Govt Override)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF7FAFB),
              border: Border(bottom: BorderSide(color: AppColors.hairlineSoft)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VALUATION CONTROLS & OVERRIDES',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.deepTeal, letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: data.landRealizablePercentage.toString(),
                        enabled: !isReadOnly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Land Realizable %',
                          suffixText: '%',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val.replaceAll('%', '').trim()) ?? 85.0;
                          provider.setLandRealizablePercentage(parsed);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: data.buildingRealizablePercentage.toString(),
                        enabled: !isReadOnly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Bldg Realizable %',
                          suffixText: '%',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val.replaceAll('%', '').trim()) ?? 85.0;
                          provider.setBuildingRealizablePercentage(parsed);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: data.landDistressPercentage.toString(),
                        enabled: !isReadOnly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Land Distress %',
                          suffixText: '%',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val.replaceAll('%', '').trim()) ?? 75.0;
                          provider.setLandDistressPercentage(parsed);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: data.buildingDistressPercentage.toString(),
                        enabled: !isReadOnly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Bldg Distress %',
                          suffixText: '%',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val.replaceAll('%', '').trim()) ?? 75.0;
                          provider.setBuildingDistressPercentage(parsed);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: data.governmentValue > 0 ? IndianNumberFormatter.format(data.governmentValue, includeDecimals: true) : '',
                        enabled: !isReadOnly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Statutory Government Guideline Value (₹)',
                          prefixText: '₹ ',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val.replaceAll(',', '').trim()) ?? 0.0;
                          provider.setGovernmentValue(parsed);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Separate percentages and statutory government guideline value apply directly to the 4-column summary table below in real time.',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4-Column Live Valuation Summary Grid Table matching DOCX output
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.hairlineSoft),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3494BA),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
                    ),
                    child: Row(
                      children: const [
                        Expanded(flex: 3, child: Text('VALUATION PARAMETER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white))),
                        Expanded(flex: 2, child: Text('LAND (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white), textAlign: TextAlign.right)),
                        Expanded(flex: 2, child: Text('BUILDING (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white), textAlign: TextAlign.right)),
                        Expanded(flex: 2, child: Text('TOTAL (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white), textAlign: TextAlign.right)),
                      ],
                    ),
                  ),
                  // Row 1: Fair Value (Say Land + Say Bldg)
                  _buildInlineSummaryTableRow(
                    'Fair Market Value (Say Land + Say Bldg)',
                    '₹ ${IndianNumberFormatter.format(data.sayLandValue)}',
                    '₹ ${IndianNumberFormatter.format(data.sayBuildingValue)}',
                    '₹ ${IndianNumberFormatter.format(data.fairValue)}',
                    isHighlight: true,
                  ),
                  const Divider(height: 1),
                  // Row 2: Realizable Value
                  _buildInlineSummaryTableRow(
                    'Realizable Value (${data.landRealizablePercentage}% Land, ${data.buildingRealizablePercentage}% Bldg)',
                    '₹ ${IndianNumberFormatter.format(data.landRealizableValue)}',
                    '₹ ${IndianNumberFormatter.format(data.buildingRealizableValue)}',
                    '₹ ${IndianNumberFormatter.format(data.realizableValue)}',
                  ),
                  const Divider(height: 1),
                  // Row 3: Distress Sale Value
                  _buildInlineSummaryTableRow(
                    'Distress Sale Value (${data.landDistressPercentage}% Land, ${data.buildingDistressPercentage}% Bldg)',
                    '₹ ${IndianNumberFormatter.format(data.landDistressValue)}',
                    '₹ ${IndianNumberFormatter.format(data.buildingDistressValue)}',
                    '₹ ${IndianNumberFormatter.format(data.distressSaleValue)}',
                  ),
                  const Divider(height: 1),
                  // Row 4: Government Value
                  _buildInlineSummaryTableRow(
                    'Government / Guideline Value',
                    '₹ ${IndianNumberFormatter.format(data.landGovernmentValue)}',
                    '₹ ${IndianNumberFormatter.format(data.buildingGovernmentValue)}',
                    '₹ ${IndianNumberFormatter.format(data.governmentValue)}',
                    isHighlight: true,
                  ),
                  const Divider(height: 1),
                  // Row 5: Insurable Value
                  _buildInlineSummaryTableRow(
                    'Insurable Value (Replacement Cost)',
                    'N/A',
                    '₹ ${IndianNumberFormatter.format(insurableVal)}',
                    '₹ ${IndianNumberFormatter.format(insurableVal)}',
                  ),
                ],
              ),
            ),
          ),

          // Total in words footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildSummaryDetailRow(
              'Total Fair Market Value (in words):',
              '₹ ${IndianNumberFormatter.format(data.fairValue)}',
              IndianCurrencyToWords.convertToWords(data.fairValue),
              isHighlight: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineSummaryTableRow(String label, String land, String bldg, String total, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isHighlight ? const Color(0xFFF3F9FA) : Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
                color: isHighlight ? AppColors.primary : AppColors.ink,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              land,
              style: GoogleFonts.firaCode(fontSize: 12, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              bldg,
              style: GoogleFonts.firaCode(fontSize: 12, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              total,
              style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: isHighlight ? AppColors.primary : AppColors.ink),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDetailRow(String label, String value, String words, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                  fontSize: isHighlight ? 14 : 12,
                  color: isHighlight ? AppColors.primary : AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: GoogleFonts.firaCode(
                fontWeight: FontWeight.bold,
                fontSize: isHighlight ? 16 : 13,
                color: isHighlight ? AppColors.primary : AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(words, style: GoogleFonts.merriweather(fontStyle: FontStyle.italic, fontSize: 11, color: AppColors.slate)),
      ],
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
