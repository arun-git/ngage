import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/badge.dart';
import '../../../providers/badge_providers.dart';

class StreaksSection extends ConsumerWidget {
  final String memberId;

  const StreaksSection({
    super.key,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streaksAsync = ref.watch(memberStreaksProvider(memberId));

    return streaksAsync.when(
      data: (streaks) => streaks.isEmpty
          ? _buildEmptyState(context)
          : _buildStreaksView(context, streaks),
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
              Icons.local_fire_department,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Streaks Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start participating consistently to build your first streak!',
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
              'Error Loading Streaks',
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

  Widget _buildStreaksView(BuildContext context, List<MemberStreak> streaks) {
    // Sort streaks by current streak (active first, then by length)
    final sortedStreaks = List<MemberStreak>.from(streaks)
      ..sort((a, b) {
        if (a.isActive && !b.isActive) return -1;
        if (!a.isActive && b.isActive) return 1;
        return b.currentStreak.compareTo(a.currentStreak);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak Statistics
          _buildStreakStatistics(context, streaks),
          
          const SizedBox(height: 24),
          
          // Active Streaks
          Text(
            'Your Streaks',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          ...sortedStreaks.map((streak) => _buildStreakCard(context, streak)),
          
          const SizedBox(height: 24),
          
          // Streak Tips
          _buildStreakTips(context),
        ],
      ),
    );
  }

  Widget _buildStreakStatistics(BuildContext context, List<MemberStreak> streaks) {
    final activeStreaks = streaks.where((s) => s.isActive).length;
    final longestStreak = streaks.isNotEmpty 
        ? streaks.map((s) => s.longestStreak).reduce((a, b) => a > b ? a : b)
        : 0;
    final totalStreaks = streaks.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Streak Overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  context,
                  'Active',
                  activeStreaks.toString(),
                  Icons.local_fire_department,
                  Colors.orange,
                ),
                _buildStatColumn(
                  context,
                  'Longest',
                  '$longestStreak days',
                  Icons.trending_up,
                  Colors.green,
                ),
                _buildStatColumn(
                  context,
                  'Total',
                  totalStreaks.toString(),
                  Icons.timeline,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStreakCard(BuildContext context, MemberStreak streak) {
    final streakColor = streak.isActive ? Colors.orange : Colors.grey;
    final daysSinceLastActivity = DateTime.now().difference(streak.lastActivityDate).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: streakColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStreakIcon(streak.type),
                    color: streakColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStreakTypeName(streak.type),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (streak.isActive) ...[
                            Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Active',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else ...[
                            Icon(
                              Icons.pause_circle_outline,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Inactive',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${streak.currentStreak}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: streakColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'days',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: streakColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Streak Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStreakDetail(
                  context,
                  'Longest',
                  '${streak.longestStreak} days',
                ),
                _buildStreakDetail(
                  context,
                  'Started',
                  _formatDate(streak.streakStartDate),
                ),
                _buildStreakDetail(
                  context,
                  'Last Activity',
                  daysSinceLastActivity == 0 
                      ? 'Today'
                      : daysSinceLastActivity == 1
                          ? 'Yesterday'
                          : '$daysSinceLastActivity days ago',
                ),
              ],
            ),
            
            // Progress indicator for active streaks
            if (streak.isActive && streak.currentStreak > 0) ...[
              const SizedBox(height: 16),
              _buildStreakProgress(context, streak),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreakDetail(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakProgress(BuildContext context, MemberStreak streak) {
    // Show progress towards next milestone (e.g., 7, 14, 30, 60, 100 days)
    final milestones = [7, 14, 30, 60, 100, 200, 365];
    final nextMilestone = milestones.firstWhere(
      (milestone) => milestone > streak.currentStreak,
      orElse: () => milestones.last,
    );
    
    final progress = streak.currentStreak / nextMilestone;
    final daysToGo = nextMilestone - streak.currentStreak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Next milestone: $nextMilestone days',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '$daysToGo days to go',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.grey.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      ],
    );
  }

  Widget _buildStreakTips(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  'Streak Tips',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTip(context, 'Set daily reminders to maintain your streaks'),
            _buildTip(context, 'Even small activities count towards your streak'),
            _buildTip(context, 'Longer streaks earn bonus points and special badges'),
            _buildTip(context, 'Don\'t worry if you break a streak - you can always start again!'),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(BuildContext context, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStreakIcon(StreakType type) {
    switch (type) {
      case StreakType.dailyLogin:
        return Icons.login;
      case StreakType.eventParticipation:
        return Icons.event;
      case StreakType.socialEngagement:
        return Icons.forum;
      case StreakType.submissionStreak:
        return Icons.upload_file;
      case StreakType.judgingStreak:
        return Icons.gavel;
    }
  }

  String _getStreakTypeName(StreakType type) {
    switch (type) {
      case StreakType.dailyLogin:
        return 'Daily Login';
      case StreakType.eventParticipation:
        return 'Event Participation';
      case StreakType.socialEngagement:
        return 'Social Engagement';
      case StreakType.submissionStreak:
        return 'Submission Streak';
      case StreakType.judgingStreak:
        return 'Judging Streak';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}