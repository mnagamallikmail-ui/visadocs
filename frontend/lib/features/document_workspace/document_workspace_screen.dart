import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../../providers/order_provider.dart';
import '../../services/unload_protection_stub.dart'
    if (dart.library.html) '../../services/unload_protection_web.dart';
import '../../services/api_service.dart';
import '../../services/token_storage.dart';
import '../../widgets/in_line_reauth_dialog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
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
  final DocumentWorkspaceProvider? provider;

  const DocumentWorkspaceScreen({
    super.key,
    required this.orderId,
    this.reportNumber,
    required this.role,
    this.provider,
  });

  @override
  State<DocumentWorkspaceScreen> createState() => _DocumentWorkspaceScreenState();
}

class _DocumentWorkspaceScreenState extends State<DocumentWorkspaceScreen> {
  late final DocumentWorkspaceProvider _provider;
  bool _showPersistentSaveFailure = false;
  bool _isReauthOpen = false;

  // Responsive Sidebar Adaptation (Phase 2B)
  bool? _userSidebarCompact;
  bool? _userSidebarCollapsed;

  @override
  void initState() {
    super.initState();
    _provider = widget.provider ?? DocumentWorkspaceProvider();
    if (widget.provider == null) {
      _provider.loadWorkspace(widget.orderId);
    }

    // SPRINT 6 EMERGENCY HOTFIX: Global 401 Interception & Zero Data Loss Modal
    ApiService().onSessionExpired = () {
      if (mounted) {
        _showReauthModal();
      }
    };

    // SPRINT 6 EMERGENCY HOTFIX: Browser exit protection
    if (kIsWeb) {
      setupBeforeUnloadProtection(() =>
          _provider.isDirty || TokenStorage.loadDraftFromStorage(widget.orderId) != null);
    }
  }

  void _showReauthModal() {
    if (_isReauthOpen || !mounted) return;
    _isReauthOpen = true;
    InLineReauthDialog.show(
      context,
      onAuthenticatedAndSync: () async {
        final success = await _provider.saveChanges();
        if (success && mounted) {
          setState(() {
            _showPersistentSaveFailure = false;
          });
        }
      },
    ).then((_) {
      _isReauthOpen = false;
    });
  }

