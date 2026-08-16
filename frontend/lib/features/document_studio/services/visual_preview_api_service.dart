import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../services/api_service.dart';
import '../models/visual_preview_model.dart';

/// API client for interacting with Document Studio visual preview endpoints.
class VisualPreviewApiService {
  final ApiService _api = ApiService();

  /// Fetches visual preview page metadata and coordinate bounding boxes.
  Future<VisualPreviewModel> getVisualPreview(int templateId, {bool force = false}) async {
    final response = await _api.dio.get(
      '/api/v1/studio/templates/$templateId/visual-preview',
      queryParameters: {'force': force},
    );

    if (response.statusCode == 200 && response.data != null) {
      final dynamic raw = response.data is String ? jsonDecode(response.data as String) : response.data;
      return VisualPreviewModel.fromJson(raw as Map<String, dynamic>);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: 'Failed to retrieve visual preview: HTTP ${response.statusCode}',
    );
  }

  /// Builds a fully qualified image URL for a specific template page tile.
  String buildPageImageUrl(int templateId, int pageIndex) {
    final base = _api.dio.options.baseUrl;
    return '$base/api/v1/studio/templates/$templateId/pages/$pageIndex.png';
  }
}
