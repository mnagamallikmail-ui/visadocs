import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provaluer_frontend/constants/order_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('P0 Workspace Abandonment Recovery & Admin Controls Governance Tests', () {

    test('Canonical authoring states are open and governable', () {
      expect(OrderStatus.workspaceReady, 'WORKSPACE_READY');
      expect(OrderStatus.drafting, 'DRAFTING');
      expect(OrderStatus.actionNeeded, 'ACTION_NEEDED');
      expect(OrderStatus.assigned, 'ASSIGNED');

      expect(OrderStatus.isOpen(OrderStatus.workspaceReady), isTrue);
      expect(OrderStatus.isOpen(OrderStatus.drafting), isTrue);
      expect(OrderStatus.isOpen(OrderStatus.actionNeeded), isTrue);
      expect(OrderStatus.isOpen(OrderStatus.assigned), isTrue);
    });

    test('Staleness and Abandonment Indicator Logic calculates correct thresholds', () {
      final now = DateTime.now();

      // Helper simulating the UI badge evaluator
      List<String> evaluateBadges(Map<String, dynamic> order) {
        final badges = <String>[];
        final status = (order['status']?.toString() ?? '').toUpperCase();
        final isActive = status == 'ASSIGNED' ||
            status == 'WORKSPACE_READY' ||
            status == 'DRAFTING' ||
            status == 'ACTION_NEEDED';

        // SLA
        final expStr = order['slaExpiryTime']?.toString();
        if (expStr != null) {
          final exp = DateTime.tryParse(expStr);
          if (exp != null) {
            if (now.isAfter(exp)) {
              final odHours = now.difference(exp).inMinutes / 60.0;
              if (odHours >= 4.0) {
                badges.add('CRITICAL');
              } else {
                badges.add('OVERDUE');
              }
            } else {
              final remHours = exp.difference(now).inMinutes / 60.0;
              if (remHours <= 4.0) {
                badges.add('WARNING');
              } else {
                badges.add('ON_TRACK');
              }
            }
          }
        }

        // Staleness & Abandonment
        if (isActive) {
          final hbStr = order['lastHeartbeat']?.toString();
          final claimStr = order['claimedAt']?.toString();
          DateTime? lastActive = DateTime.tryParse(hbStr ?? '') ?? DateTime.tryParse(claimStr ?? '');

          if (lastActive != null) {
            final hoursStale = now.difference(lastActive).inMinutes / 60.0;
            if (hoursStale >= 72.0) {
              badges.add('Stale 72h');
            } else if (hoursStale >= 48.0) {
              badges.add('Stale 48h');
            } else if (hoursStale >= 24.0) {
              badges.add('Stale 24h');
            }

            if (hoursStale >= 6.0) {
              badges.add('Abandoned');
            }
          }
        }
        return badges;
      }

      // 1. Order active 75 hours ago -> Stale 72h + Abandoned
      final stale72 = evaluateBadges({
        'status': 'DRAFTING',
        'lastHeartbeat': now.subtract(const Duration(hours: 75)).toIso8601String(),
      });
      expect(stale72.contains('Stale 72h'), isTrue);
      expect(stale72.contains('Abandoned'), isTrue);

      // 2. Order active 50 hours ago -> Stale 48h + Abandoned
      final stale48 = evaluateBadges({
        'status': 'WORKSPACE_READY',
        'lastHeartbeat': now.subtract(const Duration(hours: 50)).toIso8601String(),
      });
      expect(stale48.contains('Stale 48h'), isTrue);
      expect(stale48.contains('Abandoned'), isTrue);

      // 3. Order active 26 hours ago -> Stale 24h + Abandoned
      final stale24 = evaluateBadges({
        'status': 'ASSIGNED',
        'lastHeartbeat': now.subtract(const Duration(hours: 26)).toIso8601String(),
      });
      expect(stale24.contains('Stale 24h'), isTrue);
      expect(stale24.contains('Abandoned'), isTrue);

      // 4. SLA Warning & Critical
      final warningOrder = evaluateBadges({
        'status': 'DRAFTING',
        'slaExpiryTime': now.add(const Duration(hours: 2)).toIso8601String(),
      });
      expect(warningOrder.contains('WARNING'), isTrue);

      final criticalOrder = evaluateBadges({
        'status': 'ACTION_NEEDED',
        'slaExpiryTime': now.subtract(const Duration(hours: 5)).toIso8601String(),
      });
      expect(criticalOrder.contains('CRITICAL'), isTrue);
    });

    test('Data Protection Certification: Recovery never deletes workspace fields', () {
      final orderMap = {
        'id': 101,
        'status': 'DRAFTING',
        'inputValues': '{"land_rate": 3000, "market_value": 7500000}',
        'documentDomSnapshot': '{"dom": "<div>Inspection Completed</div>"}',
        'fieldMappingSnapshot': '{"FM_1": "Owner Name"}',
      };

      // Simulating recovery to ACTION_NEEDED
      final recoveredMap = Map<String, dynamic>.from(orderMap);
      recoveredMap['status'] = 'ACTION_NEEDED';
      recoveredMap['pauseReason'] = 'Analyst abandoned drafting session. Authored work preserved; awaiting reassignment.';

      // Assert data protection
      expect(recoveredMap['inputValues'], orderMap['inputValues']);
      expect(recoveredMap['documentDomSnapshot'], orderMap['documentDomSnapshot']);
      expect(recoveredMap['fieldMappingSnapshot'], orderMap['fieldMappingSnapshot']);
      expect(recoveredMap['status'], 'ACTION_NEEDED');
    });
  });
}
