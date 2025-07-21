import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../models/badge.dart' as badge_model;
import '../../providers/badge_providers.dart';
import '../../providers/auth_providers.dart';

/// Main screen for displaying gamification features
class GamificationScreen extends ConsumerStatefulWidget {
  const GamificationScreen({super.key});

  @override
  ConsumerState<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends ConsumerState<GamificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMember = ref.watch(currentMemberProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: 'Overview'),
            Tab(icon: Icon(Icons.badge), text: 'Badges'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
          ],
        ),
      ),
      body: currentMember == null
          ? const Center(
              child: Text('Please log in to view achievements'),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(currentMember.id),
                _buildBadgesTab(currentMember.id),
                _buildLeaderboardTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab(String memberId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummarySection(memberId),
          const SizedBox(height: 24),
          _buildStreaksSection(memberId),
          const SizedBox(height: 24),
          _buildRecentBadgesSection(memberId),
        ],
      ),
    );
  }

  Widget _buildSummarySection(String memberId) {
    final summaryAsync = ref.watch(memberGamificationSummaryProvider(memberId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        summaryAsync.when(
          data: (summary) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.badge,
                        label: 'Badges',
                        value: '${summary.totalBadges}',
                        color: Colors.blue,
                      ),
                      _buildStatItem(
                        icon: Icons.star,
                        label: 'Points',
                        value: '${summary.totalPoints}',
                        color: Colors.amber,
                      ),
                      _buildStatItem(
                        icon: Icons.local_fire_department,
                        label: 'Streaks',
                        value: '${summary.activeStreaks}',
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: summary.totalMilestones > 0 
                        ? summary.completedMilestones / summary.totalMilestones 
                        : 0.0,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Milestones: ${summary.completedMilestones}/${summary.totalMilestones}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Error loading summary: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStreaksSection(String memberId) {
    final streaksAsync = ref.watch(memberStreaksProvider(memberId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Streaks',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        streaksAsync.when(
          data: (streaks) {
            if (streaks.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No streaks yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start participating to build your streaks!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: streaks
                  .map((streak) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.local_fire_department,
                            color: streak.isActive ? Colors.orange : Colors.grey,
                          ),
                          title: Text('${streak.type.value} Streak'),
                          subtitle: Text(
                            'Current: ${streak.currentStreak} | Best: ${streak.longestStreak}',
                          ),
                          trailing: streak.isActive
                              ? const Icon(Icons.trending_up, color: Colors.green)
                              : null,
                        ),
                      ))
                  .toList(),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Error loading streaks: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentBadgesSection(String memberId) {
    final badgesAsync = ref.watch(memberBadgesProvider(memberId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Badges',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        badgesAsync.when(
          data: (badges) {
            if (badges.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.badge,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No badges earned yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Participate in events to earn your first badge!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: badges.take(5).length,
                itemBuilder: (context, index) {
                  final badgeData = badges[index];
                  final badge = badgeData['badge'] as badge_model.Badge;
                  
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.badge,
                              size: 32,
                              color: _getBadgeColor(badge.rarity),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              badge.name,
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Error loading badges: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesTab(String memberId) {
    final badgesAsync = ref.watch(memberBadgesProvider(memberId));

    return badgesAsync.when(
      data: (badges) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final badgeData = badges[index];
          final badge = badgeData['badge'] as badge_model.Badge;
          
          return Card(
            child: InkWell(
              onTap: () => _showBadgeDetails(badge),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.badge,
                      size: 48,
                      color: _getBadgeColor(badge.rarity),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${badge.pointValue} pts',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading badges: $error'),
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    final leaderboardAsync = ref.watch(pointsLeaderboardProvider(
      const LeaderboardParams(limit: 20),
    ));

    return leaderboardAsync.when(
      data: (leaderboard) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leaderboard.length,
        itemBuilder: (context, index) {
          final entry = leaderboard[index];
          final rank = index + 1;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getRankColor(rank),
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text('Member ${entry['memberId']}'),
              subtitle: Text('${entry['totalBadges']} badges'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${entry['totalPoints']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading leaderboard: $error'),
      ),
    );
  }

  Color _getBadgeColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return Colors.grey;
      case BadgeRarity.uncommon:
        return Colors.green;
      case BadgeRarity.rare:
        return Colors.blue;
      case BadgeRarity.epic:
        return Colors.purple;
      case BadgeRarity.legendary:
        return Colors.orange;
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey; // Silver
      case 3:
        return Colors.brown; // Bronze
      default:
        return Colors.blue;
    }
  }

  void _showBadgeDetails(badge_model.Badge badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(badge.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badge.description),
            const SizedBox(height: 16),
            Text('Category: ${badge.category.value}'),
            Text('Rarity: ${badge.rarity.value}'),
            Text('Points: ${badge.pointValue}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}