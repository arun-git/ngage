import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/badge.dart';
import '../../../providers/badge_providers.dart';

class BadgesSection extends ConsumerWidget {
  final String memberId;

  const BadgesSection({
    super.key,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(memberBadgesProvider(memberId));

    return badgesAsync.when(
      data: (badges) => badges.isEmpty
          ? _buildEmptyState(context)
          : _buildBadgesList(context, badges),
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
              Icons.military_tech,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Badges Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Participate in events and activities to earn your first badge!',
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
              'Error Loading Badges',
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

  Widget _buildBadgesList(BuildContext context, List<Map<String, dynamic>> badges) {
    // Group badges by category
    final badgesByCategory = <BadgeCategory, List<Map<String, dynamic>>>{};
    
    for (final badgeData in badges) {
      final badge = badgeData['badge'] as Badge;
      badgesByCategory.putIfAbsent(badge.category, () => []).add(badgeData);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics
          _buildBadgeStatistics(context, badges),
          
          const SizedBox(height: 24),
          
          // Badges by category
          ...badgesByCategory.entries.map((entry) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getCategoryName(entry.key),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: entry.value.length,
                itemBuilder: (context, index) {
                  final badgeData = entry.value[index];
                  return _buildBadgeCard(context, badgeData);
                },
              ),
              const SizedBox(height: 24),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildBadgeStatistics(BuildContext context, List<Map<String, dynamic>> badges) {
    final rarityCount = <BadgeRarity, int>{};
    for (final badgeData in badges) {
      final badge = badgeData['badge'] as Badge;
      rarityCount[badge.rarity] = (rarityCount[badge.rarity] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Badge Collection',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: BadgeRarity.values.map((rarity) {
                final count = rarityCount[rarity] ?? 0;
                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getRarityColor(rarity).withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getRarityColor(rarity),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          count.toString(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _getRarityColor(rarity),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRarityName(rarity),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(BuildContext context, Map<String, dynamic> badgeData) {
    final badge = badgeData['badge'] as Badge;
    final memberBadge = badgeData['memberBadge'] as MemberBadge;

    return Card(
      child: InkWell(
        onTap: () => _showBadgeDetails(context, badge, memberBadge),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getRarityColor(badge.rarity).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getRarityColor(badge.rarity),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.military_tech,
                  color: _getRarityColor(badge.rarity),
                  size: 24,
                ),
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
                _formatDate(memberBadge.earnedAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRarityColor(badge.rarity).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${badge.pointValue} pts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getRarityColor(badge.rarity),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context, Badge badge, MemberBadge memberBadge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getRarityColor(badge.rarity).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getRarityColor(badge.rarity),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.military_tech,
                color: _getRarityColor(badge.rarity),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                badge.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              badge.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(context, 'Category', _getCategoryName(badge.category)),
            _buildDetailRow(context, 'Rarity', _getRarityName(badge.rarity)),
            _buildDetailRow(context, 'Points', '${badge.pointValue}'),
            _buildDetailRow(context, 'Earned', _formatDate(memberBadge.earnedAt)),
            if (memberBadge.eventId != null)
              _buildDetailRow(context, 'Event', memberBadge.eventId!),
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

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(BadgeCategory category) {
    switch (category) {
      case BadgeCategory.participation:
        return 'Participation';
      case BadgeCategory.performance:
        return 'Performance';
      case BadgeCategory.social:
        return 'Social';
      case BadgeCategory.consistency:
        return 'Consistency';
      case BadgeCategory.creativity:
        return 'Creativity';
      case BadgeCategory.leadership:
        return 'Leadership';
      case BadgeCategory.special:
        return 'Special';
    }
  }

  String _getRarityName(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return 'Common';
      case BadgeRarity.uncommon:
        return 'Uncommon';
      case BadgeRarity.rare:
        return 'Rare';
      case BadgeRarity.epic:
        return 'Epic';
      case BadgeRarity.legendary:
        return 'Legendary';
    }
  }

  Color _getRarityColor(BadgeRarity rarity) {
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
        return Colors.amber;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}