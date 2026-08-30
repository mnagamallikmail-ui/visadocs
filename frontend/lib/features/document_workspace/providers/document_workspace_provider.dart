import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../document_studio/models/visual_preview_model.dart';
import '../models/document_workspace_model.dart';
import '../models/workspace_view_model.dart';
import '../services/document_workspace_api_service.dart';

class DocumentWorkspaceProvider extends ChangeNotifier {
  final DocumentWorkspaceApiService _apiService = DocumentWorkspaceApiService();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isAutoSaving = false;
  bool _isSubmitting = false;
  bool _isCompilingPreview = false;
  bool _isDirty = false;
  String? _errorMessage;
  DateTime? _lastSavedAt;

  WorkspaceViewMode _viewMode = WorkspaceViewMode.tableEdit;
  DocumentWorkspaceModel? _workspaceModel;
  DocumentWorkspaceVm? _workspaceVm;
  VisualPreviewModel? _livePreviewModel;

  int _activeSectionIndex = 0;

  Map<String, String> _activeValues = {};
  final Map<String, String> _deltaValues = {};

  // Standard zoom preset levels: 50%, 75%, 100%, 125%, 150%, 200%
  static const List<double> zoomLevels = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  int _zoomIndex = 2; // Default: 100% (1.0)

  String? _hoveredKey;
  String? _focusedKey;

  Timer? _autoSaveTimer;

  // Getters
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isAutoSaving => _isAutoSaving;
  bool get isSubmitting => _isSubmitting;
  bool get isCompilingPreview => _isCompilingPreview;
  bool get isDirty => _isDirty;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSavedAt => _lastSavedAt;

  WorkspaceViewMode get viewMode => _viewMode;
  DocumentWorkspaceModel? get workspaceModel => _workspaceModel;
  DocumentWorkspaceVm? get workspaceVm => _workspaceVm;
  VisualPreviewModel? get livePreviewModel => _livePreviewModel;
  int get activeSectionIndex => _activeSectionIndex;
  Map<String, String> get activeValues => _activeValues;
  Map<String, String> get deltaValues => _deltaValues;

  double get zoomScale => zoomLevels[_zoomIndex];
  int get zoomPercentage => (zoomScale * 100).round();
  bool get canZoomIn => _zoomIndex < zoomLevels.length - 1;
  bool get canZoomOut => _zoomIndex > 0;

  String? get hoveredKey => _hoveredKey;
  String? get focusedKey => _focusedKey;
  bool get hasWorkspace => _workspaceModel != null;
  bool get isReadOnly => _workspaceModel?.readOnly ?? false;

  void setActiveSectionIndex(int index) {
    if (_activeSectionIndex != index) {
      _activeSectionIndex = index;
      notifyListeners();
    }
  }

