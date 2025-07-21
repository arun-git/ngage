import 'package:flutter/material.dart';
import '../../../models/models.dart';

/// Widget for displaying a single badge
class BadgeCard extends StatelessWidget {
  final Badge badge;
  final bool isEarned;
  final DateTime? earnedAt;
  final VoidCallback? onTap;
  final bool showDetails;

  const BadgeCard({
    super.key,
    required this.badge,
    this.isEarned = false,
    this.earnedAt,
    this.onTap,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isEarned ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isEarned
                ? Border.all(color: _getRarityColor(badge.rarity), width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildBadgeIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badge.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isEarned ? null : colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        if (showDetails) ...[
                          const SizedBox(height: 4),
                          Text(
                            badge.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isEarned ? null : colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildRarityChip(),
                ],
              ),
              if (showDetails) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPointsChip(),
                    if (isEarned && earnedAt != null) _buildEarnedDate(),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getRarityColor(badge.rarity).withOpacity(0.1),
        border: Border.all(
          color: _getRarityColor(badge.rarity),
          width: 2,
        ),
      ),
      child: Icon(
        _getBadgeIcon(),
        color: isEarned ? _getRarityColor(badge.rarity) : Colors.grey,
        size: 24,
      ),
    );
  }

  Widget _buildRarityChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getRarityColor(badge.rarity).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getRarityColor(badge.rarity)),
      ),
      child: Text(
        badge.rarity.value.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _getRarityColor(badge.rarity),
        ),
      ),
    );
  }

  Widget _buildPointsChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            '${badge.pointValue} pts',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnedDate() {
    if (earnedAt == null) return const SizedBox.shrink();

    return Text(
      'Earned ${_formatDate(earnedAt!)}',
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey[600],
        fontStyle: FontStyle.italic,
      ),
    );
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
        return Colors.orange;
    }
  }

  IconData _getBadgeIcon() {
    switch (badge.type) {
      case BadgeType.participation:
        return Icons.people;
      case BadgeType.performance:
        return Icons.emoji_events;
      case BadgeType.social:
        return Icons.favorite;
      case BadgeType.milestone:
        return Icons.flag;
      case BadgeType.special:
        return Icons.star;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}