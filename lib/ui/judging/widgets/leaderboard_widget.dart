import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../providers/judging_providers.dart';

/// Widget for displaying event leaderboards
class LeaderboardWidget extends ConsumerWidget {
  final String eventId;
  final bool showCriteriaBreakdown;
  final int? maxEntries;

  const LeaderboardWidget({
    super.key,
    required this.eventId,
    this.showCriteriaBreakdown = false,
    this.maxEntries,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(eventLeaderboardProvider(eventId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.leaderboard, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Leaderboard',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.refresh(eventLeaderboardProvider(eventId)),
                  tooltip: 'Refresh Leaderboard',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            leaderboardAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorWidget(error),
              data: (leaderboard) => _buildLeaderboardContent(context, leaderboard),
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
        Text('Error loading leaderboard: $error'),
      ],
    );
  }

  Widget _buildLeaderboardContent(BuildContext context, Leaderboard leaderboard) {
    if (!leaderboard.hasEntries) {
      return const Column(
        children: [
          Icon(Icons.emoji_events, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('No scores available yet'),
          Text(
            'The leaderboard will appear once submissions are scored.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final entries = maxEntries != null 
        ? leaderboard.getTopEntries(maxEntries!)
        : leaderboard.entries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Leaderboard metadata
        _buildLeaderboardStats(context, leaderboard),
        
        const SizedBox(height: 16),
        
        // Top 3 podium (if showing full leaderboard)
        if (maxEntries == null && entries.length >= 3) ...[
          _buildPodium(context, leaderboard.getTopEntries(3)),
          const SizedBox(height: 24),
        ],
        
        // Full leaderboard table
        _buildLeaderboardTable(context, entries),
      ],
    );
  }

  Widget _buildLeaderboardStats(BuildContext context, Leaderboard leaderboard) {
    final metadata = leaderboard.metadata;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              'Teams',
              leaderboard.teamCount.toString(),
              Icons.groups,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              'Submissions',
              metadata['totalSubmissions']?.toString() ?? '0',
              Icons.assignment,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              'Total Scores',
              metadata['totalScores']?.toString() ?? '0',
              Icons.score,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              context,
              'Last Updated',
              _formatDateTime(leaderboard.calculatedAt),
              Icons.update,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildPodium(BuildContext context, List<LeaderboardEntry> topThree) {
    return Container(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Second place
          if (topThree.length > 1)
            Expanded(child: _buildPodiumPlace(context, topThree[1], 2, 140)),
          
          // First place
          if (topThree.isNotEmpty)
            Expanded(child: _buildPodiumPlace(context, topThree[0], 1, 180)),
          
          // Third place
          if (topThree.length > 2)
            Expanded(child: _buildPodiumPlace(context, topThree[2], 3, 100)),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(BuildContext context, LeaderboardEntry entry, int place, double height) {
    Color color;
    IconData icon;
    
    switch (place) {
      case 1:
        color = Colors.amber;
        icon = Icons.emoji_events;
        break;
      case 2:
        color = Colors.grey;
        icon = Icons.emoji_events;
        break;
      case 3:
        color = Colors.brown;
        icon = Icons.emoji_events;
        break;
      default:
        color = Colors.blue;
        icon = Icons.emoji_events;
    }

    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Trophy icon
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          
          // Team name
          Text(
            entry.teamName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Score
          Text(
            entry.averageScore.toStringAsFixed(1),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Podium base
          Container(
            height: height - 100,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(color: color),
            ),
            child: Center(
              child: Text(
                place.toString(),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTable(BuildContext context, List<LeaderboardEntry> entries) {
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 40, child: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold))),
              const Expanded(flex: 3, child: Text('Team', style: TextStyle(fontWeight: FontWeight.bold))),
              const Expanded(flex: 2, child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold))),
              const Expanded(flex: 2, child: Text('Submissions', style: TextStyle(fontWeight: FontWeight.bold))),
              if (showCriteriaBreakdown)
                const Expanded(flex: 3, child: Text('Breakdown', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        
        // Table rows
        ...entries.asMap().entries.map((entryData) {
          final index = entryData.key;
          final entry = entryData.value;
          final isEven = index % 2 == 0;
          
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isEven ? null : Colors.grey.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: _buildRankWidget(entry.position),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.teamName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.averageScore.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(entry.averageScore),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(entry.submissionCount.toString()),
                ),
                if (showCriteriaBreakdown)
                  Expanded(
                    flex: 3,
                    child: _buildCriteriaBreakdown(context, entry),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRankWidget(int position) {
    if (position <= 3) {
      Color color;
      switch (position) {
        case 1:
          color = Colors.amber;
          break;
        case 2:
          color = Colors.grey;
          break;
        case 3:
          color = Colors.brown;
          break;
        default:
          color = Colors.blue;
      }
      
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            position.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }
    
    return Text(
      position.toString(),
      style: const TextStyle(fontWeight: FontWeight.w500),
    );
  }

  Widget _buildCriteriaBreakdown(BuildContext context, LeaderboardEntry entry) {
    if (entry.criteriaScores.isEmpty) {
      return const Text('-', style: TextStyle(color: Colors.grey));
    }

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: entry.criteriaScores.entries.take(3).map((criteriaEntry) => 
        Chip(
          label: Text(
            '${_formatCriterionName(criteriaEntry.key)}: ${criteriaEntry.value.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: _getScoreColor(criteriaEntry.value).withOpacity(0.1),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        )
      ).toList(),
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
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
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
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}