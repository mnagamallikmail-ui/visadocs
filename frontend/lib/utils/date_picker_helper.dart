import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Class representing the result of a date picker interaction.
class DatePickerResult {
  final bool isClear;
  final DateTime? date;

  const DatePickerResult.selected(DateTime this.date) : isClear = false;
  const DatePickerResult.clear() : isClear = true, date = null;
}

class DatePickerHelper {
  static const List<String> months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Formats a DateTime into strict dd-MMM-yyyy format (e.g., 03-Sep-2026)
  static String formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year.toString();
    return '$day-$month-$year';
  }

  /// Parses any common date format into DateTime:
  /// - dd-MMM-yyyy (03-Sep-2026, 3-Sep-2026)
  /// - dd-MM-yyyy (13-09-2026)
  /// - yyyy-MM-dd (2026-09-13)
  /// - Slash/dot delimiters (13/09/2026, 13.09.2026, 2026/09/13)
  /// - Full month names (03-September-2026)
  static DateTime? parseFlexibleDate(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // 1. Try standard ISO 8601
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;

    // 2. Normalize delimiters: replace '/', '.', ' ' with '-'
    final normalized = trimmed.replaceAll('/', '-').replaceAll('.', '-').replaceAll(' ', '-');
    final parts = normalized.split('-').where((p) => p.isNotEmpty).toList();
    if (parts.length == 3) {
      final p0 = parts[0];
      final p1 = parts[1];
      final p2 = parts[2];

      // Format: yyyy-MM-dd or yyyy-MMM-dd
      if (p0.length == 4 && int.tryParse(p0) != null) {
        final y = int.parse(p0);
        final m = _parseMonth(p1);
        final d = int.tryParse(p2);
        if (m != null && d != null && d >= 1 && d <= 31) {
          return DateTime(y, m, d);
        }
      }

      // Format: dd-MM-yyyy or dd-MMM-yyyy
      final y = int.tryParse(p2);
      final d = int.tryParse(p0);
      final m = _parseMonth(p1);
      if (y != null && d != null && m != null && d >= 1 && d <= 31) {
        return DateTime(y, m, d);
      }
    }
    return null;
  }

  static int? _parseMonth(String mStr) {
    final numMonth = int.tryParse(mStr);
    if (numMonth != null && numMonth >= 1 && numMonth <= 12) {
      return numMonth;
    }
    final lower = mStr.toLowerCase();
    for (int i = 0; i < months.length; i++) {
      if (lower.startsWith(months[i].toLowerCase())) {
        return i + 1;
      }
    }
    return null;
  }

  /// Centralized date placeholder classification rule:
  /// Matches 'DATE', '*DATE*', 'DT_*', '*_DT', '*_DT_*', and known date aliases.
  /// Strictly rejects text, names, remarks, addresses, composite tables, images, numbers.
  static bool isDateKey(String key, [String? fieldType]) {
    final k = key.replaceAll(RegExp(r'[<>\s]'), '').trim().toUpperCase();
    if (k.isEmpty ||
        k == 'COMPOSITE_PROPERTY_TABLE' ||
        k == 'DYNAMIC_COMPOSITE_PROPERTY_TABLE' ||
        k == 'COMPOSITE_TABLE' ||
        k.startsWith('CALC:')) {
      return false;
    }
    // Explicit non-date placeholders must never become DATE
    if (k == 'TEXT' ||
        k == 'TXT' ||
        k == 'TEXT_PLACEHOLDER' ||
        k.startsWith('TEXT_') ||
        k.endsWith('_TEXT') ||
        k.startsWith('TXT_') ||
        k.endsWith('_TXT') ||
        RegExp(r'^(TEXT|TXT)_\d+$').hasMatch(k) ||
        k == 'OWNER_NAME' ||
        k == 'PROPERTY_REMARKS' ||
        k.contains('NAME') ||
        k.contains('REMARK') ||
        k.contains('ADDRESS') ||
        k.contains('RATE') ||
        k.contains('VALUE') ||
        k.contains('AREA') ||
        k.contains('DESC') ||
        k.contains('COMMENT') ||
        k.contains('NOTE') ||
        k.contains('CAPTION')) {
      return false;
    }

    final isExplicitDate = k == 'DATE' ||
        k.startsWith('DATE_') ||
        k.endsWith('_DATE') ||
        k.contains('_DATE_') ||
        k.startsWith('DT_') ||
        k.endsWith('_DT') ||
        k.contains('_DT_') ||
        k == 'INSPECTION_DATE' ||
        k == 'VALUATION_DATE' ||
        k == 'REPORT_DATE' ||
        k == 'VISIT_DATE' ||
        k == 'APPLICATION_DATE' ||
        k == 'LEGAL_DATE' ||
        k == 'DATE_OF_INSPECTION' ||
        k == 'DATE_OF_REPORT' ||
        k == 'DATE_OF_VALUATION' ||
        k == 'DATE_OF_VISIT';

    if (isExplicitDate) return true;

    final t = (fieldType ?? '').trim().toUpperCase();
    if (t == 'DATE' && k.contains('DATE')) return true;

    return false;
  }

  /// Displays the full-featured, accessible calendar picker dialog:
  /// - Month picker & Year picker via header click
  /// - Previous / Next month buttons
  /// - Today's date highlighted
  /// - Single-click date selection with automatic close
  /// - 'Today' button to quickly set current date and auto-close
  /// - 'Clear' button to empty the field and auto-close
  /// - Keyboard accessibility
  /// Returns formatted dd-MMM-yyyy string, '' (empty for clear), or null if cancelled.
  static Future<String?> showAppDatePicker({
    required BuildContext context,
    required String title,
    required String currentValue,
  }) async {
    final now = DateTime.now();
    DateTime initial = now;
    final parsed = parseFlexibleDate(currentValue);
    if (parsed != null) {
      initial = parsed;
    }

    final firstDate = DateTime(1970);
    final lastDate = DateTime(2050);
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final result = await showDialog<DatePickerResult>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dialog Header
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 20,
                      color: AppColors.workspaceCorporateNavy,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title.isNotEmpty ? title : 'Select Date',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.slate),
                      onPressed: () => Navigator.of(ctx).pop(null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Cancel',
                    ),
                  ],
                ),
                const Divider(height: 16, color: AppColors.hairline),

                // Calendar Date Picker
                Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.deepTeal,
                      onPrimary: Colors.white,
                      onSurface: AppColors.ink,
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: initial,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    onDateChanged: (selectedDate) {
                      // Single-click selection: automatically closes dialog
                      Navigator.of(ctx).pop(DatePickerResult.selected(selectedDate));
                    },
                  ),
                ),

                const Divider(height: 16, color: AppColors.hairline),

                // Bottom Action Bar: Clear & Today
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop(const DatePickerResult.clear());
                      },
                      icon: const Icon(Icons.clear_rounded, size: 14, color: Color(0xFFDC2626)),
                      label: Text(
                        'Clear',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(null),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop(DatePickerResult.selected(DateTime.now()));
                      },
                      icon: const Icon(Icons.today_rounded, size: 14, color: Colors.white),
                      label: Text(
                        'Today',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepTeal,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) return null;
    if (result.isClear) return '';
    if (result.date != null) return formatDate(result.date!);
    return null;
  }
}
