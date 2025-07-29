import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/member_providers.dart';
import '../../providers/group_providers.dart';
import '../widgets/event_banner_image.dart';

/// Card widget displaying event information with role-based action controls
class EventCard extends ConsumerWidget {
  final Event event;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner image if available
            if (event.bannerImageUrl != null)
              Expanded(
                flex: 3,
                child: EventBannerImage(
                  imageUrl: event.bannerImageUrl!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status chip and title row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildCompactStatusChip(context),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Event type
                    Row(
                      children: [
                        Icon(
                          _getEventTypeIcon(),
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getEventTypeLabel(),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Description
                    Expanded(
                      child: Text(
                        event.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Compact time information
                    _buildCompactTimeInfo(context),

                    // Action buttons if provided
                    if (onEdit != null || onDelete != null) ...[
                      const SizedBox(height: 8),
                      _buildCompactActionButtons(context, ref),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatusChip(BuildContext context) {
    final (color, backgroundColor) = _getStatusColors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getStatusLabel(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }

  Widget _buildCompactActionButtons(BuildContext context, WidgetRef ref) {
    // Get current member from auth state
    final activeMemberAsync = ref.watch(activeMemberProvider);

    return activeMemberAsync.when(
      data: (member) {
        if (member == null) return const SizedBox.shrink();

        // Check if current member is an admin in this group
        final membershipAsync = ref.watch(groupMembershipProvider((
          groupId: event.groupId,
          memberId: member.id,
        )));

        return membershipAsync.when(
          data: (membership) {
            // Only show action buttons to admin users
            if (membership == null || !membership.isAdmin) {
              return const SizedBox.shrink();
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 16),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
                      color: Colors.red,
                      tooltip: 'Edit Event (Admin)',
                    ),
                  ),
                if (onEdit != null && onDelete != null)
                  const SizedBox(width: 4),
                if (onDelete != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 16),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
                      color: Colors.red,
                      tooltip: 'Delete Event (Admin)',
                    ),
                  ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  IconData _getEventTypeIcon() {
    switch (event.eventType) {
      case EventType.competition:
        return Icons.emoji_events;
      case EventType.challenge:
        return Icons.flag;
      case EventType.survey:
        return Icons.poll;
    }
  }

  String _getEventTypeLabel() {
    switch (event.eventType) {
      case EventType.competition:
        return 'Competition';
      case EventType.challenge:
        return 'Challenge';
      case EventType.survey:
        return 'Survey';
    }
  }

  String _getStatusLabel() {
    switch (event.status) {
      case EventStatus.draft:
        return 'Draft';
      case EventStatus.scheduled:
        return 'Scheduled';
      case EventStatus.active:
        return 'Active';
      case EventStatus.completed:
        return 'Completed';
      case EventStatus.cancelled:
        return 'Cancelled';
    }
  }

  (Color, Color) _getStatusColors(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (event.status) {
      case EventStatus.draft:
        return (colorScheme.outline, colorScheme.outline.withOpacity(0.1));
      case EventStatus.scheduled:
        return (Colors.blue, Colors.blue.withOpacity(0.1));
      case EventStatus.active:
        return (Colors.green, Colors.green.withOpacity(0.1));
      case EventStatus.completed:
        return (colorScheme.primary, colorScheme.primary.withOpacity(0.1));
      case EventStatus.cancelled:
        return (colorScheme.error, colorScheme.error.withOpacity(0.1));
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (eventDate == today) {
      return 'Today ${_formatTime(dateTime)}';
    } else if (eventDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow ${_formatTime(dateTime)}';
    } else if (eventDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  Widget _buildCompactTimeInfo(BuildContext context) {
    if (event.startTime == null && event.endTime == null) {
      return Row(
        children: [
          Icon(
            Icons.schedule,
            size: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              'Not scheduled',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 10,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    // Show the most relevant time info
    DateTime? relevantTime;
    IconData icon = Icons.schedule;
    String prefix = 'Time';

    if (event.status == EventStatus.active && event.endTime != null) {
      relevantTime = event.endTime;
      icon = Icons.stop;
      prefix = 'Ends';
    } else if (event.startTime != null) {
      relevantTime = event.startTime;
      icon = Icons.play_arrow;
      prefix = 'Starts';
    } else if (event.endTime != null) {
      relevantTime = event.endTime;
      icon = Icons.stop;
      prefix = 'Ends';
    }

    if (relevantTime == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            '$prefix: ${_formatCompactDateTime(relevantTime)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 10,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatCompactDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (eventDate == today) {
      return 'Today ${_formatTime(dateTime)}';
    } else if (eventDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (eventDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
