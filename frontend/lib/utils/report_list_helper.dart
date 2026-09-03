import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';

class ReportListHelper {
  /// Formats raw date (String, DateTime, or List) into standard DD-MM-YYYY format
  static String formatReportDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      if (raw is String) {
        final dt = DateTime.parse(raw);
        final d = dt.day.toString().padLeft(2, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final y = dt.year.toString();
        return '$d-$m-$y';
      } else if (raw is DateTime) {
        final d = raw.day.toString().padLeft(2, '0');
        final m = raw.month.toString().padLeft(2, '0');
        final y = raw.year.toString();
        return '$d-$m-$y';
      }
    } catch (_) {}
    return raw.toString();
  }

  /// Filters strictly by: Report Number, Client Name, Bank Name, Report Date
  /// Sorts strictly by: Report Number, Report Date, Client Name, Bank Name
  static List<dynamic> filterAndSortReports(
    List<dynamic> reports,
    String query,
    String sortBy,
  ) {
    final q = query.trim().toLowerCase();

    var result = reports.where((r) {
      if (q.isEmpty) return true;
      final reportNum = (r['reportNumber'] ?? 'PV-${r['id']}').toString().toLowerCase();
      final clientName = (r['clientName'] ?? '').toString().toLowerCase();
      final bankName = (r['bankName'] ?? '').toString().toLowerCase();
      final dateFormatted = formatReportDate(r['createdAt']).toLowerCase();
      final rawDate = (r['createdAt'] ?? '').toString().toLowerCase();

      return reportNum.contains(q) ||
          clientName.contains(q) ||
          bankName.contains(q) ||
          dateFormatted.contains(q) ||
          rawDate.contains(q);
    }).toList();

    result.sort((a, b) {
      switch (sortBy) {
        case 'date_asc':
          final da = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(1970);
          final db = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(1970);
          return da.compareTo(db);
        case 'date_desc':
          final da = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(1970);
          final db = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(1970);
          return db.compareTo(da);
        case 'report_num_asc':
          final na = (a['reportNumber'] ?? 'PV-${a['id']}').toString().toLowerCase();
          final nb = (b['reportNumber'] ?? 'PV-${b['id']}').toString().toLowerCase();
          return na.compareTo(nb);
        case 'report_num_desc':
          final na = (a['reportNumber'] ?? 'PV-${a['id']}').toString().toLowerCase();
          final nb = (b['reportNumber'] ?? 'PV-${b['id']}').toString().toLowerCase();
          return nb.compareTo(na);
        case 'client_name_asc':
          final ca = (a['clientName'] ?? '').toString().toLowerCase();
          final cb = (b['clientName'] ?? '').toString().toLowerCase();
          return ca.compareTo(cb);
        case 'client_name_desc':
          final ca = (a['clientName'] ?? '').toString().toLowerCase();
          final cb = (b['clientName'] ?? '').toString().toLowerCase();
          return cb.compareTo(ca);
        case 'bank_name_asc':
          final ba = (a['bankName'] ?? '').toString().toLowerCase();
          final bb = (b['bankName'] ?? '').toString().toLowerCase();
          return ba.compareTo(bb);
        case 'bank_name_desc':
          final ba = (a['bankName'] ?? '').toString().toLowerCase();
          final bb = (b['bankName'] ?? '').toString().toLowerCase();
          return bb.compareTo(ba);
        default:
          final da = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(1970);
          final db = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(1970);
          return db.compareTo(da);
      }
    });

    return result;
  }

  /// Approved Deletion Permission Rule:
  /// - Reports created by Super Admin on behalf of a Client: Only Super Admin can delete; Client cannot!
  /// - Unfinalized: Creator or Super Admin may delete.
  /// - Finalized: Only Super Admin may delete.
  static bool canDeleteReport(dynamic report, AuthProvider auth) {
    final isSuperAdmin = auth.isSuperAdmin || auth.role == 'SUPER_ADMIN';
    final isAdminCreated = report['adminCreated'] == true;

    if (isAdminCreated) {
      return isSuperAdmin;
    }

    final valStatus = (report['valuationStatus'] ?? '').toString().toUpperCase();
    final status = (report['status'] ?? '').toString().toUpperCase();
    final isFinalized = valStatus == 'FINALIZED' ||
        valStatus == 'LOCKED' ||
        status == 'SPA_CONFIRMED' ||
        status == 'FINAL_DELIVERY';

    if (isFinalized) {
      return isSuperAdmin;
    } else {
      final clientId = report['clientId'];
      final isCreator = clientId != null && auth.userId != null && clientId == auth.userId;
      return isCreator || isSuperAdmin;
    }
  }
}

/// Standard Search and Sorting Toolbar strictly for Report Number, Report Date, Client Name, and Bank Name.
class ReportSearchSortBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String sortBy;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final ValueChanged<String?> onSortChanged;
  final EdgeInsetsGeometry padding;

  const ReportSearchSortBar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onSortChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Search by Report #, Client Name, Bank Name, or Date...',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.slate),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.slate),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16, color: AppColors.slate),
                          onPressed: onSearchCleared,
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.hairline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.hairline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.brandBlue),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.hairline),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: sortBy,
                icon: const Icon(Icons.sort, size: 18, color: AppColors.slate),
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink, fontWeight: FontWeight.w500),
                onChanged: onSortChanged,
                items: const [
                  DropdownMenuItem(value: 'date_desc', child: Text('Report Date (Newest)')),
                  DropdownMenuItem(value: 'date_asc', child: Text('Report Date (Oldest)')),
                  DropdownMenuItem(value: 'report_num_asc', child: Text('Report Number (A-Z)')),
                  DropdownMenuItem(value: 'report_num_desc', child: Text('Report Number (Z-A)')),
                  DropdownMenuItem(value: 'client_name_asc', child: Text('Client Name (A-Z)')),
                  DropdownMenuItem(value: 'client_name_desc', child: Text('Client Name (Z-A)')),
                  DropdownMenuItem(value: 'bank_name_asc', child: Text('Bank Name (A-Z)')),
                  DropdownMenuItem(value: 'bank_name_desc', child: Text('Bank Name (Z-A)')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
