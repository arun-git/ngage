import 'package:flutter/material.dart';
import '../../../models/analytics.dart';

class ParticipationMetricsCard extends StatelessWidget {
  final ParticipationMetrics metrics;

  const ParticipationMetricsCard({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Participation Metrics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: Column(
                children: [
                  // Participation Rate
                  _buildMetricRow(
                    context,
                    'Participation Rate',
                    '${metrics.participationRate.toStringAsFixed(1)}%',
                    _getParticipationColor(context, metrics.participationRate),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Members Stats
                  _buildStatRow(
                    context,
                    'Active Members',
                    '${metrics.activeMembers}/${metrics.totalMembers}',
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Teams Stats
                  _buildStatRow(
                    context,
                    'Active Teams',
                    '${metrics.activeTeams}/${metrics.totalTeams}',
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Events Stats
                  _buildStatRow(
                    context,
                    'Completed Events',
                    '${metrics.completedEvents}/${metrics.totalEvents}',
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Submissions
                  _buildStatRow(
                    context,
                    'Total Submissions',
                    '${metrics.totalSubmissions}',
                  ),
                  
                  const Spacer(),
                  
                  // Category Breakdown
                  if (metrics.membersByCategory.isNotEmpty) ...[
                    const Divider(),
                    Text(
                      'Members by Category',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    ...metrics.membersByCategory.entries.take(3).map(
                      (entry) => _buildCategoryRow(context, entry.key, entry.value),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(BuildContext context, String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(BuildContext context, String category, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              category,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getParticipationColor(BuildContext context, double rate) {
    if (rate >= 80) {
      return Colors.green;
    } else if (rate >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}