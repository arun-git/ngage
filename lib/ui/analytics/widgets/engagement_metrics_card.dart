import 'package:flutter/material.dart';
import '../../../models/analytics.dart';

class EngagementMetricsCard extends StatelessWidget {
  final EngagementMetrics metrics;

  const EngagementMetricsCard({
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
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Social Engagement',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: Column(
                children: [
                  // Total Posts
                  _buildMetricRow(
                    context,
                    'Total Posts',
                    '${metrics.totalPosts}',
                    Theme.of(context).colorScheme.primary,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Average Likes per Post
                  _buildStatRow(
                    context,
                    'Avg Likes/Post',
                    metrics.averageLikesPerPost.toStringAsFixed(1),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Average Comments per Post
                  _buildStatRow(
                    context,
                    'Avg Comments/Post',
                    metrics.averageCommentsPerPost.toStringAsFixed(1),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Total Likes
                  _buildStatRow(
                    context,
                    'Total Likes',
                    '${metrics.totalLikes}',
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Total Comments
                  _buildStatRow(
                    context,
                    'Total Comments',
                    '${metrics.totalComments}',
                  ),
                  
                  const Spacer(),
                  
                  // Top Contributors
                  if (metrics.topContributors.isNotEmpty) ...[
                    const Divider(),
                    Text(
                      'Top Contributors',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    ...metrics.topContributors.take(3).map(
                      (contributorId) => _buildContributorRow(
                        context,
                        contributorId,
                        metrics.postsByMember[contributorId] ?? 0,
                        metrics.likesByMember[contributorId] ?? 0,
                        metrics.commentsByMember[contributorId] ?? 0,
                      ),
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

  Widget _buildContributorRow(
    BuildContext context,
    String contributorId,
    int posts,
    int likes,
    int comments,
  ) {
    // In a real app, you'd resolve the contributor ID to a name
    final contributorName = 'User ${contributorId.substring(0, 8)}...';
    final totalActivity = posts * 3 + likes + comments * 2; // Weighted score
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              contributorName,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$totalActivity pts',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}