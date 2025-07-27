import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../providers/judging_providers.dart';
import '../../../services/judging_service.dart';

/// Widget for displaying score aggregation and statistics
class ScoreAggregationWidget extends ConsumerWidget {
  final String submissionId;
  final bool showIndividualScores;

  const ScoreAggregationWidget({
    super.key,
    required this.submissionId,
    this.showIndividualScores = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggregationAsync =
        ref.watch(submissionAggregationProvider(submissionId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Score Analysis',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            aggregationAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorWidget(error),
              data: (aggregation) =>
                  _buildAggregationContent(context, aggregation),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Column(
      children: [
        const Icon(Icons.error, size: 48, color: Colors.red),
        const SizedBox(height: 8),
        SelectableText('Error loading score analysis: $error'),
      ],
    );
  }

  Widget _buildAggregationContent(
      BuildContext context, AggregatedScore aggregation) {
    if (aggregation.judgeCount == 0) {
      return const Column(
        children: [
          Icon(Icons.score, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('No scores available yet'),
          Text(
            'Scores will appear here once judges start evaluating this submission.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary statistics
        _buildSummaryStats(context, aggregation),

        const SizedBox(height: 24),

        // Criteria breakdown
        if (aggregation.criteriaAverages.isNotEmpty) ...[
          _buildCriteriaBreakdown(context, aggregation),
          const SizedBox(height: 24),
        ],

        // Score distribution
        _buildScoreDistribution(context, aggregation),

        if (showIndividualScores &&
            aggregation.individualScores.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildIndividualScores(context, aggregation),
        ],
      ],
    );
  }

  Widget _buildSummaryStats(BuildContext context, AggregatedScore aggregation) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Average Score',
            aggregation.averageScore.toStringAsFixed(1),
            Icons.trending_up,
            _getScoreColor(aggregation.averageScore),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Total Judges',
            aggregation.judgeCount.toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Score Range',
            '${aggregation.scoreRange.min.toStringAsFixed(1)} - ${aggregation.scoreRange.max.toStringAsFixed(1)}',
            Icons.straighten,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaBreakdown(
      BuildContext context, AggregatedScore aggregation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Criteria Breakdown',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...aggregation.criteriaAverages.entries
            .map((entry) => _buildCriteriaBar(context, entry.key, entry.value)),
      ],
    );
  }

  Widget _buildCriteriaBar(
      BuildContext context, String criterion, double score) {
    final percentage = score / 100.0; // Assuming max score is 100
    final color = _getScoreColor(score);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatCriterionName(criterion),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                score.toStringAsFixed(1),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDistribution(
      BuildContext context, AggregatedScore aggregation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score Distribution',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Lowest',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      aggregation.scoreRange.min.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Average',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      aggregation.averageScore.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _getScoreColor(aggregation.averageScore),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Highest',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      aggregation.scoreRange.max.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Range',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      aggregation.scoreRange.range.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIndividualScores(
      BuildContext context, AggregatedScore aggregation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Individual Judge Scores',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...aggregation.individualScores
            .map((score) => _buildIndividualScoreCard(context, score)),
      ],
    );
  }

  Widget _buildIndividualScoreCard(BuildContext context, Score score) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Judge ${score.judgeId.substring(0, 8)}...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const Spacer(),
                if (score.totalScore != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getScoreColor(score.totalScore!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      score.totalScore!.toStringAsFixed(1),
                      style: TextStyle(
                        color: _getScoreColor(score.totalScore!),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (score.scores.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: score.scores.entries
                    .map((entry) => Chip(
                          label: Text(
                            '${_formatCriterionName(entry.key)}: ${entry.value}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.grey.withOpacity(0.1),
                        ))
                    .toList(),
              ),
            ],
            if (score.comments != null && score.comments!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.comment, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        score.comments!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.lightGreen;
    if (score >= 70) return Colors.orange;
    if (score >= 60) return Colors.deepOrange;
    return Colors.red;
  }

  String _formatCriterionName(String criterion) {
    // Convert camelCase or snake_case to Title Case
    return criterion
        .replaceAllMapped(
            RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
