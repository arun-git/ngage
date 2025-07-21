import 'package:flutter/material.dart';
import '../../../models/models.dart';

/// Widget for displaying streak information
class StreakCard extends StatelessWidget {
  final MemberStreak streak;
  final VoidCallback? onTap;

  const StreakCard({
    super.key,
    required this.streak,
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStreakIcon(colorScheme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStreakTitle(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStreakDescription(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStreakBadge(colorScheme),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStreakStat(
                      'Current Streak',
                      '${streak.currentStreak}',
                      Icons.local_fire_department,
                      Colors.orange,
                      theme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStreakStat(
                      'Best Streak',
                      '${streak.longestStreak}',
                      Icons.emoji_events,
                      Colors.amber,
                      theme,
                    ),
                  ),
                ],
              ),
              if (streak.lastActivityDate != null) ...[
                const SizedBox(height: 12),
                _buildLastActivityInfo(theme, colorScheme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakIcon(ColorScheme colorScheme) {
    final color = _getStreakColor();
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(
        _getStreakIconData(),
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildStreakBadge(ColorScheme colorScheme) {
    final isActive = _isStreakActive();
    final color = isActive ? Colors.green : Colors.grey;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.pause_circle,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'ACTIVE' : 'PAUSED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakStat(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLastActivityInfo(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Text(
            'Last activity: ${_formatLastActivity()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _getStreakTitle() {
    switch (streak.type) {
      case StreakType.participation:
        return 'Participation Streak';
      case StreakType.submission:
        return 'Submission Streak';
      case StreakType.judging:
        return 'Judging Streak';
      case StreakType.social:
        return 'Social Streak';
    }
  }

  String _getStreakDescription() {
    switch (streak.type) {
      case StreakType.participation:
        return 'Consecutive days participating in events';
      case StreakType.submission:
        return 'Consecutive submissions made';
      case StreakType.judging:
        return 'Consecutive judging activities';
      case StreakType.social:
        return 'Consecutive days with social activity';
    }
  }

  IconData _getStreakIconData() {
    switch (streak.type) {
      case StreakType.participation:
        return Icons.people;
      case StreakType.submission:
        return Icons.upload;
      case StreakType.judging:
        return Icons.gavel;
      case StreakType.social:
        return Icons.favorite;
    }
  }

  Color _getStreakColor() {
    switch (streak.type) {
      case StreakType.participation:
        return Colors.blue;
      case StreakType.submission:
        return Colors.green;
      case StreakType.judging:
        return Colors.purple;
      case StreakType.social:
        return Colors.pink;
    }
  }

  bool _isStreakActive() {
    if (streak.lastActivityDate == null) return false;
    
    final now = DateTime.now();
    final lastActivity = streak.lastActivityDate!;
    final daysSinceLastActivity = now.difference(lastActivity).inDays;
    
    // Consider streak active if last activity was today or yesterday
    return daysSinceLastActivity <= 1;
  }

  String _formatLastActivity() {
    if (streak.lastActivityDate == null) return 'Never';
    
    final now = DateTime.now();
    final lastActivity = streak.lastActivityDate!;
    final difference = now.difference(lastActivity);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${lastActivity.day}/${lastActivity.month}/${lastActivity.year}';
    }
  }
}