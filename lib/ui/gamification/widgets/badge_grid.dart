import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/models.dart';
import '../../../providers/badge_providers.dart';
import 'badge_card.dart';

/// Widget for displaying badges in a grid layout
class BadgeGrid extends ConsumerWidget {
  final String? memberId;
  final BadgeFilterType filterType;
  final BadgeRarity? filterRarity;
  final int crossAxisCount;
  final bool showDetails;
  final Function(Badge)? onBadgeTap;

  const BadgeGrid({
    super.key,
    this.memberId,
    this.filterType = BadgeFilterType.all,
    this.filterRarity,
    this.crossAxisCount = 2,
    this.showDetails = true,
    this.onBadgeTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBadgesAsync = ref.watch(allBadgesProvider);
    final memberBadgesAsync = memberId != null
        ? ref.watch(memberBadgesProvider(memberId!))
        : const AsyncValue.data(<MemberBadge>[]);

    return allBadgesAsync.when(
      data: (allBadges) => memberBadgesAsync.when(
        data: (memberBadges) {
          final filteredBadges = _filterBadges(allBadges, memberBadges);
          
          if (filteredBadges.isEmpty) {
            return _buildEmptyState(context);
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: showDetails ? 0.8 : 1.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: filteredBadges.length,
            itemBuilder: (context, index) {
              final badgeInfo = filteredBadges[index];
              final badge = badgeInfo['badge'] as Badge;
              final isEarned = badgeInfo['isEarned'] as bool;
              final earnedAt = badgeInfo['earnedAt'] as DateTime?;

              return BadgeCard(
                badge: badge,
                isEarned: isEarned,
                earnedAt: earnedAt,
                showDetails: showDetails,
                onTap: onBadgeTap != null ? () => onBadgeTap!(badge) : null,
              );
            },
          );
        },
        loading: () => _buildLoadingGrid(),
        error: (error, stack) => _buildErrorState(context, error),
      ),
      loading: () => _buildLoadingGrid(),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  List<Map<String, dynamic>> _filterBadges(
    List<Badge> allBadges,
    List<MemberBadge> memberBadges,
  ) {
    final earnedBadgeIds = memberBadges.map((mb) => mb.badgeId).toSet();
    final earnedBadgeMap = {
      for (var mb in memberBadges) mb.badgeId: mb.earnedAt
    };

    List<Badge> filteredBadges = allBadges;

    // Apply rarity filter
    if (filterRarity != null) {
      filteredBadges = filteredBadges
          .where((badge) => badge.rarity == filterRarity)
          .toList();
    }

    // Apply type filter
    switch (filterType) {
      case BadgeFilterType.earned:
        filteredBadges = filteredBadges
            .where((badge) => earnedBadgeIds.contains(badge.id))
            .toList();
        break;
      case BadgeFilterType.unearned:
        filteredBadges = filteredBadges
            .where((badge) => !earnedBadgeIds.contains(badge.id))
            .toList();
        break;
      case BadgeFilterType.recent:
        final recentThreshold = DateTime.now().subtract(const Duration(days: 30));
        filteredBadges = filteredBadges
            .where((badge) {
              final earnedAt = earnedBadgeMap[badge.id];
              return earnedAt != null && earnedAt.isAfter(recentThreshold);
            })
            .toList();
        break;
      case BadgeFilterType.all:
        // No additional filtering
        break;
    }

    // Sort badges: earned first, then by rarity, then by name
    filteredBadges.sort((a, b) {
      final aEarned = earnedBadgeIds.contains(a.id);
      final bEarned = earnedBadgeIds.contains(b.id);

      if (aEarned != bEarned) {
        return bEarned ? 1 : -1; // Earned badges first
      }

      // Then by rarity (legendary first)
      final rarityOrder = {
        BadgeRarity.legendary: 0,
        BadgeRarity.epic: 1,
        BadgeRarity.rare: 2,
        BadgeRarity.uncommon: 3,
        BadgeRarity.common: 4,
      };

      final aRarityOrder = rarityOrder[a.rarity] ?? 5;
      final bRarityOrder = rarityOrder[b.rarity] ?? 5;

      if (aRarityOrder != bRarityOrder) {
        return aRarityOrder.compareTo(bRarityOrder);
      }

      // Finally by name
      return a.name.compareTo(b.name);
    });

    return filteredBadges.map((badge) => {
      'badge': badge,
      'isEarned': earnedBadgeIds.contains(badge.id),
      'earnedAt': earnedBadgeMap[badge.id],
    }).toList();
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: showDetails ? 0.8 : 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 6, // Show 6 skeleton cards
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 12,
                        width: 100,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showDetails) ...[
              const SizedBox(height: 12),
              Container(
                height: 12,
                width: double.infinity,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 20,
                    width: 60,
                    color: Colors.grey[300],
                  ),
                  Container(
                    height: 20,
                    width: 40,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    String message;
    IconData icon;
    
    switch (filterType) {
      case BadgeFilterType.earned:
        message = 'No badges earned yet.\nStart participating to earn your first badge!';
        icon = Icons.emoji_events;
        break;
      case BadgeFilterType.unearned:
        message = 'All badges have been earned!\nCongratulations on your achievement!';
        icon = Icons.celebration;
        break;
      case BadgeFilterType.recent:
        message = 'No recent badges.\nKeep participating to earn more!';
        icon = Icons.schedule;
        break;
      case BadgeFilterType.all:
        message = 'No badges available.';
        icon = Icons.badge;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load badges',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}