import 'package:flutter/material.dart';
import '../../../models/analytics.dart';

class JudgeActivityCard extends StatelessWidget {
  final JudgeActivityMetrics metrics;

  const JudgeActivityCard({
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
                  Icons.gavel,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Judge Activity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: Column(
                children: [
                  // Active Judges
                  _buildMetricRow(
                    context,
                    'Active Judges',
                    '${metrics.activeJudges}/${metrics.totalJudges}',
                    _getActivityColor(context, metrics.activeJudges, metrics.totalJudges),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Average Scores per Judge
                  _buildStatRow(
                    context,
                    'Avg Scores/Judge',
                    metrics.averageScoresPerJudge.toStringAsFixed(1),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Average Comments per Judge
                  _buildStatRow(
                    context,
                    'Avg Comments/Judge',
                    metrics.averageCommentsPerJudge.toStringAsFixed(1),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Total Scores
                  _buildStatRow(
                    context,
                    'Total Scores',
                    '${metrics.totalScores}',
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Total Comments
                  _buildStatRow(
                    context,
                    'Total Comments',
                    '${metrics.totalComments}',
                  ),
                  
                  const Spacer(),
                  
                  // Top Judges by Activity
                  if (metrics.scoresByJudge.isNotEmpty) ...[
                    const Divider(),
                    Text(
                      'Most Active Judges',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    ...metrics.scoresByJudge.entries
                        .toList()
                        ..sort((a, b) => b.value.compareTo(a.value))
                        ..take(3)
                        ..map((entry) => _buildJudgeRow(
                              context,
                              entry.key,
                              entry.value,
                              metrics.commentsByJudge[entry.key] ?? 0,
                            )),
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

  Widget _buildJudgeRow(BuildContext context, String judgeId, int scores, int comments) {
    // In a real app, you'd resolve the judge ID to a name
    final judgeName = 'Judge ${judgeId.substring(0, 8)}...';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              judgeName,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$scores scores',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$comments comments',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(BuildContext context, int active, int total) {
    if (total == 0) return Colors.grey;
    
    final rate = (active / total) * 100;
    if (rate >= 80) {
      return Colors.green;
    } else if (rate >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}