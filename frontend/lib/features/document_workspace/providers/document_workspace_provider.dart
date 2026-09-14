import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../document_studio/models/visual_preview_model.dart';
import '../models/document_workspace_model.dart';
import '../models/valuation_models.dart';
import '../models/workspace_view_model.dart';
import '../services/document_workspace_api_service.dart';
import '../services/placeholder_registry.dart';
import '../services/valuation_calculator.dart';

import '../services/alias_resolution_engine.dart';
import '../services/placeholder_normalization_registry.dart';
import '../services/value_normalization_engine.dart';

enum DocumentScrollMode {
  continuous,
  sectionBySection,
}

class DocumentWorkspaceProvider extends ChangeNotifier {
  final DocumentWorkspaceApiService _apiService = DocumentWorkspaceApiService();

  String? _validationError;
  String? get validationError => _validationError;

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
  final PlaceholderRegistry placeholderRegistry = PlaceholderRegistry();

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
    if (_activeValues.containsKey('SALEABLE_AREA') || _activeValues.containsKey('SALEABLE_RATE') || _activeValues.containsKey('MARKET_RATE_FLAT')) return true;
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

    // Pre-seed dual values for any existing area/rate/percentage inputs
    _activeValues.keys.toList().forEach((k) {
      final uk = k.toUpperCase();
      final val = _activeValues[k];
      if (val != null && val.isNotEmpty && !uk.endsWith('_RAW') && !uk.endsWith('_NUMERIC') && !uk.endsWith('_UNIT') && !uk.endsWith('_STANDARD_SQFT')) {
        if (PlaceholderNormalizationRegistry.isAreaKey(uk) ||
            PlaceholderNormalizationRegistry.isRateKey(uk) ||
            PlaceholderNormalizationRegistry.isPercentageKey(uk)) {
          final dual = ValueNormalizationEngine.createDualValueResult(uk, val);
          dual.valuesToStore.forEach((dk, dv) {
            _activeValues[dk] = dv;
          });
        }
      }
    });

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
    if (_compositeItems.isNotEmpty) {
      final existingIdx = _compositeItems.indexWhere((i) => i.itemCategory.toUpperCase() == 'MAIN_UNIT');
      if (existingIdx >= 0) {
        final mUnit = _compositeItems[existingIdx];
        final rawArea = _activeValues['SALEABLE_AREA_STANDARD_SQFT'] ?? _activeValues['SALEABLE_AREA_NUMERIC'] ?? _activeValues['SALEABLE_AREA'];
        if (rawArea != null && rawArea.isNotEmpty) {
          final parsedNum = ValueNormalizationEngine.extractNumericValue(rawArea) ??
              double.tryParse(rawArea.replaceAll(RegExp(r'[^0-9.]'), '').trim());
          if (parsedNum != null && parsedNum > 0) {
            mUnit.quantity = parsedNum;
          }
        }
        final rawRate = _activeValues['SALEABLE_RATE'] ?? _activeValues['MARKET_RATE_FLAT'] ?? _activeValues['COMPOSITE_RATE'] ?? _activeValues['CURRENT_MARKET_RATE'] ?? _activeValues['FLAT_MARKET_RATE'] ?? _activeValues['BUILDING_MARKET_RATE'];
        if (rawRate != null && rawRate.isNotEmpty) {
          final parsedRate = ValueNormalizationEngine.extractNumericValue(rawRate) ??
              double.tryParse(rawRate.replaceAll(RegExp(r'[^0-9.]'), '').trim());
          if (parsedRate != null && parsedRate > 0) {
            mUnit.rate = parsedRate;
          }
        }
      }
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
        final rawArea = _activeValues['SALEABLE_AREA'] ?? _activeValues['SUPER_BUILT_UP_AREA'] ?? _activeValues['PROPERTY_AREA_SFT'] ?? _activeValues['SBUA'] ?? _activeValues['FLAT_AREA'] ?? '1000';
        final dualArea = ValueNormalizationEngine.createDualValueResult('SALEABLE_AREA', rawArea);
        final areaVal = dualArea.standardSqftValue;
        dualArea.valuesToStore.forEach((k, v) {
          _activeValues[k] = v;
        });

        final rawRate = _activeValues['SALEABLE_RATE'] ?? _activeValues['MARKET_RATE_FLAT'] ?? _activeValues['COMPOSITE_RATE'] ?? _activeValues['CURRENT_MARKET_RATE'] ?? _activeValues['FLAT_MARKET_RATE'] ?? _activeValues['BUILDING_MARKET_RATE'] ?? '0';
        final dualRate = ValueNormalizationEngine.createDualValueResult('MARKET_RATE_FLAT', rawRate);
        final compRate = dualRate.numericValue;
        dualRate.valuesToStore.forEach((k, v) {
          _activeValues[k] = v;
        });

        final constCost = _valuationData!.compositeConstructionCost > 0 ? _valuationData!.compositeConstructionCost : 2000.0;
        final age = double.tryParse((_activeValues['COMPOSITE_BUILDING_AGE'] ?? '0').replaceAll(',', '')) ?? 0.0;
        final life = double.tryParse((_activeValues['COMPOSITE_BUILDING_TOTAL_LIFE'] ?? '60').replaceAll(',', '')) ?? 60.0;

        _compositeItems = [
          ValuationCompositeItemModel(
            orderId: orderId,
            itemCategory: 'MAIN_UNIT',
            description: subType,
            enteredUnit: dualArea.detectedUnit,
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
          ValuationCompositeItemModel(
            orderId: orderId,
            itemCategory: 'PARKING',
            description: 'Car Parking',
            enteredUnit: 'Slot',
            quantity: 1.0,
            rate: 0.0,
            amount: 0.0,
            depreciationAmount: 0.0,
            isInsurable: false,
            sortOrder: 2,
          ),
        ];
      } else {
        ensureCompositeMainUnit();
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
      _mergePlaceholdersPreservingRaw(initialPlaceholders);
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
      _mergePlaceholdersPreservingRaw(initialPlaceholders);
    }
  }

