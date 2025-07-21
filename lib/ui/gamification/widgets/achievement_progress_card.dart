import 'package:flutter/material.dart';
import '../../../models/models.dart';

/// Widget for displaying achievement progress and level information
class AchievementProgressCard extends StatelessWidget {
  final MemberAchievement achievement;
  final VoidCallback? onTap;

  const AchievementProgressCard({
    super.key,
    required this.achievement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildLevelIcon(colorScheme),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level ${achievement.level}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          achievement.levelTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildTotalPointsChip(colorScheme),
                ],
              ),
              const SizedBox(height: 20),
              if (achievement.nextLevelPoints > 0) ...[
                _buildProgressSection(theme, colorScheme),
                const SizedBox(height: 16),
              ],
              _buildCategoryBreakdown(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelIcon(ColorScheme colorScheme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        _getLevelIcon(),
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildTotalPointsChip(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 16, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            '${achievement.totalPoints}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme, ColorScheme colorScheme) {
    final progress = achievement.currentLevelPoints / achievement.nextLevelPoints;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress to Next Level',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${achievement.currentLevelPoints}/${achievement.nextLevelPoints}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toInt()}% complete',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(ThemeData theme, ColorScheme colorScheme) {
    if (achievement.categoryPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Points by Category',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: achievement.categoryPoints.entries
              .map((entry) => _buildCategoryChip(entry.key, entry.value, colorScheme))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String category, int points, ColorScheme colorScheme) {
    final color = _getCategoryColor(category);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(category),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$points',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getLevelIcon() {
    if (achievement.level >= 8) return Icons.emoji_events;
    if (achievement.level >= 6) return Icons.military_tech;
    if (achievement.level >= 4) return Icons.workspace_premium;
    if (achievement.level >= 2) return Icons.star;
    return Icons.person;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'participation':
        return Colors.blue;
      case 'performance':
        return Colors.green;
      case 'social':
        return Colors.pink;
      case 'milestone':
        return Colors.purple;
      case 'special':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'participation':
        return Icons.people;
      case 'performance':
        return Icons.trending_up;
      case 'social':
        return Icons.favorite;
      case 'milestone':
        return Icons.flag;
      case 'special':
        return Icons.star;
      default:
        return Icons.category;
    }
  }
}