import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
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
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Dual Mode Switcher
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.hairline)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_tree_outlined, size: 16, color: AppColors.deepTeal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'DOCUMENT SECTIONS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Dual Workspace Mode Segment Control
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => provider.setScrollMode(DocumentScrollMode.continuous),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            decoration: BoxDecoration(
                              color: provider.scrollMode == DocumentScrollMode.continuous
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: provider.scrollMode == DocumentScrollMode.continuous
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 12,
                                  color: provider.scrollMode == DocumentScrollMode.continuous
                                      ? AppColors.deepTeal
                                      : AppColors.slate,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    'Continuous',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: provider.scrollMode == DocumentScrollMode.continuous
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: provider.scrollMode == DocumentScrollMode.continuous
                                          ? AppColors.deepTeal
                                          : AppColors.slate,
                                    ),
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
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            decoration: BoxDecoration(
                              color: provider.scrollMode == DocumentScrollMode.sectionBySection
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: provider.scrollMode == DocumentScrollMode.sectionBySection
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tab_rounded,
                                  size: 12,
                                  color: provider.scrollMode == DocumentScrollMode.sectionBySection
                                      ? AppColors.deepTeal
                                      : AppColors.slate,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    'Sections',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: provider.scrollMode == DocumentScrollMode.sectionBySection
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: provider.scrollMode == DocumentScrollMode.sectionBySection
                                          ? AppColors.deepTeal
                                          : AppColors.slate,
                                    ),
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

          // Section List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: vm.sections.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.hairline),
              itemBuilder: (context, index) {
                final section = vm.sections[index];
                final isActive = provider.activeSectionIndex == index;
                final isCompleted = section.isCompleted(provider.activeValues);
                final completedCount = section.getCompletedCount(provider.activeValues);
                final totalCount = section.totalFields;

                return InkWell(
                  onTap: () {
                    provider.requestScrollToSection(index);
                    onSectionSelected?.call();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.deepTeal.withValues(alpha: 0.08) : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isActive ? AppColors.deepTeal : Colors.transparent,
                          width: 3.5,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        // Section number or completion checkmark
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppColors.successAccent.withValues(alpha: 0.15)
                                : (isActive ? AppColors.deepTeal : AppColors.steel.withValues(alpha: 0.2)),
                          ),
                          alignment: Alignment.center,
                          child: isCompleted
                              ? const Icon(Icons.check_rounded, size: 14, color: AppColors.successAccent)
                              : Text(
                                  '${section.sectionIndex + 1}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isActive ? Colors.white : AppColors.slate,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 10),

                        // Title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                  color: isActive ? AppColors.ink : AppColors.slate,
                                ),
                              ),
                              if (totalCount > 0) ...[
                                const SizedBox(height: 3),
                                Text(
                                  '$completedCount of $totalCount filled',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: isCompleted ? AppColors.successAccent : AppColors.steel,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        if (isActive)
                          const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.deepTeal),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Overall Progress Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceSoft,
              border: Border(top: BorderSide(color: AppColors.hairline)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Report Progress',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.hairline,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.deepTeal),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$completedFields of $totalFields fields answered',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
