import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../document_studio/models/visual_preview_model.dart';
import '../providers/document_workspace_provider.dart';

/// Read-only Compiled Final PDF Preview Viewer with multi-page scrolling and zoom controls.
class LivePreviewViewerWidget extends StatefulWidget {
  const LivePreviewViewerWidget({super.key});

  @override
  State<LivePreviewViewerWidget> createState() => _LivePreviewViewerWidgetState();
}

class _LivePreviewViewerWidgetState extends State<LivePreviewViewerWidget> {
  final ScrollController _scrollController = ScrollController();
  final ApiService _api = ApiService();

  static const double basePageWidth = 794.0;
  static const double basePageHeight = 1123.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentWorkspaceProvider>();

    if (provider.isCompilingPreview) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairline),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.deepTeal),
              const SizedBox(height: 20),
              Text('Compiling True Final Document...', style: AppTypography.heading4().copyWith(color: AppColors.ink)),
              const SizedBox(height: 8),
              Text(
                'Hydrating Word XML runs with your draft values & rendering 200 DPI vector pages',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm().copyWith(color: AppColors.slate),
              ),
            ],
          ),
        ),
      );
    }

    final preview = provider.livePreviewModel;
    if (preview == null || preview.pages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_outlined, size: 48, color: AppColors.slate),
            const SizedBox(height: 16),
            Text('No compiled preview generated yet.', style: AppTypography.bodyMdMedium(color: AppColors.ink)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Compile Final Preview'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.deepTeal, foregroundColor: Colors.white),
              onPressed: () => provider.refreshLivePreview(),
            ),
          ],
        ),
      );
    }

    final scale = provider.zoomScale;
    final scaledWidth = basePageWidth * scale;
    final scaledHeight = basePageHeight * scale;

    return Stack(
      children: [
        // ─── Multi-Page Scrollable Viewport ──────────────────────────
        Positioned.fill(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 90),
            child: Center(
              child: Column(
                children: [
                  for (int pIdx = 0; pIdx < preview.pages.length; pIdx++) ...[
                    _buildCompiledPageSheet(
                      preview.pages[pIdx],
                      pIdx,
                      preview.totalPages,
                      provider.workspaceModel!.orderId,
                      scaledWidth,
                      scaledHeight,
                    ),
                    if (pIdx < preview.pages.length - 1) const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ),

        // ─── Floating Zoom & Recompile Toolbar ───────────────────────
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: _buildPreviewToolbar(provider, preview),
          ),
        ),
      ],
    );
  }

  Widget _buildCompiledPageSheet(
    VisualPageModel page,
    int pageIndex,
    int totalPages,
    int orderId,
    double width,
    double height,
  ) {
    final baseUrl = _api.dio.options.baseUrl;
    final imageUrl = '$baseUrl/api/v1/orders/$orderId/live-pages/$pageIndex.png';
    final authToken = _api.token;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                imageUrl,
                headers: authToken != null ? {'Authorization': 'Bearer $authToken'} : null,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                          : null,
                      color: AppColors.deepTeal,
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text('Page ${pageIndex + 1} tile loading error', style: AppTypography.caption(color: AppColors.slate)),
                  );
                },
              ),
            ),
          ),

          // Page indicator badge
          Positioned(
            bottom: 8,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Page ${pageIndex + 1} of $totalPages (Final PDF)',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewToolbar(DocumentWorkspaceProvider provider, VisualPreviewModel model) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${model.totalPages} Pages (True Final)',
              style: AppTypography.caption(color: AppColors.deepTeal).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 18, color: AppColors.hairline),
          const SizedBox(width: 12),

          // Zoom Controls
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 18, color: AppColors.ink),
            tooltip: 'Zoom Out',
            onPressed: provider.canZoomOut ? provider.zoomOut : null,
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${provider.zoomPercentage}%',
              textAlign: TextAlign.center,
              style: AppTypography.caption(color: AppColors.ink).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.ink),
            tooltip: 'Zoom In',
            onPressed: provider.canZoomIn ? provider.zoomIn : null,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, size: 18, color: AppColors.slate),
            tooltip: 'Reset Zoom (100%)',
            onPressed: provider.resetZoom,
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 18, color: AppColors.hairline),
          const SizedBox(width: 12),

          // Re-compile Button
          ElevatedButton.icon(
            icon: const Icon(Icons.sync_rounded, size: 14),
            label: const Text('Re-compile Preview'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: provider.refreshLivePreview,
          ),
        ],
      ),
    );
  }
}
