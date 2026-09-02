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
import 'widgets/valuation_workspace_editor_widget.dart';

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
    final finalVal = _provider.valuationData?.fairValue ?? 0.0;
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
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sticky Property Context Header (Always visible throughout scrolling)
                  if (!provider.isLoading && provider.workspaceModel != null)
                    _buildPropertyContextHeader(provider),
                  Expanded(
                    child: provider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: AppColors.deepTeal),
                          )
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: provider.viewMode == WorkspaceViewMode.valuationEngine
                                ? ValuationWorkspaceEditorWidget(
                                    key: const ValueKey('VALUATION_ENGINE_LAYOUT'),
                                    orderId: widget.orderId,
                                    readOnly: provider.isReadOnly,
                                    onValuationChanged: (newPlaceholders) {
                                      provider.updateValuesFromValuation(newPlaceholders);
                                    },
                                  )
                                : provider.viewMode == WorkspaceViewMode.tableEdit
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
                ],
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
      title: Row(
        children: [
          // Platform Title & Reference
          Text(
            'ProValuer Workspace',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '•  $reportNum',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 18, color: AppColors.hairline),
          const SizedBox(width: 12),

          // Segmented View Mode Toggle
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
                if (widget.role == 'ADMIN' || widget.role == 'SUPER_ADMIN')
                  _buildSegmentButton(
                    title: 'Valuation Engine (Admin)',
                    icon: Icons.calculate_outlined,
                    isActive: provider.viewMode == WorkspaceViewMode.valuationEngine,
                    onTap: () => provider.setViewMode(WorkspaceViewMode.valuationEngine),
                  ),
                _buildSegmentButton(
                  title: 'Data Entry & Tables',
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
      actions: [
        // Subtle Auto-save Status Indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (provider.isAutoSaving) ...[
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: 6),
                Text('Auto-saving...', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate)),
              ] else if (provider.isDirty) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('Unsaved edits', style: GoogleFonts.inter(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600)),
              ] else if (provider.lastSavedAt != null) ...[
                const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.successAccent),
                const SizedBox(width: 5),
                Text('Auto-saved', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate)),
              ],
            ],
          ),
        ),

        // Subordinate Save Draft Button (Neutral outline, only active if dirty)
        OutlinedButton.icon(
          icon: provider.isSaving
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.slate),
                )
              : Icon(
                  Icons.save_outlined,
                  size: 14,
                  color: provider.isDirty ? AppColors.ink : AppColors.stone,
                ),
          label: Text(
            provider.isSaving ? 'Saving...' : 'Save Draft',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: provider.isDirty ? AppColors.ink : AppColors.stone,
            ),
          ),
          onPressed: (provider.isDirty && !provider.isSaving && !provider.isReadOnly)
              ? () => provider.saveChanges()
              : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            disabledForegroundColor: AppColors.stone,
            side: BorderSide(
              color: provider.isDirty ? AppColors.hairlineStrong : AppColors.hairline,
              width: 1.2,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const SizedBox(width: 10),

        // SINGLE DOMINANT PRIMARY ACTION: PA Submit to SPA
        if ((isPa || isAdmin) && (status == 'ASSIGNED' || status == 'ACTION_NEEDED')) ...[
          ElevatedButton.icon(
            icon: provider.isSubmitting
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 14),
            label: Text(
              provider.isSubmitting ? 'Submitting...' : 'SUBMIT TO SPA',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3),
            ),
            onPressed: provider.isSubmitting ? null : _handleSubmitToSpa,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: 10),
        ],

        // SINGLE DOMINANT PRIMARY ACTION: SPA Approve Report
        if ((isSpa || isAdmin) && (status == 'SPA_GATE' || status == 'ASSIGNED')) ...[
          ElevatedButton.icon(
            icon: provider.isSubmitting
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.verified_rounded, size: 14),
            label: Text(
              provider.isSubmitting ? 'Approving...' : 'APPROVE & COMPILE',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3),
            ),
            onPressed: provider.isSubmitting ? null : _handleSpaApprove,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: 10),
        ],

        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.slate, size: 20),
          tooltip: 'Reload Document Data',
          onPressed: () => provider.loadWorkspace(widget.orderId),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  /// Sticky Property Context Header Strip (Fixed 42px bar, always visible throughout scrolling)
  Widget _buildPropertyContextHeader(DocumentWorkspaceProvider provider) {
    final workspace = provider.workspaceModel;
    final status = workspace?.status ?? 'ASSIGNED';
    final reportNum = workspace?.reportNumber ?? widget.reportNumber ?? 'Order #${widget.orderId}';

    String propertyType = provider.getValue('PROPERTY_TYPE');
    if (propertyType.isEmpty) propertyType = 'Commercial Property';

    String ownerName = provider.getValue('OWNER_NAME');
    if (ownerName.isEmpty) ownerName = provider.getValue('CLIENT_NAME');
    if (ownerName.isEmpty) ownerName = 'M/s Property Owner';

    String bankName = provider.getValue('BANK_NAME');
    if (bankName.isEmpty) bankName = 'Lending Institution';

    String branchName = provider.getValue('BRANCH_NAME');
    final bankDisplay = branchName.isNotEmpty ? '$bankName ($branchName)' : bankName;

    String location = provider.getValue('PROPERTY_ADDRESS');
    if (location.isEmpty) location = provider.getValue('PROP_LOCATION');
    if (location.isEmpty) location = 'Site Location';

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.hairline, width: 1.2)),
      ),
      child: Row(
        children: [
          // Property Category Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.deepTeal.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.apartment_rounded, color: AppColors.deepTeal, size: 13),
                const SizedBox(width: 5),
                Text(
                  propertyType,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepTeal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 18, color: AppColors.hairline),
          const SizedBox(width: 12),

          // Owner Metadata
          _buildContextMetaItem(
            label: 'OWNER',
            value: ownerName,
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 18, color: AppColors.hairline),
          const SizedBox(width: 12),

          // Bank Metadata
          _buildContextMetaItem(
            label: 'BANK',
            value: bankDisplay,
            icon: Icons.account_balance_outlined,
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 18, color: AppColors.hairline),
          const SizedBox(width: 12),

          // Location Metadata
          Expanded(
            child: _buildContextMetaItem(
              label: 'LOCATION',
              value: location,
              icon: Icons.place_outlined,
            ),
          ),

          const SizedBox(width: 12),
          Container(width: 1, height: 18, color: AppColors.hairline),
          const SizedBox(width: 12),

          // Report Identification Monospace
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'REPORT REF: ',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.steel),
              ),
              Text(
                reportNum,
                style: GoogleFonts.firaCode(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Lifecycle Status Badge
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
        ],
      ),
    );
  }

  Widget _buildContextMetaItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.steel),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.steel,
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
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
