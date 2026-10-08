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

  /// Delta persistence of in-document input values with workspaceRevision concurrency token
  Future<Map<String, dynamic>?> saveDocumentValues(
    int orderId,
    Map<String, String> values, {
    int? workspaceRevision,
  }) async {
    final response = await _api.dio.post(
      '/api/v1/orders/$orderId/save-document-values',
      data: {
        'values': values,
        if (workspaceRevision != null) 'workspaceRevision': workspaceRevision,
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      final dynamic raw = response.data is String ? jsonDecode(response.data as String) : response.data;
      if (raw is Map<String, dynamic>) {
        return raw;
      }
      return {'status': 'SAVED'};
    }
    return null;
  }

  /// FIX 8: Real-time telemetry & invalidation check
  Future<Map<String, dynamic>?> checkWorkspaceTelemetry(int orderId) async {
    try {
      final response = await _api.dio.post('/api/v1/orders/$orderId/heartbeat');
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data is String ? jsonDecode(response.data as String) : response.data;
        if (raw is Map<String, dynamic>) {
          return raw;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Initialize Document Workspace for order
  Future<DocumentWorkspaceModel> initializeWorkspace(int orderId) async {
    final response = await _api.dio.post('/api/v1/orders/$orderId/initialize-workspace');
    if (response.statusCode == 200 && response.data != null) {
      final dynamic raw = response.data is String ? jsonDecode(response.data as String) : response.data;
      return DocumentWorkspaceModel.fromJson(raw as Map<String, dynamic>);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: 'Failed to initialize workspace: HTTP ${response.statusCode}',
    );
  }

  /// SPRINT 6: Bind Template permanently
  Future<Map<String, dynamic>> bindTemplate(int orderId, int templateId, {bool forceSnapshotRebuild = false}) async {
    final response = await _api.dio.post(
      '/api/v1/orders/$orderId/bind-template',
      data: {'templateId': templateId, 'forceSnapshotRebuild': forceSnapshotRebuild},
    );
    if (response.statusCode == 200 && response.data != null) {
      final dynamic raw = response.data is String ? jsonDecode(response.data as String) : response.data;
      return raw as Map<String, dynamic>;
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: 'Failed to bind template: HTTP ${response.statusCode}',
    );
  }

  /// SPRINT 6: Pre-submission Draft Validation Engine
  Future<Map<String, dynamic>> validateDraft(int orderId) async {
    final response = await _api.dio.get('/api/v1/orders/$orderId/validate-draft');
    if (response.statusCode == 200 && response.data != null) {
      final dynamic raw = response.data is String ? jsonDecode(response.data as String) : response.data;
      return raw as Map<String, dynamic>;
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: 'Failed to validate draft: HTTP ${response.statusCode}',
    );
  }

  /// Advances order status to SPA_GATE.
  /// Throws a [DioException] with the server's validation message on HTTP 400,
  /// so the caller can surface the exact list of missing fields to the PA.
  Future<bool> submitToSpa(int orderId) async {
    final response = await _api.dio.post(
      '/api/v1/orders/$orderId/submit-to-spa',
      options: Options(validateStatus: (status) => true),
    );
    if (response.statusCode == 200) return true;

    // Extract the server-provided error detail from the 400 response body
    final body = response.data;
    final String serverMsg;
    if (body is Map && body['error'] != null) {
      serverMsg = body['error'] as String;
    } else if (body is String && body.isNotEmpty) {
      serverMsg = body;
    } else {
      serverMsg = 'Submission failed (HTTP ${response.statusCode})';
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: serverMsg,
      message: serverMsg,
    );
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

  /// Generates PDF on-demand as a separate post-approval action
  Future<Map<String, dynamic>> generatePdf(int orderId) async {
    final response = await _api.dio.post('/api/v1/orders/$orderId/generate-pdf');
    if (response.statusCode == 200 && response.data != null) {
      final dynamic raw = response.data is String ? jsonDecode(response.data as String) : response.data;
      return raw as Map<String, dynamic>;
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: 'Failed to generate PDF: HTTP ${response.statusCode}',
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
