import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../services/api_service.dart';
import '../../document_studio/models/visual_preview_model.dart';
import '../models/document_workspace_model.dart';

/// API Service for the Document Workspace Engine
class DocumentWorkspaceApiService {
  final ApiService _api = ApiService();

  /// Fetches complete document workspace payload with visual preview & active values.
  Future<DocumentWorkspaceModel> getDocumentWorkspace(int orderId) async {
    final response = await _api.dio.get('/api/v1/orders/$orderId/document-workspace');

    if (response.statusCode == 200 && response.data != null) {
      final dynamic raw = response.data is String ? jsonDecode(response.data as String) : response.data;
      return DocumentWorkspaceModel.fromJson(raw as Map<String, dynamic>);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: 'Failed to load document workspace: HTTP ${response.statusCode}',
    );
  }

  /// Delta persistence of in-document input values.
  Future<bool> saveDocumentValues(int orderId, Map<String, String> values) async {
    final response = await _api.dio.post(
      '/api/v1/orders/$orderId/save-document-values',
      data: {'values': values},
    );

    return response.statusCode == 200;
  }

  /// Advances order status from ASSIGNED to SPA_GATE.
  Future<bool> submitToSpa(int orderId) async {
    final response = await _api.dio.post('/api/v1/orders/$orderId/submit-to-spa');
    return response.statusCode == 200;
  }

  /// Approves report, computes fees, and triggers binary DOCX/PDF report compilation.
  Future<Map<String, dynamic>> spaApprove(
    int orderId, {
    required double finalValue,
    Map<String, String>? modifiedValues,
  }) async {
    final response = await _api.dio.post(
      '/api/v1/orders/$orderId/spa-approve',
      data: {
        'finalValue': finalValue,
        if (modifiedValues != null && modifiedValues.isNotEmpty) 'modifiedValues': modifiedValues,
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      final dynamic raw = response.data is String ? jsonDecode(response.data as String) : response.data;
      return raw as Map<String, dynamic>;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: 'Failed to approve document report: HTTP ${response.statusCode}',
    );
  }

  /// Compiles live hydrated preview PDF and returns rendered page metadata.
  Future<VisualPreviewModel> compileLivePreview(int orderId) async {
    final response = await _api.dio.post('/api/v1/orders/$orderId/compile-live-preview');

    if (response.statusCode == 200 && response.data != null) {
      final dynamic raw = response.data is String ? jsonDecode(response.data as String) : response.data;
      return VisualPreviewModel.fromJson(raw as Map<String, dynamic>);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: 'Failed to compile live preview: HTTP ${response.statusCode}',
    );
  }
}
