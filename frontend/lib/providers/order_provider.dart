import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';

class UploadResult {
  final bool success;
  final String? errorMessage;
  UploadResult({required this.success, this.errorMessage});
}

class OrderProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<dynamic> _clientOrders = [];
  List<dynamic> _unassignedPool = [];
  List<dynamic> _paOrders = [];
  List<dynamic> _allOrders = [];
  List<dynamic> _activeTemplates = [];
  bool _isLoadingTemplates = false;
  dynamic _currentOrder;
  Timer? _heartbeatTimer;
  String? _lastError;

  List<dynamic> get clientOrders => _clientOrders;
  List<dynamic> get unassignedPool => _unassignedPool;
  List<dynamic> get paOrders => _paOrders;
  List<dynamic> get allOrders => _allOrders;
  List<dynamic> get activeTemplates => _activeTemplates;
  bool get isLoadingTemplates => _isLoadingTemplates;
  dynamic get currentOrder => _currentOrder;
  String? get lastError => _lastError;

  Future<void> fetchClientOrders() async {
    try {
      final response = await _apiService.dio.get('/api/v1/orders/client');
      if (response.statusCode == 200) {
        _clientOrders = response.data;
        notifyListeners();
      }
    } catch (e) {
      // Error fetching client orders
    }
  }

  Future<void> fetchUnassignedPool() async {
    try {
      final response = await _apiService.dio.get('/api/v1/orders/unassigned');
      if (response.statusCode == 200) {
        _unassignedPool = response.data;
        notifyListeners();
      }
    } catch (e) {
      // Error fetching unassigned pool
    }
  }

  Future<void> fetchPaOrders() async {
    try {
      final response = await _apiService.dio.get('/api/v1/orders/pa');
      if (response.statusCode == 200) {
        _paOrders = response.data;
        notifyListeners();
      }
    } catch (e) {
      // Error fetching pa orders
    }
  }

  Future<void> fetchAllOrders() async {
    try {
      final response = await _apiService.dio.get('/api/v1/orders/all');
      if (response.statusCode == 200) {
        _allOrders = response.data;
        notifyListeners();
      }
    } catch (e) {
      // Error fetching all orders
    }
  }

  Future<void> fetchActiveTemplates() async {
    _isLoadingTemplates = true;
    notifyListeners();
    try {
      final response = await _apiService.dio.get('/api/v1/templates/active');
      debugPrint('[TEMPLATE_API] status=${response.statusCode}');
      debugPrint('[TEMPLATE_API] body=${jsonEncode(response.data)}');
      if (response.statusCode == 200 && response.data is List) {
        _activeTemplates = response.data;
      }
    } catch (e) {
      debugPrint('[TEMPLATE_API] error=$e');
      // Error fetching active templates — _activeTemplates unchanged
    } finally {
      _isLoadingTemplates = false;
      notifyListeners();
    }
  }

  Future<bool> associateTemplate(int orderId, int templateId) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/orders/$orderId/template',
        queryParameters: {'templateId': templateId},
      );
      if (response.statusCode == 200) {
        await fetchPaOrders();
        return true;
      }
    } catch (e) {
      // Error associating template
    }
    return false;
  }

  Future<Map<String, dynamic>?> fetchOrderInputs(int orderId) async {
    try {
      final response = await _apiService.dio.get('/api/v1/orders/$orderId/inputs');
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (e) {
      // Error fetching inputs
    }
    return null;
  }


  Future<dynamic> saveDraft(String propertyCategory, String purpose, double estimatedValue, Map<String, String> inputs, {int? id}) async {
    try {
      final response = await _apiService.dio.post('/api/v1/orders/draft', data: {
        'id': id,
        'propertyCategory': propertyCategory,
        'purpose': purpose,
        'estimatedValue': estimatedValue,
        'inputs': inputs,
      });
      if (response.statusCode == 200) {
        await fetchClientOrders();
        return response.data;
      }
    } catch (e) {
      // Error saving draft
    }
    return null;
  }

  Future<bool> deleteDraft(int orderId) async {
    try {
      final response = await _apiService.dio.delete('/api/v1/orders/$orderId/draft');
      if (response.statusCode == 200) {
        await fetchClientOrders();
        return true;
      }
    } catch (e) {
      // Error deleting draft
    }
    return false;
  }

  Future<bool> submitIntake(int orderId, double depositAmount) async {
    try {
      // 1. Process simulated deposit payment
      final payResponse = await _apiService.dio.post('/api/v1/payments/process-deposit', queryParameters: {
        'orderId': orderId,
        'amount': depositAmount
      });
      
      if (payResponse.statusCode == 200) {
        // 2. Submit order intake and calculate SLA
        final submitResponse = await _apiService.dio.post('/api/v1/orders/$orderId/submit');
        if (submitResponse.statusCode == 200) {
          await fetchClientOrders();
          return true;
        }
      }
    } catch (e) {
      // Error submitting intake
    }
    return false;
  }

  Future<bool> claimOrder(int orderId) async {
    try {
      final response = await _apiService.dio.post('/api/v1/orders/$orderId/claim');
      if (response.statusCode == 200) {
        await fetchUnassignedPool();
        startHeartbeat(orderId);
        return true;
      }
    } catch (e) {
      // Error claiming order
    }
    return false;
  }

  Future<dynamic> createStaffReport(String clientName, String bankName, String branchName, int templateId) async {
    _lastError = null;
    try {
      final response = await _apiService.dio.post('/api/v1/orders/create-by-staff', data: {
        'clientName': clientName,
        'bankName': bankName,
        'branchName': branchName,
        'templateId': templateId,
      });
      if (response.statusCode == 200) {
        return response.data;
      }
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response?.data['error'] != null) {
        _lastError = e.response?.data['error'].toString();
      } else {
        _lastError = e.message ?? "Error creating staff report";
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }

  void startHeartbeat(int orderId) {
    _heartbeatTimer?.cancel();
    // Send telemetry heartbeat every 30 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        await _apiService.dio.post('/api/v1/orders/$orderId/heartbeat');
      } catch (e) {
        // Heartbeat failure
      }
    });
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<bool> pauseOrder(int orderId, String reason) async {
    try {
      final response = await _apiService.dio.post('/api/v1/orders/$orderId/pause', queryParameters: {
        'reason': reason
      });
      if (response.statusCode == 200) {
        stopHeartbeat();
        await fetchUnassignedPool();
        return true;
      }
    } catch (e) {
      // Error pausing order
    }
    return false;
  }

  Future<bool> resumeOrder(int orderId) async {
    try {
      final response = await _apiService.dio.post('/api/v1/orders/$orderId/resume');
      if (response.statusCode == 200) {
        await fetchClientOrders();
        return true;
      }
    } catch (e) {
      // Error resuming order
    }
    return false;
  }

  Future<bool> submitReportDraft(int orderId, Map<String, String> inputs) async {
    try {
      final response = await _apiService.dio.post('/api/v1/orders/$orderId/submit-draft', data: inputs);
      if (response.statusCode == 200) {
        await fetchAllOrders();
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Error submitting report draft
    }
    return false;
  }

  Future<bool> spaVerify(int orderId, double? finalValue) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (finalValue != null) {
        queryParams['finalValue'] = finalValue;
      }
      final response = await _apiService.dio.post('/api/v1/orders/$orderId/spa-verify', queryParameters: queryParams);
      if (response.statusCode == 200) {
        await fetchAllOrders();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> revertToReview(int orderId) async {
    try {
      final response = await _apiService.dio.post('/api/v1/orders/$orderId/revert-to-review');
      if (response.statusCode == 200) {
        await fetchAllOrders();
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Error reverting to review
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> fetchRevisions(int orderId) async {
    try {
      final response = await _apiService.dio.get('/api/v1/orders/$orderId/revisions');
      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (_) {}
    return [];
  }

  Future<Uint8List?> downloadRevisionPdf(int orderId, int revNumber) async {
    try {
      final response = await _apiService.dio.get<List<int>>(
        '/api/v1/orders/$orderId/revisions/$revNumber/pdf',
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data!);
      }
    } catch (_) {}
    return null;
  }

  Future<Uint8List?> downloadRevisionDocx(int orderId, int revNumber) async {
    try {
      final response = await _apiService.dio.get<List<int>>(
        '/api/v1/orders/$orderId/revisions/$revNumber/docx',
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data!);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> processBalancePayment(int orderId, double amount) async {
    try {
      final response = await _apiService.dio.post('/api/v1/payments/process-balance', queryParameters: {
        'orderId': orderId,
        'amount': amount
      });
      if (response.statusCode == 200) {
        await fetchClientOrders();
        return true;
      }
    } catch (e) {
      // Payment failure
    }
    return false;
  }

  Future<bool> releaseGate(int orderId) async {
    try {
      final response = await _apiService.dio.post('/api/v1/orders/$orderId/release-gate');
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      // Release failure
    }
    return false;
  }

  Future<Map<String, dynamic>?> downloadReport(int orderId) async {
    try {
      final response = await _apiService.dio.get('/api/v1/orders/$orderId/download');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      // Error downloading report
    }
    return null;
  }

  String? _lastDocxError;
  String? get lastDocxError => _lastDocxError;

  Future<Uint8List?> downloadReportDocx(int orderId) async {
    _lastDocxError = null;
    try {
      final response = await _apiService.dio.get(
        '/api/v1/orders/$orderId/download-docx',
        options: Options(
          responseType: ResponseType.bytes,
          // Explicitly override the global 'Accept: application/json' header.
          // Without this, Spring's content negotiation picks Jackson which
          // Base64-encodes the byte[] into a JSON string instead of raw binary.
          headers: {
            'Accept': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document, application/octet-stream, */*',
          },
        ),
      );
      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      }
      _lastDocxError = 'Server returned status ${response.statusCode}';
    } on DioException catch (e) {
      if (e.response?.data != null) {
        try {
          // Try to decode the error body (may be bytes or string)
          final raw = e.response!.data;
          if (raw is List<int>) {
            _lastDocxError = String.fromCharCodes(raw);
          } else {
            _lastDocxError = raw.toString();
          }
        } catch (_) {
          _lastDocxError = e.message ?? 'DOCX download failed (${e.response?.statusCode})';
        }
      } else {
        _lastDocxError = e.message ?? 'DOCX download failed';
      }
    } catch (e) {
      _lastDocxError = e.toString();
    }
    return null;
  }

  Future<List<dynamic>?> fetchOrderDocuments(int orderId) async {
    try {
      final response = await _apiService.dio.get('/api/v1/orders/$orderId/documents');
      if (response.statusCode == 200) {
        return List<dynamic>.from(response.data);
      }
    } catch (e) {
      // Error fetching documents
    }
    return null;
  }

  Future<UploadResult> uploadDocument(int orderId, String category, String filename, List<int> bytes) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
        'category': category,
      });
      final response = await _apiService.dio.post(
        '/api/v1/orders/$orderId/documents/upload',
        data: formData,
      );
      return UploadResult(success: response.statusCode == 200);
    } on DioException catch (e) {
      String msg = "Failed to upload document.";
      if (e.response?.data != null && e.response!.data is String) {
        msg = e.response!.data.toString();
      } else if (e.response?.data != null && e.response!.data is Map && e.response!.data['message'] != null) {
        msg = e.response!.data['message'].toString();
      } else if (e.message != null) {
        msg = e.message!;
      }
      return UploadResult(success: false, errorMessage: msg);
    } catch (e) {
      return UploadResult(success: false, errorMessage: e.toString());
    }
  }

  Future<Uint8List?> downloadDocument(int documentId) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/orders/documents/$documentId/download',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': 'application/octet-stream, */*',
          },
        ),
      );
      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      }
    } catch (e) {
      // Error downloading document
    }
    return null;
  }

  @override
  void dispose() {
    stopHeartbeat();
    super.dispose();
  }
}