  void _mergePlaceholdersPreservingRaw(Map<String, String> placeholders) {
    placeholders.forEach((k, v) {
      final uk = k.toUpperCase();
      if (isCalculatedValuationKey(uk)) {
        _activeValues[uk] = v;
        _deltaValues[uk] = v;
        _activeValues[k] = v;
        _deltaValues[k] = v;
        return;
      }
      if (uk.endsWith('_RAW') || (uk.endsWith('_NUMERIC') && !uk.contains('AMOUNT') && !uk.contains('FAIR_VALUE') && !uk.contains('DEPRECIATION')) || (uk.endsWith('_UNIT') && !uk.contains('AMOUNT')) || uk.endsWith('_STANDARD_SQFT')) {
        if (_activeValues.containsKey(uk) && _activeValues[uk]!.isNotEmpty) {
          return;
        }
      }
      final rawKey = '${uk}_RAW';
      if (_activeValues.containsKey(rawKey) && _activeValues[rawKey]!.isNotEmpty) {
        if (!PlaceholderNormalizationRegistry.isAreaKey(uk) && !PlaceholderNormalizationRegistry.isRateKey(uk)) {
          _activeValues[uk] = _activeValues[rawKey]!;
          _deltaValues[uk] = _activeValues[rawKey]!;
          _activeValues[k] = _activeValues[rawKey]!;
          _deltaValues[k] = _activeValues[rawKey]!;
        }
      } else {
        _activeValues[uk] = v;
        _deltaValues[uk] = v;
        _activeValues[k] = v;
        _deltaValues[k] = v;
      }
    });
  }

