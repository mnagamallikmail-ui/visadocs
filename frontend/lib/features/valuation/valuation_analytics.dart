import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/design_system.dart';
import 'valuation_repository.dart';

class ValuationAnalyticsWidget extends StatelessWidget {
  const ValuationAnalyticsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<ValuationRepository>(context);
    final list = repo.requests;

    final pendingCount = list.where((r) => r.status == 'PENDING').length;
    final progressCount = list.where((r) => r.status == 'IN_PROGRESS').length;
    final completedCount = list.where((r) => r.status == 'COMPLETED').length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Portfolio Analytics Overview",
            style: DesignSystem.h2(color: DesignSystem.primary),
          ),
          const SizedBox(height: 8),
          Text(
            "Track operations health, submission status flow, and recent pipeline activities.",
            style: DesignSystem.body(color: DesignSystem.textSecondary),
          ),
          const SizedBox(height: 30),

          // Stat Cards Row
          Row(
            children: [
              _buildStatCard("Pending Review", pendingCount.toString(), Icons.pending_actions, Colors.orange),
              const SizedBox(width: 16),
              _buildStatCard("In Progress", progressCount.toString(), Icons.hourglass_top, Colors.blue),
              const SizedBox(width: 16),
              _buildStatCard("Completed Projects", completedCount.toString(), Icons.task_alt, Colors.green),
            ],
          ),

          const SizedBox(height: 40),

          // Activity Feed
          Text(
            "Recent Activity Pipeline",
            style: DesignSystem.body(fontWeight: FontWeight.bold, fontSize: 16, color: DesignSystem.primary),
          ),
          const SizedBox(height: 15),
          Container(
            decoration: DesignSystem.cardDecoration,
            padding: const EdgeInsets.all(20),
            child: list.isEmpty
                ? Center(
                    child: Text(
                      "No recent activities logged.",
                      style: DesignSystem.body(color: DesignSystem.textSecondary),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length > 5 ? 5 : list.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final req = list[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: DesignSystem.primary.withOpacity(0.05),
                          child: const Icon(Icons.assignment, color: DesignSystem.primary, size: 18),
                        ),
                        title: Text(
                          "New Request ${req.id} submitted for ${req.clientName}",
                          style: DesignSystem.body(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          "Asset Type: ${req.propertyType} | Purpose: ${req.purpose}",
                          style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 12),
                        ),
                        trailing: Text(
                          DateFormat('dd MMM, hh:mm a').format(req.submissionDate),
                          style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 11),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        decoration: DesignSystem.cardDecoration,
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.08),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: DesignSystem.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
