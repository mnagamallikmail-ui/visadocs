import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/utils/report_list_helper.dart';
import 'package:provaluer_frontend/providers/auth_provider.dart';

class MockAuthProvider extends AuthProvider {
  final int? _mockUserId;
  final String _mockRole;

  MockAuthProvider({required int? userId, required String role})
      : _mockUserId = userId,
        _mockRole = role;

  @override
  int? get userId => _mockUserId;

  @override
  String? get role => _mockRole;

  @override
  bool get isSuperAdmin => _mockRole == 'SUPER_ADMIN';
}

void main() {
  group('ReportListHelper Search Tests', () {
    final sampleReports = [
      {
        'id': 101,
        'reportNumber': 'PV-MUM-2026-001',
        'clientName': 'Rajesh Sharma',
        'bankName': 'HDFC Bank',
        'createdAt': '2026-09-01T10:00:00',
        'status': 'DRAFT',
      },
      {
        'id': 102,
        'reportNumber': 'PV-DEL-2026-002',
        'clientName': 'Pooja Verma',
        'bankName': 'State Bank of India',
        'createdAt': '2026-09-02T12:00:00',
        'status': 'ASSIGNED',
      },
      {
        'id': 103,
        'reportNumber': 'PV-BLR-2026-003',
        'clientName': 'Amit Patel',
        'bankName': 'ICICI Bank',
        'createdAt': '2026-08-15T09:00:00',
        'status': 'SPA_CONFIRMED',
      },
    ];

    test('Search strictly filters by Report Number', () {
      final results = ReportListHelper.filterAndSortReports(sampleReports, 'MUM-2026', 'date_desc');
      expect(results.length, 1);
      expect(results.first['reportNumber'], 'PV-MUM-2026-001');
    });

    test('Search strictly filters by Client Name', () {
      final results = ReportListHelper.filterAndSortReports(sampleReports, 'Pooja', 'date_desc');
      expect(results.length, 1);
      expect(results.first['clientName'], 'Pooja Verma');
    });

    test('Search strictly filters by Bank Name', () {
      final results = ReportListHelper.filterAndSortReports(sampleReports, 'ICICI', 'date_desc');
      expect(results.length, 1);
      expect(results.first['bankName'], 'ICICI Bank');
    });

    test('Search strictly filters by Report Date formatted', () {
      final results = ReportListHelper.filterAndSortReports(sampleReports, '15-08-2026', 'date_desc');
      expect(results.length, 1);
      expect(results.first['id'], 103);
    });

    test('Non-matching search returns empty list', () {
      final results = ReportListHelper.filterAndSortReports(sampleReports, 'NonExistentQuery', 'date_desc');
      expect(results.isEmpty, true);
    });
  });

  group('ReportListHelper Sort Tests', () {
    final sampleReports = [
      {
        'id': 1,
        'reportNumber': 'PV-C',
        'clientName': 'Charlie',
        'bankName': 'Zeta Bank',
        'createdAt': '2026-05-10T10:00:00',
      },
      {
        'id': 2,
        'reportNumber': 'PV-A',
        'clientName': 'Alice',
        'bankName': 'Beta Bank',
        'createdAt': '2026-09-01T10:00:00',
      },
      {
        'id': 3,
        'reportNumber': 'PV-B',
        'clientName': 'Bob',
        'bankName': 'Alpha Bank',
        'createdAt': '2026-01-01T10:00:00',
      },
    ];

    test('Sort by Report Date (Newest first - default)', () {
      final sorted = ReportListHelper.filterAndSortReports(sampleReports, '', 'date_desc');
      expect(sorted.map((r) => r['id']).toList(), [2, 1, 3]);
    });

    test('Sort by Report Date (Oldest first)', () {
      final sorted = ReportListHelper.filterAndSortReports(sampleReports, '', 'date_asc');
      expect(sorted.map((r) => r['id']).toList(), [3, 1, 2]);
    });

    test('Sort by Report Number (Ascending)', () {
      final sorted = ReportListHelper.filterAndSortReports(sampleReports, '', 'report_num_asc');
      expect(sorted.map((r) => r['reportNumber']).toList(), ['PV-A', 'PV-B', 'PV-C']);
    });

    test('Sort by Report Number (Descending)', () {
      final sorted = ReportListHelper.filterAndSortReports(sampleReports, '', 'report_num_desc');
      expect(sorted.map((r) => r['reportNumber']).toList(), ['PV-C', 'PV-B', 'PV-A']);
    });

    test('Sort by Client Name (Ascending)', () {
      final sorted = ReportListHelper.filterAndSortReports(sampleReports, '', 'client_name_asc');
      expect(sorted.map((r) => r['clientName']).toList(), ['Alice', 'Bob', 'Charlie']);
    });

    test('Sort by Client Name (Descending)', () {
      final sorted = ReportListHelper.filterAndSortReports(sampleReports, '', 'client_name_desc');
      expect(sorted.map((r) => r['clientName']).toList(), ['Charlie', 'Bob', 'Alice']);
    });

    test('Sort by Bank Name (Ascending)', () {
      final sorted = ReportListHelper.filterAndSortReports(sampleReports, '', 'bank_name_asc');
      expect(sorted.map((r) => r['bankName']).toList(), ['Alpha Bank', 'Beta Bank', 'Zeta Bank']);
    });

    test('Sort by Bank Name (Descending)', () {
      final sorted = ReportListHelper.filterAndSortReports(sampleReports, '', 'bank_name_desc');
      expect(sorted.map((r) => r['bankName']).toList(), ['Zeta Bank', 'Beta Bank', 'Alpha Bank']);
    });
  });

  group('ReportListHelper Deletion Permission Tests', () {
    final unfinalizedReport = {
      'id': 501,
      'clientId': 10,
      'status': 'ASSIGNED',
      'valuationStatus': 'DRAFT',
    };

    final finalizedReport = {
      'id': 502,
      'clientId': 10,
      'status': 'FINAL_DELIVERY',
      'valuationStatus': 'FINALIZED',
    };

    test('Creator CAN delete unfinalized report', () {
      final creatorAuth = MockAuthProvider(userId: 10, role: 'PA');
      expect(ReportListHelper.canDeleteReport(unfinalizedReport, creatorAuth), true);
    });

    test('Non-creator CANNOT delete unfinalized report', () {
      final nonCreatorAuth = MockAuthProvider(userId: 99, role: 'PA');
      expect(ReportListHelper.canDeleteReport(unfinalizedReport, nonCreatorAuth), false);
    });

    test('Super Admin CAN delete unfinalized report', () {
      final saAuth = MockAuthProvider(userId: 1, role: 'SUPER_ADMIN');
      expect(ReportListHelper.canDeleteReport(unfinalizedReport, saAuth), true);
    });

    test('Creator CANNOT delete finalized report', () {
      final creatorAuth = MockAuthProvider(userId: 10, role: 'PA');
      expect(ReportListHelper.canDeleteReport(finalizedReport, creatorAuth), false);
    });

    test('Super Admin CAN delete finalized report', () {
      final saAuth = MockAuthProvider(userId: 1, role: 'SUPER_ADMIN');
      expect(ReportListHelper.canDeleteReport(finalizedReport, saAuth), true);
    });

    final adminCreatedReport = {
      'id': 503,
      'clientId': 10,
      'adminCreated': true,
      'status': 'DRAFT',
      'valuationStatus': 'DRAFT',
    };

    test('Client CANNOT delete report created by Super Admin on their behalf', () {
      final clientAuth = MockAuthProvider(userId: 10, role: 'CLIENT');
      expect(ReportListHelper.canDeleteReport(adminCreatedReport, clientAuth), false);
    });

    test('Super Admin CAN delete report created by Super Admin on behalf of Client', () {
      final saAuth = MockAuthProvider(userId: 1, role: 'SUPER_ADMIN');
      expect(ReportListHelper.canDeleteReport(adminCreatedReport, saAuth), true);
    });

    final clientCreatedReport = {
      'id': 601,
      'clientId': 4,
      'adminCreated': false,
      'status': 'DRAFT',
      'valuationStatus': 'DRAFT',
    };

    test('Client CAN delete their own client-created report', () {
      final clientAuth = MockAuthProvider(userId: 4, role: 'CLIENT');
      expect(ReportListHelper.canDeleteReport(clientCreatedReport, clientAuth), true);
    });

    test('Client CAN delete their own report even if userId is null in AuthProvider', () {
      final clientAuth = MockAuthProvider(userId: null, role: 'CLIENT');
      expect(ReportListHelper.canDeleteReport(clientCreatedReport, clientAuth), true);
    });

    test('PA CANNOT delete client-created report', () {
      final paAuth = MockAuthProvider(userId: 2, role: 'PA');
      expect(ReportListHelper.canDeleteReport(clientCreatedReport, paAuth), false);
    });

    test('SPA CANNOT delete client-created report', () {
      final spaAuth = MockAuthProvider(userId: 3, role: 'SPA');
      expect(ReportListHelper.canDeleteReport(clientCreatedReport, spaAuth), false);
    });

    test('Super Admin CAN delete client-created report', () {
      final saAuth = MockAuthProvider(userId: 1, role: 'SUPER_ADMIN');
      expect(ReportListHelper.canDeleteReport(clientCreatedReport, saAuth), true);
    });
  });
}
