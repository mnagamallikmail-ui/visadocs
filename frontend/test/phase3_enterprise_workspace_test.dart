import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/services/indexed_db_draft_service.dart';
import 'package:provaluer_frontend/features/document_workspace/services/workspace_autosave_queue.dart';
import 'package:provaluer_frontend/features/document_workspace/services/workspace_lease_client.dart';
import 'package:provaluer_frontend/services/workspace_sse_service.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/workspace_health_bar_widget.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/draft_recovery_dialog.dart';
import 'package:provaluer_frontend/widgets/session_challenge_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step 1: IndexedDB V2 Draft System', () {
    test('WorkspaceDraftModel serializes and deserializes accurately with all metadata', () {
      final now = DateTime.now();
      final draft = WorkspaceDraftModel(
        orderId: 105,
        draftVersion: 2,
        revision: 4,
        sourceSession: 'sess_123_tab_456',
        savedAt: now,
        deltaValues: {'PROPERTY_ADDRESS': '123 Marine Drive', 'BORROWER_NAME': 'John Doe'},
        fullSnapshot: {'PROPERTY_ADDRESS': '123 Marine Drive', 'CITY': 'Mumbai'},
      );

      final json = draft.toJson();
      expect(json['orderId'], 105);
      expect(json['draftVersion'], 2);
      expect(json['revision'], 4);
      expect(json['sourceSession'], 'sess_123_tab_456');

      final reconstructed = WorkspaceDraftModel.fromJson(json);
      expect(reconstructed.orderId, 105);
      expect(reconstructed.draftVersion, 2);
      expect(reconstructed.revision, 4);
      expect(reconstructed.sourceSession, 'sess_123_tab_456');
      expect(reconstructed.deltaValues['PROPERTY_ADDRESS'], '123 Marine Drive');
      expect(reconstructed.fullSnapshot['CITY'], 'Mumbai');
    });

    test('IndexedDbDraftService persists, retrieves, and discards drafts cleanly', () async {
      final service = IndexedDbDraftService.instance;
      final draft = WorkspaceDraftModel(
        orderId: 999,
        revision: 2,
        sourceSession: 'sess_test',
        savedAt: DateTime.now(),
        deltaValues: {'LAND_AREA': '1200'},
        fullSnapshot: {'LAND_AREA': '1200'},
      );

      await service.saveDraft(draft);
      final existsBefore = await service.hasDraft(999);
      expect(existsBefore, isTrue);

      final loaded = await service.getDraft(999);
      expect(loaded, isNotNull);
      expect(loaded!.deltaValues['LAND_AREA'], '1200');

      await service.deleteDraft(999);
      final existsAfter = await service.hasDraft(999);
      expect(existsAfter, isFalse);
    });
  });

  group('Step 2 & 6: Workspace Lease Client & Concurrency Status', () {
    test('WorkspaceLeaseResult properly distinguishes active editor and conflict states', () {
      final activeResult = WorkspaceLeaseResult.fromJson({
        'lockStatus': 'ACTIVE',
        'readOnly': false,
        'currentEditor': 'poojitha',
        'currentEditorRole': 'PA',
        'workspaceRevision': 5,
      });
      expect(activeResult.isActiveEditor, isTrue);
      expect(activeResult.isSameUserConflict, isFalse);
      expect(activeResult.isDifferentUserConflict, isFalse);

      final sameUserConflict = WorkspaceLeaseResult.fromJson({
        'lockStatus': 'CONFLICT_SAME_USER',
        'readOnly': true,
        'currentEditor': 'poojitha',
      });
      expect(sameUserConflict.isActiveEditor, isFalse);
      expect(sameUserConflict.isSameUserConflict, isTrue);

      final diffUserConflict = WorkspaceLeaseResult.fromJson({
        'lockStatus': 'CONFLICT_DIFFERENT_USER',
        'readOnly': true,
        'currentEditor': 'raghav',
        'currentEditorRole': 'SPA',
      });
      expect(diffUserConflict.isActiveEditor, isFalse);
      expect(diffUserConflict.isDifferentUserConflict, isTrue);
    });
  });

  group('Step 3: Workspace Health Bar Widget', () {
    testWidgets('Renders Online, Saved, and Active Editor when active and clean', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkspaceHealthBarWidget(
              isOnline: true,
              syncStatus: QueueSyncStatus.saved,
              pendingSyncCount: 0,
              isReadOnly: false,
              activeEditorName: 'poojitha',
              activeEditorRole: 'PA',
            ),
          ),
        ),
      );

      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Editor: poojitha (PA)'), findsOneWidget);
      expect(find.text('Read-Only Mode'), findsNothing);
    });

    testWidgets('Renders Read-Only badge and Switch Tab button on Same-User Conflict', (tester) async {
      bool switchTabTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkspaceHealthBarWidget(
              isOnline: true,
              syncStatus: QueueSyncStatus.idle,
              pendingSyncCount: 0,
              isReadOnly: true,
              activeEditorName: 'poojitha',
              isSameUserConflict: true,
              onSwitchTab: () {
                switchTabTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Read-Only Mode (poojitha)'), findsOneWidget);
      final button = find.text('Switch Editing To This Tab');
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pump();
      expect(switchTabTapped, isTrue);
    });

    testWidgets('Renders Offline draft and pending count badge when disconnected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkspaceHealthBarWidget(
              isOnline: false,
              syncStatus: QueueSyncStatus.offline,
              pendingSyncCount: 3,
              isReadOnly: false,
            ),
          ),
        ),
      );

      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Offline Draft'), findsOneWidget);
      expect(find.text('3 Pending'), findsOneWidget);
    });
  });

  group('Step 4: Draft Recovery Dialog (Never Auto-Restore)', () {
    testWidgets('Displays uncommitted draft info and fires Restore callback on selection', (tester) async {
      bool restored = false;
      bool discarded = false;

      final testDraft = WorkspaceDraftModel(
        orderId: 777,
        revision: 2,
        sourceSession: 'sess_prior',
        savedAt: DateTime(2026, 11, 14, 15, 30),
        deltaValues: {'VALUATION_METHOD': 'COMPOSITE', 'FLAT_AREA': '1250'},
        fullSnapshot: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraftRecoveryDialog(
              draft: testDraft,
              serverRevision: 2,
              onRestore: () {
                restored = true;
              },
              onDiscard: () {
                discarded = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Unsaved Draft Detected'), findsOneWidget);
      expect(find.text('2 field(s)'), findsOneWidget);
      expect(find.text('v2 (Server: v2)'), findsOneWidget);

      await tester.tap(find.text('Restore Draft'));
      await tester.pump();

      expect(restored, isTrue);
      expect(discarded, isFalse);
    });

    testWidgets('Fires Discard callback when Discard Draft is tapped', (tester) async {
      bool restored = false;
      bool discarded = false;

      final testDraft = WorkspaceDraftModel(
        orderId: 777,
        revision: 1,
        sourceSession: 'sess_prior',
        savedAt: DateTime(2026, 11, 14, 15, 30),
        deltaValues: {'SOME_KEY': '123'},
        fullSnapshot: {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DraftRecoveryDialog(
              draft: testDraft,
              serverRevision: 3,
              onRestore: () {
                restored = true;
              },
              onDiscard: () {
                discarded = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Discard Draft'));
      await tester.pump();

      expect(discarded, isTrue);
      expect(restored, isFalse);
    });
  });

  group('Step 5: Session Challenge Dialog', () {
    testWidgets('Renders device, platform, location (no raw IP) with backend timeoutSeconds and handles Keep Session', (tester) async {
      bool kept = false;
      bool allowed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionChallengeDialog(
              deviceName: 'Chrome on Windows 11',
              platform: 'Windows Desktop',
              approximateLocation: 'Mumbai, Maharashtra, India',
              timeoutSeconds: 30,
              onKeepSession: () {
                kept = true;
              },
              onAllowSession: () {
                allowed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Another Login Detected'), findsOneWidget);
      expect(find.text('Chrome on Windows 11'), findsOneWidget);
      expect(find.text('Windows Desktop'), findsOneWidget);
      expect(find.text('Mumbai, Maharashtra, India'), findsOneWidget);
      expect(find.textContaining('192.168'), findsNothing);
      expect(find.text('Action Required In:'), findsOneWidget);
      expect(find.textContaining('second(s)'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Keep Session (30 s)'));
      await tester.pump();

      expect(kept, isTrue);
      expect(allowed, isFalse);
    });
  });

  group('Step 8: SSE Real-Time Event Dispatching', () {
    test('WorkspaceSseEvent extracts event properties correctly', () {
      final ev = WorkspaceSseEvent(
        eventType: 'LEASE_LOST',
        data: {
          'orderId': 105,
          'newEditor': 'admin_user',
          'reason': 'Break-glass takeover initiated',
        },
      );

      expect(ev.eventType, 'LEASE_LOST');
      expect(ev.orderId, 105);
      expect(ev.newEditor, 'admin_user');
      expect(ev.reason, 'Break-glass takeover initiated');

      final challengeEv = WorkspaceSseEvent(
        eventType: 'LOGIN_CHALLENGE',
        data: {
          'challengeSessionId': 'sess_incoming_999',
          'requestingDevice': 'Firefox on Linux',
          'requestingPlatform': 'Linux Desktop',
          'approximateLocation': 'Bengaluru, India',
          'timeoutSeconds': 30,
        },
      );

      expect(challengeEv.challengeSessionId, 'sess_incoming_999');
      expect(challengeEv.requestingDevice, 'Firefox on Linux');
      expect(challengeEv.requestingPlatform, 'Linux Desktop');
      expect(challengeEv.approximateLocation, 'Bengaluru, India');
      expect(challengeEv.timeoutSeconds, 30);
    });
  });
}
