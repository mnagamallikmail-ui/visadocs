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


  Future<dynamic> saveDraft(String propertyCategory, String purpose, double estimatedValue, Map<String, String> inputs, {int? id, String? serviceCategory}) async {
    try {
      final payload = <String, dynamic>{
        'id': id,
        'propertyCategory': propertyCategory,
        'purpose': purpose,
        'estimatedValue': estimatedValue,
        'inputs': inputs,
      };
      if (serviceCategory != null && serviceCategory.isNotEmpty) {
        payload['serviceCategory'] = serviceCategory;
      }
      final response = await _apiService.dio.post('/api/v1/orders/draft', data: payload);
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

  /// SPRINT 1: Submit client valuation request with document validation and Telegram alert
  Future<Map<String, dynamic>?> submitRequest(int orderId) async {
    try {
      final response = await _apiService.dio.post('/api/v1/orders/$orderId/submit-request');
      if (response.statusCode == 200 && response.data != null) {
        await fetchClientOrders();
        return Map<String, dynamic>.from(response.data);
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      return {'error': e.message ?? 'Submission error'};
    } catch (e) {
      return {'error': e.toString()};
    }
    return null;
  }

  // ── SPRINT 2: Quotation Engine Methods ──

  Future<Map<String, dynamic>?> provideQuote(int orderId, Map<String, dynamic> quoteData) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/orders/$orderId/provide-quote',
        data: quoteData,
      );
      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        return Map<String, dynamic>.from(e.response!.data);
      }
      return {'error': e.message ?? 'Quotation submission failed'};
    } catch (e) {
      return {'error': e.toString()};
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchOrderQuote(int orderId) async {
    try {
      final response = await _apiService.dio.get('/api/v1/orders/$orderId/quote');
      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map) {
        return Map<String, dynamic>.from(e.response!.data);
      }
    } catch (_) {}
    return null;
  }

  Future<Uint8List?> downloadQuotePdf(int orderId) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/orders/$orderId/quote-pdf',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/pdf'},
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data);
      }
    } catch (_) {}
    return null;
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

  Future<bool> pauseOrder(int orderId, String reason, {String? description}) async {
    try {
      final Map<String, dynamic> queryParams = {'reason': reason};
      if (description != null && description.isNotEmpty) {
        queryParams['description'] = description;
      }
      final response = await _apiService.dio.post('/api/v1/orders/$orderId/pause', queryParameters: queryParams);
      if (response.statusCode == 200) {
        stopHeartbeat();
        await fetchPaOrders();
        await fetchUnassignedPool();
        await fetchAllOrders();
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
        await fetchPaOrders();
        await fetchClientOrders();
        await fetchAllOrders();
        startHeartbeat(orderId);
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

  String? _lastPdfError;
  String? get lastPdfError => _lastPdfError;

  Future<Uint8List?> downloadReportPdf(int orderId) async {
    _lastPdfError = null;
    try {
      final response = await _apiService.dio.get(
        '/api/v1/orders/$orderId/download-pdf',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept': 'application/pdf, application/octet-stream, */*',
          },
        ),
      );
      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      }
      _lastPdfError = 'Server returned status ${response.statusCode}';
    } on DioException catch (e) {
      if (e.response?.data != null) {
        try {
          final raw = e.response!.data;
          if (raw is List<int>) {
            _lastPdfError = String.fromCharCodes(raw);
          } else {
            _lastPdfError = raw.toString();
          }
        } catch (_) {
          _lastPdfError = e.message ?? 'PDF download failed (${e.response?.statusCode})';
        }
      } else {
        _lastPdfError = e.message ?? 'PDF download failed';
      }
    } catch (e) {
      _lastPdfError = e.toString();
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

  Future<Map<String, dynamic>?> fetchPaymentDetails(int orderId) async {
    try {
      final response = await _apiService.dio.get('/api/v1/orders/$orderId/payment-details');
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (e) {
      // Error fetching payment details
    }
    return null;
  }

  Future<Map<String, dynamic>?> submitPaymentProof({
    required int orderId,
    required String utrNumber,
    required String paymentMethod,
    required String paymentDate,
    required double amountPaid,
    String? notes,
    required List<int> fileBytes,
    required String filename,
  }) async {
    if (fileBytes.isEmpty) {
      return {'error': 'Payment proof receipt file cannot be empty.'};
    }
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(fileBytes, filename: filename),
        'utrNumber': utrNumber,
        'paymentMethod': paymentMethod,
        'paymentDate': paymentDate,
        'amountPaid': amountPaid,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });

      final response = await _apiService.dio.post(
        '/api/v1/orders/$orderId/submit-payment',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        await fetchClientOrders();
        await fetchAllOrders();
        return Map<String, dynamic>.from(response.data);
      }
      return {'error': 'Server returned unexpected status: ${response.statusCode}'};
    } on DioException catch (e) {
      String msg = "Payment submission failed.";
      if (e.response?.data != null && e.response!.data is Map && e.response!.data['error'] != null) {
        msg = e.response!.data['error'].toString();
      } else if (e.response?.data != null && e.response!.data is String) {
        msg = e.response!.data.toString();
      } else if (e.message != null) {
        msg = e.message!;
      }
      return {'error': msg};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> verifyPayment({
    required int orderId,
    double? verifiedAmount,
    String? adminNotes,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/orders/$orderId/verify-payment',
        data: {
          if (verifiedAmount != null) 'verifiedAmount': verifiedAmount,
          if (adminNotes != null && adminNotes.isNotEmpty) 'adminNotes': adminNotes,
        },
      );
      if (response.statusCode == 200) {
        await fetchPaymentReviewQueue();
        await fetchReleaseQueue();
        await fetchAllOrders();
        return Map<String, dynamic>.from(response.data);
      }
    } on DioException catch (e) {
      String msg = "Payment verification failed.";
      if (e.response?.data != null && e.response!.data is Map && e.response!.data['error'] != null) {
        msg = e.response!.data['error'].toString();
      }
      return {'error': msg};
    } catch (e) {
      return {'error': e.toString()};
    }
    return {'error': 'Verification failed.'};
  }

  Future<Map<String, dynamic>?> rejectPayment({
    required int orderId,
    required String rejectionReason,
    String? adminNotes,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/orders/$orderId/reject-payment',
        data: {
          'rejectionReason': rejectionReason,
          if (adminNotes != null && adminNotes.isNotEmpty) 'adminNotes': adminNotes,
        },
      );
      if (response.statusCode == 200) {
        await fetchAllOrders();
        return Map<String, dynamic>.from(response.data);
      }
    } on DioException catch (e) {
      String msg = "Payment rejection failed.";
      if (e.response?.data != null && e.response!.data is Map && e.response!.data['error'] != null) {
        msg = e.response!.data['error'].toString();
      }
      return {'error': msg};
    } catch (e) {
      return {'error': e.toString()};
    }
    return {'error': 'Rejection failed.'};
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SPRINT 4: Admin Controlled Pool Release
  // ══════════════════════════════════════════════════════════════════════════

  List<dynamic> _releaseQueue = [];
  List<dynamic> get releaseQueue => _releaseQueue;

  List<dynamic> _paymentReviewQueue = [];
  List<dynamic> get paymentReviewQueue => _paymentReviewQueue;

  Future<void> fetchPaymentReviewQueue() async {
    try {
      final response = await _apiService.dio.get('/api/v1/orders/payment-review-queue');
      if (response.statusCode == 200) {
        _paymentReviewQueue = response.data is List ? response.data : [];
        notifyListeners();
      }
    } on DioException catch (e) {
      debugPrint('[PAYMENT_REVIEW_QUEUE] Error: ${e.response?.data}');
    } catch (e) {
      debugPrint('[PAYMENT_REVIEW_QUEUE] Error: $e');
    }
  }

  Future<void> fetchReleaseQueue() async {
    try {
      final response = await _apiService.dio.get('/api/v1/orders/release-queue');
      if (response.statusCode == 200) {
        _releaseQueue = response.data is List ? response.data : [];
        notifyListeners();
      }
    } on DioException catch (e) {
      debugPrint('[RELEASE_QUEUE] Error: ${e.response?.data}');
    } catch (e) {
      debugPrint('[RELEASE_QUEUE] Error: $e');
    }
  }

  Future<Map<String, dynamic>?> waivePayment({
    required int orderId,
    String? reason,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/admin/orders/$orderId/waive-payment',
        data: {
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      if (response.statusCode == 200) {
        await fetchPaymentReviewQueue();
        await fetchReleaseQueue();
        await fetchAllOrders();
        return Map<String, dynamic>.from(response.data);
      }
    } on DioException catch (e) {
      String msg = 'Waive payment failed.';
      if (e.response?.data != null && e.response!.data is Map && e.response!.data['message'] != null) {
        msg = e.response!.data['message'].toString();
      }
      return {'error': msg};
    } catch (e) {
      return {'error': e.toString()};
    }
    return {'error': 'Waive payment failed.'};
  }

  Future<Map<String, dynamic>?> releaseToPool({
    required int orderId,
    String? intakeNotes,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/orders/$orderId/release-to-pool',
        data: {
          if (intakeNotes != null && intakeNotes.isNotEmpty) 'intakeNotes': intakeNotes,
        },
      );
      if (response.statusCode == 200) {
        await fetchReleaseQueue();
        await fetchAllOrders();
        await fetchUnassignedPool();
        return Map<String, dynamic>.from(response.data);
      }
    } on DioException catch (e) {
      String msg = 'Release to pool failed.';
      if (e.response?.data != null && e.response!.data is Map && e.response!.data['error'] != null) {
        msg = e.response!.data['error'].toString();
      }
      return {'error': msg};
    } catch (e) {
      return {'error': e.toString()};
    }
    return {'error': 'Release failed.'};
  }

  Future<Map<String, dynamic>?> holdIntake({
    required int orderId,
    required String holdReason,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/orders/$orderId/hold-intake',
        data: {'holdReason': holdReason},
      );
      if (response.statusCode == 200) {
        await fetchReleaseQueue();
        await fetchAllOrders();
        return Map<String, dynamic>.from(response.data);
      }
    } on DioException catch (e) {
      String msg = 'Hold intake failed.';
      if (e.response?.data != null && e.response!.data is Map && e.response!.data['error'] != null) {
        msg = e.response!.data['error'].toString();
      }
      return {'error': msg};
    } catch (e) {
      return {'error': e.toString()};
    }
    return {'error': 'Hold failed.'};
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SPRINT 6: Document Workspace & SPA Gate Lifecycle
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> initializeWorkspace(int orderId) async {
    _lastError = null;
    try {
      final response = await _apiService.dio.post('/api/v1/orders/$orderId/initialize-workspace');
      if (response.statusCode == 200 && response.data != null) {
        await fetchPaOrders();
        await fetchAllOrders();
        return Map<String, dynamic>.from(response.data);
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map && e.response!.data['message'] != null) {
        _lastError = e.response!.data['message'].toString();
      } else {
        _lastError = e.message ?? "Failed to initialize workspace";
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }

  Future<Map<String, dynamic>?> bindTemplate(int orderId, int templateId, {bool forceSnapshotRebuild = false}) async {
    _lastError = null;
    try {
      final response = await _apiService.dio.post(
        '/api/v1/orders/$orderId/bind-template',
        data: {'templateId': templateId, 'forceSnapshotRebuild': forceSnapshotRebuild},
      );
      if (response.statusCode == 200 && response.data != null) {
        await fetchPaOrders();
        await fetchAllOrders();
        return Map<String, dynamic>.from(response.data);
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map && e.response!.data['error'] != null) {
        _lastError = e.response!.data['error'].toString();
      } else {
        _lastError = e.message ?? "Failed to bind template";
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }

  Future<Map<String, dynamic>?> validateDraft(int orderId) async {
    _lastError = null;
    try {
      final response = await _apiService.dio.get('/api/v1/orders/$orderId/validate-draft');
      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map && e.response!.data['message'] != null) {
        _lastError = e.response!.data['message'].toString();
      } else {
        _lastError = e.message ?? "Failed to validate draft";
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }

  Future<Map<String, dynamic>?> submitDraftToSpa(int orderId) async {
    _lastError = null;
    try {
      final response = await _apiService.dio.post('/api/v1/orders/$orderId/submit-to-spa');
      if (response.statusCode == 200 && response.data != null) {
        await fetchPaOrders();
        await fetchAllOrders();
        return Map<String, dynamic>.from(response.data);
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map && e.response!.data['message'] != null) {
        _lastError = e.response!.data['message'].toString();
      } else if (e.response?.data != null && e.response!.data is Map && e.response!.data['error'] != null) {
        _lastError = e.response!.data['error'].toString();
      } else {
        _lastError = e.message ?? "Failed to submit draft to SPA gate";
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }

  Future<bool> saveDocumentValues(int orderId, Map<String, String> values) async {
    _lastError = null;
    try {
      final response = await _apiService.dio.post(
        '/api/v1/orders/$orderId/save-document-values',
        data: {'values': values},
      );
      if (response.statusCode == 200) {
        return true;
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map && e.response!.data['error'] != null) {
        _lastError = e.response!.data['error'].toString();
      } else {
        _lastError = e.message ?? "Failed to save document values";
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return false;
  }

  Future<Map<String, dynamic>?> fetchClientDeliverable(String refCode) async {
    try {
      final response = await _apiService.dio.get('/api/v1/client/delivery/orders/$refCode');
      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }

  Future<Map<String, dynamic>?> generateDeliveryToken(String refCode, {String fileType = 'REPORT_PDF'}) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/client/delivery/orders/$refCode/generate-token',
        data: {'fileType': fileType},
      );
      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map && e.response!.data['error'] != null) {
        _lastError = e.response!.data['error'].toString();
      } else {
        _lastError = e.message ?? "Failed to generate download token";
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }

  Future<Uint8List?> streamDeliveryFile(String token) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/client/delivery/stream',
        queryParameters: {'token': token},
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data);
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }

  Future<Map<String, dynamic>?> acknowledgeDelivery(
    String refCode, {
    required String action,
    String? clarificationType,
    String? clarificationNotes,
    String? acceptanceDeclaration,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/client/delivery/orders/$refCode/acknowledge',
        data: {
          'action': action,
          if (clarificationType != null) 'clarificationType': clarificationType,
          if (clarificationNotes != null) 'clarificationNotes': clarificationNotes,
          if (acceptanceDeclaration != null) 'acceptanceDeclaration': acceptanceDeclaration,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data is Map && e.response!.data['error'] != null) {
        _lastError = e.response!.data['error'].toString();
      } else {
        _lastError = e.message ?? "Failed to submit acknowledgement";
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchOrderInvoice(int orderId) async {
    try {
      final response = await _apiService.dio.get('/api/v1/delivery/orders/$orderId/invoice');
      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return null;
  }

  @override
  void dispose() {
    stopHeartbeat();
    super.dispose();
  }
}
