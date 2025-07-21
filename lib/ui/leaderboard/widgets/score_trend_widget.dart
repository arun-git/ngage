import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../providers/leaderboard_providers.dart';

/// Widget for displaying score trends and performance analytics
class ScoreTrendWidget extends ConsumerWidget {
  final String teamId;
  final Duration? period;
  final int? dataPoints;
  final bool showChart;

  const ScoreTrendWidget({
    super.key,
    required this.teamId,
    this.period,
    this.dataPoints,
    this.showChart = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendRequest = ScoreTrendRequest(
      teamId: teamId,
      period: period,
      dataPoints: dataPoints,
    );

    final trendAsync = ref.watch(teamScoreTrendProvider(trendRequest));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            trendAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => _buildErrorWidget(context, error),
              data: (trend) => _buildTrendContent(context, trend),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'Error loading trend data',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendContent(BuildContext context, ScoreTrend trend) {
    if (!trend.hasDataPoints) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trend summary
        _buildTrendSummary(context, trend),
        
        const SizedBox(height: 16),
        
        // Chart or data points
        if (showChart)
          _buildTrendChart(context, trend)
        else
          _buildDataPointsList(context, trend),
        
        const SizedBox(height: 16),
        
        // Trend statistics
        _buildTrendStatistics(context, trend),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.trending_flat,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'No Trend Data Available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            'Submit more entries to see performance trends.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendSummary(BuildContext context, ScoreTrend trend) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getTrendColor(trend.trendDirection).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getTrendColor(trend.trendDirection).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getTrendIcon(trend.trendDirection),
            color: _getTrendColor(trend.trendDirection),
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trend.trendDescription,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _getTrendColor(trend.trendDirection),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Average Score: ${trend.averageScore.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${trend.dataPointCount} data points',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getTrendColor(trend.trendDirection),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${trend.trendPercentage >= 0 ? '+' : ''}${trend.trendPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, ScoreTrend trend) {
    // Simple line chart representation using containers
    // In a real implementation, you might use a charting library like fl_chart
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Chart title
          Text(
            'Score Over Time',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          
          // Simple chart representation
          Expanded(
            child: _buildSimpleChart(context, trend),
          ),
          
          // X-axis labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Earliest',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Latest',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleChart(BuildContext context, ScoreTrend trend) {
    final dataPoints = trend.dataPoints;
    if (dataPoints.isEmpty) return const SizedBox();

    final maxScore = dataPoints.map((p) => p.score).reduce((a, b) => a > b ? a : b);
    final minScore = dataPoints.map((p) => p.score).reduce((a, b) => a < b ? a : b);
    final scoreRange = maxScore - minScore;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: dataPoints.asMap().entries.map((entry) {
        final index = entry.key;
        final point = entry.value;
        
        // Normalize height (0.1 to 1.0)
        final normalizedHeight = scoreRange > 0 
            ? 0.1 + 0.9 * ((point.score - minScore) / scoreRange)
            : 0.5;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Tooltip(
              message: '${point.eventName}\nScore: ${point.score.toStringAsFixed(1)}\n${_formatDateTime(point.timestamp)}',
              child: Container(
                height: 120 * normalizedHeight,
                decoration: BoxDecoration(
                  color: _getTrendColor(trend.trendDirection).withOpacity(0.7),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDataPointsList(BuildContext context, ScoreTrend trend) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Scores',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        
        ...trend.dataPoints.take(5).map((point) => ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: _getScoreColor(point.score).withOpacity(0.1),
            child: Text(
              point.score.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(point.score),
              ),
            ),
          ),
          title: Text(
            point.eventName,
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            _formatDateTime(point.timestamp),
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Text(
            point.score.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getScoreColor(point.score),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildTrendStatistics(BuildContext context, ScoreTrend trend) {
    final metadata = trend.metadata;
    final highestScore = metadata['highestScore'] as double? ?? 0.0;
    final lowestScore = metadata['lowestScore'] as double? ?? 0.0;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Highest',
            highestScore.toStringAsFixed(1),
            Icons.trending_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            'Lowest',
            lowestScore.toStringAsFixed(1),
            Icons.trending_down,
            Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            'Average',
            trend.averageScore.toStringAsFixed(1),
            Icons.trending_flat,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            'Range',
            (highestScore - lowestScore).toStringAsFixed(1),
            Icons.height,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTrendColor(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.upward:
        return Colors.green;
      case TrendDirection.downward:
        return Colors.red;
      case TrendDirection.stable:
        return Colors.blue;
    }
  }

  IconData _getTrendIcon(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.upward:
        return Icons.trending_up;
      case TrendDirection.downward:
        return Icons.trending_down;
      case TrendDirection.stable:
        return Icons.trending_flat;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.lightGreen;
    if (score >= 70) return Colors.orange;
    if (score >= 60) return Colors.deepOrange;
    return Colors.red;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}