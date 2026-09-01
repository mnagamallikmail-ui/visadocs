import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/indian_number_formatter.dart';
import '../../../utils/indian_currency_to_words.dart';
import '../models/workspace_view_model.dart';
import '../models/valuation_models.dart';
import '../services/valuation_calculator.dart';
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
    } else if (block is ValuationPropertyBlockVm) {
      return _buildInlinePropertySection(context, provider);
    } else if (block is ValuationSummaryBlockVm) {
      return _buildInlineSummarySection(context, provider);
    }
    return const SizedBox.shrink();
  }

  // ─── Inline Valuation: LAND_TABLE ─────────────────────────────────────────
  Widget _buildInlineLandSection(BuildContext context, DocumentWorkspaceProvider provider) {
    final landItems = provider.landItems;
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Add Parcel'),
                    onPressed: provider.addLandItem,
                  ),
              ],
            ),
          ),

          // Scrollable Table Content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 960,
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    color: AppColors.surfaceSoft,
                    child: Row(
                      children: const [
                        SizedBox(width: 44, child: Text('S.No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                        Expanded(flex: 4, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Entered Area', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Area (Sq.Ft)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Rate (INR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Amount (INR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        SizedBox(width: 36),
                      ],
                    ),
                  ),

                  // Dynamic Rows
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
                          Expanded(flex: 4, child: TextFormField(
                            initialValue: item.description.isNotEmpty ? item.description : (item.surveyNo.isNotEmpty ? 'Plot (Sy.No.${item.surveyNo})' : ''),
                            enabled: !isReadOnly,
                            decoration: const InputDecoration(hintText: 'e.g. Commercial Plot (Sy.No.42/A)', isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              item.description = val;
                              provider.recalculateValuation();
                            },
                          )),
                          const SizedBox(width: 6),
                          Expanded(flex: 2, child: TextFormField(
                            initialValue: item.enteredArea.toString(),
                            enabled: !isReadOnly,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              item.enteredArea = double.tryParse(val) ?? 0;
                              provider.recalculateValuation();
                            },
                          )),
                          const SizedBox(width: 6),
                          Expanded(flex: 2, child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: ['Sq.Ft', 'Sq.Yd', 'Acre', 'Gunta', 'Hectare'].contains(item.enteredUnit) ? item.enteredUnit : 'Sq.Ft',
                            items: ['Sq.Ft', 'Sq.Yd', 'Acre', 'Gunta', 'Hectare'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 11)))).toList(),
                            onChanged: isReadOnly ? null : (val) {
                              if (val != null) {
                                item.enteredUnit = val;
                                provider.recalculateValuation();
                              }
                            },
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          )),
                          const SizedBox(width: 6),
                          Expanded(flex: 2, child: Text(IndianNumberFormatter.format(item.standardAreaSqft), style: GoogleFonts.firaCode(fontSize: 11))),
                          const SizedBox(width: 6),
                          Expanded(flex: 2, child: TextFormField(
                            initialValue: item.rate.toString(),
                            enabled: !isReadOnly,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              item.rate = double.tryParse(val) ?? 0;
                              provider.recalculateValuation();
                            },
                          )),
                          const SizedBox(width: 6),
                          Expanded(flex: 2, child: Text(IndianNumberFormatter.format(item.value), style: GoogleFonts.firaCode(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary))),
                          SizedBox(
                            width: 36,
                            child: isReadOnly || landItems.length <= 1
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

          // Total Row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL LAND VALUE (INR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(
                  'INR ${IndianNumberFormatter.format(provider.valuationData?.totalLandValue ?? 0)}',
                  style: GoogleFonts.firaCode(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Inline Valuation: BUILDING_TABLE ─────────────────────────────────────
  Widget _buildInlineBuildingSection(BuildContext context, DocumentWorkspaceProvider provider) {
    final buildingItems = provider.buildingItems;
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Add Structure'),
                    onPressed: provider.addBuildingItem,
                  ),
              ],
            ),
          ),
          // Scrollable Table Content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1040,
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    color: AppColors.surfaceSoft,
                    child: Row(
                      children: const [
                        Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Building Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Area (Sq.Ft)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Rate (INR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Repl Cost (INR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 1, child: Text('Age', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 1, child: Text('Life', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 1, child: Text('Dep %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Depr (INR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(flex: 2, child: Text('Value (INR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        SizedBox(width: 36),
                      ],
                    ),
                  ),

                  // Dynamic Rows
                  ...buildingItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairlineSoft))),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: TextFormField(
                            initialValue: item.description.isNotEmpty ? item.description : (item.structureType != 'Ground Floor' && item.structureType.isNotEmpty ? item.structureType : 'Commercial Building'),
                            enabled: !isReadOnly,
                            decoration: const InputDecoration(hintText: 'e.g. Commercial Office Building', isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              item.description = val;
                              provider.recalculateValuation();
                            },
                          )),
                          const SizedBox(width: 4),
                          Expanded(flex: 2, child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: ['RCC Commercial', 'RCC Residential', 'Industrial Building', 'Warehouse', 'Steel Shed', 'PEB Structure'].contains(item.buildingType) ? item.buildingType : 'RCC Commercial',
                            items: ['RCC Commercial', 'RCC Residential', 'Industrial Building', 'Warehouse', 'Steel Shed', 'PEB Structure'].map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 10)))).toList(),
                            onChanged: isReadOnly ? null : (val) {
                              if (val != null) {
                                item.buildingType = val;
                                provider.recalculateValuation();
                              }
                            },
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          )),
                          const SizedBox(width: 4),
                          Expanded(flex: 2, child: TextFormField(
                            initialValue: item.enteredArea.toString(),
                            enabled: !isReadOnly,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              item.enteredArea = double.tryParse(val) ?? 0;
                              provider.recalculateValuation();
                            },
                          )),
                          const SizedBox(width: 4),
                          Expanded(flex: 2, child: TextFormField(
                            initialValue: item.replacementRate.toString(),
                            enabled: !isReadOnly,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              item.replacementRate = double.tryParse(val) ?? 0;
                              provider.recalculateValuation();
                            },
                          )),
                          const SizedBox(width: 4),
                          Expanded(flex: 2, child: Text(IndianNumberFormatter.format(item.replacementCost), style: GoogleFonts.firaCode(fontSize: 10))),
                          const SizedBox(width: 4),
                          Expanded(flex: 1, child: TextFormField(
                            initialValue: item.buildingAge.toString(),
                            enabled: !isReadOnly,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              item.buildingAge = double.tryParse(val) ?? 0;
                              provider.recalculateValuation();
                            },
                          )),
                          const SizedBox(width: 4),
                          Expanded(flex: 1, child: TextFormField(
                            initialValue: item.buildingUsefulLife.toString(),
                            enabled: !isReadOnly,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              item.buildingUsefulLife = int.tryParse(val) ?? 60;
                              provider.recalculateValuation();
                            },
                          )),
                          const SizedBox(width: 4),
                          Expanded(flex: 1, child: Text('${item.depreciationPercentage.toStringAsFixed(1)}%', style: GoogleFonts.firaCode(fontSize: 10))),
                          const SizedBox(width: 4),
                          Expanded(flex: 2, child: Text(IndianNumberFormatter.format(item.depreciationAmount), style: GoogleFonts.firaCode(fontSize: 10, color: AppColors.brandRedDark))),
                          const SizedBox(width: 4),
                          Expanded(flex: 2, child: Text(IndianNumberFormatter.format(item.buildingValue), style: GoogleFonts.firaCode(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary))),
                          SizedBox(
                            width: 36,
                            child: isReadOnly || buildingItems.length <= 1
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

          // Total Row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL BUILDING VALUE (INR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(
                  'INR ${IndianNumberFormatter.format(provider.valuationData?.totalBuildingValue ?? 0)}',
                  style: GoogleFonts.firaCode(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Inline Valuation: VALUE OF THE PROPERTY TABLE ─────────────────────────
  Widget _buildInlinePropertySection(BuildContext context, DocumentWorkspaceProvider provider) {
    final data = provider.valuationData;
    final landVal = data?.totalLandValue ?? 0.0;
    final bldgVal = data?.totalBuildingValue ?? 0.0;
    final fairVal = data?.fairValue ?? 0.0;
    final sayVal = ValuationCalculator.computeSayValue(fairVal);

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
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                  child: const Text('CALCULATED SUMMARY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                // Table Header
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
                    Padding(padding: const EdgeInsets.all(10), child: Text('Value of Land', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
                    Padding(padding: const EdgeInsets.all(10), child: Text('₹ ${IndianNumberFormatter.format(landVal)}', style: GoogleFonts.firaCode(fontSize: 14, fontWeight: FontWeight.bold))),
                  ],
                ),
                TableRow(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairlineSoft))),
                  children: [
                    Padding(padding: const EdgeInsets.all(10), child: Text('Value of Buildings', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
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

  // ─── Inline Valuation: VALUATION_SUMMARY_TABLE ────────────────────────────
  Widget _buildInlineSummarySection(BuildContext context, DocumentWorkspaceProvider provider) {
    final data = provider.valuationData;
    if (data == null) return const SizedBox.shrink();

    final isReadOnly = provider.isReadOnly;
    final insurableVal = data.insurableValue > 0 ? data.insurableValue : data.totalReplacementCost;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.successAccent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SUMMARY OF VALUATION',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
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
          const SizedBox(height: 16),
          _buildSummaryDetailRow('Total Land Value:', '₹ ${IndianNumberFormatter.format(data.totalLandValue)}', IndianCurrencyToWords.convertToWords(data.totalLandValue)),
          const Divider(height: 18),
          _buildSummaryDetailRow('Total Building Value:', '₹ ${IndianNumberFormatter.format(data.totalBuildingValue)}', IndianCurrencyToWords.convertToWords(data.totalBuildingValue)),
          const Divider(height: 18),
          _buildSummaryDetailRow('Total Fair Market Value:', '₹ ${IndianNumberFormatter.format(data.fairValue)}', IndianCurrencyToWords.convertToWords(data.fairValue), isHighlight: true),
          const Divider(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue: data.realizablePercentage.toString(),
                            enabled: !isReadOnly,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Realizable %',
                              isDense: true,
                              suffixText: '%',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              data.realizablePercentage = double.tryParse(val) ?? 85.0;
                              provider.recalculateValuation();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryDetailRow(
                            'Realizable Value (${data.realizablePercentage}%):',
                            '₹ ${IndianNumberFormatter.format(data.realizableValue)}',
                            IndianCurrencyToWords.convertToWords(data.realizableValue),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue: data.distressSalePercentage.toString(),
                            enabled: !isReadOnly,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Distress %',
                              isDense: true,
                              suffixText: '%',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              data.distressSalePercentage = double.tryParse(val) ?? 75.0;
                              provider.recalculateValuation();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryDetailRow(
                            'Distress Sale Value (${data.distressSalePercentage}%):',
                            '₹ ${IndianNumberFormatter.format(data.distressSaleValue)}',
                            IndianCurrencyToWords.convertToWords(data.distressSaleValue),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          _buildSummaryDetailRow('Insurable Value (Total Building Replacement Cost):', '₹ ${IndianNumberFormatter.format(insurableVal)}', IndianCurrencyToWords.convertToWords(insurableVal)),
          const Divider(height: 18),
          
          // Government Value Section with Dynamic Calculation & Override
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.hairlineSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Government / Guideline Rates', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.deepTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('STATUTORY CALCULATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.deepTeal)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: '12000',
                        enabled: !isReadOnly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Govt Land Rate (₹/Sq.Yd)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          provider.recalculateValuation();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: '2100',
                        enabled: !isReadOnly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Govt RCC Rate (₹/Sq.Ft)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          provider.recalculateValuation();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: '1500',
                        enabled: !isReadOnly,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Govt Steel Rate (₹/Sq.Ft)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          provider.recalculateValuation();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryDetailRow(
                  'Calculated Government Value:',
                  '₹ ${IndianNumberFormatter.format(data.governmentValue)}',
                  IndianCurrencyToWords.convertToWords(data.governmentValue),
                ),
              ],
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
