import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/visual_preview_model.dart';
import '../services/visual_preview_api_service.dart';

/// State management provider for pixel-perfect visual previews, zoom scaling, and page navigation.
class VisualPreviewProvider extends ChangeNotifier {
  final VisualPreviewApiService _apiService = VisualPreviewApiService();

  bool _isLoading = false;
  String? _errorMessage;
  VisualPreviewModel? _previewModel;

  double _zoomScale = 1.0;
  int _currentPageIndex = 0;
  String? _hoveredKey;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  VisualPreviewModel? get previewModel => _previewModel;
  double get zoomScale => _zoomScale;
  int get currentPageIndex => _currentPageIndex;
  String? get hoveredKey => _hoveredKey;
  bool get hasPreview => _previewModel != null && _previewModel!.pages.isNotEmpty;

  /// Loads or refreshes the pixel-perfect visual preview for a template.
  Future<void> loadVisualPreview(int templateId, {bool force = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final model = await _apiService.getVisualPreview(templateId, force: force);
      _previewModel = model;
      _currentPageIndex = 0;
    } on DioException catch (dioErr) {
      if (dioErr.response?.statusCode == 403) {
        _errorMessage = 'Document Studio is restricted or disabled for your role.';
      } else if (dioErr.response?.statusCode == 404) {
        _errorMessage = 'Template #$templateId was not found.';
      } else {
        final msg = dioErr.response?.data?['error']?.toString();
        _errorMessage = msg ?? dioErr.message ?? 'Failed to load visual preview';
      }
    } catch (e) {
      _errorMessage = 'Unexpected visual preview error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets zoom scale clamped between 50% (0.5) and 250% (2.5).
  void setZoom(double scale) {
    _zoomScale = scale.clamp(0.5, 2.5);
    notifyListeners();
  }

  /// Increments zoom by +15%.
  void zoomIn() {
    setZoom(_zoomScale + 0.15);
  }

  /// Decrements zoom by -15%.
  void zoomOut() {
    setZoom(_zoomScale - 0.15);
  }

  /// Resets zoom back to standard 100% (1.0).
  void resetZoom() {
    setZoom(1.0);
  }

  /// Calculates fit-to-width scale relative to viewport width.
  void fitWidth(double viewportWidth) {
    if (_previewModel == null || _previewModel!.pageDimensions.widthPt <= 0) {
      resetZoom();
      return;
    }
    // Target content width ~ 780px standard base
    final available = viewportWidth - 80;
    if (available > 0) {
      final scale = available / 780.0;
      setZoom(scale);
    }
  }

  /// Updates the current active visible page index.
  void setCurrentPage(int index) {
    if (_currentPageIndex != index) {
      _currentPageIndex = index;
      notifyListeners();
    }
  }

  /// Sets or clears the currently hovered placeholder key.
  void setHoveredKey(String? key) {
    if (_hoveredKey != key) {
      _hoveredKey = key;
      notifyListeners();
    }
  }

  /// Builds the full URL for a page image.
  String getPageImageUrl(int templateId, int pageIndex) {
    return _apiService.buildPageImageUrl(templateId, pageIndex);
  }
}
