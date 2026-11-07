import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Form draft state holding question-answer pairs and active section index.
class ValuationDraft {
  final String reportId;
  final int activeSectionIndex;
  final Map<String, dynamic> formValues;
  final DateTime lastSaved;

  ValuationDraft({
    required this.reportId,
    required this.activeSectionIndex,
    required this.formValues,
    required this.lastSaved,
  });

  Map<String, dynamic> toJson() => {
        'reportId': reportId,
        'activeSectionIndex': activeSectionIndex,
        'formValues': formValues,
        'lastSaved': lastSaved.toIso8601String(),
      };

  factory ValuationDraft.fromJson(Map<String, dynamic> json) => ValuationDraft(
        reportId: json['reportId']?.toString() ?? '',
        activeSectionIndex: json['activeSectionIndex'] is int ? json['activeSectionIndex'] : 0,
        formValues: Map<String, dynamic>.from(json['formValues'] ?? {}),
        lastSaved: DateTime.tryParse(json['lastSaved']?.toString() ?? '') ?? DateTime.now(),
      );
}

/// Service managing 30-second autosave, draft persistence, and restoration.
class ValuationAutosaveService with WidgetsBindingObserver {
  ValuationAutosaveService._() {
    WidgetsBinding.instance.addObserver(this);
  }
  static final ValuationAutosaveService instance = ValuationAutosaveService._();

  Timer? _periodicTimer;
  String? _activeReportId;
  int _activeSectionIndex = 0;
  Map<String, dynamic> _currentFormValues = {};

  /// Starts the 30-second autosave loop for the active valuation report.
  void startAutosaveSession({
    required String reportId,
    required int initialSectionIndex,
    required Map<String, dynamic> initialValues,
  }) {
    _activeReportId = reportId;
    _activeSectionIndex = initialSectionIndex;
    _currentFormValues = Map<String, dynamic>.from(initialValues);

    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _flushDraftToStorage();
    });
  }

  /// Updates current in-memory form values.
  void updateFormState({
    required int sectionIndex,
    required Map<String, dynamic> formValues,
  }) {
    _activeSectionIndex = sectionIndex;
    _currentFormValues = Map<String, dynamic>.from(formValues);
  }

  /// Flushes form state immediately upon section change.
  Future<void> onSectionChanged(int newSectionIndex) async {
    _activeSectionIndex = newSectionIndex;
    await _flushDraftToStorage();
  }

  /// Manually triggers immediate autosave.
  Future<void> saveImmediately() async {
    await _flushDraftToStorage();
  }

  /// Checks if an existing unsaved draft exists for a given report ID.
  Future<ValuationDraft?> checkForExistingDraft(String reportId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('draft_valuation_$reportId');
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return ValuationDraft.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('[ValuationAutosaveService] Error reading draft: $e');
    }
    return null;
  }

  /// Clears draft once report has been submitted to backend.
  Future<void> clearDraft(String reportId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('draft_valuation_$reportId');
      if (_activeReportId == reportId) {
        _stopSession();
      }
    } catch (e) {
      debugPrint('[ValuationAutosaveService] Error clearing draft: $e');
    }
  }

  void _stopSession() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _activeReportId = null;
  }

  Future<void> _flushDraftToStorage() async {
    if (_activeReportId == null || _currentFormValues.isEmpty) return;
    try {
      final draft = ValuationDraft(
        reportId: _activeReportId!,
        activeSectionIndex: _activeSectionIndex,
        formValues: _currentFormValues,
        lastSaved: DateTime.now(),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('draft_valuation_$_activeReportId', jsonEncode(draft.toJson()));
      debugPrint('[ValuationAutosaveService] Autosaved draft for report $_activeReportId at ${draft.lastSaved}');
    } catch (e) {
      debugPrint('[ValuationAutosaveService] Error flushing draft: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _flushDraftToStorage();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicTimer?.cancel();
  }
}

