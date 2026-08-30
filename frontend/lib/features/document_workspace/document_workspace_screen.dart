import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'models/document_workspace_model.dart';
import 'providers/document_workspace_provider.dart';
import 'widgets/document_table_workspace_widget.dart';
import 'widgets/live_preview_viewer_widget.dart';
import 'widgets/section_navigation_tree_widget.dart';

class DocumentWorkspaceScreen extends StatefulWidget {
  final int orderId;
  final String? reportNumber;
  final String role; // 'PA', 'SPA', 'SUPER_ADMIN', 'ADMIN', 'CLIENT'

  const DocumentWorkspaceScreen({
    super.key,
    required this.orderId,
    this.reportNumber,
    required this.role,
  });

  @override
  State<DocumentWorkspaceScreen> createState() => _DocumentWorkspaceScreenState();
}

class _DocumentWorkspaceScreenState extends State<DocumentWorkspaceScreen> {
  late final DocumentWorkspaceProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = DocumentWorkspaceProvider();
    _provider.loadWorkspace(widget.orderId);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_provider.isDirty) return true;

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Unsaved Modifications', style: AppTypography.heading4().copyWith(color: AppColors.ink)),
        content: Text(
          'You have pending in-document changes that have not been saved to the server. How would you like to proceed?',
          style: AppTypography.bodySm().copyWith(color: AppColors.slate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('CANCEL'),
            child: Text('Cancel', style: AppTypography.bodyMdMedium(color: AppColors.slate)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('DISCARD'),
            child: Text('Discard & Leave', style: AppTypography.bodyMdMedium(color: AppColors.brandRedDark)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop('SAVE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepTeal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save & Leave'),
          ),
        ],
      ),
    );

    if (choice == 'SAVE') {
      await _provider.saveChanges();
      return true;
    } else if (choice == 'DISCARD') {
      return true;
    }
    return false;
  }

  Future<void> _handleSubmitToSpa() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.send_rounded, color: AppColors.deepTeal, size: 20),
            const SizedBox(width: 8),
            Text('Submit Report to SPA?', style: AppTypography.heading4().copyWith(color: AppColors.ink)),
          ],
        ),
        content: Text(
          'This will save all in-document inputs and transfer the valuation file to Senior Property Analyst (SPA) review queue.',
          style: AppTypography.bodySm().copyWith(color: AppColors.slate),
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
            ),
            child: const Text('Submit to SPA'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _provider.submitToSpa();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document report submitted to SPA for review'),
          backgroundColor: AppColors.successAccent,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.errorMessage ?? 'Failed to submit to SPA'),
          backgroundColor: AppColors.brandRedDark,
        ),
      );
    }
  }

  Future<void> _handleSpaApprove() async {
    final finalValueController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.successAccent, size: 20),
            const SizedBox(width: 8),
            Text('Approve Valuation Report', style: AppTypography.heading4().copyWith(color: AppColors.ink)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the final confirmed property valuation value to lock and compile the final document report.',
              style: AppTypography.bodySm().copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: finalValueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Final Valuation Amount (INR)',
                prefixText: 'INR ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: AppTypography.bodyMdMedium(color: AppColors.slate)),
          ),
          ElevatedButton(
            onPressed: () {
              if (finalValueController.text.trim().isEmpty) return;
              Navigator.of(ctx).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve & Compile'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final finalVal = double.parse(finalValueController.text.trim());
    final success = await _provider.spaApprove(finalVal);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Valuation report approved and compiled successfully!'),
          backgroundColor: AppColors.successAccent,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.errorMessage ?? 'Failed to approve valuation report'),
          backgroundColor: AppColors.brandRedDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<DocumentWorkspaceProvider>(
        builder: (context, provider, _) {
          return PopScope(
            canPop: !provider.isDirty,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop(result);
              }
            },
            child: Scaffold(
              backgroundColor: AppColors.canvas,
              appBar: _buildAppBar(context, provider),
              body: provider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.deepTeal),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: provider.viewMode == WorkspaceViewMode.tableEdit
                          ? Row(
                              key: const ValueKey('TABLE_EDIT_LAYOUT'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: const [
                                SectionNavigationTreeWidget(),
                                Expanded(
                                  child: DocumentTableWorkspaceWidget(),
                                ),
                              ],
                            )
                          : const LivePreviewViewerWidget(key: ValueKey('COMPILED_PREVIEW')),
                    ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, DocumentWorkspaceProvider provider) {
    final workspace = provider.workspaceModel;
    final status = workspace?.status ?? 'ASSIGNED';
    final reportNum = workspace?.reportNumber ?? widget.reportNumber ?? 'Order #${widget.orderId}';

    final isPa = widget.role == 'PA';
    final isSpa = widget.role == 'SPA';
    final isAdmin = widget.role == 'SUPER_ADMIN' || widget.role == 'ADMIN';

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
        tooltip: 'Back to Orders',
        onPressed: () async {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
      title: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
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
                  const Icon(Icons.description_outlined, color: AppColors.deepTeal, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Document Workspace',
                    style: AppTypography.caption(color: AppColors.deepTeal).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              reportNum,
              style: AppTypography.heading4().copyWith(color: AppColors.ink),
            ),
            const SizedBox(width: 12),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(status).withValues(alpha: 0.3)),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(status),
                ),
              ),
            ),

            // Auto-save Status Indicator
            const SizedBox(width: 16),
            if (provider.isAutoSaving) ...[
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.deepTeal),
              ),
              const SizedBox(width: 6),
              Text('Auto-saving...', style: AppTypography.caption(color: AppColors.slate)),
            ] else if (provider.isDirty) ...[
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('Unsaved changes', style: AppTypography.caption(color: AppColors.warning)),
            ] else if (provider.lastSavedAt != null) ...[
              const Icon(Icons.check_circle_outline_rounded, size: 12, color: AppColors.successAccent),
              const SizedBox(width: 4),
              Text('All changes saved', style: AppTypography.caption(color: AppColors.slate)),
            ],

            const SizedBox(width: 20),

            // ─── Segmented View Mode Toggle ────────────────────────────
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSegmentButton(
                    title: 'Table Workspace',
                    icon: Icons.table_chart_outlined,
                    isActive: provider.viewMode == WorkspaceViewMode.tableEdit,
                    onTap: () => provider.setViewMode(WorkspaceViewMode.tableEdit),
                  ),
                  _buildSegmentButton(
                    title: 'Compiled PDF Preview',
                    icon: Icons.picture_as_pdf_outlined,
                    isActive: provider.viewMode == WorkspaceViewMode.compiledPreview,
                    onTap: () => provider.setViewMode(WorkspaceViewMode.compiledPreview),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Save Draft Button - ALWAYS VISIBLE in toolbar across all dirty/saving/saved states
        ElevatedButton.icon(
          icon: provider.isSaving
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(
                  provider.isDirty ? Icons.save_rounded : Icons.check_circle_rounded,
                  size: 15,
                  color: provider.isDirty
                      ? Colors.white
                      : (provider.isReadOnly ? AppColors.slate : AppColors.successAccent),
                ),
          label: Text(
            provider.isSaving
                ? 'Saving...'
                : (provider.isDirty ? 'Save Draft' : 'Saved'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: provider.isDirty
                  ? Colors.white
                  : (provider.isReadOnly ? AppColors.slate : AppColors.ink),
            ),
          ),
          onPressed: (provider.isDirty && !provider.isSaving && !provider.isReadOnly)
              ? () => provider.saveChanges()
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: provider.isDirty ? AppColors.deepTeal : AppColors.surfaceSoft,
            foregroundColor: provider.isDirty ? Colors.white : AppColors.ink,
            disabledBackgroundColor: provider.isSaving
                ? AppColors.deepTeal
                : AppColors.surfaceSoft,
            disabledForegroundColor: provider.isSaving ? Colors.white : AppColors.slate,
            elevation: 0,
            side: BorderSide(
              color: provider.isDirty ? AppColors.deepTeal : AppColors.hairline,
              width: 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const SizedBox(width: 8),

        // PA Action: Submit to SPA
        if ((isPa || isAdmin) && (status == 'ASSIGNED' || status == 'ACTION_NEEDED')) ...[
          ElevatedButton.icon(
            icon: provider.isSubmitting
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 15),
            label: Text(provider.isSubmitting ? 'Submitting...' : 'SUBMIT TO SPA'),
            onPressed: provider.isSubmitting ? null : _handleSubmitToSpa,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // SPA Action: Approve Report
        if ((isSpa || isAdmin) && (status == 'SPA_GATE' || status == 'ASSIGNED')) ...[
          ElevatedButton.icon(
            icon: provider.isSubmitting
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.verified_rounded, size: 15),
            label: Text(provider.isSubmitting ? 'Approving...' : 'APPROVE & COMPILE'),
            onPressed: provider.isSubmitting ? null : _handleSpaApprove,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: 8),
        ],

        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.slate),
          tooltip: 'Reload Document',
          onPressed: () => provider.loadWorkspace(widget.orderId),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? AppColors.deepTeal : AppColors.slate),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.deepTeal : AppColors.slate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ASSIGNED':
        return AppColors.deepTeal;
      case 'SPA_GATE':
        return AppColors.warning;
      case 'SPA_CONFIRMED':
      case 'FINAL_DELIVERY':
        return AppColors.successAccent;
      case 'ACTION_NEEDED':
        return AppColors.brandRedDark;
      default:
        return AppColors.slate;
    }
  }
}
