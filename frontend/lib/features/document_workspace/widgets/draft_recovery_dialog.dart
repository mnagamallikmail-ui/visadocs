import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/indexed_db_draft_service.dart';
import '../../../theme/app_colors.dart';

class DraftRecoveryDialog extends StatelessWidget {
  final WorkspaceDraftModel draft;
  final int serverRevision;
  final VoidCallback onRestore;
  final VoidCallback onDiscard;

  const DraftRecoveryDialog({
    super.key,
    required this.draft,
    required this.serverRevision,
    required this.onRestore,
    required this.onDiscard,
  });

  static Future<bool?> show(
    BuildContext context, {
    required WorkspaceDraftModel draft,
    required int serverRevision,
    required VoidCallback onRestore,
    required VoidCallback onDiscard,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DraftRecoveryDialog(
        draft: draft,
        serverRevision: serverRevision,
        onRestore: onRestore,
        onDiscard: onDiscard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat('dd MMM yyyy, hh:mm a').format(draft.savedAt);
    final isStale = draft.revision < serverRevision;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isStale ? Colors.amber.shade100 : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isStale ? Icons.warning_amber_rounded : Icons.restore_page_outlined,
              color: isStale ? Colors.amber.shade900 : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Unsaved Draft Detected',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isStale
                ? 'An offline draft exists from a previous session, but newer changes were saved to the server by another editor.'
                : 'An uncommitted local draft was found for this report. Would you like to restore your uncommitted changes or discard them?',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Saved at:', formattedTime),
                const SizedBox(height: 6),
                _buildInfoRow('Modified fields:', '${draft.deltaValues.length} field(s)'),
                const SizedBox(height: 6),
                _buildInfoRow('Draft revision:', 'v${draft.revision} (Server: v$serverRevision)'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Note: Unsaved drafts are never restored automatically to protect data integrity.',
            style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pop(false);
            onDiscard();
          },
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
          label: const Text('Discard Draft', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red.shade300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(true);
            onRestore();
          },
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Restore Draft'),
          style: FilledButton.styleFrom(
            backgroundColor: isStale ? Colors.amber.shade900 : AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.black54))),
      ],
    );
  }
}

