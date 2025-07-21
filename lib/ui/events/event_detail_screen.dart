import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/event_providers.dart';
import 'create_event_screen.dart';
import 'clone_event_screen.dart';
import 'event_access_screen.dart';
import 'event_prerequisites_screen.dart';

/// Screen displaying detailed information about an event
class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventStreamProvider(eventId));

    return eventAsync.when(
      data: (event) {
        if (event == null) {
          return _buildNotFoundScreen(context);
        }
        return _buildEventDetailScreen(context, ref, event);
      },
      loading: () => _buildLoadingScreen(context),
      error: (error, stack) => _buildErrorScreen(context, error),
    );
  }

  Widget _buildEventDetailScreen(BuildContext context, WidgetRef ref, Event event) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, event, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Event'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (event.status == EventStatus.draft)
                const PopupMenuItem(
                  value: 'schedule',
                  child: ListTile(
                    leading: Icon(Icons.schedule),
                    title: Text('Schedule Event'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (event.status == EventStatus.scheduled)
                const PopupMenuItem(
                  value: 'activate',
                  child: ListTile(
                    leading: Icon(Icons.play_arrow),
                    title: Text('Activate Event'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (event.status == EventStatus.active)
                const PopupMenuItem(
                  value: 'complete',
                  child: ListTile(
                    leading: Icon(Icons.check_circle),
                    title: Text('Complete Event'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: 'clone',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Clone Event'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'access',
                child: ListTile(
                  leading: Icon(Icons.security),
                  title: Text('Manage Access'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'prerequisites',
                child: ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Prerequisites'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (event.status == EventStatus.draft)
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete Event', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Type Header
            _buildHeaderSection(context, event),
            
            const SizedBox(height: 24),
            
            // Description
            _buildDescriptionSection(context, event),
            
            const SizedBox(height: 24),
            
            // Scheduling Information
            _buildSchedulingSection(context, event),
            
            const SizedBox(height: 24),
            
            // Access Control
            _buildAccessSection(context, event),
            
            const SizedBox(height: 24),
            
            // Judging Criteria (if any)
            if (event.judgingCriteria.isNotEmpty) ...[
              _buildJudgingSection(context, event),
              const SizedBox(height: 24),
            ],
            
            // Action Buttons
            _buildActionButtons(context, ref, event),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, Event event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getEventTypeIcon(event.eventType),
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getEventTypeLabel(event.eventType),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusChip(context, event),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Created: ${_formatDateTime(event.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            if (event.updatedAt != event.createdAt)
              Text(
                'Updated: ${_formatDateTime(event.updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context, Event event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulingSection(BuildContext context, Event event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scheduling',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (event.startTime != null) ...[
              _buildScheduleItem(
                context,
                icon: Icons.play_arrow,
                label: 'Start Time',
                value: _formatDateTime(event.startTime!),
                color: Colors.green,
              ),
              const SizedBox(height: 12),
            ],
            
            if (event.endTime != null) ...[
              _buildScheduleItem(
                context,
                icon: Icons.stop,
                label: 'End Time',
                value: _formatDateTime(event.endTime!),
                color: Colors.red,
              ),
              const SizedBox(height: 12),
            ],
            
            if (event.submissionDeadline != null) ...[
              _buildScheduleItem(
                context,
                icon: Icons.access_time,
                label: 'Submission Deadline',
                value: _formatDateTime(event.submissionDeadline!),
                color: Colors.orange,
                subtitle: _getDeadlineStatus(event),
              ),
            ],
            
            if (event.startTime == null && event.endTime == null) ...[
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Event not scheduled yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccessSection(BuildContext context, Event event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Access Control',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Icon(
                  event.isOpenEvent ? Icons.public : Icons.group,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.isOpenEvent ? 'Open Event' : 'Restricted Event',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        event.isOpenEvent
                            ? 'All teams in the group can participate'
                            : 'Only ${event.eligibleTeamIds?.length ?? 0} selected team(s) can participate',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJudgingSection(BuildContext context, Event event) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Judging Criteria',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...event.judgingCriteria.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Event event) {
    return Column(
      children: [
        if (event.status == EventStatus.draft) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _scheduleEvent(context, ref, event),
              icon: const Icon(Icons.schedule),
              label: const Text('Schedule Event'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        if (event.status == EventStatus.scheduled) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _activateEvent(context, ref, event),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Activate Event'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        if (event.status == EventStatus.active) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _completeEvent(context, ref, event),
              icon: const Icon(Icons.check_circle),
              label: const Text('Complete Event'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _editEvent(context, event),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Event'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, Event event) {
    final (color, backgroundColor) = _getStatusColors(context, event);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusLabel(event.status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScreen(BuildContext context, Object error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: Center(
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
              'Error loading event',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64),
            SizedBox(height: 16),
            Text('Event not found'),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, Event event, String action) {
    switch (action) {
      case 'edit':
        _editEvent(context, event);
        break;
      case 'schedule':
        _scheduleEvent(context, ref, event);
        break;
      case 'activate':
        _activateEvent(context, ref, event);
        break;
      case 'complete':
        _completeEvent(context, ref, event);
        break;
      case 'clone':
        _cloneEvent(context, ref, event);
        break;
      case 'access':
        _manageAccess(context, event);
        break;
      case 'prerequisites':
        _managePrerequisites(context, event);
        break;
      case 'delete':
        _deleteEvent(context, ref, event);
        break;
    }
  }

  void _editEvent(BuildContext context, Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(
          groupId: event.groupId,
          eventToEdit: event,
        ),
      ),
    );
  }

  void _scheduleEvent(BuildContext context, WidgetRef ref, Event event) {
    // This would open a scheduling dialog
    // For now, we'll show a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Event'),
        content: const Text('Event scheduling dialog would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  Future<void> _activateEvent(BuildContext context, WidgetRef ref, Event event) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Activate Event',
      'Are you sure you want to activate this event? This will make it available for submissions.',
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(eventServiceProvider).activateEvent(event.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event activated successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to activate event: $e')),
          );
        }
      }
    }
  }

  Future<void> _completeEvent(BuildContext context, WidgetRef ref, Event event) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Complete Event',
      'Are you sure you want to complete this event? This will close submissions and finalize results.',
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(eventServiceProvider).completeEvent(event.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event completed successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to complete event: $e')),
          );
        }
      }
    }
  }

  Future<void> _cloneEvent(BuildContext context, WidgetRef ref, Event event) async {
    final result = await Navigator.of(context).push<Event>(
      MaterialPageRoute(
        builder: (context) => CloneEventScreen(originalEvent: event),
      ),
    );

    if (result != null && context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => EventDetailScreen(eventId: result.id),
        ),
      );
    }
  }

  void _manageAccess(BuildContext context, Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventAccessScreen(event: event),
      ),
    );
  }

  void _managePrerequisites(BuildContext context, Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventPrerequisitesScreen(event: event),
      ),
    );
  }

  Future<void> _deleteEvent(BuildContext context, WidgetRef ref, Event event) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'Delete Event',
      'Are you sure you want to delete this event? This action cannot be undone.',
      destructive: true,
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(eventServiceProvider).deleteEvent(event.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete event: $e')),
          );
        }
      }
    }
  }

  Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String content, {
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: destructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _getDeadlineStatus(Event event) {
    final timeUntil = event.timeUntilDeadline;
    if (timeUntil == null) {
      return 'Deadline passed';
    }
    return '${_formatDuration(timeUntil)} remaining';
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.competition:
        return Icons.emoji_events;
      case EventType.challenge:
        return Icons.flag;
      case EventType.survey:
        return Icons.poll;
    }
  }

  String _getEventTypeLabel(EventType type) {
    switch (type) {
      case EventType.competition:
        return 'Competition';
      case EventType.challenge:
        return 'Challenge';
      case EventType.survey:
        return 'Survey';
    }
  }

  String _getStatusLabel(EventStatus status) {
    switch (status) {
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

  (Color, Color) _getStatusColors(BuildContext context, Event event) {
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
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${_formatTime(dateTime)}';
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
}