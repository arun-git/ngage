import 'package:flutter/material.dart';
import '../../../models/analytics.dart';

class AnalyticsSummaryCard extends StatelessWidget {
  final AnalyticsMetrics metrics;

  const AnalyticsSummaryCard({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Analytics Summary',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                _buildPeriodChip(context),
              ],
            ),
            const SizedBox(height: 20),
            
            // Key Metrics Row
            LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth > 600;
                
                if (isWideScreen) {
                  return Row(
                    children: [
                      Expanded(child: _buildSummaryMetric(
                        context,
                        'Participation Rate',
                        '${metrics.participation.participationRate.toStringAsFixed(1)}%',
                        Icons.people,
                        _getParticipationColor(metrics.participation.participationRate),
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSummaryMetric(
                        context,
                        'Active Judges',
                        '${metrics.judgeActivity.activeJudges}/${metrics.judgeActivity.totalJudges}',
                        Icons.gavel,
                        _getJudgeActivityColor(metrics.judgeActivity),
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSummaryMetric(
                        context,
                        'Social Posts',
                        '${metrics.engagement.totalPosts}',
                        Icons.forum,
                        Theme.of(context).colorScheme.tertiary,
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSummaryMetric(
                        context,
                        'Total Submissions',
                        '${metrics.participation.totalSubmissions}',
                        Icons.upload_file,
                        Theme.of(context).colorScheme.secondary,
                      )),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildSummaryMetric(
                            context,
                            'Participation Rate',
                            '${metrics.participation.participationRate.toStringAsFixed(1)}%',
                            Icons.people,
                            _getParticipationColor(metrics.participation.participationRate),
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSummaryMetric(
                            context,
                            'Active Judges',
                            '${metrics.judgeActivity.activeJudges}/${metrics.judgeActivity.totalJudges}',
                            Icons.gavel,
                            _getJudgeActivityColor(metrics.judgeActivity),
                          )),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildSummaryMetric(
                            context,
                            'Social Posts',
                            '${metrics.engagement.totalPosts}',
                            Icons.forum,
                            Theme.of(context).colorScheme.tertiary,
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSummaryMetric(
                            context,
                            'Total Submissions',
                            '${metrics.participation.totalSubmissions}',
                            Icons.upload_file,
                            Theme.of(context).colorScheme.secondary,
                          )),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
            
            const SizedBox(height: 20),
            
            // Additional Insights
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
                    'Key Insights',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(_generateInsights(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(BuildContext context) {
    final startDate = metrics.periodStart;
    final endDate = metrics.periodEnd;
    final duration = endDate.difference(startDate).inDays;
    
    String periodText;
    if (duration <= 7) {
      periodText = 'Last 7 days';
    } else if (duration <= 30) {
      periodText = 'Last 30 days';
    } else if (duration <= 90) {
      periodText = 'Last 90 days';
    } else {
      periodText = '${duration} days';
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

  List<Widget> _generateInsights(BuildContext context) {
    final insights = <Widget>[];
    
    // Participation insight
    if (metrics.participation.participationRate > 80) {
      insights.add(_buildInsightItem(
        context,
        Icons.trending_up,
        'Excellent participation rate! ${metrics.participation.participationRate.toStringAsFixed(1)}% of members are actively engaged.',
        Colors.green,
      ));
    } else if (metrics.participation.participationRate < 50) {
      insights.add(_buildInsightItem(
        context,
        Icons.trending_down,
        'Low participation rate. Consider strategies to increase member engagement.',
        Colors.orange,
      ));
    }
    
    // Judge activity insight
    if (metrics.judgeActivity.totalJudges > 0) {
      final judgeParticipation = (metrics.judgeActivity.activeJudges / metrics.judgeActivity.totalJudges) * 100;
      if (judgeParticipation < 60) {
        insights.add(_buildInsightItem(
          context,
          Icons.warning,
          'Only ${judgeParticipation.toStringAsFixed(0)}% of judges are active. Consider judge engagement strategies.',
          Colors.orange,
        ));
      }
    }
    
    // Engagement insight
    if (metrics.engagement.totalPosts > 0 && metrics.engagement.averageLikesPerPost > 5) {
      insights.add(_buildInsightItem(
        context,
        Icons.favorite,
        'High social engagement! Posts are receiving an average of ${metrics.engagement.averageLikesPerPost.toStringAsFixed(1)} likes.',
        Colors.green,
      ));
    }
    
    // Default insight if no specific insights
    if (insights.isEmpty) {
      insights.add(_buildInsightItem(
        context,
        Icons.info,
        'Analytics data is being collected. More insights will be available as activity increases.',
        Theme.of(context).colorScheme.primary,
      ));
    }
    
    return insights;
  }

  Widget _buildInsightItem(BuildContext context, IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Color _getParticipationColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getJudgeActivityColor(JudgeActivityMetrics judgeActivity) {
    if (judgeActivity.totalJudges == 0) return Colors.grey;
    
    final rate = (judgeActivity.activeJudges / judgeActivity.totalJudges) * 100;
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }
}