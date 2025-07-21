import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/badge_providers.dart';

class LeaderboardSection extends ConsumerWidget {
  final ScrollController? scrollController;

  const LeaderboardSection({
    super.key,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(pointsLeaderboardProvider(
      const LeaderboardParams(limit: 100),
    ));

    return leaderboardAsync.when(
      data: (leaderboard) => leaderboard.isEmpty
          ? _buildEmptyState(context)
          : _buildLeaderboardList(context, leaderboard),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Leaderboard Data',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The leaderboard will populate as members earn points!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Leaderboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(BuildContext context, List<Map<String, dynamic>> leaderboard) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final entry = leaderboard[index];
        final rank = entry['rank'] as int;
        final member = entry['member'] as Map<String, dynamic>;
        final points = entry['points'];

        return _buildLeaderboardItem(context, rank, member, points);
      },
    );
  }

  Widget _buildLeaderboardItem(
    BuildContext context,
    int rank,
    Map<String, dynamic> member,
    dynamic points,
  ) {
    final isTopThree = rank <= 3;
    final rankColor = _getRankColor(rank);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isTopThree ? 4 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: isTopThree 
                    ? Border.all(color: rankColor, width: 2)
                    : null,
              ),
              child: Center(
                child: isTopThree
                    ? Icon(
                        _getRankIcon(rank),
                        color: rankColor,
                        size: 20,
                      )
                    : Text(
                        rank.toString(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: rankColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Member Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${member['firstName'] ?? ''} ${member['lastName'] ?? ''}'.trim(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (member['title'] != null) ...[
                    Text(
                      member['title'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                  if (member['category'] != null) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        member['category'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  points.totalPoints.toString(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: rankColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'points',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                
                // Points breakdown for top 3
                if (isTopThree) ...[
                  const SizedBox(height: 8),
                  _buildPointsBreakdown(context, points),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsBreakdown(BuildContext context, dynamic points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (points.eventPoints > 0)
          _buildPointsBreakdownItem(
            context,
            'Events',
            points.eventPoints,
            Icons.event,
            Colors.blue,
          ),
        if (points.socialPoints > 0)
          _buildPointsBreakdownItem(
            context,
            'Social',
            points.socialPoints,
            Icons.forum,
            Colors.green,
          ),
        if (points.badgePoints > 0)
          _buildPointsBreakdownItem(
            context,
            'Badges',
            points.badgePoints,
            Icons.military_tech,
            Colors.purple,
          ),
        if (points.streakBonusPoints > 0)
          _buildPointsBreakdownItem(
            context,
            'Streaks',
            points.streakBonusPoints,
            Icons.local_fire_department,
            Colors.orange,
          ),
      ],
    );
  }

  Widget _buildPointsBreakdownItem(
    BuildContext context,
    String label,
    int points,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            '$label: $points',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey; // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events; // Trophy
      case 2:
        return Icons.military_tech; // Medal
      case 3:
        return Icons.workspace_premium; // Award
      default:
        return Icons.circle;
    }
  }
}