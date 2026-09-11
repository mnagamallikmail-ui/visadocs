import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../models/workspace_view_model.dart';
import '../providers/document_workspace_provider.dart';

class SectionNavigationTreeWidget extends StatelessWidget {
  final VoidCallback? onSectionSelected;

  const SectionNavigationTreeWidget({
    super.key,
    this.onSectionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentWorkspaceProvider>();
    final vm = provider.workspaceVm;

    if (vm == null || vm.sections.isEmpty) {
      return Container(
        width: 280,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(right: BorderSide(color: AppColors.hairline)),
        ),
        child: Center(
          child: Text(
            'No sections available',
            style: AppTypography.bodySm().copyWith(color: AppColors.slate),
          ),
        ),
      );
    }

    final totalFields = vm.totalFields;
    final completedFields = vm.getCompletedFieldsCount(provider.activeValues);
    final progress = vm.getCompletionProgress(provider.activeValues);

    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppColors.workspacePanel,
        border: Border(right: BorderSide(color: AppColors.workspaceBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Dual Mode Switcher
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: const BoxDecoration(
              color: AppColors.workspacePanel,
              border: Border(bottom: BorderSide(color: AppColors.workspaceBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_tree_outlined, size: 16, color: AppColors.workspaceCorporateNavy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'DOCUMENT SECTIONS',
                        style: AppTypography.workspaceSidebarItem(
                          color: AppColors.workspacePrimaryText,
                          isActive: true,
                        ).copyWith(fontSize: 11, letterSpacing: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Dual Workspace Mode Segment Control
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.workspaceSegmentBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => provider.setScrollMode(DocumentScrollMode.continuous),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                            decoration: BoxDecoration(
                              color: provider.scrollMode == DocumentScrollMode.continuous
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: provider.scrollMode == DocumentScrollMode.continuous
                                  ? AppShadows.subtleElevated
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 13,
                                  color: provider.scrollMode == DocumentScrollMode.continuous
                                      ? AppColors.workspacePrimaryText
                                      : AppColors.workspaceSecondaryText,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Continuous',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.workspaceButton(
                                      color: provider.scrollMode == DocumentScrollMode.continuous
                                          ? AppColors.workspacePrimaryText
                                          : AppColors.workspaceSecondaryText,
                                      weight: provider.scrollMode == DocumentScrollMode.continuous
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ).copyWith(fontSize: 10.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => provider.setScrollMode(DocumentScrollMode.sectionBySection),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                            decoration: BoxDecoration(
                              color: provider.scrollMode == DocumentScrollMode.sectionBySection
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: provider.scrollMode == DocumentScrollMode.sectionBySection
                                  ? AppShadows.subtleElevated
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tab_rounded,
                                  size: 13,
                                  color: provider.scrollMode == DocumentScrollMode.sectionBySection
                                      ? AppColors.workspacePrimaryText
                                      : AppColors.workspaceSecondaryText,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Sections',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.workspaceButton(
                                      color: provider.scrollMode == DocumentScrollMode.sectionBySection
                                          ? AppColors.workspacePrimaryText
                                          : AppColors.workspaceSecondaryText,
                                      weight: provider.scrollMode == DocumentScrollMode.sectionBySection
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ).copyWith(fontSize: 10.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Section List with Dual Status and Numeric Counters
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: vm.sections.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.workspaceBorder),
              itemBuilder: (context, index) {
                final section = vm.sections[index];
                final isActive = provider.activeSectionIndex == index;
                final isCompleted = section.isCompleted(provider.activeValues);
                final completedCount = section.getCompletedCount(provider.activeValues);
                final totalCount = section.totalFields;
                final inProgress = completedCount > 0 && !isCompleted;

                return InkWell(
                  onTap: () {
                    provider.requestScrollToSection(index);
                    onSectionSelected?.call();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.workspaceCanvas : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isActive ? AppColors.workspaceCorporateNavy : Colors.transparent,
                          width: 2.0, // Refined 2px max left accent border
                        ),
                      ),
                      boxShadow: isActive ? AppShadows.subtleElevated : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Section Number Avatar / Subtle Completion Check
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppColors.workspaceSuccess.withValues(alpha: 0.12)
                                : (isActive
                                    ? AppColors.workspaceCorporateNavy
                                    : AppColors.workspaceSegmentBg),
                            border: Border.all(
                              color: isCompleted
                                  ? AppColors.workspaceSuccess.withValues(alpha: 0.4)
                                  : (isActive
                                      ? AppColors.workspaceCorporateNavy
                                      : (inProgress ? AppColors.warning.withValues(alpha: 0.5) : AppColors.workspaceBorder)),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: isCompleted
                              ? const Icon(Icons.check_rounded, size: 12, color: AppColors.workspaceSuccess)
                              : Text(
                                  '${section.sectionIndex + 1}',
                                  style: AppTypography.workspaceMicro(
                                    color: isActive
                                        ? Colors.white
                                        : (inProgress ? AppColors.warning : AppColors.workspaceSecondaryText),
                                    weight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 10),

                        // Section Title & Progress Fraction
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                section.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.workspaceSidebarItem(
                                  color: isActive ? AppColors.workspaceCorporateNavy : AppColors.workspacePrimaryText,
                                  isActive: isActive,
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Simplified Status: Clean fractional field progress
                              Text(
                                '$completedCount of $totalCount fields',
                                style: AppTypography.workspaceMicro(
                                  color: isCompleted ? AppColors.workspaceSuccess : AppColors.workspaceSecondaryText,
                                  weight: isCompleted ? FontWeight.w600 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (isActive)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.workspaceCorporateNavy),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ─── Compact Missing Data Validation Panel ───────────────────────────
          _buildMissingDataPanel(context, provider, vm),

          // ─── Overall Progress Milestone Card ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.workspacePanel,
              border: Border(top: BorderSide(color: AppColors.workspaceBorder, width: 1.0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Report Progress',
                        style: AppTypography.workspaceSidebarItem(
                          color: AppColors.workspacePrimaryText,
                          isActive: true,
                        ).copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.workspaceSegmentBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(progress * 100).round()}%',
                        style: AppTypography.workspaceMicro(
                          color: progress >= 1.0 ? AppColors.workspaceSuccess : AppColors.workspacePrimaryText,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.workspaceBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? AppColors.workspaceSuccess : AppColors.workspaceCorporateNavy,
                    ),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$completedFields / $totalFields fields filled',
                        style: AppTypography.workspaceMicro(color: AppColors.workspaceSecondaryText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${vm.sections.where((s) => s.isCompleted(provider.activeValues)).length} / ${vm.sections.length} sections',
                      style: AppTypography.workspaceMicro(color: AppColors.workspaceSecondaryText, weight: FontWeight.w600),
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

  /// Interactive Missing Data Panel identifying critical blockers with direct jump
  Widget _buildMissingDataPanel(BuildContext context, DocumentWorkspaceProvider provider, DocumentWorkspaceVm vm) {
    const criticalFields = [
      {'key': 'OWNER_NAME', 'label': 'Owner / Borrower Name'},
      {'key': 'PROPERTY_ADDRESS', 'label': 'Property Location / Address'},
      {'key': 'PROPERTY_TYPE', 'label': 'Property Classification'},
      {'key': 'TOTAL_LAND_VALUE', 'label': 'Total Land Valuation'},
      {'key': 'TOTAL_BUILDING_VALUE', 'label': 'Total Building Valuation'},
      {'key': 'FAIR_VALUE', 'label': 'Fair Market Value'},
      {'key': 'GOVERNMENT_VALUE', 'label': 'Guideline / Govt Value'},
    ];

    final List<_MissingFieldItem> missingList = [];

    for (final crit in criticalFields) {
      final key = crit['key']!;
      final label = crit['label']!;
      final currentVal = provider.activeValues[key]?.trim();

      if (currentVal == null || currentVal.isEmpty || currentVal == '0' || currentVal == '₹ 0') {
        int targetSec = 0;
        for (int i = 0; i < vm.sections.length; i++) {
          if (vm.sections[i].boundKeys.contains(key)) {
            targetSec = i;
            break;
          }
        }
        missingList.add(_MissingFieldItem(key: key, label: label, sectionIndex: targetSec));
      }
    }

    if (missingList.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.workspaceSegmentBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.workspaceBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 13, color: AppColors.workspaceSuccess),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Critical parameters complete',
                style: AppTypography.workspaceMicro(color: AppColors.workspaceSecondaryText, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.workspaceSegmentBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.workspaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Required Parameters (${missingList.length})',
                  style: AppTypography.workspaceMicro(
                    color: AppColors.workspacePrimaryText,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final item in missingList.take(3))
            InkWell(
              onTap: () {
                provider.requestScrollToSection(item.sectionIndex);
                onSectionSelected?.call();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(
                  children: [
                    const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.workspaceSecondaryText),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${item.label} (Sec ${item.sectionIndex + 1})',
                        style: AppTypography.workspaceMicro(
                          color: AppColors.workspaceSecondaryText,
                          weight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (missingList.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 18),
              child: Text(
                '+ ${missingList.length - 3} more parameters',
                style: AppTypography.workspaceMicro(
                  color: AppColors.steel,
                  weight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MissingFieldItem {
  final String key;
  final String label;
  final int sectionIndex;

  const _MissingFieldItem({
    required this.key,
    required this.label,
    required this.sectionIndex,
  });
}