  void recalculateValuation() {
    if (_valuationData == null) {
      _valuationData = ValuationDataModel(
        orderId: _workspaceModel?.orderId ?? 0,
        valuationMethodology: 'COMPOSITE',
      );
    }

    if (isCompositeProperty || _compositeItems.isNotEmpty) {
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

      _mergePlaceholdersPreservingRaw(placeholders);

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

      _mergePlaceholdersPreservingRaw(placeholders);

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

  void addCompositeParkingItem() {
    final orderId = _workspaceModel?.orderId ?? 0;
    final parkingCount = _compositeItems.where((i) => i.itemCategory.toUpperCase() == 'PARKING').length;
    _compositeItems.add(ValuationCompositeItemModel(
      orderId: orderId,
      itemCategory: 'PARKING',
      description: parkingCount == 0 ? 'Car Parking' : 'Parking Slot #${parkingCount + 1}',
      enteredUnit: 'Slot',
      quantity: 1.0,
      rate: 0.0,
      amount: 0.0,
      depreciationAmount: 0.0,
      isInsurable: false,
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
        if (item.itemCategory.toUpperCase() == 'MAIN_UNIT') {
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

  /// Updates an in-document input value directly with reactive dependency cascade
  /// and Value Normalization Engine integration.
  void updateValue(String key, String value, {bool notify = true}) {
    final upperKey = key.toUpperCase();

    // Phase 4B: Value Normalization Engine Validation & Normalization
    if (PlaceholderNormalizationRegistry.isAreaKey(upperKey) ||
        PlaceholderNormalizationRegistry.isRateKey(upperKey) ||
        PlaceholderNormalizationRegistry.isPercentageKey(upperKey) ||
        upperKey == 'GOVERNMENT_VALUE' ||
        upperKey == 'COMPOSITE_GOVERNMENT_RATE') {

      final numericVal = ValueNormalizationEngine.tryNormalize(upperKey, value);
      if (numericVal == null) {
        // Validation Rule: Reject when no numeric value exists.
        // No silent conversion to zero. Do NOT recalculate. Do NOT overwrite values.
        _validationError = ValueNormalizationEngine.validationErrorMsg;
        notifyListeners();
        return;
      }

      // Input is valid: clear any prior validation error
      _validationError = null;

      final dual = ValueNormalizationEngine.createDualValueResult(upperKey, value);
      dual.valuesToStore.forEach((k, v) {
        _activeValues[k] = v;
        _deltaValues[k] = v;
      });
      _isDirty = true;

      // Propagate authoritative area (STANDARD_SQFT) to calculation models
      if (PlaceholderNormalizationRegistry.isAreaKey(upperKey)) {
        ensureCompositeMainUnit();
        for (final item in _compositeItems) {
          if (item.itemCategory.toUpperCase() == 'MAIN_UNIT') {
            item.quantity = dual.standardSqftValue;
            item.enteredUnit = dual.detectedUnit;
            break;
          }
        }
        for (final land in _landItems) {
          land.standardAreaSqft = dual.standardSqftValue;
          land.enteredUnit = dual.detectedUnit;
          land.enteredArea = dual.numericValue;
        }

        // Publish runtime field values as required by Fix 3
        final stdSqftStr = ValueNormalizationEngine.formatNormalizedString(dual.standardSqftValue);
        _activeValues['SALEABLE_AREA'] = stdSqftStr;
        _deltaValues['SALEABLE_AREA'] = stdSqftStr;
        _activeValues['SALEABLE_AREA_RAW'] = value;
        _deltaValues['SALEABLE_AREA_RAW'] = value;
        _activeValues['SALEABLE_AREA_NUMERIC'] = ValueNormalizationEngine.formatNormalizedString(dual.numericValue);
        _deltaValues['SALEABLE_AREA_NUMERIC'] = _activeValues['SALEABLE_AREA_NUMERIC']!;
        _activeValues['SALEABLE_AREA_UNIT'] = dual.detectedUnit;
        _deltaValues['SALEABLE_AREA_UNIT'] = dual.detectedUnit;
        _activeValues['SALEABLE_AREA_STANDARD_SQFT'] = stdSqftStr;
        _deltaValues['SALEABLE_AREA_STANDARD_SQFT'] = stdSqftStr;

        recalculateValuation();
        return;
      } else if (PlaceholderNormalizationRegistry.isRateKey(upperKey)) {
        ensureCompositeMainUnit();
        for (final item in _compositeItems) {
          if (item.itemCategory.toUpperCase() == 'MAIN_UNIT') {
            item.rate = dual.numericValue;
            break;
          }
        }

        // Publish runtime field values as required by Fix 3
        final rateNumStr = ValueNormalizationEngine.formatNormalizedString(dual.numericValue);
        _activeValues['MARKET_RATE_FLAT'] = rateNumStr;
        _deltaValues['MARKET_RATE_FLAT'] = rateNumStr;
        _activeValues['SALEABLE_RATE'] = rateNumStr;
        _deltaValues['SALEABLE_RATE'] = rateNumStr;
        _activeValues['MARKET_RATE_FLAT_RAW'] = value;
        _deltaValues['MARKET_RATE_FLAT_RAW'] = value;
        _activeValues['SALEABLE_RATE_RAW'] = value;
        _deltaValues['SALEABLE_RATE_RAW'] = value;
        _activeValues['MARKET_RATE_FLAT_NUMERIC'] = rateNumStr;
        _deltaValues['MARKET_RATE_FLAT_NUMERIC'] = rateNumStr;

        recalculateValuation();
        return;
      } else if (upperKey == 'GOVERNMENT_VALUE') {
        if (_valuationData != null) {
          _valuationData!.governmentValue = dual.numericValue;
          recalculateValuation();
          return;
        }
      } else if (upperKey == 'COMPOSITE_GOVERNMENT_RATE') {
        if (_valuationData != null) {
          _valuationData!.compositeGovernmentRate = dual.numericValue;
          recalculateValuation();
          return;
        }
      } else if (PlaceholderNormalizationRegistry.isPercentageKey(upperKey)) {
        if (_valuationData != null) {
          if (upperKey.contains('REALIZABLE')) {
            _valuationData!.realizablePercentage = dual.numericValue;
          } else if (upperKey.contains('DISTRESS')) {
            _valuationData!.distressSalePercentage = dual.numericValue;
          }
          recalculateValuation();
          return;
        }
      }
    } else if (upperKey == 'COMPOSITE_CONSTRUCTION_COST' ||
        upperKey == 'CONSTRUCTION_COST' ||
        upperKey == 'CONSTRUCTION_RATE' ||
        upperKey == 'COMPOSITE_CONSTRUCTION_RATE') {
      final cost = ValueNormalizationEngine.tryNormalize(upperKey, value) ??
          (double.tryParse(value.replaceAll('₹', '').replaceAll(',', '').trim()) ?? 2000.0);
      final costStr = cost.toString();
      _activeValues['COMPOSITE_CONSTRUCTION_COST'] = costStr;
      _deltaValues['COMPOSITE_CONSTRUCTION_COST'] = costStr;
      _activeValues['CONSTRUCTION_COST'] = costStr;
      _deltaValues['CONSTRUCTION_COST'] = costStr;
      ensureCompositeMainUnit();
      setCompositeConstructionCost(cost);
      return;
    } else if (upperKey == 'COMPOSITE_BUILDING_AGE') {
      final clean = value.replaceAll(RegExp(r'[^0-9.]'), '').trim();
      final age = double.tryParse(clean) ?? 0.0;
      _activeValues['COMPOSITE_BUILDING_AGE'] = clean;
      _deltaValues['COMPOSITE_BUILDING_AGE'] = clean;
      ensureCompositeMainUnit();
      for (final item in _compositeItems) {
        if (item.itemCategory.toUpperCase() == 'MAIN_UNIT') {
          item.buildingAge = age;
        }
      }
      if (_valuationData != null) {
        _valuationData!.compositeBuildingAge = age;
      }
      recalculateValuation();
      return;
    } else if (upperKey == 'COMPOSITE_BUILDING_TOTAL_LIFE' ||
        upperKey == 'USEFUL_LIFE' ||
        upperKey == 'BUILDING_USEFUL_LIFE' ||
        upperKey == 'TOTAL_LIFE' ||
        upperKey == 'BUILDING_TOTAL_LIFE') {
      final clean = value.replaceAll(RegExp(r'[^0-9.]'), '').trim();
      final life = double.tryParse(clean) ?? 60.0;
      _activeValues['COMPOSITE_BUILDING_TOTAL_LIFE'] = clean;
      _deltaValues['COMPOSITE_BUILDING_TOTAL_LIFE'] = clean;
      _activeValues['USEFUL_LIFE'] = clean;
      _deltaValues['USEFUL_LIFE'] = clean;
      ensureCompositeMainUnit();
      for (final item in _compositeItems) {
        if (item.itemCategory.toUpperCase() == 'MAIN_UNIT') {
          item.totalLife = life;
        }
      }
      if (_valuationData != null) {
        _valuationData!.compositeBuildingTotalLife = life;
      }
      recalculateValuation();
      return;
    } else {
      if (_activeValues[upperKey] != value) {
        _activeValues[upperKey] = value;
        _deltaValues[upperKey] = value;
        if (upperKey == 'IMG_COVER_PAGE' || upperKey == 'IMG_FRONT_PAGE' || upperKey == 'COVER_IMAGE') {
          _activeValues['IMG_COVER_PAGE'] = value;
          _deltaValues['IMG_COVER_PAGE'] = value;
          _activeValues['IMG_FRONT_PAGE'] = value;
          _deltaValues['IMG_FRONT_PAGE'] = value;
          _activeValues['COVER_IMAGE'] = value;
          _deltaValues['COVER_IMAGE'] = value;
        }
        _isDirty = true;
        _validationError = null;
        if (notify) {
          notifyListeners();
        }
      }
    }
  }

  void notifyChanges() {
    notifyListeners();
  }

  String getValue(String key) {
    final upper = key.toUpperCase();
    if (upper == 'IMG_COVER_PAGE' || upper == 'IMG_FRONT_PAGE' || upper == 'COVER_IMAGE') {
      final img = _activeValues['IMG_COVER_PAGE'] ?? _activeValues['IMG_FRONT_PAGE'] ?? _activeValues['COVER_IMAGE'];
      if (img != null && img.isNotEmpty) return img;
    }
    if (upper == 'SALEABLE_RATE' || upper == 'MARKET_RATE_FLAT') {
      final rate = _activeValues['SALEABLE_RATE'] ?? _activeValues['MARKET_RATE_FLAT'] ?? _activeValues['MARKET_RATE_FLAT_NUMERIC'];
      if (rate != null && rate.isNotEmpty) return rate;
    }
    return _activeValues[key.toUpperCase()] ?? _activeValues[key.toLowerCase()] ?? _activeValues[key] ?? '';
  }

  void ensureCompositeMainUnit() {
    final orderId = _workspaceModel?.orderId ?? 0;
    final areaStr = _activeValues['SALEABLE_AREA_STANDARD_SQFT'] ?? _activeValues['SALEABLE_AREA_NUMERIC'] ?? _activeValues['SALEABLE_AREA'] ?? '1000';
    final parsedArea = ValueNormalizationEngine.extractNumericValue(areaStr);
    final area = parsedArea ?? (double.tryParse(areaStr.replaceAll(RegExp(r'[^0-9.]'), '').trim()) ?? 1000.0);
    final rateStr = _activeValues['SALEABLE_RATE'] ?? _activeValues['MARKET_RATE_FLAT_NUMERIC'] ?? _activeValues['MARKET_RATE_FLAT'] ?? '0';
    final rate = double.tryParse(rateStr.replaceAll(',', '').trim()) ?? 0.0;
    final costStr = _activeValues['COMPOSITE_CONSTRUCTION_COST'] ?? '2000';
    final cost = double.tryParse(costStr.replaceAll(',', '').trim()) ?? 2000.0;
    final ageStr = _activeValues['COMPOSITE_BUILDING_AGE'] ?? '0';
    final age = double.tryParse(ageStr.replaceAll(RegExp(r'[^0-9.]'), '').trim()) ?? 0.0;
    final lifeStr = _activeValues['COMPOSITE_BUILDING_TOTAL_LIFE'] ?? '60';
    final life = double.tryParse(lifeStr.replaceAll(RegExp(r'[^0-9.]'), '').trim()) ?? 60.0;

    if (_compositeItems.isEmpty) {
      _compositeItems.add(ValuationCompositeItemModel(
        orderId: orderId,
        itemCategory: 'MAIN_UNIT',
        description: _activeValues['PROPERTY_SUB_TYPE'] ?? _activeValues['PROPERTY_TYPE'] ?? 'Main Unit',
        enteredUnit: _activeValues['SALEABLE_AREA_UNIT'] ?? 'Sq.Ft',
        quantity: area,
        rate: rate,
        constructionCost: cost,
        buildingAge: age,
        totalLife: life,
        sortOrder: 0,
      ));
      _compositeItems.add(ValuationCompositeItemModel(
        orderId: orderId,
        itemCategory: 'INTERIOR_WORK',
        description: 'Interior Works & Improvements',
        enteredUnit: 'LS',
        quantity: 1.0,
        rate: 0.0,
        amount: 0.0,
        depreciationMode: 'DIRECT_AMOUNT',
        depreciationAmount: 0.0,
        isInsurable: true,
        sortOrder: 1,
      ));
      _compositeItems.add(ValuationCompositeItemModel(
        orderId: orderId,
        itemCategory: 'PARKING',
        description: 'Car Parking',
        enteredUnit: 'Slot',
        quantity: 1.0,
        rate: 0.0,
        amount: 0.0,
        depreciationAmount: 0.0,
        isInsurable: false,
        sortOrder: 2,
      ));
      return;
    }

    final existingIdx = _compositeItems.indexWhere((i) => i.itemCategory.toUpperCase() == 'MAIN_UNIT');
    if (existingIdx >= 0) {
      final item = _compositeItems[existingIdx];
      if (_activeValues.containsKey('SALEABLE_AREA_STANDARD_SQFT') || _activeValues.containsKey('SALEABLE_AREA_NUMERIC') || _activeValues.containsKey('SALEABLE_AREA')) {
        if (parsedArea != null && parsedArea > 0) {
          item.quantity = parsedArea;
        } else if (area > 0) {
          item.quantity = area;
        }
        if (_activeValues.containsKey('SALEABLE_AREA_UNIT')) {
          item.enteredUnit = _activeValues['SALEABLE_AREA_UNIT']!;
        }
      }
      if (_activeValues.containsKey('SALEABLE_RATE') || _activeValues.containsKey('MARKET_RATE_FLAT_NUMERIC') || _activeValues.containsKey('MARKET_RATE_FLAT')) {
        item.rate = rate;
      }
      if (cost > 0) item.constructionCost = cost;
      if (_activeValues.containsKey('COMPOSITE_BUILDING_AGE')) item.buildingAge = age;
      if (_activeValues.containsKey('COMPOSITE_BUILDING_TOTAL_LIFE') && life > 0) item.totalLife = life;
    } else {
      final mainUnit = ValuationCompositeItemModel(
        orderId: orderId,
        itemCategory: 'MAIN_UNIT',
        description: _activeValues['PROPERTY_SUB_TYPE'] ?? _activeValues['PROPERTY_TYPE'] ?? 'Main Unit',
        enteredUnit: _activeValues['SALEABLE_AREA_UNIT'] ?? 'Sq.Ft',
        quantity: area,
        rate: rate,
        constructionCost: cost,
        buildingAge: age,
        totalLife: life,
        sortOrder: 0,
      );
      _compositeItems.insert(0, mainUnit);
    }
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
