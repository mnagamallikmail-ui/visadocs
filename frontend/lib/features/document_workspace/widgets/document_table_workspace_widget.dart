import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/indian_number_formatter.dart';
import '../../../utils/indian_currency_to_words.dart';
import '../../document_studio/models/studio_document_model.dart';
import '../models/workspace_view_model.dart';
import '../models/valuation_models.dart';
import '../services/valuation_calculator.dart';
import '../services/value_normalization_engine.dart';
import '../providers/document_workspace_provider.dart';
import 'document_input_slot_widget.dart';
import 'inline_editable_placeholder_widget.dart';


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
    } else if (block is ValuationCompositeBlockVm) {
      return _buildInlineCompositeSection(context, provider);
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
        color: AppColors.workspacePanel,
        borderRadius: AppRadius.br8,
        border: Border.all(color: AppColors.workspaceBorder),
        boxShadow: AppShadows.subtleElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.workspaceSegmentBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(7.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.landscape_rounded, color: AppColors.workspaceCorporateNavy, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'VALUE OF LAND',
                      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.workspacePrimaryText),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.workspaceCanvas,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.workspaceBorder),
                      ),
                      child: Text('<<LAND_TABLE>>', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.workspaceSecondaryText)),
                    ),
                  ],
                ),
                if (!isReadOnly)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.workspaceCorporateNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.br8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600),
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
        color: AppColors.workspacePanel,
        borderRadius: AppRadius.br8,
        border: Border.all(color: AppColors.workspaceBorder),
        boxShadow: AppShadows.subtleElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.workspaceSegmentBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(7.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.apartment_rounded, color: AppColors.workspaceCorporateNavy, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'VALUE OF BUILDING',
                      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.workspacePrimaryText),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.workspaceCanvas,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.workspaceBorder),
                      ),
                      child: const Text('<<BUILDING_TABLE>>', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.workspaceSecondaryText)),
                    ),
                  ],
                ),
                if (!isReadOnly)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.workspaceCorporateNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.br8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600),
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
        color: AppColors.workspacePanel,
        borderRadius: AppRadius.br8,
        border: Border.all(color: AppColors.workspaceBorder),
        boxShadow: AppShadows.subtleElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.workspaceSegmentBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(7.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.compare_arrows_rounded, color: AppColors.workspaceCorporateNavy, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'COMPARABLE SALES GRID',
                      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.workspacePrimaryText),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.workspaceCanvas,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.workspaceBorder),
                      ),
                      child: Text('<<COMPARABLES_TABLE>>', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.workspaceSecondaryText)),
                    ),
                  ],
                ),
                if (!isReadOnly)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.workspaceCorporateNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.br8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600),
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
        color: AppColors.workspacePanel,
        borderRadius: AppRadius.br8,
        border: Border.all(color: AppColors.workspaceBorder),
        boxShadow: AppShadows.subtleElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.workspaceSegmentBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(7.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: AppColors.workspaceCorporateNavy, size: 20),
                const SizedBox(width: 8),
                Text(
                  'VALUE OF THE PROPERTY',
                  style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.workspacePrimaryText),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.workspaceCanvas,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.workspaceBorder),
                  ),
                  child: Text('<<PROPERTY_VALUE_TABLE>>', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.workspaceSecondaryText)),
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
        color: AppColors.workspacePanel,
        borderRadius: AppRadius.br8,
        border: Border.all(color: AppColors.workspaceBorder),
        boxShadow: AppShadows.subtleElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.workspaceSegmentBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(7.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.workspaceSuccess, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'SUMMARY OF VALUATION',
                        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.workspacePrimaryText),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.workspaceCanvas,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.workspaceBorder),
                        ),
                        child: Text('<<VALUATION_SUMMARY_TABLE>>', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.workspaceSecondaryText)),
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

  // ─── Inline Valuation: COMPOSITE_PROPERTY_TABLE (Interactive Editor) ────────
  Widget _buildInlineCompositeSection(BuildContext context, DocumentWorkspaceProvider provider) {
    provider.ensureCompositeMainUnit();
    final compItems = provider.compositeItems.isNotEmpty
        ? provider.compositeItems
        : [
            ValuationCompositeItemModel(
              itemCategory: 'MAIN_UNIT',
              description: 'Main Unit',
              enteredUnit: 'Sq.Ft',
              quantity: 1000.0,
              rate: 0.0,
              sortOrder: 0,
            ),
          ];
    final data = provider.valuationData ?? ValuationDataModel(orderId: 0, valuationMethodology: 'COMPOSITE');
    final isReadOnly = provider.isReadOnly;


    final rawFairVal = data.rawFairValue;
    final sayFairVal = data.sayFairValue > 0 ? data.sayFairValue : ValuationCalculator.computeSayValue(rawFairVal);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.workspacePanel,
        borderRadius: AppRadius.br8,
        border: Border.all(color: AppColors.workspaceBorder),
        boxShadow: AppShadows.subtleElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.workspaceSegmentBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(7.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.apartment_rounded, color: AppColors.workspaceCorporateNavy, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'COMPOSITE PROPERTY VALUATION',
                        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.workspacePrimaryText),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.workspaceCanvas,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.workspaceBorder),
                        ),
                        child: Text(
                          '<<COMPOSITE_PROPERTY_TABLE>>',
                          style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.workspaceSecondaryText),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ONE SINGLE COMPOSITE VALUATION TABLE
                _buildUnifiedCompositeTable(context, compItems, data, isReadOnly, provider),
                const SizedBox(height: 20),

                // 2. Valuation Parameters Summary Card (Consumes Say Value)
                _buildCompositeSummaryCard(context, data, sayFairVal, isReadOnly, provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ONE SINGLE COMPOSITE PROPERTY VALUATION TABLE
  /// Holds Row 1: Main Unit / Flat, Row 2: Interior Works, Row 3: Parking,
  /// followed by TOTAL VALUATION row and SAY VALUE footer in the SAME TABLE.
  Widget _buildUnifiedCompositeTable(
    BuildContext context,
    List<ValuationCompositeItemModel> items,
    ValuationDataModel data,
    bool isReadOnly,
    DocumentWorkspaceProvider provider,
  ) {
    ValuationCompositeItemModel? mainUnit;
    for (final item in items) {
      if (item.itemCategory.toUpperCase() == 'MAIN_UNIT') {
        mainUnit = item;
        break;
      }
    }
    mainUnit ??= items.isNotEmpty ? items.first : ValuationCompositeItemModel(itemCategory: 'MAIN_UNIT', quantity: 1000, rate: 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.hairlineSoft),
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppShadows.subtleElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Column Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1A3B5C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: const [
                SizedBox(width: 35, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white), textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text('ITEM DESCRIPTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white))),
                SizedBox(width: 8),
                Expanded(flex: 2, child: Text('QTY / AREA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white))),
                SizedBox(width: 8),
                SizedBox(width: 70, child: Text('UNIT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white), textAlign: TextAlign.center)),
                SizedBox(width: 8),
                Expanded(flex: 2, child: Text('RATE (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white), textAlign: TextAlign.right)),
                SizedBox(width: 8),
                Expanded(flex: 2, child: Text('AMOUNT (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white), textAlign: TextAlign.right)),
                SizedBox(width: 8),
                Expanded(flex: 2, child: Text('DEPRECIATION (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white), textAlign: TextAlign.right)),
                SizedBox(width: 8),
                Expanded(flex: 2, child: Text('FAIR VALUE (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white), textAlign: TextAlign.right)),
                SizedBox(width: 8),
                SizedBox(width: 45, child: Text('ACT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white), textAlign: TextAlign.center)),
              ],
            ),
          ),

          // Table Rows
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isMainUnit = item.itemCategory.toUpperCase() == 'MAIN_UNIT';
            final isParking = item.itemCategory.toUpperCase() == 'PARKING';

            if (isMainUnit) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFBFDFF),
                  border: Border(bottom: BorderSide(color: AppColors.hairlineSoft)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 35, child: Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: item.description.isNotEmpty ? item.description : 'Main Unit / Flat',
                            enabled: !isReadOnly,
                            decoration: const InputDecoration(
                              hintText: 'Unit Description (e.g. Flat No / Floor)',
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            ),
                            onChanged: (val) {
                              item.description = val;
                              provider.recalculateValuation();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Authoritative SALEABLE_AREA driver
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            key: const ValueKey('main_unit_saleable_area_input'),
                            initialValue: provider.getValue('SALEABLE_AREA').isNotEmpty
                                ? provider.getValue('SALEABLE_AREA')
                                : (item.quantity > 0 ? ValueNormalizationEngine.formatNormalizedString(item.quantity) : ''),
                            enabled: !isReadOnly,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: '<<SALEABLE_AREA>>',
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            ),
                            onChanged: (val) {
                              provider.updateValue('SALEABLE_AREA', val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            provider.getValue('SALEABLE_AREA_UNIT').isNotEmpty ? provider.getValue('SALEABLE_AREA_UNIT') : item.enteredUnit,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Authoritative MARKET_RATE_FLAT driver
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            key: const ValueKey('main_unit_market_rate_input'),
                            initialValue: provider.getValue('MARKET_RATE_FLAT').isNotEmpty
                                ? provider.getValue('MARKET_RATE_FLAT')
                                : (item.rate > 0 ? ValueNormalizationEngine.formatNormalizedString(item.rate) : ''),
                            enabled: !isReadOnly,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: '<<MARKET_RATE_FLAT>>',
                              prefixText: '₹ ',
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            ),
                            onChanged: (val) {
                              provider.updateValue('MARKET_RATE_FLAT', val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Amount = SALEABLE_AREA * MARKET_RATE_FLAT
                        Expanded(
                          flex: 2,
                          child: Text(
                            provider.getValue('UNIT_AMOUNT').isNotEmpty
                                ? '₹ ${provider.getValue('UNIT_AMOUNT')}'
                                : '₹ ${IndianNumberFormatter.format(item.amount)}',
                            style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Depreciation = Area * Cost * (Age / Life) * 90%
                        Expanded(
                          flex: 2,
                          child: Text(
                            provider.getValue('MAIN_UNIT_DEPRECIATION').isNotEmpty
                                ? '₹ ${provider.getValue('MAIN_UNIT_DEPRECIATION')}'
                                : '₹ ${IndianNumberFormatter.format(item.depreciationAmount)}',
                            style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD46B08)),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // MAIN_UNIT_FAIR_VALUE = UNIT_AMOUNT - MAIN_UNIT_DEPRECIATION (Protected: Never reads FAIR_VALUE)
                        Expanded(
                          flex: 2,
                          child: Text(
                            provider.getValue('MAIN_UNIT_FAIR_VALUE').isNotEmpty
                                ? '₹ ${provider.getValue('MAIN_UNIT_FAIR_VALUE')}'
                                : '₹ ${IndianNumberFormatter.format(item.fairValue)}',
                            style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF096DD9)),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 45,
                          child: Center(
                            child: Icon(Icons.verified, size: 18, color: Color(0xFF3494BA)),
                          ),
                        ),
                      ],
                    ),

                    // Inline Formula Parameters Bar for Main Unit Depreciation
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F9FD),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF3494BA).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calculate_outlined, size: 14, color: Color(0xFF3494BA)),
                              const SizedBox(width: 4),
                              Text(
                                'Depreciation Drivers: ',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF3494BA)),
                              ),
                              Text(
                                '<<SALEABLE_AREA>> × Cost × (Age/Life) × 90%',
                                style: GoogleFonts.firaCode(fontSize: 10, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.constructionCost > 0 ? item.constructionCost.toString() : '2000',
                              enabled: !isReadOnly,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Construction Cost (₹/Sq.Ft)',
                                prefixText: '₹ ',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              ),
                              onChanged: (val) {
                                provider.updateValue('COMPOSITE_CONSTRUCTION_COST', val);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.buildingAge > 0 ? item.buildingAge.toString() : '0',
                              enabled: !isReadOnly,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Age (Years)',
                                suffixText: 'Yrs',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              ),
                              onChanged: (val) {
                                provider.updateValue('COMPOSITE_BUILDING_AGE', val);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.totalLife > 0 ? item.totalLife.toString() : '60',
                              enabled: !isReadOnly,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Useful Life (Years)',
                                suffixText: 'Yrs',
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              ),
                              onChanged: (val) {
                                provider.updateValue('COMPOSITE_BUILDING_TOTAL_LIFE', val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else if (isParking) {
              // Parking Row: QUANTITY * RATE, editable unit (Slot, No, LS, Sq.Ft, Bay)
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.hairlineSoft)),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 35, child: Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: item.description.isNotEmpty ? item.description : 'Car Parking',
                        enabled: !isReadOnly,
                        decoration: const InputDecoration(
                          hintText: 'Parking Description',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                        initialValue: item.quantity > 0 ? item.quantity.toString() : '1',
                        enabled: !isReadOnly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Qty / Slots',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                        onChanged: (val) {
                          item.quantity = double.tryParse(val.replaceAll(',', '').trim()) ?? 1.0;
                          item.amount = item.quantity * item.rate;
                          provider.recalculateValuation();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      child: TextFormField(
                        initialValue: item.enteredUnit.isNotEmpty ? item.enteredUnit : 'Slot',
                        enabled: !isReadOnly,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: 'Slot/No',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        ),
                        onChanged: (val) {
                          item.enteredUnit = val;
                          provider.recalculateValuation();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: item.rate > 0 ? item.rate.toString() : '',
                        enabled: !isReadOnly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Rate / Slot',
                          prefixText: '₹ ',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                        onChanged: (val) {
                          item.rate = double.tryParse(val.replaceAll(',', '').trim()) ?? 0.0;
                          item.amount = item.quantity * item.rate;
                          provider.recalculateValuation();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₹ ${IndianNumberFormatter.format(item.amount)}',
                        style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: item.depreciationAmount > 0 ? item.depreciationAmount.toString() : '0',
                        enabled: !isReadOnly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          prefixText: '₹ ',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                        onChanged: (val) {
                          item.depreciationAmount = double.tryParse(val.replaceAll(',', '').trim()) ?? 0.0;
                          provider.recalculateValuation();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₹ ${IndianNumberFormatter.format(item.fairValue)}',
                        style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 45,
                      child: !isReadOnly
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              onPressed: () {
                                final origIdx = provider.compositeItems.indexOf(item);
                                if (origIdx > 0) {
                                  provider.removeCompositeItem(origIdx);
                                }
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            } else {
              // Interior Works Row: User entered amount, user entered depreciation
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.hairlineSoft)),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 35, child: Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: item.description.isNotEmpty ? item.description : 'Interior Works & Improvements',
                        enabled: !isReadOnly,
                        decoration: const InputDecoration(
                          hintText: 'Description',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                        initialValue: item.quantity > 0 ? item.quantity.toString() : '1',
                        enabled: !isReadOnly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                        onChanged: (val) {
                          item.quantity = double.tryParse(val.replaceAll(',', '').trim()) ?? 1.0;
                          provider.recalculateValuation();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      child: TextFormField(
                        initialValue: item.enteredUnit.isNotEmpty ? item.enteredUnit : 'LS',
                        enabled: !isReadOnly,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: 'LS',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        ),
                        onChanged: (val) {
                          item.enteredUnit = val;
                          provider.recalculateValuation();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: item.rate > 0 ? item.rate.toString() : '',
                        enabled: !isReadOnly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Rate',
                          prefixText: '₹ ',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                        onChanged: (val) {
                          final r = double.tryParse(val.replaceAll(',', '').trim()) ?? 0.0;
                          item.rate = r;
                          if (r > 0 && item.quantity > 0) item.amount = item.quantity * r;
                          provider.recalculateValuation();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // User Entered Interior Amount
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: item.amount > 0 ? item.amount.toString() : '',
                        enabled: !isReadOnly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹)',
                          prefixText: '₹ ',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                        onChanged: (val) {
                          final amt = double.tryParse(val.replaceAll(',', '').trim()) ?? 0.0;
                          item.amount = amt;
                          if (item.rate <= 0) item.rate = amt;
                          provider.recalculateValuation();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // User Entered Interior Depreciation (Affects ONLY INTERIOR_FAIR_VALUE)
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: item.depreciationAmount > 0 ? item.depreciationAmount.toString() : '0',
                        enabled: !isReadOnly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Depr (₹)',
                          prefixText: '₹ ',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                        onChanged: (val) {
                          item.depreciationAmount = double.tryParse(val.replaceAll(',', '').trim()) ?? 0.0;
                          item.depreciationMode = 'DIRECT_AMOUNT';
                          provider.recalculateValuation();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // INTERIOR_FAIR_VALUE = Amount - Depreciation
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₹ ${IndianNumberFormatter.format(item.fairValue)}',
                        style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 45,
                      child: !isReadOnly
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              onPressed: () {
                                final origIdx = provider.compositeItems.indexOf(item);
                                if (origIdx > 0) {
                                  provider.removeCompositeItem(origIdx);
                                }
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            }
          }),

          // Action Buttons Toolbar for adding rows
          if (!isReadOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF9FBFC),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('+ Add Interior Row', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3494BA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => provider.addCompositeInteriorItem(),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.directions_car_outlined, size: 14),
                    label: const Text('+ Add Parking Row', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3B5C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => provider.addCompositeParkingItem(),
                  ),
                ],
              ),
            ),

          // TOTAL VALUATION ROW (in the SAME table)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F9FA),
              border: Border(top: BorderSide(color: AppColors.hairlineSoft, width: 1.5)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 35),
                Expanded(
                  flex: 3,
                  child: Text(
                    'TOTAL VALUATION',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1A3B5C)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: const SizedBox.shrink()),
                const SizedBox(width: 8),
                const SizedBox(width: 70),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: const SizedBox.shrink()),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    provider.getValue('TOTAL_AMOUNT').isNotEmpty
                        ? '₹ ${provider.getValue('TOTAL_AMOUNT')}'
                        : '₹ ${IndianNumberFormatter.format(data.totalAmount)}',
                    style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    provider.getValue('TOTAL_DEPRECIATION').isNotEmpty
                        ? '₹ ${provider.getValue('TOTAL_DEPRECIATION')}'
                        : '₹ ${IndianNumberFormatter.format(data.totalDepreciation)}',
                    style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFD46B08)),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    provider.getValue('TOTAL_FAIR_VALUE').isNotEmpty
                        ? '₹ ${provider.getValue('TOTAL_FAIR_VALUE')}'
                        : '₹ ${IndianNumberFormatter.format(data.totalFairValue)}',
                    style: GoogleFonts.firaCode(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF3494BA)),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(width: 45),
              ],
            ),
          ),

          // SAY VALUE ROW (in the SAME table footer)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.hairlineSoft)),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(7)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'SAY VALUE (Rounded)',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7FF),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF91D5FF)),
                          ),
                          child: const Text('<<SAY_VALUE>>', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF096DD9))),
                        ),
                      ],
                    ),
                    Text(
                      provider.getValue('SAY_VALUE').isNotEmpty
                          ? '₹ ${provider.getValue('SAY_VALUE')}'
                          : '₹ ${IndianNumberFormatter.format(data.sayFairValue)}',
                      style: GoogleFonts.firaCode(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.successAccent),
                    ),
                  ],
                ),
                if (provider.getValue('SAY_VALUE_WORDS').isNotEmpty || provider.getValue('FAIR_VALUE_WORDS').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '(Rupees ${provider.getValue('SAY_VALUE_WORDS').isNotEmpty ? provider.getValue('SAY_VALUE_WORDS') : provider.getValue('FAIR_VALUE_WORDS')} Only)',
                      style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompositeSummaryCard(BuildContext context, ValuationDataModel data, double sayFairVal, bool isReadOnly, DocumentWorkspaceProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3494BA).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF3494BA).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'VALUATION PARAMETERS SUMMARY',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF3494BA), letterSpacing: 0.5),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF3494BA).withValues(alpha: 0.3)),
                  ),
                  child: const Text('Consumes Say Value as Fair Value', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF3494BA))),
                ),
              ],
            ),
          ),

          // Controls & Overrides Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.hairlineSoft)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: data.realizablePercentage.toString(),
                    enabled: !isReadOnly,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Realizable %',
                      suffixText: '%',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val.replaceAll('%', '').trim()) ?? 85.0;
                      provider.setRealizablePercentage(parsed);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: data.distressSalePercentage.toString(),
                    enabled: !isReadOnly,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Distress Sale %',
                      suffixText: '%',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val.replaceAll('%', '').trim()) ?? 75.0;
                      provider.setDistressSalePercentage(parsed);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: data.compositeGovernmentRate > 0 ? data.compositeGovernmentRate.toString() : '',
                    enabled: !isReadOnly,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Govt Composite Rate (₹/Sq.Ft)',
                      prefixText: '₹ ',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val.replaceAll(',', '').trim()) ?? 0.0;
                      provider.setCompositeGovernmentRate(parsed);
                    },
                  ),
                ),
              ],
            ),
          ),

          // 2-Column Summary Table
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.hairlineSoft),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3494BA),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('VALUATION PARAMETER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                        Text('AMOUNT (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                      ],
                    ),
                  ),
                  // Row 1: Fair Value (Say Value)
                  _buildCompositeSummaryRow('Fair Value', '₹ ${IndianNumberFormatter.format(sayFairVal)}', isHighlight: true),
                  const Divider(height: 1),
                  // Row 2: Realizable Value
                  _buildCompositeSummaryRow('Realizable Value (${data.realizablePercentage.toStringAsFixed(1)}%)', '₹ ${IndianNumberFormatter.format(data.realizableValue)}'),
                  const Divider(height: 1),
                  // Row 3: Distress Sale Value
                  _buildCompositeSummaryRow('Distress Sale Value (${data.distressSalePercentage.toStringAsFixed(1)}%)', '₹ ${IndianNumberFormatter.format(data.distressSaleValue)}'),
                  const Divider(height: 1),
                  // Row 4: Government Value
                  _buildCompositeSummaryRow('Government Value (Area × Govt Rate)', '₹ ${IndianNumberFormatter.format(data.governmentValue)}', isHighlight: true),
                  const Divider(height: 1),
                  // Row 5: Insurable Value
                  _buildCompositeSummaryRow('Insurable Value (Area × Cost + Insurable Interiors)', '₹ ${IndianNumberFormatter.format(data.insurableValue)}'),
                ],
              ),
            ),
          ),

          // Total in words
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fair Value (in words):',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                ),
                const SizedBox(height: 2),
                Text(
                  IndianCurrencyToWords.convertToWords(sayFairVal),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF3494BA)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompositeSummaryRow(String label, String amount, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isHighlight ? const Color(0xFFF3F9FA) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
              color: isHighlight ? const Color(0xFF3494BA) : AppColors.ink,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.firaCode(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isHighlight ? const Color(0xFF3494BA) : AppColors.ink,
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
    final rawTitle = section.title.trim();
    // Strip redundant leading numbers such as "1. " so "1. General Document" doesn't repeat "SECTION 1"
    final cleanTitle = rawTitle.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '').trim();

    return Container(
      margin: EdgeInsets.only(bottom: isContinuous ? 6 : 10, top: isContinuous ? 6 : 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.workspacePanel,
        borderRadius: AppRadius.br8,
        border: Border.all(color: AppColors.workspaceBorder),
        boxShadow: AppShadows.subtleElevated,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.workspaceSegmentBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'SECTION ${section.sectionIndex + 1}',
              style: GoogleFonts.montserrat(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.workspaceSecondaryText,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cleanTitle.isNotEmpty ? cleanTitle : rawTitle,
              style: AppTypography.workspaceSectionTitle(),
            ),
          ),
          if (isReadOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.workspaceSegmentBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'READ-ONLY',
                style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.workspaceSecondaryText),
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
            style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.workspaceSecondaryText),
          ),
        ),
      ),
    );
  }

  Color _parseHexColor(String hexStr) {
    try {
      final clean = hexStr.replaceFirst('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return AppColors.workspacePrimaryText;
  }

  Widget _buildParagraphBlock(BuildContext context, ParagraphBlockVm block, bool readOnly) {
    // ── Document-Native Paragraph Rendering (WYSIWYG Inline Placeholders & Reflow) ──
    if (block.hasNodes) {
      final spans = <InlineSpan>[];
      final imageWidgets = <Widget>[];

      int placeholderIdx = 0;
      for (final node in block.nodes) {
        if (node is TextRunNode) {
          spans.add(TextSpan(
            text: node.text,
            style: GoogleFonts.montserrat(
              fontSize: node.fontSizePt,
              fontWeight: node.isBold ? FontWeight.w700 : FontWeight.w400,
              fontStyle: node.isItalic ? FontStyle.italic : FontStyle.normal,
              color: node.fontColor != null ? _parseHexColor(node.fontColor!) : AppColors.workspacePrimaryText,
              height: 1.65,
            ),
          ));
        } else if (node is PlaceholderRunNode) {
          if (node.fieldVm.isCompositeTable) {
            final provider = context.read<DocumentWorkspaceProvider>();
            imageWidgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildInlineCompositeSection(context, provider),
              ),
            );
            continue;
          }
          if (node.fieldVm.isImage) {
            imageWidgets.add(
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: DocumentInputSlotWidget(fieldVm: node.fieldVm, readOnly: readOnly),
              ),
            );
            continue;
          }
          final instanceId = '${block.id}_${node.key}_${placeholderIdx++}';
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            baseline: TextBaseline.alphabetic,
            child: InlineEditablePlaceholderWidget(
              instanceId: instanceId,
              fieldVm: node.fieldVm,
              readOnly: readOnly,
              textStyle: GoogleFonts.montserrat(
                fontSize: node.fontSizePt,
                fontWeight: node.isBold ? FontWeight.w700 : FontWeight.w600,
                fontStyle: node.isItalic ? FontStyle.italic : FontStyle.normal,
                color: AppColors.workspaceCorporateNavy,
              ),
            ),
          ));
        } else if (node is ImageRunNode) {
          imageWidgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: DocumentInputSlotWidget(fieldVm: node.fieldVm, readOnly: readOnly),
            ),
          );
        }
      }

      if (spans.isEmpty && imageWidgets.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.br8,
          border: Border.all(color: AppColors.workspaceBorder),
          boxShadow: AppShadows.subtleElevated,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (spans.isNotEmpty)
              Text.rich(
                TextSpan(children: spans),
                textAlign: block.textAlign, // Preserves template alignment: LEFT, CENTER, RIGHT, JUSTIFY
              ),
            if (imageWidgets.isNotEmpty) ...imageWidgets,
          ],
        ),
      );
    }


    // Static text fallback
    final text = block.staticText ?? block.rawText ?? '';
    if (text.isEmpty || text.length <= 1 || text == '_' || text == 'n' || text == 'r') {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.br8,
        border: Border.all(color: AppColors.workspaceBorder),
        boxShadow: AppShadows.subtleElevated,
      ),
      child: Text(
        text,
        textAlign: block.textAlign,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          color: AppColors.workspacePrimaryText,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildTableCard(BuildContext context, TableVm tableVm, bool readOnly) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.workspacePanel,
        borderRadius: AppRadius.br8,
        border: Border.all(color: AppColors.workspaceBorder),
        boxShadow: AppShadows.subtleElevated,
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

    // Dedicated Composite Table Routing:
    // If this row contains the <<COMPOSITE_PROPERTY_TABLE>> placeholder, route directly to composite table renderer
    if (rowVm.hasCompositeTable) {
      final provider = context.read<DocumentWorkspaceProvider>();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _buildInlineCompositeSection(context, provider),
      );
    }

    // Dedicated Mixed Narrative Inside Table Cells Routing (Document-Native WYSIWYG):
    // If any cell in this row contains mixed text + placeholders (e.g. "Dear <<BANK_NAME>>, Property owned by <<OWNER_NAME>>..."),
    // preserve document flow using Text.rich and WidgetSpan instead of Question-Answer layout.
    if (rowVm.rawCells.any((c) => _isMixedContentCell(c))) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.workspaceBorder.withValues(alpha: 0.6), width: isLast ? 0 : 0.8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final cell in rowVm.rawCells)
              Expanded(
                flex: cell.colSpan > 0 ? cell.colSpan : 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildTableCell(context, cell, rowVm, readOnly),
                ),
              ),
          ],
        ),
      );
    }

    // 1. Merged Section Sub-header / Category Heading Row (STRICT: ALWAYS LEFT ALIGNED, SAME LEFT BOUNDARY)
    if (rowVm.isSectionHeadingRow) {
      final title = (rowVm.questionText != null && rowVm.questionText!.isNotEmpty)
          ? rowVm.questionText!
          : (rowVm.rawCells.isNotEmpty
              ? rowVm.rawCells.map((c) => c.plainText.trim()).where((t) => t.isNotEmpty).join(' ')
              : 'Sub-section');
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.workspaceSegmentBg,
          border: Border(bottom: BorderSide(color: AppColors.workspaceBorder, width: isLast ? 0 : 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (rowVm.serialNo != null && rowVm.serialNo!.isNotEmpty) ...[
              SizedBox(
                width: 48,
                child: Center(
                  child: Text(
                    rowVm.serialNo!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.workspaceSecondaryText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.left, // STRICT: ALWAYS LEFT ALIGNED
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.workspacePrimaryText,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      );
    }


    // 2. Table Column Header Row (STRICT FIXED GRID: Column 1=48, Column 2=flex 5, Column 3=flex 6)
    if (rowVm.isTableHeader) {
      final cells = rowVm.rawCells;
      String col1Text = 'No.';
      String col2Text = 'Description';
      String col3Text = 'Value';

      if (cells.length >= 3) {
        if (cells[0].plainText.isNotEmpty) col1Text = cells[0].plainText;
        if (cells[1].plainText.isNotEmpty) col2Text = cells[1].plainText;
        if (cells[2].plainText.isNotEmpty) col3Text = cells[2].plainText;
      } else if (cells.length == 2) {
        if (cells[0].plainText.isNotEmpty) col2Text = cells[0].plainText;
        if (cells[1].plainText.isNotEmpty) col3Text = cells[1].plainText;
      } else if (cells.length == 1) {
        if (cells[0].plainText.isNotEmpty) col2Text = cells[0].plainText;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.workspaceCanvas,
          border: Border(bottom: BorderSide(color: AppColors.workspaceBorder.withValues(alpha: 0.7), width: isLast ? 0 : 1.0)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(
                col1Text,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.workspaceSecondaryText),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: Text(
                col2Text,
                textAlign: TextAlign.left,
                style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.workspaceSecondaryText),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: Text(
                col3Text,
                textAlign: TextAlign.left,
                style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.workspaceSecondaryText),
              ),
            ),
          ],
        ),
      );
    }

    // 3. Question-Answer Row (3-Column Layout: [INDEX: 48] [QUESTION: flex 5] [ANSWER: flex 6])
    if (rowVm.is3Column) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.workspaceBorder.withValues(alpha: 0.6), width: isLast ? 0 : 0.8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // S.No — COLUMN 1: Fixed width 48
            SizedBox(
              width: 48,
              child: Center(
                child: Text(
                  rowVm.serialNo ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.workspaceSecondaryText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Question Prompt — COLUMN 2: Fixed flex 5, LEFT ALIGNED
            Expanded(
              flex: 5,
              child: _buildQuestionPrompt(rowVm),
            ),
            const SizedBox(width: 12),

            // Answer Input(s) — COLUMN 3: Fixed flex 6
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final f in rowVm.inputFields) ...[
                    DocumentInputSlotWidget(fieldVm: f, readOnly: readOnly),
                    if (rowVm.inputFields.last != f) const SizedBox(height: 4),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4. Question-Answer Row (2-Column Layout with empty Col 1: STRICT FIXED GRID)
    if (rowVm.is2Column) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.workspaceBorder.withValues(alpha: 0.6), width: isLast ? 0 : 0.8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Empty Column 1 to preserve strict fixed grid alignment across rows
            const SizedBox(width: 48),
            const SizedBox(width: 12),

            // Question Prompt — COLUMN 2: Fixed flex 5, LEFT ALIGNED
            Expanded(
              flex: 5,
              child: _buildQuestionPrompt(rowVm),
            ),
            const SizedBox(width: 12),

            // Answer Input(s) — COLUMN 3: Fixed flex 6
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final f in rowVm.inputFields) ...[
                    DocumentInputSlotWidget(fieldVm: f, readOnly: readOnly),
                    if (rowVm.inputFields.last != f) const SizedBox(height: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.workspaceCanvas.withValues(alpha: 0.6),
        border: Border(bottom: BorderSide(color: AppColors.workspaceBorder.withValues(alpha: 0.6), width: isLast ? 0 : 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              rowVm.rawCells.map((c) => c.plainText.trim()).where((t) => t.isNotEmpty).join('  '),
              textAlign: TextAlign.left,
              style: GoogleFonts.montserrat(fontSize: 11.5, color: AppColors.workspaceSecondaryText, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  bool _isMixedContentCell(StudioTableCell cell) {
    if (cell.plainText.contains('<<')) {
      final stripped = cell.plainText.replaceAll(RegExp(r'<<[^>]+>>'), '').trim();
      if (stripped.isNotEmpty) return true;
    }
    if (cell.placeholderBindings.isNotEmpty) {
      for (final p in cell.paragraphs) {
        for (final r in p.runs) {
          if (!r.isPlaceholder && r.text.trim().isNotEmpty) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Widget _buildTableCell(BuildContext context, StudioTableCell cell, TableRowVm rowVm, bool readOnly) {
    // When mixed content exists: Text + Placeholder inside a cell,
    // render using Text.rich, WidgetSpan, and InlineEditablePlaceholderWidget.
    if (_isMixedContentCell(cell)) {
      final spans = <InlineSpan>[];
      String rawText = cell.plainText;
      if (!rawText.contains('<<') && cell.paragraphs.isNotEmpty) {
        final sb = StringBuffer();
        for (final p in cell.paragraphs) {
          for (final r in p.runs) {
            if (r.isPlaceholder && r.placeholderKey != null) {
              sb.write('<<${r.placeholderKey}>>');
            } else {
              sb.write(r.text);
            }
          }
        }
        rawText = sb.toString();
      }
      final matcher = RegExp(r'<<([^>]+)>>');
      int lastIndex = 0;
      int placeholderIdx = 0;

      for (final match in matcher.allMatches(rawText)) {
        if (match.start > lastIndex) {
          final textBefore = rawText.substring(lastIndex, match.start);
          spans.add(TextSpan(
            text: textBefore,
            style: GoogleFonts.montserrat(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: AppColors.workspacePrimaryText,
              height: 1.65,
            ),
          ));
        }

        final key = match.group(1)!.trim().toUpperCase();
        InputFieldVm? fieldVm;
        for (final f in rowVm.inputFields) {
          if (f.key.toUpperCase() == key) {
            fieldVm = f;
            break;
          }
        }
        if (fieldVm == null) {
          final provider = context.read<DocumentWorkspaceProvider>();
          fieldVm = InputFieldVm(
            key: key,
            questionText: DocumentWorkspaceVm.toHumanizedLabel(key),
            fieldType: 'TEXT',
            currentValue: provider.getValue(key),
          );
        }

        final instanceId = 'tbl_${cell.cellId}_${key}_${placeholderIdx++}';
        if (fieldVm.isImage) {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SizedBox(
              width: 320,
              child: DocumentInputSlotWidget(fieldVm: fieldVm, readOnly: readOnly),
            ),
          ));
        } else {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            baseline: TextBaseline.alphabetic,
            child: InlineEditablePlaceholderWidget(
              instanceId: instanceId,
              fieldVm: fieldVm,
              readOnly: readOnly,
              textStyle: GoogleFonts.montserrat(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.workspaceCorporateNavy,
              ),
            ),
          ));
        }

        lastIndex = match.end;
      }

      if (lastIndex < rawText.length) {
        spans.add(TextSpan(
          text: rawText.substring(lastIndex),
          style: GoogleFonts.montserrat(
            fontSize: 11.5,
            fontWeight: FontWeight.w400,
            color: AppColors.workspacePrimaryText,
            height: 1.65,
          ),
        ));
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.left,
        ),
      );
    }

    // If cell contains pure placeholders without narrative, render standard slot widget
    if (cell.placeholderBindings.isNotEmpty) {
      final provider = context.read<DocumentWorkspaceProvider>();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final b in cell.placeholderBindings) ...[
            DocumentInputSlotWidget(
              fieldVm: rowVm.inputFields.firstWhere(
                (f) => f.key.toUpperCase() == b.key.toUpperCase(),
                orElse: () => InputFieldVm(
                  key: b.key.toUpperCase(),
                  questionText: b.questionText.isNotEmpty ? b.questionText : DocumentWorkspaceVm.toHumanizedLabel(b.key),
                  fieldType: b.fieldType,
                  currentValue: provider.getValue(b.key),
                ),
              ),
              readOnly: readOnly,
            ),
            const SizedBox(height: 4),
          ],
        ],
      );
    }

    // Static text cell
    return Text(
      cell.plainText.trim(),
      style: GoogleFonts.montserrat(
        fontSize: 11.5,
        fontWeight: cell.isHeader ? FontWeight.w700 : FontWeight.w500,
        color: cell.isHeader ? AppColors.workspaceCorporateNavy : AppColors.workspacePrimaryText,
      ),
    );
  }

  /// Field Priority Renderer: Required (* in red), Important (subtle info icon), or Standard
  Widget _buildQuestionPrompt(TableRowVm rowVm) {
    final text = rowVm.questionText ?? '';
    final lowerText = text.toLowerCase();

    // Check if any field key or question text indicates a critical required underwriting field
    bool isRequired = false;
    for (final f in rowVm.inputFields) {
      final k = f.key.toUpperCase();
      if (k.contains('OWNER') ||
          k.contains('CLIENT') ||
          k.contains('ADDRESS') ||
          k.contains('EXTENT') ||
          k.contains('RATE') ||
          k.contains('GUIDELINE') ||
          k.contains('FAIR_VALUE') ||
          k.contains('TOTAL_LAND') ||
          k.contains('TOTAL_BUILDING') ||
          k.contains('REPORT_NO')) {
        isRequired = true;
        break;
      }
    }
    if (!isRequired &&
        (lowerText.contains('name of the owner') ||
            lowerText.contains('total extent') ||
            lowerText.contains('market rate') ||
            lowerText.contains('guideline') ||
            lowerText.contains('fair market value') ||
            lowerText.contains('property address'))) {
      isRequired = true;
    }

    // Check if important parameter
    bool isImportant = false;
    if (!isRequired) {
      for (final f in rowVm.inputFields) {
        final k = f.key.toUpperCase();
        if (k.contains('ZONE') ||
            k.contains('BOUNDARY') ||
            k.contains('NORTH') ||
            k.contains('SOUTH') ||
            k.contains('EAST') ||
            k.contains('WEST') ||
            k.contains('ROAD') ||
            k.contains('DEPRECIATION') ||
            k.contains('AGE')) {
          isImportant = true;
          break;
        }
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.left,
                  style: GoogleFonts.montserrat(
                    fontSize: 12.5,
                    fontWeight: isRequired ? FontWeight.w600 : FontWeight.w500,
                    color: AppColors.workspacePrimaryText,
                    height: 1.25,
                  ),
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.workspaceErrorText,
                  ),
                ),
            ],
          ),
        ),
        if (isImportant) ...[
          const SizedBox(width: 4),
          const Tooltip(
            message: 'Key appraisal parameter',
            child: Icon(Icons.info_outline_rounded, size: 13, color: AppColors.workspaceSecondaryText),
          ),
        ],
      ],
    );
  }
}