  void initAutoSave() {
    _autoSaveTimer?.cancel();
    // Auto-save every 30 seconds if dirty
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isDirty && !_isSaving && !_isAutoSaving && !isReadOnly) {
        saveChanges(isAutoSave: true);
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  /// Loads the Document Workspace payload and constructs the ViewModel hierarchy
  Future<void> loadWorkspace(int orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final model = await _apiService.getDocumentWorkspace(orderId);
      _workspaceModel = model;
      _activeValues = Map<String, String>.from(model.values);
      _deltaValues.clear();

      if (model.documentDom != null) {
        _workspaceVm = DocumentWorkspaceVm.fromDocumentDom(model.documentDom!, _activeValues);
      } else {
        _workspaceVm = null;
      }

      _isDirty = false;
      _lastSavedAt = DateTime.now();
      initAutoSave();
    } on DioException catch (dioErr) {
      if (dioErr.response?.statusCode == 403) {
        _errorMessage = 'Access to this order document workspace is restricted.';
      } else if (dioErr.response?.statusCode == 404) {
        _errorMessage = 'Order #$orderId was not found.';
      } else {
        _errorMessage = dioErr.message ?? 'Failed to load document workspace';
      }
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Test helper to hydrate workspace model directly
  void setWorkspaceModelForTest(DocumentWorkspaceModel model) {
    _workspaceModel = model;
    _activeValues = Map<String, String>.from(model.values);
    _deltaValues.clear();
    if (model.documentDom != null) {
      _workspaceVm = DocumentWorkspaceVm.fromDocumentDom(model.documentDom!, _activeValues);
    }
    _isDirty = false;
    notifyListeners();
  }

  /// Switches between [Table Edit] and [Compiled Preview]
  Future<void> setViewMode(WorkspaceViewMode mode) async {
    if (_viewMode == mode) return;

    _viewMode = mode;
    notifyListeners();

    if (mode == WorkspaceViewMode.compiledPreview) {
      await refreshLivePreview();
    }
  }

  /// Triggers server-side PDF compilation with current hydrated values
  Future<void> refreshLivePreview() async {
    if (_workspaceModel == null) return;

    _isCompilingPreview = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Flush unsaved delta values to backend first
      if (_deltaValues.isNotEmpty) {
        await _apiService.saveDocumentValues(_workspaceModel!.orderId, _deltaValues);
        _deltaValues.clear();
        _isDirty = false;
      }

      final preview = await _apiService.compileLivePreview(_workspaceModel!.orderId);
      _livePreviewModel = preview;
    } catch (e) {
      _errorMessage = 'Live preview compilation failed: $e';
    } finally {
      _isCompilingPreview = false;
      notifyListeners();
    }
  }

  /// Updates an in-document input value directly
  void updateValue(String key, String value) {
    final upperKey = key.toUpperCase();
    if (_activeValues[upperKey] != value) {
      _activeValues[upperKey] = value;
      _deltaValues[upperKey] = value;
      _isDirty = true;
      notifyListeners();
    }
  }

  String getValue(String key) {
    return _activeValues[key.toUpperCase()] ?? '';
  }

  /// Saves changed delta values to backend
  Future<bool> saveChanges({bool isAutoSave = false}) async {
    if (_workspaceModel == null || _deltaValues.isEmpty) {
      _isDirty = false;
      notifyListeners();
      return true;
    }

    if (isAutoSave) {
      _isAutoSaving = true;
    } else {
      _isSaving = true;
    }
    notifyListeners();

    try {
      final deltaToSave = Map<String, String>.from(_deltaValues);
      final success = await _apiService.saveDocumentValues(
        _workspaceModel!.orderId,
        deltaToSave,
      );

      if (success) {
        deltaToSave.forEach((k, _) {
          if (_deltaValues[k] == deltaToSave[k]) {
            _deltaValues.remove(k);
          }
        });
        _isDirty = _deltaValues.isNotEmpty;
        _lastSavedAt = DateTime.now();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to save changes: $e';
      return false;
    } finally {
      _isSaving = false;
      _isAutoSaving = false;
      notifyListeners();
    }
  }

  /// Submits order to SPA Review (PA Action)
  Future<bool> submitToSpa() async {
    if (_workspaceModel == null) return false;

    _isSubmitting = true;
    notifyListeners();

    try {
      if (_deltaValues.isNotEmpty) {
        await _apiService.saveDocumentValues(_workspaceModel!.orderId, _deltaValues);
        _deltaValues.clear();
        _isDirty = false;
      }

      final success = await _apiService.submitToSpa(_workspaceModel!.orderId);
      if (success) {
        _workspaceModel = _workspaceModel!.copyWith(status: 'SPA_GATE');
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to submit to SPA: $e';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Approves report and triggers final PDF/DOCX compilation (SPA Action)
  Future<bool> spaApprove(double finalValue) async {
    if (_workspaceModel == null) return false;

    _isSubmitting = true;
    notifyListeners();

    try {
      final modifiedValues = _deltaValues.isNotEmpty ? Map<String, String>.from(_deltaValues) : null;
      final result = await _apiService.spaApprove(
        _workspaceModel!.orderId,
        finalValue: finalValue,
        modifiedValues: modifiedValues,
      );

      if (result['status'] == 'SPA_CONFIRMED') {
        _deltaValues.clear();
        _isDirty = false;
        _workspaceModel = _workspaceModel!.copyWith(status: 'SPA_CONFIRMED');
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to approve report: $e';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // Zoom Controls: 50%, 75%, 100%, 125%, 150%, 200%
  void zoomIn() {
    if (canZoomIn) {
      _zoomIndex++;
      notifyListeners();
    }
  }

  void zoomOut() {
    if (canZoomOut) {
      _zoomIndex--;
      notifyListeners();
    }
  }

  void resetZoom() {
    _zoomIndex = 2; // 100%
    notifyListeners();
  }

  void setHoveredKey(String? key) {
    if (_hoveredKey != key) {
      _hoveredKey = key;
      notifyListeners();
    }
  }

  void setFocusedKey(String? key) {
    if (_focusedKey != key) {
      _focusedKey = key;
      notifyListeners();
    }
  }
}
