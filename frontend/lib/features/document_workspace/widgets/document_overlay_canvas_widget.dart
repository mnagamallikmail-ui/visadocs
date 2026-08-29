import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../document_studio/models/visual_preview_model.dart';
import '../providers/document_workspace_provider.dart';
import 'inline_overlay_input_widget.dart';

/// Document Workspace Canvas rendering pixel-perfect vector page sheets with inline editable overlays.
class DocumentOverlayCanvasWidget extends StatefulWidget {
  const DocumentOverlayCanvasWidget({super.key});

  @override
  State<DocumentOverlayCanvasWidget> createState() => _DocumentOverlayCanvasWidgetState();
}

class _DocumentOverlayCanvasWidgetState extends State<DocumentOverlayCanvasWidget> {
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

    if (provider.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.deepTeal),
            const SizedBox(height: 16),
            Text('Loading Document Workspace...', style: AppTypography.bodyMdMedium(color: AppColors.ink)),
            const SizedBox(height: 4),
            Text('Streaming high-DPI document layout and field overlays',
                style: AppTypography.bodySm().copyWith(color: AppColors.slate)),
          ],
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.brandRedDark),
              const SizedBox(height: 12),
              Text('Unable to Load Document', style: AppTypography.heading4().copyWith(color: AppColors.ink)),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySm().copyWith(color: AppColors.slate),
              ),
            ],
          ),
        ),
      );
    }

    final workspace = provider.workspaceModel;
    if (workspace == null || workspace.visualPreview.pages.isEmpty) {
      return Center(
        child: Text('No document pages available for this order.',
            style: AppTypography.bodyMdMedium(color: AppColors.slate)),
      );
    }

    final previewModel = workspace.visualPreview;
    final scale = provider.zoomScale;
    final scaledWidth = basePageWidth * scale;
    final scaledHeight = basePageHeight * scale;

    return Stack(
      children: [
        // ─── Multi-Page Scrollable Viewport ──────────────────────────
        Positioned.fill(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 80),
            child: Center(
              child: Column(
                children: [
                  for (int pIdx = 0; pIdx < previewModel.pages.length; pIdx++) ...[
                    _buildPageSheet(
                      previewModel.pages[pIdx],
                      pIdx,
                      previewModel.totalPages,
                      previewModel.templateId,
                      scaledWidth,
                      scaledHeight,
                      provider.isReadOnly,
                    ),
                    if (pIdx < previewModel.pages.length - 1) const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ),

        // ─── Floating Zoom Toolbar ───────────────────────────────────
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: _buildCanvasToolbar(provider, previewModel),
          ),
        ),
      ],
    );
  }

  Widget _buildPageSheet(
    VisualPageModel page,
    int pageIndex,
    int totalPages,
    int templateId,
    double width,
    double height,
    bool readOnly,
  ) {
    final baseUrl = _api.dio.options.baseUrl;
    final imageUrl = '$baseUrl/api/v1/studio/templates/$templateId/pages/$pageIndex.png';
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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 1. Vector 200 DPI Page Image Tile
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image_rounded, size: 36, color: AppColors.slate),
                        const SizedBox(height: 8),
                        Text(
                          'Page ${pageIndex + 1} Preview Tile Unavailable',
                          style: AppTypography.caption(color: AppColors.slate),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. Interactive Input Overlays
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cWidth = constraints.maxWidth;
                final cHeight = constraints.maxHeight;

                return Stack(
                  children: [
                    for (final placeholder in page.placeholders) ...[
                      for (final rect in placeholder.rectangles) ...[
                        InlineOverlayInputWidget(
                          placeholder: placeholder,
                          rect: rect,
                          containerWidth: cWidth,
                          containerHeight: cHeight,
                          readOnly: readOnly,
                        ),
                      ],
                    ],
                  ],
                );
              },
            ),
          ),

          // 3. Page Number Badge
          Positioned(
            bottom: 8,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Page ${pageIndex + 1} of $totalPages',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasToolbar(DocumentWorkspaceProvider provider, VisualPreviewModel model) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
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
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${model.totalPages} Pages (Template View)',
              style: AppTypography.caption(color: AppColors.ink).copyWith(fontWeight: FontWeight.w700),
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
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, size: 18, color: AppColors.slate),
            tooltip: 'Reset Zoom (100%)',
            onPressed: provider.resetZoom,
          ),
        ],
      ),
    );
  }
}
