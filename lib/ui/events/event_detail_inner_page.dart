import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/event_providers.dart';
import '../../providers/event_submission_integration_providers.dart';
import '../../services/event_submission_integration_service.dart';
import '../widgets/event_banner_image.dart';
import '../widgets/robust_network_image.dart';
import '../submissions/widgets/deadline_countdown_widget.dart';
import '../submissions/widgets/deadline_status_widget.dart';
import '../submissions/submissions_list_screen.dart';
import '../../services/submission_navigation_service.dart';

import 'create_event_inner_page.dart';
import 'clone_event_screen.dart';
import 'event_access_screen.dart';
import 'event_prerequisites_screen.dart';

/// Inner page showing event details that replaces the group content
class EventDetailInnerPage extends ConsumerWidget {
  final String eventId;
  final String groupName;
  final VoidCallback onBack;

  const EventDetailInnerPage({
    super.key,
    required this.eventId,
    required this.groupName,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventStreamProvider(eventId));

    return eventAsync.when(
      data: (event) {
        if (event == null) {
          return _buildNotFoundContent(context);
        }
        return _buildEventDetailContent(context, ref, event);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorContent(context, error),
    );
  }

  Widget _buildEventDetailContent(
      BuildContext context, WidgetRef ref, Event event) {
    return Column(
      children: [
        // Event content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner image if available
                if (event.bannerImageUrl != null) ...[
                  Container(
                    width: double.infinity,
                    height: 200,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: EventBannerImage(
                        imageUrl: event.bannerImageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],

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

                // Submissions Section
                _buildSubmissionsSection(context, ref, event),
                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(context, ref, event),
              ],
            ),
          ),
        ),
      ],
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
              Row(
                children: [
                  Expanded(
                    child: _buildScheduleItem(
                      context,
                      icon: Icons.access_time,
                      label: 'Submission Deadline',
                      value: _formatDateTime(event.submissionDeadline!),
                      color: Colors.orange,
                      subtitle: _getDeadlineStatus(event),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DeadlineStatusWidget(
                    event: event,
                    showTime: false,
                  ),
                ],
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

  Widget _buildSubmissionsSection(
      BuildContext context, WidgetRef ref, Event event) {
    final eventStatsAsync =
        ref.watch(eventWithSubmissionStatsProvider(event.id));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Submissions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _viewAllSubmissions(context, event),
                  icon: const Icon(Icons.list, size: 16),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Deadline countdown if active
            if (event.submissionDeadline != null &&
                event.status == EventStatus.active) ...[
              DeadlineCountdownWidget(
                event: event,
                compact: true,
              ),
              const SizedBox(height: 16),
            ],

            // Submission statistics
            eventStatsAsync.when(
              data: (stats) => _buildSubmissionStatistics(context, stats),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Error loading submissions: $error',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewAllSubmissions(context, event),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Submissions'),
                  ),
                ),
                const SizedBox(width: 8),
                if (event.status == EventStatus.active)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _createSubmission(context, event),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Submit Entry'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionStatistics(
      BuildContext context, EventWithSubmissionStats stats) {
    return Column(
      children: [
        // Overview row
        Row(
          children: [
            _buildStatItem(
              context,
              'Total',
              stats.totalSubmissions.toString(),
              Icons.assignment,
              Colors.blue,
            ),
            const SizedBox(width: 16),
            _buildStatItem(
              context,
              'Submitted',
              stats.submittedSubmissions.toString(),
              Icons.send,
              Colors.green,
            ),
            const SizedBox(width: 16),
            _buildStatItem(
              context,
              'Draft',
              stats.draftSubmissions.toString(),
              Icons.edit,
              Colors.orange,
            ),
          ],
        ),

        // Review status row (if there are submissions under review)
        if (stats.underReviewSubmissions > 0 ||
            stats.approvedSubmissions > 0 ||
            stats.rejectedSubmissions > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                context,
                'Under Review',
                stats.underReviewSubmissions.toString(),
                Icons.hourglass_empty,
                Colors.purple,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                context,
                'Approved',
                stats.approvedSubmissions.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                context,
                'Rejected',
                stats.rejectedSubmissions.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ],
          ),
        ],

        // Progress indicator
        if (stats.totalSubmissions > 0) ...[
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Submission Progress',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  Text(
                    '${(stats.submissionRate * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: stats.submissionRate,
                backgroundColor:
                    Theme.of(context).colorScheme.outline.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  stats.submissionRate > 0.7 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _viewAllSubmissions(BuildContext context, Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubmissionsListScreen(
          eventId: event.id,
          isJudgeView: true,
        ),
      ),
    );
  }

  void _createSubmission(BuildContext context, Event event) {
    // In a real app, you'd get the current user's team ID and member ID from auth state
    SubmissionNavigationService.showSubmissionActionDialog(
      context,
      event: event,
      teamId: 'current_team_id', // This should come from current user's team
      memberId: 'current_member_id', // This should come from auth state
    );
  }

  void _manageSubmissions(BuildContext context, Event event) {
    // Navigate to submission management screen
    // This could be a more advanced management interface
    _viewAllSubmissions(context, event);
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
        /*SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _editEvent(context, event),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Event'),
          ),
        ),*/
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

  Widget _buildNotFoundContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 64),
          const SizedBox(height: 16),
          const Text('Event not found'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onBack,
            child: const Text('Back to Events'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, Object error) {
    return Center(
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onBack,
            child: const Text('Back to Events'),
          ),
        ],
      ),
    );
  }