  @override
  void dispose() {
    if (widget.provider == null) {
      _provider.dispose();
    }
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_provider.isDirty) return true;

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Unsaved Modifications', style: AppTypography.workspaceSectionTitle()),
        content: Text(
          'You have pending in-document changes that have not been saved to the server. How would you like to proceed?',
          style: AppTypography.workspaceBody(color: AppColors.workspaceSecondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('CANCEL'),
            child: Text('Cancel', style: AppTypography.workspaceButton(color: AppColors.workspaceSecondaryText)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('DISCARD'),
            child: Text('Discard & Leave', style: AppTypography.workspaceButton(color: AppColors.workspaceErrorText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop('SAVE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.workspaceCorporateNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    final status = _provider.workspaceModel?.status ?? '';
    final isResubmit = status == 'SPA_GATE';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Row(
          children: [
            const Icon(Icons.send_rounded, color: AppColors.workspaceCorporateNavy, size: 20),
            const SizedBox(width: 8),
            Text(isResubmit ? 'Resubmit Report to SPA?' : 'Submit Report to SPA?', style: AppTypography.workspaceSectionTitle()),
          ],
        ),
        content: Text(
          isResubmit
              ? 'This will save all updated document inputs and alert the Senior Property Analyst (SPA) to review the latest changes.'
              : 'This will save all in-document inputs and transfer the valuation file to Senior Property Analyst (SPA) review queue.',
          style: AppTypography.workspaceBody(color: AppColors.workspaceSecondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: AppTypography.workspaceButton(color: AppColors.workspaceSecondaryText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.workspaceCorporateNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isResubmit ? 'Resubmit to SPA' : 'Submit to SPA'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _provider.submitToSpa();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isResubmit
              ? 'Updated document report resubmitted to SPA for review'
              : 'Document report submitted to SPA for review'),
          backgroundColor: AppColors.workspaceSuccess,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.errorMessage ?? 'Failed to submit to SPA'),
          backgroundColor: AppColors.workspaceErrorText,
        ),
      );
    }
  }

  Future<void> _handleSpaApprove() async {
    final finalVal = _provider.valuationData?.fairValue ?? 0.0;
    final success = await _provider.spaApprove(finalVal);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Valuation report approved (Word generated successfully)!'),
          backgroundColor: AppColors.workspaceSuccess,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      final approveError = _provider.errorMessage;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approveError != null && approveError.isNotEmpty
              ? approveError
              : 'Failed to approve valuation report. Please try again.'),
          backgroundColor: AppColors.workspaceErrorText,
        ),
      );
    }
  }

  Future<void> _handleRecompileWord() async {
    final finalVal = _provider.valuationData?.fairValue ?? 0.0;
    final success = await _provider.spaApprove(finalVal);
    if (!mounted) return;

    if (success) {
      final rev = _provider.workspaceModel?.workspaceRevision ?? 0;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Word report recompiled successfully! (Revision $rev)'),
          backgroundColor: AppColors.workspaceSuccess,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      final err = _provider.errorMessage;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err != null && err.isNotEmpty ? err : 'Failed to recompile Word document.'),
          backgroundColor: AppColors.workspaceErrorText,
        ),
      );
    }
  }

  Future<void> _handleDownloadWord() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final bytes = await orderProvider.downloadReportDocx(widget.orderId);
    if (!mounted) return;

    if (bytes == null) {
      final errMsg = orderProvider.lastDocxError ?? 'Failed to download Word document.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errMsg),
          backgroundColor: AppColors.workspaceErrorText,
        ),
      );
      return;
    }

    try {
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.wordprocessingml.document');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'Report_${widget.orderId}.docx')
        ..style.display = 'none';
      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Word document downloaded successfully!'),
          backgroundColor: AppColors.workspaceSuccess,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading Word document: $e'),
          backgroundColor: AppColors.workspaceErrorText,
        ),
      );
    }
  }

  Future<void> _handleGeneratePdf() async {
    final success = await _provider.generatePdfOnDemand();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF generated successfully! Downloading...'),
          backgroundColor: AppColors.workspaceSuccess,
          duration: Duration(seconds: 4),
        ),
      );
      await _handleDownloadPdf();
    } else {
      final err = _provider.errorMessage;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err != null && err.isNotEmpty ? err : 'Failed to generate PDF. Please try again.'),
          backgroundColor: AppColors.workspaceErrorText,
        ),
      );
    }
  }

  Future<void> _handleDownloadPdf() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final bytes = await orderProvider.downloadReportPdf(widget.orderId);
    if (!mounted) return;

    if (bytes == null) {
      final errMsg = orderProvider.lastPdfError ?? 'Failed to download PDF.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errMsg),
          backgroundColor: AppColors.workspaceErrorText,
        ),
      );
      return;
    }

    try {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'Report_${widget.orderId}.pdf')
        ..style.display = 'none';
      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading PDF: $e'),
          backgroundColor: AppColors.workspaceErrorText,
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
              backgroundColor: AppColors.workspaceCanvas,
              appBar: _buildAppBar(context, provider),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sticky Property Context Header (Always visible throughout scrolling)
                  if (!provider.isLoading && provider.workspaceModel != null)
                    _buildPropertyContextHeader(provider),

                  // Multi-Tab Collision Banner (FIX 4)
                  if (provider.hasActiveSessionConflict)
                    _buildMultiTabConflictBanner(provider),

                  // Session Taken Over Banner (FIX 4)
                  if (provider.sessionTakenOver)
                    _buildSessionTakenOverBanner(provider),

                  // Concurrency Revision Conflict Banner (FIX 1 & FIX 3)
                  if (provider.hasRevisionConflict)
                    _buildRevisionConflictBanner(provider),

                  // Real-Time Invalidation Notice Banner (FIX 8)
                  if (provider.invalidationNotice != null)
                    _buildInvalidationBanner(provider),

                  // Stale Local Draft Quarantine Banner (FIX 6)
                  if (provider.hasPendingStaleLocalDraft)
                    _buildStaleDraftQuarantineBanner(provider),

                  // SPRINT 6 EMERGENCY HOTFIX: Persistent Save Failure Banner (Phase 5)
                  if (provider.saveState == SaveState.error || _showPersistentSaveFailure)
                    _buildPersistentSaveFailureBanner(provider),

                  // SPRINT 6 EMERGENCY HOTFIX: Recovered Local Draft Banner (Phase 9)
                  if (provider.hasRecoveredLocalDraft)
                    _buildRecoveredDraftBanner(provider),
                  Expanded(
                    child: provider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: AppColors.workspaceCorporateNavy),
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
                                      ? Focus(
                                          onKeyEvent: (node, event) {
                                            if (event is KeyDownEvent) {
                                              if (event.logicalKey == LogicalKeyboardKey.tab || event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                                if (provider.placeholderRegistry.activeId == null) {
                                                  provider.placeholderRegistry.activateFirst();
                                                  return KeyEventResult.handled;
                                                }
                                              }
                                            }
                                            return KeyEventResult.ignored;
                                          },
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final availableWidth = constraints.maxWidth;
                                              // Desktop wide (>= 1440): Expanded (280px)
                                              // Medium laptops (1150..1440): Compact mode (68px)
                                              // Smaller widths (< 1150): Collapsible (pinned 34px tab)
                                              final bool defaultCompact = availableWidth >= 1150 && availableWidth < 1440;
                                              final bool defaultCollapsed = availableWidth < 1150;
                                              final bool isCollapsed = _userSidebarCollapsed ?? defaultCollapsed;
                                              final bool isCompact = !isCollapsed && (_userSidebarCompact ?? defaultCompact);

                                              return Row(
                                                key: const ValueKey('TABLE_EDIT_LAYOUT'),
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  if (!isCollapsed)
                                                    Focus(
                                                      canRequestFocus: false,
                                                      descendantsAreFocusable: false,
                                                      child: SectionNavigationTreeWidget(
                                                        isCompact: isCompact,
                                                        onToggleCompact: () {
                                                          setState(() {
                                                            if (isCompact) {
                                                              _userSidebarCompact = false;
                                                              _userSidebarCollapsed = false;
                                                            } else {
                                                              _userSidebarCompact = true;
                                                            }
                                                          });
                                                        },
                                                      ),
                                                    )
                                                  else
                                                    Container(
                                                      width: 34,
                                                      decoration: const BoxDecoration(
                                                        color: AppColors.workspacePanel,
                                                        border: Border(right: BorderSide(color: AppColors.workspaceBorder)),
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          const SizedBox(height: 12),
                                                          Tooltip(
                                                            message: 'Open Document Sections',
                                                            child: IconButton(
                                                              icon: const Icon(Icons.menu_open_rounded, size: 16, color: AppColors.workspaceCorporateNavy),
                                                              onPressed: () {
                                                                setState(() {
                                                                  _userSidebarCollapsed = false;
                                                                  _userSidebarCompact = availableWidth < 1366;
                                                                });
                                                              },
                                                              padding: EdgeInsets.zero,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  const Expanded(
                                                    child: DocumentTableWorkspaceWidget(),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
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
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 1),
      child: Focus(
        canRequestFocus: false,
        descendantsAreFocusable: false,
        child: AppBar(
      backgroundColor: AppColors.workspacePanel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.workspaceBorder, height: 1),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.workspacePrimaryText),
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
            style: AppTypography.workspaceSectionTitle().copyWith(fontSize: 14),
          ),
          const SizedBox(width: 8),
          Text(
            '•  $reportNum',
            style: AppTypography.workspaceMetadataValue(color: AppColors.workspaceSecondaryText).copyWith(fontSize: 12.5),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 18, color: AppColors.workspaceBorder),
          const SizedBox(width: 12),

          // Segmented View Mode Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.workspaceSegmentBg,
              borderRadius: BorderRadius.circular(8),
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
        // SPRINT 6 EMERGENCY HOTFIX: Visible Autosave Status Area (Phase 6)
        _buildAutosaveStatusIndicator(provider),

        // Subordinate Save Draft Button (Ghost-style appearance) with Visible Failure (Phase 5)
        TextButton.icon(
          icon: provider.isSaving
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.workspaceSecondaryText),
                )
              : Icon(
                  Icons.save_outlined,
                  size: 14,
                  color: provider.isDirty ? AppColors.workspacePrimaryText : AppColors.steel,
                ),
          label: Text(
            provider.isSaving ? 'Saving...' : 'Save Draft',
            style: AppTypography.workspaceButton(
              color: provider.isDirty ? AppColors.workspacePrimaryText : AppColors.steel,
              weight: FontWeight.w600,
            ),
          ),
          onPressed: (provider.isDirty && !provider.isSaving && !provider.isReadOnly)
              ? () async {
                  final success = await provider.saveChanges();
                  if (!context.mounted) return;
                  if (!success) {
                    setState(() {
                      _showPersistentSaveFailure = true;
                    });
                    if (ApiService().isSessionExpired) {
                      _showReauthModal();
                    }
                  } else {
                    setState(() {
                      _showPersistentSaveFailure = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Draft saved successfully to database'),
                        backgroundColor: AppColors.workspaceSuccess,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: Colors.transparent,
          ),
        ),
        const SizedBox(width: 10),

        // SINGLE DOMINANT PRIMARY ACTION: PA Submit / Resubmit to SPA
        if ((isPa || isAdmin) &&
            (status == 'ASSIGNED' ||
             status == 'WORKSPACE_READY' ||
             status == 'DRAFTING' ||
             status == 'ACTION_NEEDED' ||
             status == 'SPA_GATE')) ...[
          ElevatedButton.icon(
            icon: provider.isSubmitting
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 14),
            label: Text(
              provider.isSubmitting
                  ? 'Submitting...'
                  : (status == 'SPA_GATE' ? 'RESUBMIT TO SPA' : 'SUBMIT TO SPA'),
              style: AppTypography.workspaceButton(
                color: Colors.white,
                weight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            onPressed: provider.isSubmitting ? null : _handleSubmitToSpa,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.workspaceCorporateNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 10),
        ],

        // SINGLE DOMINANT PRIMARY ACTION: SPA Approve Report (Word-First)
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
              provider.isSubmitting
                  ? (provider.compileStatusMessage ?? 'Compiling Word document...')
                  : 'APPROVE REPORT',
              style: AppTypography.workspaceButton(
                color: Colors.white,
                weight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            onPressed: provider.isSubmitting ? null : _handleSpaApprove,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.workspaceSuccess,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 10),
        ],

        // AFTER APPROVAL ACTIONS: Download Word | Recompile Word | Generate PDF
        if ((isSpa || isAdmin) && (status == 'SPA_CONFIRMED' || status == 'FINAL_DELIVERY' || status == 'CLIENT_DOWNLOADED' || status == 'CLOSED')) ...[
          // 1. Download Word
          OutlinedButton.icon(
            icon: const Icon(Icons.description_outlined, size: 14),
            label: Text(
              'Download Word',
              style: AppTypography.workspaceButton(
                color: AppColors.workspaceCorporateNavy,
                weight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            onPressed: provider.isSubmitting || provider.isGeneratingPdf ? null : _handleDownloadWord,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.workspaceCorporateNavy,
              side: const BorderSide(color: AppColors.workspaceBorder),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Recompile Word
          ElevatedButton.icon(
            icon: provider.isSubmitting
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_fix_high_rounded, size: 14),
            label: Text(
              provider.isSubmitting
                  ? (provider.compileStatusMessage ?? 'Recompiling Word...')
                  : 'Recompile Word',
              style: AppTypography.workspaceButton(
                color: Colors.white,
                weight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            onPressed: provider.isSubmitting || provider.isGeneratingPdf ? null : _handleRecompileWord,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.workspaceCorporateNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),

          // 3. Generate PDF (Completely separate on-demand action)
          ElevatedButton.icon(
            icon: provider.isGeneratingPdf
                ? const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf_rounded, size: 14),
            label: Text(
              provider.isGeneratingPdf ? 'Generating PDF...' : 'Generate PDF',
              style: AppTypography.workspaceButton(
                color: Colors.white,
                weight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            onPressed: provider.isGeneratingPdf || provider.isSubmitting ? null : _handleGeneratePdf,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.workspaceSuccess,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 10),
        ],

        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.workspaceSecondaryText, size: 20),
          tooltip: 'Reload Document Data',
          onPressed: () => provider.loadWorkspace(widget.orderId),
        ),
        const SizedBox(width: 16),
      ],
    ),
  ),
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
        color: AppColors.workspacePanel,
        border: Border(bottom: BorderSide(color: AppColors.workspaceBorder, width: 1.0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
        children: [
          // Property Category Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: AppColors.workspaceSegmentBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.workspaceBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.apartment_rounded, color: AppColors.workspacePrimaryText, size: 13),
                const SizedBox(width: 5),
                Text(
                  propertyType,
                  style: AppTypography.workspaceMicro(
                    color: AppColors.workspacePrimaryText,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 18, color: AppColors.workspaceBorder),
          const SizedBox(width: 12),

          // Owner Metadata
          _buildContextMetaItem(
            label: 'OWNER',
            value: ownerName,
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 18, color: AppColors.workspaceBorder),
          const SizedBox(width: 12),

          // Bank Metadata
          _buildContextMetaItem(
            label: 'BANK',
            value: bankDisplay,
            icon: Icons.account_balance_outlined,
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 18, color: AppColors.workspaceBorder),
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
          Container(width: 1, height: 18, color: AppColors.workspaceBorder),
          const SizedBox(width: 12),

          // Report Identification
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'REPORT REF: ',
                style: AppTypography.workspaceMetadataLabel(),
              ),
              Text(
                reportNum,
                style: AppTypography.workspaceMetadataValue(),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Lifecycle Status Badge (Pill shape, soft background, no hard border)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              status,
              style: AppTypography.workspaceMicro(
                color: _getStatusColor(status),
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildContextMetaItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Tooltip(
      message: '$label: $value',
      waitDuration: const Duration(milliseconds: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.workspaceSecondaryText),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: AppTypography.workspaceMetadataLabel(),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.workspaceMetadataValue(),
            ),
          ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive ? AppShadows.subtleElevated : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.workspacePrimaryText : AppColors.workspaceSecondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTypography.workspaceButton(
                color: isActive ? AppColors.workspacePrimaryText : AppColors.workspaceSecondaryText,
                weight: isActive ? FontWeight.w700 : FontWeight.w500,
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
      case 'CLIENT_DOWNLOADED':
      case 'DELIVERY_READY':
        return AppColors.successAccent;
      case 'ON_HOLD_PAYMENT_PENDING':
        return AppColors.warning;
      case 'DELIVERY_DISPUTED':
        return AppColors.brandRedDark;
      case 'ACTION_NEEDED':
        return AppColors.brandRedDark;
      case 'CLOSED':
        return AppColors.slate;
      default:
        return AppColors.slate;
    }
  }

  /// SPRINT 6 EMERGENCY HOTFIX: Visible Autosave Status Area (Phase 6)
  Widget _buildAutosaveStatusIndicator(DocumentWorkspaceProvider provider) {
    if (provider.isSubmitting && provider.compileStatusMessage != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 6),
            Text(
              provider.compileStatusMessage!,
              style: AppTypography.workspaceMicro(color: AppColors.primaryBlue, weight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    final api = ApiService();
    final isSessionExpired = api.isSessionExpired ||
        (provider.saveErrorMessage != null && provider.saveErrorMessage!.contains('Session expired'));

    if (isSessionExpired) {
      // SAVE STATE #4: ⚠ Session expired — re-authentication required
      return InkWell(
        onTap: () => _showReauthModal(),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            border: Border.all(color: const Color(0xFFFCA5A5)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.workspaceErrorText),
              const SizedBox(width: 5),
              Text(
                'Session expired — re-authentication required',
                style: AppTypography.workspaceMicro(color: AppColors.workspaceErrorText, weight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.workspaceErrorText,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Re-Auth', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.saveState == SaveState.error) {
      // SAVE STATE #3: 🔴 Save failed — edits preserved locally
      return InkWell(
        onTap: () => provider.saveChanges(),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            border: Border.all(color: const Color(0xFFFCA5A5)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                'Save failed — edits preserved locally',
                style: AppTypography.workspaceMicro(color: const Color(0xFFDC2626), weight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.refresh_rounded, size: 13, color: Color(0xFFDC2626)),
            ],
          ),
        ),
      );
    }

    if (provider.isSaving || provider.isAutoSaving || provider.saveState == SaveState.saving) {
      // SAVE STATE #2: 🟡 Saving draft...
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 6),
            Text('Saving draft...', style: AppTypography.workspaceMicro(color: AppColors.workspaceSecondaryText)),
          ],
        ),
      );
    }

    if (provider.saveState == SaveState.dirtyLocal || provider.isDirty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(color: AppColors.workspaceWarning, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('Unsaved edits (cached locally)', style: AppTypography.workspaceMicro(color: AppColors.workspaceWarning, weight: FontWeight.w700)),
          ],
        ),
      );
    }

    // SAVE STATE #1: ✅ All changes saved
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.workspaceSuccess),
          const SizedBox(width: 5),
          Text('All changes saved', style: AppTypography.workspaceMicro(color: AppColors.workspaceSecondaryText)),
        ],
      ),
    );
  }

  /// SPRINT 6 EMERGENCY HOTFIX: Persistent Save Failure Banner (Phase 5)
  Widget _buildPersistentSaveFailureBanner(DocumentWorkspaceProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFEF2F2),
        border: Border(bottom: BorderSide(color: Color(0xFFFCA5A5))),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B)),
                children: [
                  const TextSpan(text: '⚠ Save Failed: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: 'Session expired or connection unavailable. '),
                  TextSpan(
                    text: 'Your edits have been preserved locally.',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade900),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (ApiService().isSessionExpired) ...[
            ElevatedButton(
              onPressed: _showReauthModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.workspaceCorporateNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Re-Authenticate', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
          ],
          ElevatedButton(
            onPressed: provider.isSaving ? null : () => provider.saveChanges(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            child: provider.isSaving
                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                : const Text('Retry Save', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Color(0xFF991B1B)),
            onPressed: () => setState(() => _showPersistentSaveFailure = false),
            tooltip: 'Dismiss',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// SPRINT 6 EMERGENCY HOTFIX: Recovered Local Draft Banner (Phase 9)
  Widget _buildRecoveredDraftBanner(DocumentWorkspaceProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF0FDF4),
        border: Border(bottom: BorderSide(color: Color(0xFFBBF7D0))),
      ),
      child: Row(
        children: [
          const Icon(Icons.restore_page_rounded, color: Color(0xFF16A34A), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Recovered unsaved draft from local backup. All your changes are restored.',
              style: TextStyle(fontSize: 13, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Color(0xFF15803D)),
            onPressed: () {
              provider.hasRecoveredLocalDraft = false;
              provider.notifyChanges();
            },
            tooltip: 'Dismiss',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// FIX 4: Multi-Tab Collision Banner
  Widget _buildMultiTabConflictBanner(DocumentWorkspaceProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBEB),
        border: Border(bottom: BorderSide(color: Color(0xFFFDE68A))),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Workspace is already open in another tab. Opened in Read-Only mode to prevent collisions.',
              style: TextStyle(fontSize: 13, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => provider.keepReadOnlySession(),
            child: const Text('Keep Read-Only', style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => provider.takeOverSession(),
            child: const Text('Take Over Session', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// FIX 4: Session Taken Over Banner
  Widget _buildSessionTakenOverBanner(DocumentWorkspaceProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFEF2F2),
        border: Border(bottom: BorderSide(color: Color(0xFFFECACA))),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Session Taken Over: Another tab took over editing this workspace. Switched to Read-Only mode to protect data integrity.',
              style: TextStyle(fontSize: 13, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => provider.takeOverSession(),
            child: const Text('Reclaim Editing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// FIX 1 & FIX 3: Concurrency Conflict Banner
  Widget _buildRevisionConflictBanner(DocumentWorkspaceProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFEF2F2),
        border: Border(bottom: BorderSide(color: Color(0xFFFECACA))),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_problem_rounded, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Workspace updated elsewhere. Newer revision exists on server. Refresh required to prevent overwrite.',
              style: TextStyle(fontSize: 13, color: Color(0xFF991B1B), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh Workspace', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => provider.loadWorkspace(widget.orderId),
          ),
        ],
      ),
    );
  }

  /// FIX 8: Real-Time Invalidation Notice Banner
  Widget _buildInvalidationBanner(DocumentWorkspaceProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F3FF),
        border: Border(bottom: BorderSide(color: Color(0xFFDDD6FE))),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF7C3AED), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              provider.invalidationNotice ?? 'Workspace locked. Converted to Read-Only mode.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF5B21B6), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// FIX 6: Stale Draft Quarantine Banner
  Widget _buildStaleDraftQuarantineBanner(DocumentWorkspaceProvider provider) {
    final meta = provider.pendingStaleDraftMetadata;
    final timestamp = meta?['timestamp'] ?? 'earlier';
    final draftRev = meta?['workspaceRevision'] ?? 1;
    final serverRev = provider.workspaceModel?.workspaceRevision ?? 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBEB),
        border: Border(bottom: BorderSide(color: Color(0xFFFDE68A))),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Local draft detected from $timestamp (Rev $draftRev), but server has a newer version (Rev $serverRev). Draft held in quarantine.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => provider.discardPendingStaleDraft(),
            child: const Text('Discard Local Draft', style: TextStyle(color: Color(0xFFB45309), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => provider.applyPendingStaleDraft(),
            child: const Text('Apply Anyway', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
