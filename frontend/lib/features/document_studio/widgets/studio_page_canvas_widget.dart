import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../models/visual_preview_model.dart';
import '../providers/document_studio_provider.dart';
import '../providers/visual_preview_provider.dart';

/// Pixel-perfect paginated Word document canvas rendering high-DPI page sheets
/// and interactive normalized placeholder bounding box overlays.
class StudioPageCanvasWidget extends StatefulWidget {
  final int templateId;

  const StudioPageCanvasWidget({
    super.key,
    required this.templateId,
  });

  @override
  State<StudioPageCanvasWidget> createState() => _StudioPageCanvasWidgetState();
}

class _StudioPageCanvasWidgetState extends State<StudioPageCanvasWidget> {
  final ScrollController _scrollController = ScrollController();
  final ApiService _api = ApiService();

  // Base A4 dimensions in virtual pixels at 100% scale
  static const double basePageWidth = 794.0;
  static const double basePageHeight = 1123.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewProvider = context.watch<VisualPreviewProvider>();
    final studioProvider = context.watch<DocumentStudioProvider>();

    if (previewProvider.isLoading) {
      return _buildLoadingState();
    }

    if (previewProvider.errorMessage != null) {
      return _buildErrorState(previewProvider);
    }

    if (!previewProvider.hasPreview) {
      return _buildEmptyState(previewProvider);
    }

    final previewModel = previewProvider.previewModel!;
    final scale = previewProvider.zoomScale;
    final scaledWidth = basePageWidth * scale;
    final scaledHeight = basePageHeight * scale;

    return Stack(
      children: [
        // ─── Main Multi-Page Viewport ────────────────────────────────
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
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
                          scaledWidth,
                          scaledHeight,
                          studioProvider,
                          previewProvider,
                        ),
                        if (pIdx < previewModel.pages.length - 1)
                          const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // ─── Floating Canvas Controls Toolbar ────────────────────────
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: _buildCanvasToolbar(previewProvider, previewModel),
          ),
        ),
      ],
    );
  }

  Widget _buildPageSheet(
    VisualPageModel page,
    int pageIndex,
    int totalPages,
    double width,
    double height,
    DocumentStudioProvider studioProvider,
    VisualPreviewProvider previewProvider,
  ) {
    final imageUrl = previewProvider.getPageImageUrl(widget.templateId, pageIndex);
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
          // 1. High-DPI Page Image Tile
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
                        const Icon(Icons.broken_image_rounded, size: 40, color: AppColors.slate),
                        const SizedBox(height: 8),
                        Text(
                          'Page ${pageIndex + 1} Preview Unavailable',
                          style: AppTypography.caption(color: AppColors.slate),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. Interactive Coordinate Overlay Layer
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cWidth = constraints.maxWidth;
                final cHeight = constraints.maxHeight;

                return Stack(
                  children: [
                    for (final placeholder in page.placeholders) ...[
                      for (final rect in placeholder.rectangles) ...[
                        _buildPlaceholderBoundingBox(
                          placeholder,
                          rect,
                          cWidth,
                          cHeight,
                          studioProvider,
                          previewProvider,
                        ),
                      ],
                    ],
                  ],
                );
              },
            ),
          ),

          // 3. Page Number Footer Badge
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

  Widget _buildPlaceholderBoundingBox(
    VisualPlaceholderModel placeholder,
    NormalizedRectModel rect,
    double containerWidth,
    double containerHeight,
    DocumentStudioProvider studioProvider,
    VisualPreviewProvider previewProvider,
  ) {
    final isSelected = studioProvider.selectedPlaceholderKey?.toUpperCase() == placeholder.key.toUpperCase();
    final isHovered = previewProvider.hoveredKey?.toUpperCase() == placeholder.key.toUpperCase();

    final left = rect.x * containerWidth;
    final top = rect.y * containerHeight;
    final width = rect.w * containerWidth;
    final height = rect.h * containerHeight;

    final effectiveLabel = studioProvider.getEffectiveLabel(placeholder.key);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => previewProvider.setHoveredKey(placeholder.key),
        onExit: (_) => previewProvider.setHoveredKey(null),
        child: GestureDetector(
          onTap: () {
            if (isSelected) {
              studioProvider.clearSelection();
            } else {
              studioProvider.selectPlaceholder(placeholder.key);
            }
          },
          child: Tooltip(
            message: '<<${placeholder.key}>>\nLabel: $effectiveLabel',
            textStyle: const TextStyle(fontSize: 11, color: Colors.white),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(6),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.deepTeal.withValues(alpha: 0.28)
                    : (isHovered ? AppColors.tealLight.withValues(alpha: 0.35) : AppColors.tealLight.withValues(alpha: 0.12)),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isSelected
                      ? AppColors.deepTeal
                      : (isHovered ? AppColors.deepTeal : AppColors.deepTeal.withValues(alpha: 0.4)),
                  width: isSelected ? 2.0 : (isHovered ? 1.5 : 1.0),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.deepTeal.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasToolbar(VisualPreviewProvider provider, VisualPreviewModel model) {
    final zoomPercent = (provider.zoomScale * 100).round();

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
          // Total Pages
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${model.totalPages} Pages',
              style: AppTypography.caption(color: AppColors.ink).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 18, color: AppColors.hairline),
          const SizedBox(width: 12),

          // Zoom Controls
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 18, color: AppColors.ink),
            tooltip: 'Zoom Out (-15%)',
            onPressed: provider.zoomScale > 0.5 ? provider.zoomOut : null,
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$zoomPercent%',
              textAlign: TextAlign.center,
              style: AppTypography.caption(color: AppColors.ink).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.ink),
            tooltip: 'Zoom In (+15%)',
            onPressed: provider.zoomScale < 2.5 ? provider.zoomIn : null,
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, size: 18, color: AppColors.slate),
            tooltip: 'Reset to 100%',
            onPressed: provider.resetZoom,
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 18, color: AppColors.hairline),
          const SizedBox(width: 12),

          // Reload High-DPI Cache
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.deepTeal),
            tooltip: 'Regenerate High-DPI Preview',
            onPressed: () => provider.loadVisualPreview(widget.templateId, force: true),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.deepTeal),
          const SizedBox(height: 16),
          Text(
            'Rendering Pixel-Perfect Visual Preview...',
            style: AppTypography.bodyMdMedium(color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Converting DOCX to 200 DPI vector pages & extracting coordinate geometry',
            style: AppTypography.bodySm().copyWith(color: AppColors.slate),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(VisualPreviewProvider provider) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.brandRedDark),
            const SizedBox(height: 16),
            Text('Failed to Load Visual Preview', style: AppTypography.heading4().copyWith(color: AppColors.ink)),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'An error occurred while loading preview assets.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm().copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              onPressed: () => provider.loadVisualPreview(widget.templateId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepTeal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(VisualPreviewProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.find_in_page_outlined, size: 48, color: AppColors.slate),
          const SizedBox(height: 12),
          Text('No Preview Pages Available', style: AppTypography.bodyMdMedium(color: AppColors.ink)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Generate Preview'),
            onPressed: () => provider.loadVisualPreview(widget.templateId, force: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepTeal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
