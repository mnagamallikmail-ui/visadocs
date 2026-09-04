import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../document_studio/models/visual_preview_model.dart';
import '../models/document_workspace_model.dart';
import '../models/valuation_models.dart';
import '../models/workspace_view_model.dart';
import '../services/document_workspace_api_service.dart';
import '../services/valuation_calculator.dart';

enum DocumentScrollMode {
  continuous,
  sectionBySection,
}

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
  DocumentScrollMode _scrollMode = DocumentScrollMode.continuous;
  DocumentWorkspaceModel? _workspaceModel;
  DocumentWorkspaceVm? _workspaceVm;
  VisualPreviewModel? _livePreviewModel;

  ValuationDataModel? _valuationData;
  List<ValuationLandItemModel> _landItems = [];
  List<ValuationBuildingItemModel> _buildingItems = [];
  List<ValuationComparableSaleModel> _comparables = [];
  List<ValuationCompositeItemModel> _compositeItems = [];

  int _activeSectionIndex = 0;
  final ValueNotifier<int?> scrollToSectionRequested = ValueNotifier<int?>(null);

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
  ValuationDataModel? get valuationData => _valuationData;
  List<ValuationLandItemModel> get landItems => _landItems;
  List<ValuationBuildingItemModel> get buildingItems => _buildingItems;
  List<ValuationComparableSaleModel> get comparables => _comparables;
  List<ValuationCompositeItemModel> get compositeItems => _compositeItems;

  bool get isCompositeProperty {
    final meth = _valuationData?.valuationMethodology ?? _activeValues['VALUATION_METHODOLOGY'] ?? '';
    if (meth == 'COMPOSITE') return true;
    if (_compositeItems.isNotEmpty) return true;
    final cat = (_activeValues['PROPERTY_CATEGORY'] ?? _activeValues['property_category'] ?? _activeValues['PROPERTY_TYPE'] ?? '').toLowerCase();
    return cat.contains('flat') || cat.contains('apartment') || cat.contains('commercial space') ||
           cat.contains('office') || cat.contains('retail') || cat.contains('shop') || cat.contains('commercial unit');
  }
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

  DocumentScrollMode get scrollMode => _scrollMode;

  void setScrollMode(DocumentScrollMode mode) {
    if (_scrollMode != mode) {
      _scrollMode = mode;
      notifyListeners();
    }
  }

  void requestScrollToSection(int index) {
    _activeSectionIndex = index;
    scrollToSectionRequested.value = index;
    notifyListeners();
  }

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

      _initValuationDataFromValues(orderId);

      if (model.documentDom != null) {
        _workspaceVm = DocumentWorkspaceVm.fromDocumentDom(model.documentDom!, _activeValues);
      } else {
        _workspaceVm = null;
      }

      _isDirty = false;
      _lastSavedAt = DateTime.now();
      initAutoSave();

      // Lazy background preview pre-compilation (non-blocking for immediate data entry)
      _initBackgroundPreview(orderId);
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

  void _initValuationDataFromValues(int orderId) {
    _valuationData = ValuationDataModel(orderId: orderId);

    // 1. Land Items
    final rawLand = _activeValues['RAW_LAND_ITEMS_JSON'];
    if (rawLand != null && rawLand.trim().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(rawLand);
        _landItems = decoded.map((j) => ValuationLandItemModel.fromJson(j as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    // 2. Building Items
    final rawBldg = _activeValues['RAW_BUILDING_ITEMS_JSON'];
    if (rawBldg != null && rawBldg.trim().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(rawBldg);
        _buildingItems = decoded.map((j) => ValuationBuildingItemModel.fromJson(j as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    // 3. Comparables
    final rawComp = _activeValues['RAW_COMPARABLES_JSON'];
    if (rawComp != null && rawComp.trim().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(rawComp);
        _comparables = decoded.map((j) => ValuationComparableSaleModel.fromJson(j as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    // 3b. Composite Items
    final rawCompItems = _activeValues['RAW_COMPOSITE_ITEMS_JSON'];
    if (rawCompItems != null && rawCompItems.trim().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(rawCompItems);
        _compositeItems = decoded.map((j) => ValuationCompositeItemModel.fromJson(j as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    // 4. Percentages & Overrides
    final landRealStr = _activeValues['LAND_REALIZABLE_PERCENTAGE'];
    if (landRealStr != null) {
      _valuationData!.landRealizablePercentage = double.tryParse(landRealStr) ?? 85.0;
    }
    final bldgRealStr = _activeValues['BUILDING_REALIZABLE_PERCENTAGE'];
    if (bldgRealStr != null) {
      _valuationData!.buildingRealizablePercentage = double.tryParse(bldgRealStr) ?? 85.0;
    }
    final landDistStr = _activeValues['LAND_DISTRESS_PERCENTAGE'];
    if (landDistStr != null) {
      _valuationData!.landDistressPercentage = double.tryParse(landDistStr) ?? 75.0;
    }
    final bldgDistStr = _activeValues['BUILDING_DISTRESS_PERCENTAGE'];
    if (bldgDistStr != null) {
      _valuationData!.buildingDistressPercentage = double.tryParse(bldgDistStr) ?? 75.0;
    }

    // 5. Government Value
    final govtStr = _activeValues['GOVERNMENT_VALUE'] ?? _activeValues['government_value'];
    if (govtStr != null) {
      final cleanGovt = govtStr.replaceAll(',', '').trim();
      _valuationData!.governmentValue = double.tryParse(cleanGovt) ?? 0.0;
    }

    if (isCompositeProperty) {
      _valuationData!.valuationMethodology = 'COMPOSITE';

      final govtCompRateStr = _activeValues['COMPOSITE_GOVERNMENT_RATE'];
      if (govtCompRateStr != null) {
        _valuationData!.compositeGovernmentRate = double.tryParse(govtCompRateStr.replaceAll(',', '')) ?? 0.0;
      }
      final constCostStr = _activeValues['COMPOSITE_CONSTRUCTION_COST'];
      if (constCostStr != null) {
        _valuationData!.compositeConstructionCost = double.tryParse(constCostStr.replaceAll(',', '')) ?? 2000.0;
      }

      final realStr = _activeValues['REALIZABLE_PERCENTAGE'];
      if (realStr != null) {
        _valuationData!.realizablePercentage = double.tryParse(realStr) ?? 85.0;
      }
      final distStr = _activeValues['DISTRESS_SALE_PERCENTAGE'];
      if (distStr != null) {
        _valuationData!.distressSalePercentage = double.tryParse(distStr) ?? 75.0;
      }

      if (_compositeItems.isEmpty) {
        final subType = _activeValues['PROPERTY_SUB_TYPE'] ?? _activeValues['PROPERTY_TYPE'] ?? 'Main Unit';
        final areaVal = double.tryParse((_activeValues['SUPER_BUILT_UP_AREA'] ?? _activeValues['PROPERTY_AREA_SFT'] ?? '1000').replaceAll(',', '')) ?? 1000.0;
        final compRate = double.tryParse((_activeValues['COMPOSITE_RATE'] ?? '0').replaceAll(',', '')) ?? 0.0;
        final constCost = _valuationData!.compositeConstructionCost > 0 ? _valuationData!.compositeConstructionCost : 2000.0;
        final age = double.tryParse((_activeValues['COMPOSITE_BUILDING_AGE'] ?? '0').replaceAll(',', '')) ?? 0.0;
        final life = double.tryParse((_activeValues['COMPOSITE_BUILDING_TOTAL_LIFE'] ?? '60').replaceAll(',', '')) ?? 60.0;

        _compositeItems = [
          ValuationCompositeItemModel(
            orderId: orderId,
            itemCategory: 'MAIN_UNIT',
            description: subType,
            enteredUnit: _activeValues['SUPER_BUILT_UP_AREA_UNIT'] ?? 'Sq.Ft',
            quantity: areaVal,
            rate: compRate,
            constructionCost: constCost,
            buildingAge: age,
            totalLife: life,
            sortOrder: 0,
          ),
          ValuationCompositeItemModel(
            orderId: orderId,
            itemCategory: 'INTERIOR_WORK',
            description: 'Interior Works & Improvements',
            enteredUnit: 'LS',
            quantity: 1.0,
            rate: 0.0,
            depreciationMode: 'DIRECT_AMOUNT',
            depreciationAmount: 0.0,
            isInsurable: true,
            sortOrder: 1,
          ),
        ];
      }

      ValuationCalculator.recalculateCompositeSummary(_valuationData!, _compositeItems);
      final initialPlaceholders = ValuationCalculator.generatePlaceholders(
        orderInfo: {
          'id': _workspaceModel?.orderId ?? orderId,
          'clientName': _activeValues['CLIENT_NAME'] ?? _activeValues['client_name'] ?? '',
          'bankName': _activeValues['BANK_NAME'] ?? _activeValues['bank_name'] ?? '',
          'branchName': _activeValues['BRANCH_NAME'] ?? _activeValues['branch_name'] ?? '',
          'propertyCategory': _activeValues['PROPERTY_CATEGORY'] ?? _activeValues['property_category'] ?? '',
        },
        data: _valuationData!,
        landItems: _landItems,
        buildingItems: _buildingItems,
        comparables: _comparables,
        compositeItems: _compositeItems,
      );
      _activeValues.addAll(initialPlaceholders);
    } else {
      ValuationCalculator.recalculateSummary(_valuationData!, _landItems, _buildingItems);
      final initialPlaceholders = ValuationCalculator.generatePlaceholders(
        orderInfo: {
          'id': _workspaceModel?.orderId ?? orderId,
          'clientName': _activeValues['CLIENT_NAME'] ?? _activeValues['client_name'] ?? '',
          'bankName': _activeValues['BANK_NAME'] ?? _activeValues['bank_name'] ?? '',
          'branchName': _activeValues['BRANCH_NAME'] ?? _activeValues['branch_name'] ?? '',
        },
        data: _valuationData!,
        landItems: _landItems,
        buildingItems: _buildingItems,
        comparables: _comparables,
      );
      _activeValues.addAll(initialPlaceholders);
    }
  }

  void recalculateValuation() {
    if (_valuationData == null) return;

    if (isCompositeProperty) {
      _valuationData!.valuationMethodology = 'COMPOSITE';
      ValuationCalculator.recalculateCompositeSummary(_valuationData!, _compositeItems);
      final placeholders = ValuationCalculator.generatePlaceholders(
        orderInfo: {
          'id': _workspaceModel?.orderId ?? 0,
          'clientName': _activeValues['CLIENT_NAME'] ?? _activeValues['client_name'] ?? '',
          'bankName': _activeValues['BANK_NAME'] ?? _activeValues['bank_name'] ?? '',
          'branchName': _activeValues['BRANCH_NAME'] ?? _activeValues['branch_name'] ?? '',
          'propertyCategory': _activeValues['PROPERTY_CATEGORY'] ?? _activeValues['property_category'] ?? '',
        },
        data: _valuationData!,
        landItems: _landItems,
        buildingItems: _buildingItems,
        comparables: _comparables,
        compositeItems: _compositeItems,
      );

      _activeValues.addAll(placeholders);
      _deltaValues.addAll(placeholders);

      try {
        final compJson = jsonEncode(_compositeItems.map((i) => i.toJson()).toList());
        _activeValues['RAW_COMPOSITE_ITEMS_JSON'] = compJson;
        _deltaValues['RAW_COMPOSITE_ITEMS_JSON'] = compJson;

        _activeValues['COMPOSITE_GOVERNMENT_RATE'] = _valuationData!.compositeGovernmentRate.toString();
        _deltaValues['COMPOSITE_GOVERNMENT_RATE'] = _valuationData!.compositeGovernmentRate.toString();
        _activeValues['COMPOSITE_CONSTRUCTION_COST'] = _valuationData!.compositeConstructionCost.toString();
        _deltaValues['COMPOSITE_CONSTRUCTION_COST'] = _valuationData!.compositeConstructionCost.toString();
        _activeValues['REALIZABLE_PERCENTAGE'] = _valuationData!.realizablePercentage.toString();
        _deltaValues['REALIZABLE_PERCENTAGE'] = _valuationData!.realizablePercentage.toString();
        _activeValues['DISTRESS_SALE_PERCENTAGE'] = _valuationData!.distressSalePercentage.toString();
        _deltaValues['DISTRESS_SALE_PERCENTAGE'] = _valuationData!.distressSalePercentage.toString();
      } catch (_) {}
    } else {
      ValuationCalculator.recalculateSummary(_valuationData!, _landItems, _buildingItems);
      final placeholders = ValuationCalculator.generatePlaceholders(
        orderInfo: {
          'id': _workspaceModel?.orderId ?? 0,
          'clientName': _activeValues['CLIENT_NAME'] ?? _activeValues['client_name'] ?? '',
          'bankName': _activeValues['BANK_NAME'] ?? _activeValues['bank_name'] ?? '',
          'branchName': _activeValues['BRANCH_NAME'] ?? _activeValues['branch_name'] ?? '',
        },
        data: _valuationData!,
        landItems: _landItems,
        buildingItems: _buildingItems,
        comparables: _comparables,
      );

      _activeValues.addAll(placeholders);
      _deltaValues.addAll(placeholders);

      try {
        final landJson = jsonEncode(_landItems.map((i) => i.toJson()).toList());
        final bldgJson = jsonEncode(_buildingItems.map((i) => i.toJson()).toList());
        final compJson = jsonEncode(_comparables.map((i) => i.toJson()).toList());
        _activeValues['RAW_LAND_ITEMS_JSON'] = landJson;
        _deltaValues['RAW_LAND_ITEMS_JSON'] = landJson;
        _activeValues['RAW_BUILDING_ITEMS_JSON'] = bldgJson;
        _deltaValues['RAW_BUILDING_ITEMS_JSON'] = bldgJson;
        _activeValues['RAW_COMPARABLES_JSON'] = compJson;
        _deltaValues['RAW_COMPARABLES_JSON'] = compJson;

        if (_valuationData != null) {
          _activeValues['LAND_REALIZABLE_PERCENTAGE'] = _valuationData!.landRealizablePercentage.toString();
          _deltaValues['LAND_REALIZABLE_PERCENTAGE'] = _valuationData!.landRealizablePercentage.toString();
          _activeValues['BUILDING_REALIZABLE_PERCENTAGE'] = _valuationData!.buildingRealizablePercentage.toString();
          _deltaValues['BUILDING_REALIZABLE_PERCENTAGE'] = _valuationData!.buildingRealizablePercentage.toString();
          _activeValues['LAND_DISTRESS_PERCENTAGE'] = _valuationData!.landDistressPercentage.toString();
          _deltaValues['LAND_DISTRESS_PERCENTAGE'] = _valuationData!.landDistressPercentage.toString();
          _activeValues['BUILDING_DISTRESS_PERCENTAGE'] = _valuationData!.buildingDistressPercentage.toString();
          _deltaValues['BUILDING_DISTRESS_PERCENTAGE'] = _valuationData!.buildingDistressPercentage.toString();
          _activeValues['GOVERNMENT_VALUE'] = _valuationData!.governmentValue.toString();
          _deltaValues['GOVERNMENT_VALUE'] = _valuationData!.governmentValue.toString();
        }
      } catch (_) {}
    }

    _isDirty = true;
    if (_workspaceModel?.documentDom != null) {
      _workspaceVm = DocumentWorkspaceVm.fromDocumentDom(_workspaceModel!.documentDom!, _activeValues);
    }
    notifyListeners();
  }

  void addCompositeInteriorItem() {
    final orderId = _workspaceModel?.orderId ?? 0;
    final breakupCount = _compositeItems.where((i) => i.itemCategory == 'INTERIOR_WORK').length;
    _compositeItems.add(ValuationCompositeItemModel(
      orderId: orderId,
      itemCategory: 'INTERIOR_WORK',
      description: 'Interior Improvement #$breakupCount',
      enteredUnit: 'LS',
      quantity: 1.0,
      rate: 0.0,
      depreciationMode: 'DIRECT_AMOUNT',
      depreciationAmount: 0.0,
      isInsurable: true,
      sortOrder: _compositeItems.length,
    ));
    recalculateValuation();
  }

  void removeCompositeItem(int index) {
    if (index > 0 && index < _compositeItems.length) {
      _compositeItems.removeAt(index);
      recalculateValuation();
    }
  }

  void addLandItem() {
    final orderId = _workspaceModel?.orderId ?? 0;
    _landItems.add(ValuationLandItemModel(
      orderId: orderId,
      description: 'Plot ${_landItems.length + 1}',
      enteredArea: 0,
      enteredUnit: 'Sq.Ft',
      standardAreaSqft: 0,
      rate: 0,
      value: 0,
    ));
    recalculateValuation();
  }

  void removeLandItem(int index) {
    if (index >= 0 && index < _landItems.length) {
      _landItems.removeAt(index);
      recalculateValuation();
    }
  }

  void addBuildingItem() {
    final orderId = _workspaceModel?.orderId ?? 0;
    _buildingItems.add(ValuationBuildingItemModel(
      orderId: orderId,
      buildingType: 'RCC Commercial',
      structureType: 'Floor ${_buildingItems.length + 1}',
      description: 'Structure ${_buildingItems.length + 1}',
      enteredArea: 0,
      enteredUnit: 'Sq.Ft',
      standardAreaSqft: 0,
      replacementRate: 0,
      replacementCost: 0,
      buildingAge: 0,
      buildingUsefulLife: 60,
      salvagePercentage: 10,
      depreciationPercentage: 0,
      depreciationAmount: 0,
      buildingValue: 0,
    ));
    recalculateValuation();
  }

  void removeBuildingItem(int index) {
    if (index >= 0 && index < _buildingItems.length) {
      _buildingItems.removeAt(index);
      recalculateValuation();
    }
  }

  void addComparableItem() {
    final orderId = _workspaceModel?.orderId ?? 0;
    _comparables.add(ValuationComparableSaleModel(
      orderId: orderId,
      location: 'Property ${_comparables.length + 1}',
      enteredArea: 0,
      rate: 0,
      saleValue: 0,
    ));
    recalculateValuation();
  }

  void removeComparableItem(int index) {
    if (index >= 0 && index < _comparables.length) {
      _comparables.removeAt(index);
      recalculateValuation();
    }
  }

  void setLandRealizablePercentage(double val) {
    if (_valuationData != null) {
      _valuationData!.landRealizablePercentage = val;
      recalculateValuation();
    }
  }

  void setBuildingRealizablePercentage(double val) {
    if (_valuationData != null) {
      _valuationData!.buildingRealizablePercentage = val;
      recalculateValuation();
    }
  }

  void setLandDistressPercentage(double val) {
    if (_valuationData != null) {
      _valuationData!.landDistressPercentage = val;
      recalculateValuation();
    }
  }

  void setBuildingDistressPercentage(double val) {
    if (_valuationData != null) {
      _valuationData!.buildingDistressPercentage = val;
      recalculateValuation();
    }
  }

  void setGovernmentValue(double val) {
    if (_valuationData != null) {
      _valuationData!.governmentValue = val;
      recalculateValuation();
    }
  }

  void setRealizablePercentage(double val) {
    if (_valuationData != null) {
      _valuationData!.realizablePercentage = val;
      recalculateValuation();
    }
  }

  void setDistressSalePercentage(double val) {
    if (_valuationData != null) {
      _valuationData!.distressSalePercentage = val;
      recalculateValuation();
    }
  }

  void setCompositeGovernmentRate(double val) {
    if (_valuationData != null) {
      _valuationData!.compositeGovernmentRate = val;
      recalculateValuation();
    }
  }

  void setCompositeConstructionCost(double val) {
    if (_valuationData != null) {
      _valuationData!.compositeConstructionCost = val;
      for (final item in _compositeItems) {
        if (item.itemCategory == 'MAIN_UNIT') {
          item.constructionCost = val;
        }
      }
      recalculateValuation();
    }
  }

  /// Asynchronously compiles preview in background without blocking workspace data entry
  void _initBackgroundPreview(int orderId) {
    if (_livePreviewModel != null && _livePreviewModel!.pages.isNotEmpty) return;
    _isCompilingPreview = true;

    Future.microtask(() async {
      try {
        final preview = await _apiService.compileLivePreview(orderId);
        _livePreviewModel = preview;
      } catch (_) {
        // Non-blocking background preview compilation
      } finally {
        _isCompilingPreview = false;
        notifyListeners();
      }
    });
  }

  /// Test helper to hydrate workspace model directly
  void setWorkspaceModelForTest(DocumentWorkspaceModel model) {
    _workspaceModel = model;
    _activeValues = Map<String, String>.from(model.values);
    _deltaValues.clear();
    _initValuationDataFromValues(model.orderId);
    if (model.documentDom != null) {
      _workspaceVm = DocumentWorkspaceVm.fromDocumentDom(model.documentDom!, _activeValues);
    }
    _isDirty = false;
    notifyListeners();
  }

  void markCleanForTest() {
    _deltaValues.clear();
    _isDirty = false;
    notifyListeners();
  }

  /// Switches between [Table Edit] and [Compiled Preview]
  Future<void> setViewMode(WorkspaceViewMode mode) async {
    if (_viewMode == mode) return;

    _viewMode = mode;
    notifyListeners();

    if (mode == WorkspaceViewMode.compiledPreview) {
      if (_deltaValues.isNotEmpty || (_livePreviewModel == null && !_isCompilingPreview)) {
        await refreshLivePreview();
      }
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

  void updateValuesFromValuation(Map<String, String> newPlaceholders) {
    _activeValues.addAll(newPlaceholders);
    _deltaValues.addAll(newPlaceholders);
    _isDirty = true;
    if (_workspaceModel?.documentDom != null) {
      _workspaceVm = DocumentWorkspaceVm.fromDocumentDom(_workspaceModel!.documentDom!, _activeValues);
    }
    notifyListeners();
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
