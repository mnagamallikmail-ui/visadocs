import 'package:flutter/material.dart';

/// Represents a registered inline editable placeholder instance in document order.
class PlaceholderRegistration {
  final String id;
  final String key;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;
  final BuildContext Function()? getContext;

  const PlaceholderRegistration({
    required this.id,
    required this.key,
    required this.onActivate,
    required this.onDeactivate,
    this.getContext,
  });
}

/// Centralized registry managing document-order navigation across all inline editable placeholders.
class PlaceholderRegistry {
  final List<PlaceholderRegistration> _entries = [];
  String? _activeId;

  List<PlaceholderRegistration> get entries => List.unmodifiable(_entries);
  String? get activeId => _activeId;

  /// Registers a placeholder instance into the document-order navigation sequence.
  void register(PlaceholderRegistration registration) {
    _entries.removeWhere((e) => e.id == registration.id);
    _entries.add(registration);
  }

  /// Deregisters a placeholder upon widget disposal.
  void unregister(String id) {
    if (_activeId == id) {
      _activeId = null;
    }
    _entries.removeWhere((e) => e.id == id);
  }

  /// Clears all registrations.
  void clear() {
    _entries.clear();
    _activeId = null;
  }

  /// Sets the currently active placeholder, closing any previously active editor.
  void setActive(String? id) {
    if (_activeId == id) return;

    final oldId = _activeId;
    _activeId = id;

    if (oldId != null) {
      final prev = getEntry(oldId);
      prev?.onDeactivate();
    }
  }

  /// Retrieves a registration by instance ID.
  PlaceholderRegistration? getEntry(String id) {
    try {
      return _entries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Navigates to the next placeholder in document order, activating it and scrolling it into view.
  void next(String currentId) {
    if (_entries.isEmpty) return;
    final idx = _entries.indexWhere((e) => e.id == currentId);
    if (idx != -1 && idx < _entries.length - 1) {
      final nextEntry = _entries[idx + 1];
      _activateAndScroll(nextEntry);
    } else if (idx == -1 && _entries.isNotEmpty) {
      _activateAndScroll(_entries.first);
    }
  }

  /// Navigates to the previous placeholder in document order.
  void previous(String currentId) {
    if (_entries.isEmpty) return;
    final idx = _entries.indexWhere((e) => e.id == currentId);
    if (idx > 0) {
      final prevEntry = _entries[idx - 1];
      _activateAndScroll(prevEntry);
    } else if (idx == -1 && _entries.isNotEmpty) {
      _activateAndScroll(_entries.last);
    }
  }

  /// Activates the very first editable placeholder in document order.
  void activateFirst() {
    if (_entries.isNotEmpty) {
      _activateAndScroll(_entries.first);
    }
  }

  void _activateAndScroll(PlaceholderRegistration entry) {
    // Close current if different
    if (_activeId != null && _activeId != entry.id) {
      final prev = getEntry(_activeId!);
      prev?.onDeactivate();
    }
    _activeId = entry.id;
    entry.onActivate();

    if (entry.getContext != null) {
      try {
        final ctx = entry.getContext!();
        if (ctx.mounted) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: 0.5,
          );
        }
      } catch (_) {
        // Fallback for headless testing environments without scrollable parent
      }
    }
  }
}
