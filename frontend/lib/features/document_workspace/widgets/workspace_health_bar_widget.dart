import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../services/workspace_autosave_queue.dart';

class WorkspaceHealthBarWidget extends StatelessWidget {
  final bool isOnline;
  final QueueSyncStatus syncStatus;
  final int pendingSyncCount;
  final bool isReadOnly;
  final String? activeEditorName;
  final String? activeEditorRole;
  final DateTime? lastSavedTime;
  final bool isSameUserConflict;
  final VoidCallback? onSwitchTab;
  final VoidCallback? onTakeover;

  const WorkspaceHealthBarWidget({
    super.key,
    required this.isOnline,
    required this.syncStatus,
    required this.pendingSyncCount,
    required this.isReadOnly,
    this.activeEditorName,
    this.activeEditorRole,
    this.lastSavedTime,
    this.isSameUserConflict = false,
    this.onSwitchTab,
    this.onTakeover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isReadOnly ? Colors.amber.shade50 : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isReadOnly ? Colors.amber.shade300 : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 1. Connection Pill (Online / Offline)
            _buildConnectionPill(),
            const SizedBox(width: 8),

            // 2. Sync Status Pill (Saving... / Saved / Error)
            _buildSyncPill(),
            const SizedBox(width: 8),

            // 3. Pending Sync Count Pill
            if (pendingSyncCount > 0) ...[
              _buildPendingSyncBadge(),
              const SizedBox(width: 8),
            ],

            const SizedBox(width: 16),

            // 4. Read-Only / Active Editor Indicator
            if (isReadOnly) ...[
              _buildReadOnlyBadge(),
              const SizedBox(width: 8),
            ] else if (activeEditorName != null) ...[
              _buildActiveEditorBadge(),
              const SizedBox(width: 8),
            ],

            // 5. Action Buttons (Switch Tab / Takeover)
            if (isSameUserConflict && onSwitchTab != null) ...[
              FilledButton.icon(
                onPressed: onSwitchTab,
                icon: const Icon(Icons.tab, size: 14),
                label: const Text('Switch Editing To This Tab', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
            ] else if (isReadOnly && onTakeover != null) ...[
              OutlinedButton.icon(
                onPressed: onTakeover,
                icon: const Icon(Icons.lock_open, size: 14),
                label: const Text('Admin Takeover', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
            ],

            // 6. Last Saved Time
            if (lastSavedTime != null)
              Text(
                'Last saved: ${DateFormat('hh:mm:ss a').format(lastSavedTime!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOnline ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncPill() {
    switch (syncStatus) {
      case QueueSyncStatus.syncing:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(width: 6),
            Text('Saving...', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        );
      case QueueSyncStatus.saved:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
            SizedBox(width: 4),
            Text('Saved', style: TextStyle(fontSize: 12, color: Colors.green)),
          ],
        );
      case QueueSyncStatus.queued:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.amber),
            SizedBox(width: 4),
            Text('Pending Sync', style: TextStyle(fontSize: 12, color: Colors.amber)),
          ],
        );
      case QueueSyncStatus.offline:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 14, color: Colors.orange.shade800),
            const SizedBox(width: 4),
            Text('Offline Draft', style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
          ],
        );
      case QueueSyncStatus.error:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 14, color: Colors.red),
            SizedBox(width: 4),
            Text('Sync Failed', style: TextStyle(fontSize: 12, color: Colors.red)),
          ],
        );
      case QueueSyncStatus.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPendingSyncBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$pendingSyncCount Pending',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
      ),
    );
  }

  Widget _buildReadOnlyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_outlined, size: 14, color: Colors.amber.shade900),
          const SizedBox(width: 6),
          Text(
            'Read-Only Mode ${activeEditorName != null ? '($activeEditorName)' : ''}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveEditorBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            'Editor: $activeEditorName ${activeEditorRole != null ? '($activeEditorRole)' : ''}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