  /*void _handleMenuAction(
      BuildContext context, WidgetRef ref, Event event, String action) {
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
        builder: (context) => CreateEventInnerPage(
          groupId: event.groupId,
          groupName: groupName,
          eventToEdit: event,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }*/

  void _scheduleEvent(BuildContext context, WidgetRef ref, Event event) {
    showDialog(
      context: context,
      builder: (context) => _ScheduleEventDialog(
        event: event,
        onScheduled: () {
          // Refresh the event data after scheduling
          ref.invalidate(eventProvider(event.id));
        },
      ),
    );
  }

  Future<void> _activateEvent(
      BuildContext context, WidgetRef ref, Event event) async {
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

  Future<void> _completeEvent(
      BuildContext context, WidgetRef ref, Event event) async {
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

  Future<void> _cloneEvent(
      BuildContext context, WidgetRef ref, Event event) async {
    final result = await Navigator.of(context).push<Event>(
      MaterialPageRoute(
        builder: (context) => CloneEventScreen(originalEvent: event),
      ),
    );

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event cloned successfully')),
      );
      // Navigate back and let the parent handle showing the cloned event
      onBack();
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

  Future<void> _deleteEvent(
      BuildContext context, WidgetRef ref, Event event) async {
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
          onBack();
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

/// Enhanced Schedule Event Dialog with better UX and validation
class _ScheduleEventDialog extends ConsumerStatefulWidget {
  final Event event;
  final VoidCallback? onScheduled;

  const _ScheduleEventDialog({
    required this.event,
    this.onScheduled,
  });

  @override
  ConsumerState<_ScheduleEventDialog> createState() =>
      _ScheduleEventDialogState();
}

class _ScheduleEventDialogState extends ConsumerState<_ScheduleEventDialog> {
  late DateTime startTime;
  late DateTime endTime;
  DateTime? submissionDeadline;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    // Initialize with existing times or smart defaults
    startTime = widget.event.startTime ?? now.add(const Duration(hours: 1));
    endTime = widget.event.endTime ?? startTime.add(const Duration(hours: 2));
    submissionDeadline = widget.event.submissionDeadline;

    // Ensure end time is after start time
    if (endTime.isBefore(startTime)) {
      endTime = startTime.add(const Duration(hours: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.schedule, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Schedule Event'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getEventTypeLabel(widget.event.eventType).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Start time
              _buildDateTimeField(
                context,
                label: 'Start Time',
                value: startTime,
                onChanged: (newTime) {
                  setState(() {
                    startTime = newTime;
                    // Ensure end time is after start time
                    if (endTime.isBefore(startTime)) {
                      endTime = startTime.add(const Duration(hours: 2));
                    }
                    _errorMessage = null;
                  });
                },
                icon: Icons.play_arrow,
                color: Colors.green,
              ),

              const SizedBox(height: 16),

              // End time
              _buildDateTimeField(
                context,
                label: 'End Time',
                value: endTime,
                onChanged: (newTime) {
                  setState(() {
                    endTime = newTime;
                    _errorMessage = null;
                  });
                },
                icon: Icons.stop,
                color: Colors.red,
              ),

              const SizedBox(height: 16),

              // Submission deadline (optional)
              _buildOptionalDateTimeField(
                context,
                label: 'Submission Deadline (Optional)',
                value: submissionDeadline,
                onChanged: (newTime) {
                  setState(() {
                    submissionDeadline = newTime;
                    _errorMessage = null;
                  });
                },
                onCleared: () {
                  setState(() {
                    submissionDeadline = null;
                    _errorMessage = null;
                  });
                },
                icon: Icons.access_time,
                color: Colors.orange,
              ),

              const SizedBox(height: 20),

              // Validation info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Scheduling Rules',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• End time must be after start time\n'
                      '• Submission deadline (if set) should be before or at end time\n'
                      '• All times are in your local timezone',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _scheduleEvent,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Schedule'),
        ),
      ],
    );
  }

  Widget _buildDateTimeField(
    BuildContext context, {
    required String label,
    required DateTime value,
    required Function(DateTime) onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDateTime(context, value, onChanged),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatDateTime(value),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionalDateTimeField(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required Function(DateTime) onChanged,
    required VoidCallback onCleared,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            if (value != null)
              IconButton(
                onPressed: onCleared,
                icon: const Icon(Icons.clear, size: 16),
                tooltip: 'Clear deadline',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            if (value != null) {
              _selectDateTime(context, value!, onChanged);
            } else {
              // Set default to end time if not set
              _selectDateTime(context, endTime, onChanged);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value != null ? _formatDateTime(value!) : 'Tap to set deadline',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: value != null ? null : Colors.grey.shade600,
                    fontStyle: value != null ? null : FontStyle.italic,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateTime(
    BuildContext context,
    DateTime initialValue,
    Function(DateTime) onChanged,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialValue,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialValue),
      );

      if (time != null) {
        final newDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        onChanged(newDateTime);
      }
    }
  }

  Future<void> _scheduleEvent() async {
    // Validate times
    if (endTime.isBefore(startTime)) {
      setState(() {
        _errorMessage = 'End time must be after start time';
      });
      return;
    }

    if (submissionDeadline != null && submissionDeadline!.isAfter(endTime)) {
      setState(() {
        _errorMessage = 'Submission deadline should be before or at end time';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(eventServiceProvider).scheduleEvent(
            widget.event.id,
            startTime: startTime,
            endTime: endTime,
            submissionDeadline: submissionDeadline,
          );

      if (mounted) {
        widget.onScheduled?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event scheduled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to schedule event: $e';
          _isLoading = false;
        });
      }
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
}
