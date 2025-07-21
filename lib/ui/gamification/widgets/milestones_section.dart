import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/badge.dart';
import '../../../providers/badge_providers.dart';

class MilestonesSection extends ConsumerWidget {
  final String memberId;

  const MilestonesSection({
    super.key,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(memberMilestonesProvider(memberId));

    return milestonesAsync.when(
      data: (milestones) => milestones.isEmpty
          ? _buildEmptyState(context)
          : _buildMilestonesView(context, milestones),
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
              Icons.flag,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Milestones Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Milestones will appear as you start participating in activities!',
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
              'Error Loading Milestones',
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

  Widget _buildMilestonesView(BuildContext context, List<Map<String, dynamic>> milestones) {
    // Separate completed and in-progress milestones
    final completedMilestones = milestones
        .where((m) => m['memberMilestone'].isCompleted)
        .toList();
    final inProgressMilestones = milestones
        .where((m) => !m['memberMilestone'].isCompleted)
        .toList();

    // Sort in-progress by progress percentage (closest to completion first)
    inProgressMilestones.sort((a, b) => 
        (b['progressPercentage'] as double).compareTo(a['progressPercentage'] as double));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Milestone Statistics
          _buildMilestoneStatistics(context, completedMilestones.length, milestones.length),
          
          const SizedBox(height: 24),
          
          // In Progress Milestones
          if (inProgressMilestones.isNotEmpty) ...[
            Text(
              'In Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...inProgressMilestones.map((milestone) => 
                _buildMilestoneCard(context, milestone, false)),
            const SizedBox(height: 24),
          ],
          
          // Completed Milestones
          if (completedMilestones.isNotEmpty) ...[
            Text(
              'Completed',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...completedMilestones.map((milestone) => 
                _buildMilestoneCard(context, milestone, true)),
          ],
          
          const SizedBox(height: 24),
          
          // Milestone Tips
          _buildMilestoneTips(context),
        ],
      ),
    );
  }

  Widget _buildMilestoneStatistics(BuildContext context, int completed, int total) {
    final completionRate = total > 0 ? (completed / total) * 100 : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Milestone Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  context,
                  'Completed',
                  completed.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatColumn(
                  context,
                  'In Progress',
                  (total - completed).toString(),
                  Icons.schedule,
                  Colors.orange,
                ),
                _buildStatColumn(
                  context,
                  'Completion Rate',
                  '${completionRate.toStringAsFixed(0)}%',
                  Icons.trending_up,
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMilestoneCard(
    BuildContext context, 
    Map<String, dynamic> milestoneData, 
    bool isCompleted,
  ) {
    final milestone = milestoneData['milestone'] as Milestone;
    final memberMilestone = milestoneData['memberMilestone'];
    final progressPercentage = milestoneData['progressPercentage'] as double;

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
                    color: isCompleted 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.flag,
                    color: isCompleted ? Colors.green : Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        milestone.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted) ...[
                  const Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${memberMilestone.currentProgress}/${milestone.targetValue}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            LinearProgressIndicator(
              value: progressPercentage / 100,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? Colors.green : Colors.blue,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMilestoneDetail(
                  context,
                  'Type',
                  _getMilestoneTypeName(milestone.type),
                ),
                _buildMilestoneDetail(
                  context,
                  'Reward',
                  '${milestone.pointReward} pts',
                ),
                if (isCompleted)
                  _buildMilestoneDetail(
                    context,
                    'Completed',
                    _formatDate(memberMilestone.completedAt),
                  )
                else
                  _buildMilestoneDetail(
                    context,
                    'Progress',
                    '${progressPercentage.toStringAsFixed(0)}%',
                  ),
              ],
            ),
            
            // Badge reward if applicable
            if (milestone.badgeId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.military_tech,
                      color: Colors.purple,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Badge Reward',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
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

  Widget _buildMilestoneDetail(BuildContext context, String label, String value) {
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

  Widget _buildMilestoneTips(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  'Milestone Tips',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTip(context, 'Focus on milestones that are closest to completion'),
            _buildTip(context, 'Completing milestones earns points and sometimes badges'),
            _buildTip(context, 'Milestones track your long-term progress and achievements'),
            _buildTip(context, 'New milestones may appear as you engage more with the platform'),
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

  String _getMilestoneTypeName(MilestoneType type) {
    switch (type) {
      case MilestoneType.totalPoints:
        return 'Total Points';
      case MilestoneType.eventParticipation:
        return 'Event Participation';
      case MilestoneType.socialPosts:
        return 'Social Posts';
      case MilestoneType.badgesEarned:
        return 'Badges Earned';
      case MilestoneType.streakDays:
        return 'Streak Days';
      case MilestoneType.submissionsCount:
        return 'Submissions';
      case MilestoneType.judgeScores:
        return 'Judge Scores';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}