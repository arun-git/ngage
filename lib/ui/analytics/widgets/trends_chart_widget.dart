import 'package:flutter/material.dart';
import '../../../models/analytics.dart';

class TrendsChartWidget extends StatelessWidget {
  final Map<String, dynamic> trendsData;
  final AnalyticsPeriod period;

  const TrendsChartWidget({
    super.key,
    required this.trendsData,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final trends = trendsData['trends'] as Map<String, dynamic>? ?? {};
    final dataPoints = trendsData['dataPoints'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trends Analysis',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                _buildPeriodChip(context),
              ],
            ),
            const SizedBox(height: 16),
            
            if (dataPoints < 2) ...[
              // Insufficient data message
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timeline,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Insufficient Data for Trends',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'At least 2 data points are needed for trend analysis.\nTry selecting a longer time period.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Trends visualization
              Row(
                children: [
                  // Participation Trend
                  if (trends.containsKey('participation'))
                    Expanded(
                      child: _buildTrendCard(
                        context,
                        'Participation',
                        trends['participation'] as Map<String, dynamic>,
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                  
                  const SizedBox(width: 16),
                  
                  // Engagement Trend
                  if (trends.containsKey('engagement'))
                    Expanded(
                      child: _buildTrendCard(
                        context,
                        'Engagement',
                        trends['engagement'] as Map<String, dynamic>,
                        Icons.favorite,
                        Colors.pink,
                      ),
                    ),
                  
                  const SizedBox(width: 16),
                  
                  // Judge Activity Trend
                  if (trends.containsKey('judgeActivity'))
                    Expanded(
                      child: _buildTrendCard(
                        context,
                        'Judge Activity',
                        trends['judgeActivity'] as Map<String, dynamic>,
                        Icons.gavel,
                        Colors.orange,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Trend Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trend Summary',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Analysis based on $dataPoints data points over the selected period.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._generateTrendInsights(context, trends),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(
    BuildContext context,
    String title,
    Map<String, dynamic> trendData,
    IconData icon,
    Color color,
  ) {
    final trend = trendData['trend'] as String? ?? 'stable';
    final percentChange = trendData['percentChange'] as double? ?? 0.0;
    final change = trendData['change'] as double? ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Trend indicator
          Row(
            children: [
              _getTrendIcon(trend, color),
              const SizedBox(width: 8),
              Text(
                _getTrendLabel(trend),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Percentage change
          if (percentChange != 0) ...[
            Text(
              '${percentChange > 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Change: ${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodChip(BuildContext context) {
    String periodText;
    switch (period) {
      case AnalyticsPeriod.daily:
        periodText = 'Daily';
        break;
      case AnalyticsPeriod.weekly:
        periodText = 'Weekly';
        break;
      case AnalyticsPeriod.monthly:
        periodText = 'Monthly';
        break;
      case AnalyticsPeriod.quarterly:
        periodText = 'Quarterly';
        break;
      case AnalyticsPeriod.yearly:
        periodText = 'Yearly';
        break;
      case AnalyticsPeriod.custom:
        periodText = 'Custom';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        periodText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _getTrendIcon(String trend, Color color) {
    IconData iconData;
    switch (trend) {
      case 'increasing':
        iconData = Icons.trending_up;
        break;
      case 'decreasing':
        iconData = Icons.trending_down;
        break;
      case 'stable':
      default:
        iconData = Icons.trending_flat;
        break;
    }
    
    return Icon(iconData, color: color, size: 16);
  }

  String _getTrendLabel(String trend) {
    switch (trend) {
      case 'increasing':
        return 'Increasing';
      case 'decreasing':
        return 'Decreasing';
      case 'stable':
      default:
        return 'Stable';
    }
  }

  List<Widget> _generateTrendInsights(BuildContext context, Map<String, dynamic> trends) {
    final insights = <Widget>[];
    
    trends.forEach((key, value) {
      final trendData = value as Map<String, dynamic>;
      final trend = trendData['trend'] as String;
      final percentChange = trendData['percentChange'] as double? ?? 0.0;
      
      String insight;
      Color color;
      IconData icon;
      
      switch (trend) {
        case 'increasing':
          insight = '$key is trending upward with a ${percentChange.toStringAsFixed(1)}% increase.';
          color = Colors.green;
          icon = Icons.trending_up;
          break;
        case 'decreasing':
          insight = '$key is trending downward with a ${percentChange.abs().toStringAsFixed(1)}% decrease.';
          color = Colors.red;
          icon = Icons.trending_down;
          break;
        case 'stable':
        default:
          insight = '$key remains stable with minimal change.';
          color = Colors.blue;
          icon = Icons.trending_flat;
          break;
      }
      
      insights.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      );
    });
    
    return insights;
  }
}