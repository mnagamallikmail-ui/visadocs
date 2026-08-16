import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../services/api_service.dart';
import '../models/studio_document_model.dart';
import '../models/custom_placeholder_config.dart';
import '../models/calculation_table_model.dart';

class DocumentStudioProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isPublishing = false;
  bool _isDirty = false;
  String? _errorMessage;
  StudioDocumentModel? _documentModel;
  String? _selectedPlaceholderKey;
  String? _selectedTableId;

  Map<String, CustomPlaceholderConfig> _customConfigMap = {};
  Map<String, String> _customLabels = {};
  Map<String, CalculationTableConfig> _tableConfigsMap = {};
  List<dynamic> _tableConfigs = [];

  // Getters
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isPublishing => _isPublishing;
  bool get isDirty => _isDirty;
  String? get errorMessage => _errorMessage;
  StudioDocumentModel? get documentModel => _documentModel;
  String? get selectedPlaceholderKey => _selectedPlaceholderKey;
  String? get selectedTableId => _selectedTableId;
  Map<String, CustomPlaceholderConfig> get customConfigMap => _customConfigMap;
  Map<String, String> get customLabels => _customLabels;
  Map<String, CalculationTableConfig> get tableConfigsMap => _tableConfigsMap;
  List<dynamic> get tableConfigs => _tableConfigs;
  bool get hasDocument => _documentModel != null;

  /// Loads the template's structured OpenXML document tree and configuration from the backend.
  Future<void> loadTemplateStructure(int templateId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.get(
        '/api/v1/studio/templates/$templateId/structure',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is String ? jsonDecode(response.data as String) : response.data;
        _documentModel = StudioDocumentModel.fromJson(data as Map<String, dynamic>);
      } else {
        _errorMessage = 'Failed to load document structure: HTTP ${response.statusCode}';
      }

      // Concurrently load existing configuration overrides
      await loadConfig(templateId);
    } on DioException catch (dioErr) {
      if (dioErr.response?.statusCode == 403) {
        _errorMessage = 'Document Studio is restricted or disabled for your role.';
      } else if (dioErr.response?.statusCode == 404) {
        _errorMessage = 'Template #$templateId was not found.';
      } else {
        final msg = dioErr.response?.data?['error']?.toString();
        _errorMessage = msg ?? dioErr.message ?? 'Network error while loading document structure';
      }
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Retrieves previously saved custom labels, field configs, and calculation settings.
  Future<void> loadConfig(int templateId) async {
    try {
      final response = await _apiService.dio.get(
        '/api/v1/studio/templates/$templateId/config',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // Parse customLabels JSON payload
        final rawLabels = data['customLabels'];
        if (rawLabels != null) {
          Map<String, dynamic> decodedMap = {};
          if (rawLabels is String && rawLabels.trim().isNotEmpty) {
            try {
              decodedMap = jsonDecode(rawLabels) as Map<String, dynamic>;
            } catch (_) {}
          } else if (rawLabels is Map<String, dynamic>) {
            decodedMap = rawLabels;
          }

          final Map<String, CustomPlaceholderConfig> parsedConfigMap = {};
          final Map<String, String> parsedLabels = {};

          decodedMap.forEach((key, val) {
            final upperKey = key.toUpperCase();
            if (val is Map<String, dynamic>) {
              final cfg = CustomPlaceholderConfig.fromJson(val);
              parsedConfigMap[upperKey] = cfg;
              parsedLabels[upperKey] = cfg.label;
            } else if (val is String) {
              final cfg = CustomPlaceholderConfig(label: val);
              parsedConfigMap[upperKey] = cfg;
              parsedLabels[upperKey] = val;
            }
          });

          _customConfigMap = parsedConfigMap;
          _customLabels = parsedLabels;
        }

        // Parse tableConfigs JSON string if present
        final rawTables = data['tableConfigs'];
        final Map<String, CalculationTableConfig> parsedTableMap = {};

        if (rawTables != null) {
          List<dynamic> rawList = [];
          if (rawTables is String && rawTables.trim().isNotEmpty) {
            try {
              rawList = jsonDecode(rawTables) as List<dynamic>;
            } catch (_) {
              rawList = [];
            }
          } else if (rawTables is List) {
            rawList = rawTables;
          }

          _tableConfigs = rawList;
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              final cfg = CalculationTableConfig.fromJson(item);
              if (cfg.tableId.isNotEmpty) {
                parsedTableMap[cfg.tableId] = cfg;
              }
            }
          }
        }

        _tableConfigsMap = parsedTableMap;
        _isDirty = false;
      }
    } catch (_) {
      _customConfigMap = {};
      _customLabels = {};
      _tableConfigsMap = {};
      _tableConfigs = [];
      _isDirty = false;
    }
  }

  /// Persists custom labels, questions, and table configurations to the backend.
  Future<bool> saveConfig(int templateId) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Serialize structured customConfigMap into JSON
      final Map<String, dynamic> serializedLabels = {};
      _customConfigMap.forEach((key, config) {
        serializedLabels[key] = config.toJson();
      });

      // Serialize structured tableConfigsMap into JSON
      final List<Map<String, dynamic>> serializedTables =
          _tableConfigsMap.values.map((c) => c.toJson()).toList();

      final payload = {
        'customLabels': jsonEncode(serializedLabels),
        'tableConfigs': jsonEncode(serializedTables),
      };

      final response = await _apiService.dio.post(
        '/api/v1/studio/templates/$templateId/config',
        data: payload,
      );

      final isSuccess = response.statusCode == 200;
      if (isSuccess) {
        _isDirty = false;
      }
      return isSuccess;
    } on DioException catch (dioErr) {
      _errorMessage = dioErr.response?.data?['error']?.toString() ??
          dioErr.message ??
          'Failed to save configuration';
      return false;
    } catch (e) {
      _errorMessage = 'Error saving configuration: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Publishes customized Document Studio questions into the central template dictionary and intake schema.
  Future<bool> publishToIntake(int templateId) async {
    _isPublishing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Automatically persist any unsaved local modifications before publishing
      if (_isDirty) {
        final saved = await saveConfig(templateId);
        if (!saved) {
          return false;
        }
      }

      final response = await _apiService.dio.post(
        '/api/v1/studio/templates/$templateId/publish-intake',
      );

      return response.statusCode == 200;
    } on DioException catch (dioErr) {
      _errorMessage = dioErr.response?.data?['error']?.toString() ??
          dioErr.message ??
          'Failed to publish questions to intake';
      return false;
    } catch (e) {
      _errorMessage = 'Error publishing questions: $e';
      return false;
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }

  /// Updates or sets custom configuration for a specific placeholder key.
  void updatePlaceholderConfig(String key, CustomPlaceholderConfig config) {
    final upperKey = key.toUpperCase();
    _customConfigMap[upperKey] = config;
    _customLabels[upperKey] = config.label;
    _isDirty = true;
    notifyListeners();
  }

  /// Removes custom configuration override for a placeholder key, restoring its default state.
  void resetPlaceholderConfig(String key) {
    final upperKey = key.toUpperCase();
    if (_customConfigMap.containsKey(upperKey) || _customLabels.containsKey(upperKey)) {
      _customConfigMap.remove(upperKey);
      _customLabels.remove(upperKey);
      _isDirty = true;
      notifyListeners();
    }
  }

  /// Retrieves the custom configuration for a specific placeholder key, or null if unconfigured.
  CustomPlaceholderConfig? getPlaceholderConfig(String key) {
    return _customConfigMap[key.toUpperCase()];
  }

  /// Returns the effective label for a placeholder key (custom label if configured, otherwise auto-generated label).
  String getEffectiveLabel(String key) {
    final upperKey = key.toUpperCase();
    if (_customConfigMap.containsKey(upperKey) && _customConfigMap[upperKey]!.label.trim().isNotEmpty) {
      return _customConfigMap[upperKey]!.label;
    }

    if (_documentModel != null) {
      for (final item in _documentModel!.placeholdersSummary) {
        if (item.key.toUpperCase() == upperKey && item.label.trim().isNotEmpty) {
          return item.label;
        }
      }
    }

    // Fallback: capitalize snake_case key
    return upperKey
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  /// Updates or sets a calculation table configuration.
  void updateTableConfig(CalculationTableConfig config) {
    _tableConfigsMap[config.tableId] = config;
    _isDirty = true;
    notifyListeners();
  }

  /// Retrieves the calculation configuration for a specific table, or null if unconfigured.
  CalculationTableConfig? getTableConfig(String tableId) {
    return _tableConfigsMap[tableId];
  }

  /// Sets or updates a simple custom label for a specific placeholder key (legacy fallback).
  void setCustomLabel(String key, String label) {
    final upperKey = key.toUpperCase();
    final existing = _customConfigMap[upperKey];
    if (existing != null) {
      _customConfigMap[upperKey] = existing.copyWith(label: label);
    } else {
      _customConfigMap[upperKey] = CustomPlaceholderConfig(label: label);
    }
    _customLabels[upperKey] = label;
    _isDirty = true;
    notifyListeners();
  }

  /// Sets the currently active/selected placeholder key for canvas highlighting and editor display.
  void selectPlaceholder(String key) {
    _selectedPlaceholderKey = key;
    _selectedTableId = null;
    notifyListeners();
  }

  /// Sets the currently active/selected table ID for inspector editing.
  void selectTable(String tableId) {
    _selectedTableId = tableId;
    _selectedPlaceholderKey = null;
    notifyListeners();
  }

  /// Clears active selections.
  void clearSelection() {
    _selectedPlaceholderKey = null;
    _selectedTableId = null;
    notifyListeners();
  }

  /// Resets the provider state.
  void reset() {
    _isLoading = false;
    _isSaving = false;
    _isPublishing = false;
    _isDirty = false;
    _errorMessage = null;
    _documentModel = null;
    _selectedPlaceholderKey = null;
    _selectedTableId = null;
    _customConfigMap = {};
    _customLabels = {};
    _tableConfigsMap = {};
    _tableConfigs = [];
    notifyListeners();
  }
}
