import 'package:flutter/material.dart';

class ModerationStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const ModerationStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final reportStats = stats['reports'] as Map<String, int>? ?? {};
    final actionStats = stats['actions'] as Map<String, int>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Moderation Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildReportsSection(context, reportStats),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionsSection(context, actionStats),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSection(BuildContext context, Map<String, int> reportStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildStatRow(
          context,
          'Pending',
          reportStats['pending'] ?? 0,
          Colors.orange,
          Icons.pending,
        ),
        _buildStatRow(
          context,
          'Under Review',
          reportStats['underReview'] ?? 0,
          Colors.blue,
          Icons.rate_review,
        ),
        _buildStatRow(
          context,
          'Resolved',
          reportStats['resolved'] ?? 0,
          Colors.green,
          Icons.check_circle,
        ),
        _buildStatRow(
          context,
          'Dismissed',
          reportStats['dismissed'] ?? 0,
          Colors.grey,
          Icons.cancel,
        ),
        const Divider(),
        _buildStatRow(
          context,
          'Total',
          reportStats['total'] ?? 0,
          Theme.of(context).colorScheme.primary,
          Icons.report,
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context, Map<String, int> actionStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildStatRow(
          context,
          'Hidden',
          actionStats['hidden'] ?? 0,
          Colors.orange,
          Icons.visibility_off,
        ),
        _buildStatRow(
          context,
          'Deleted',
          actionStats['deleted'] ?? 0,
          Colors.red,
          Icons.delete,
        ),
        _buildStatRow(
          context,
          'Suspended',
          actionStats['suspended'] ?? 0,
          Colors.amber,
          Icons.pause_circle,
        ),
        _buildStatRow(
          context,
          'Banned',
          actionStats['banned'] ?? 0,
          Colors.red[800]!,
          Icons.block,
        ),
        const Divider(),
        _buildStatRow(
          context,
          'Total Active',
          actionStats['totalActive'] ?? 0,
          Theme.of(context).colorScheme.primary,
          Icons.gavel,
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    int count,
    Color color,
    IconData icon, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : null,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}