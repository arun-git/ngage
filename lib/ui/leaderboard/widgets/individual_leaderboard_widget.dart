import 'package:flutter/material.dart';
import '../../../services/leaderboard_service.dart';
import '../leaderboard_screen.dart';

/// Widget for displaying individual member leaderboard
class IndividualLeaderboardWidget extends StatelessWidget {
  final IndividualLeaderboard leaderboard;
  final LeaderboardViewMode viewMode;
  final bool showCriteriaBreakdown;

  const IndividualLeaderboardWidget({
    super.key,
    required this.leaderboard,
    this.viewMode = LeaderboardViewMode.table,
    this.showCriteriaBreakdown = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!leaderboard.hasEntries) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // Leaderboard metadata
        _buildMetadataHeader(context),
        
        // Main content based on view mode
        Expanded(
          child: _buildContent(context),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Individual Scores Available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Individual rankings will appear once members submit and get scored.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataHeader(BuildContext context) {
    final metadata = leaderboard.metadata;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetadataItem(
              context,
              'Members',
              leaderboard.memberCount.toString(),
              Icons.person,
            ),
          ),
          Expanded(
            child: _buildMetadataItem(
              context,
              'Submissions',
              metadata['totalSubmissions']?.toString() ?? '0',
              Icons.assignment,
            ),
          ),
          Expanded(
            child: _buildMetadataItem(
              context,
              'Scores',
              metadata['totalScores']?.toString() ?? '0',
              Icons.score,
            ),
          ),
          Expanded(
            child: _buildMetadataItem(
              context,
              'Updated',
              _formatDateTime(leaderboard.calculatedAt),
              Icons.update,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (viewMode) {
      case LeaderboardViewMode.table:
        return _buildTableView(context);
      case LeaderboardViewMode.cards:
        return _buildCardsView(context);
      case LeaderboardViewMode.podium:
        return _buildPodiumView(context);
    }
  }

  Widget _buildTableView(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            child: Row(
              children: [
                const SizedBox(width: 50, child: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold))),
                const Expanded(flex: 3, child: Text('Member', style: TextStyle(fontWeight: FontWeight.bold))),
                const Expanded(flex: 2, child: Text('Avg Score', style: TextStyle(fontWeight: FontWeight.bold))),
                const Expanded(flex: 2, child: Text('Total Score', style: TextStyle(fontWeight: FontWeight.bold))),
                const Expanded(flex: 2, child: Text('Submissions', style: TextStyle(fontWeight: FontWeight.bold))),
                if (showCriteriaBreakdown)
                  const Expanded(flex: 3, child: Text('Breakdown', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          
          // Table rows
          ...leaderboard.entries.asMap().entries.map((entryData) {
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
                    width: 50,
                    child: _buildRankWidget(context, entry.position),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.memberName,
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
                    child: Text(
                      entry.totalScore.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w500),
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
      ),
    );
  }

  Widget _buildCardsView(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaderboard.entries.length,
      itemBuilder: (context, index) {
        final entry = leaderboard.entries[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    _buildRankWidget(context, entry.position),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.memberName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getScoreColor(entry.averageScore).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _getScoreColor(entry.averageScore)),
                      ),
                      child: Text(
                        entry.averageScore.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(entry.averageScore),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Stats row
                Row(
                  children: [
                    _buildStatChip(
                      'Total: ${entry.totalScore.toStringAsFixed(1)}',
                      Icons.score,
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      'Submissions: ${entry.submissionCount}',
                      Icons.assignment,
                      Colors.green,
                    ),
                  ],
                ),
                
                // Criteria breakdown
                if (showCriteriaBreakdown && entry.criteriaScores.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildCriteriaBreakdown(context, entry),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPodiumView(BuildContext context) {
    final topThree = leaderboard.entries.take(3).toList();
    final remaining = leaderboard.entries.skip(3).toList();
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Podium
          if (topThree.isNotEmpty) ...[
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              child: _buildPodium(context, topThree),
            ),
            const Divider(),
          ],
          
          // Remaining entries
          if (remaining.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Other Members',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...remaining.map((entry) => ListTile(
              leading: CircleAvatar(
                child: Text(entry.position.toString()),
              ),
              title: Text(entry.memberName),
              subtitle: Text('${entry.submissionCount} submissions'),
              trailing: Text(
                entry.averageScore.toStringAsFixed(1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(entry.averageScore),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildPodium(BuildContext context, List<IndividualLeaderboardEntry> topThree) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Second place
        if (topThree.length > 1)
          Expanded(child: _buildPodiumPlace(context, topThree[1], 2, 180)),
        
        // First place
        if (topThree.isNotEmpty)
          Expanded(child: _buildPodiumPlace(context, topThree[0], 1, 220)),
        
        // Third place
        if (topThree.length > 2)
          Expanded(child: _buildPodiumPlace(context, topThree[2], 3, 140)),
      ],
    );
  }

  Widget _buildPodiumPlace(BuildContext context, IndividualLeaderboardEntry entry, int place, double height) {
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
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 8),
          
          // Member name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              entry.memberName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Score
          Text(
            entry.averageScore.toStringAsFixed(1),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Podium base
          Container(
            height: height - 120,
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

  Widget _buildRankWidget(BuildContext context, int position) {
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
        width: 32,
        height: 32,
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
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          position.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCriteriaBreakdown(BuildContext context, IndividualLeaderboardEntry entry) {
    if (entry.criteriaScores.isEmpty) {
      return const Text('-', style: TextStyle(color: Colors.grey));
    }

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: entry.criteriaScores.entries.take(4).map((criteriaEntry) => 
        Chip(
          label: Text(
            '${_formatCriterionName(criteriaEntry.key)}: ${criteriaEntry.value.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 11),
          ),
          backgroundColor: _getScoreColor(criteriaEntry.value).withOpacity(0.1),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        )
      ).toList(),
    );
  }

  Widget _buildStatChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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