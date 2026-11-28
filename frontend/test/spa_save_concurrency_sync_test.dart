import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/services/document_workspace_api_service.dart';
import 'package:provaluer_frontend/features/document_workspace/services/workspace_autosave_queue.dart';
import 'package:provaluer_frontend/features/document_workspace/services/workspace_lease_client.dart';

class _StrictRevisionFakeApiService extends DocumentWorkspaceApiService {
  int serverRevision = 1;
  int apiSaveCalls = 0;
  int conflict409Count = 0;
  final Map<String, String> savedDbValues = {};
  bool forceNextConflict = false;

  @override
  Future<Map<String, dynamic>?> saveDocumentValues(
    int orderId,
    Map<String, String> values, {
    int? workspaceRevision,
  }) async {
    apiSaveCalls++;
    await Future.delayed(const Duration(milliseconds: 25));

    if (forceNextConflict || (workspaceRevision != null && workspaceRevision != serverRevision)) {
      forceNextConflict = false;
      conflict409Count++;
      throw DioException(
        requestOptions: RequestOptions(path: '/api/v1/orders/$orderId/save-document-values'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/orders/$orderId/save-document-values'),
          statusCode: 409,
          data: {'error': 'Concurrent update detected. Workspace was modified by another session. Please refresh.'},
        ),
        type: DioExceptionType.badResponse,
      );
    }

    savedDbValues.addAll(values);
    serverRevision++;
    return {'status': 'SAVED', 'workspaceRevision': serverRevision.toString()};
  }
}

class _FakeLeaseClient extends WorkspaceLeaseClient {
  @override
  Future<void> recordSyncEvent({
    required int orderId,
    required String sessionId,
    required String tabSessionId,
    required String eventType,
    String? payload,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SPA Workspace Revision Synchronization & Save Concurrency', () {
    test('Autosave + concurrent manual/timer flush never produces 409 conflicts', () async {
      final api = _StrictRevisionFakeApiService();
      final lease = _FakeLeaseClient();
      final providerDeltas = <String, String>{};
      int providerRevision = 1;
      bool manualSaveInFlight = false;

      final queue = WorkspaceAutosaveQueue(
        orderId: 42,
        sessionId: 'sess-spa',
        tabSessionId: 'tab-1',
        apiService: api,
        leaseClient: lease,
        initialRevision: providerRevision,
      );

      queue.canSaveCheck = () => !manualSaveInFlight;
      queue.onCommitSuccess = (committed, serverRev) {
        if (serverRev != null && serverRev > providerRevision) {
          providerRevision = serverRev;
        }
        committed.forEach((k, v) {
          if (providerDeltas[k] == v) providerDeltas.remove(k);
        });
      };

      // Simulate rapid SPA edits
      providerDeltas['OWNER_NAME'] = 'XYZ Industries';
      queue.enqueueEdit('OWNER_NAME', 'XYZ Industries', currentFullSnapshot: providerDeltas);
      providerDeltas['MARKET_VALUE'] = '10,00,00,000';
      queue.enqueueEdit('MARKET_VALUE', '10,00,00,000', currentFullSnapshot: providerDeltas);

      // Trigger simultaneous autosave flush + manual/timer flush
      final f1 = queue.flushImmediately();
      final f2 = queue.flushImmediately();
      final results = await Future.wait([f1, f2]);

      expect(results, everyElement(isTrue));
      expect(api.conflict409Count, equals(0));
      expect(api.apiSaveCalls, equals(1));
      expect(providerRevision, equals(2));
      expect(api.serverRevision, equals(2));
      expect(providerDeltas.isEmpty, isTrue);
      expect(api.savedDbValues['OWNER_NAME'], equals('XYZ Industries'));
      expect(api.savedDbValues['MARKET_VALUE'], equals('10,00,00,000'));

      queue.dispose();
    });

    test('Shared mutex blocks queue flush while manual save is in progress, then syncs revision', () async {
      final api = _StrictRevisionFakeApiService();
      final lease = _FakeLeaseClient();
      bool manualSaveInFlight = true;
      int providerRevision = 1;

      final queue = WorkspaceAutosaveQueue(
        orderId: 43,
        sessionId: 'sess-spa',
        tabSessionId: 'tab-1',
        apiService: api,
        leaseClient: lease,
        initialRevision: providerRevision,
      );
      queue.canSaveCheck = () => !manualSaveInFlight;

      queue.enqueueEdit('PROPERTY_ADDRESS', 'Address B', currentFullSnapshot: {'PROPERTY_ADDRESS': 'Address B'});

      // Blocked while manual save holds mutex
      final blockedResult = await queue.flushImmediately();
      expect(blockedResult, isFalse);
      expect(api.apiSaveCalls, equals(0));

      // Manual save commits rev 1 -> 2 and updates queue revision
      await api.saveDocumentValues(43, {'OWNER_NAME': 'XYZ'}, workspaceRevision: 1);
      providerRevision = api.serverRevision;
      queue.updateRevision(providerRevision);
      manualSaveInFlight = false;

      // Now queue flushes cleanly at rev 2 -> 3 with 0 conflicts
      final ok = await queue.flushImmediately();
      expect(ok, isTrue);
      expect(api.conflict409Count, equals(0));
      expect(api.serverRevision, equals(3));

      queue.dispose();
    });

    test('409 Conflict triggers onRevisionConflict (not Admin Takeover readOnly)', () async {
      final api = _StrictRevisionFakeApiService()..forceNextConflict = true;
      final lease = _FakeLeaseClient();
      bool readOnlyTriggered = false;
      bool revisionConflictTriggered = false;

      final queue = WorkspaceAutosaveQueue(
        orderId: 44,
        sessionId: 'sess-spa',
        tabSessionId: 'tab-1',
        apiService: api,
        leaseClient: lease,
        initialRevision: 1,
      );
      queue.onConflictOrReadOnly = () => readOnlyTriggered = true;
      queue.onRevisionConflict = () => revisionConflictTriggered = true;

      queue.enqueueEdit('OWNER_NAME', 'XYZ', currentFullSnapshot: {'OWNER_NAME': 'XYZ'});
      final ok = await queue.flushImmediately();

      expect(ok, isFalse);
      expect(revisionConflictTriggered, isTrue);
      expect(readOnlyTriggered, isFalse);

      queue.dispose();
    });
  });
}

