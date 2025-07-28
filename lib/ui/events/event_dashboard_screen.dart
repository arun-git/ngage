import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event.dart';
import '../../models/enums.dart';
import '../../providers/event_providers.dart';
import '../../providers/event_submission_integration_providers.dart';
import '../../services/event_submission_integration_service.dart';
import '../submissions/widgets/deadline_notification_widget.dart';
import '../admin/deadline_management_screen.dart';
import 'widgets/event_card_with_submissions.dart';

/// Enhanced event dashboard that shows events with submission integration
class EventDashboardScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? teamId; // If provided, shows team-specific view
  final bool isAdminView;

  const EventDashboardScreen({
    super.key,
    required this.groupId,
    this.teamId,
    this.isAdminView = false,
  });

  @override
  ConsumerState<EventDashboardScreen> createState() =>
      _EventDashboardScreenState();
}

class _EventDashboardScreenState extends ConsumerState<EventDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EventStatus _selectedStatus = EventStatus.active;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: widget.isAdminView ? 4 : 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdminView ? 'Event Management' : 'Events'),
        actions: [
          if (widget.isAdminView) ...[
            IconButton(
              icon: const Icon(Icons.schedule),
              onPressed: () => _openDeadlineManagement(context),
              tooltip: 'Deadline Management',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Active'),
            const Tab(text: 'Scheduled'),
            const Tab(text: 'Completed'),
            if (widget.isAdminView) const Tab(text: 'Attention'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Deadline notifications
          if (!widget.isAdminView) _buildDeadlineNotifications(),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEventsList(EventStatus.active),
                _buildEventsList(EventStatus.scheduled),
                _buildEventsList(EventStatus.completed),
                if (widget.isAdminView) _buildAttentionList(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isAdminView
          ? FloatingActionButton(
              onPressed: () => _createNewEvent(context),
              tooltip: 'Create Event',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDeadlineNotifications() {
    final upcomingDeadlinesAsync = ref.watch(upcomingDeadlineEventsProvider(
      UpcomingDeadlineParams(groupId: widget.groupId, daysAhead: 1),
    ));

    return upcomingDeadlinesAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();

        return DeadlineNotificationWidget(
          events: events,
          onTap: () => _openDeadlineManagement(context),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEventsList(EventStatus status) {
    if (widget.teamId != null) {
      return _buildTeamEventsList();
    } else {
      return _buildGeneralEventsList(status);
    }
  }

  Widget _buildGeneralEventsList(EventStatus status) {
    final eventsAsync = ref.watch(eventsByStatusProvider(EventsByStatusParams(
      groupId: widget.groupId,
      status: status,
    )));

    return eventsAsync.when(
      data: (events) => _buildEventsListView(events),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error),
    );
  }

  Widget _buildTeamEventsList() {
    final eventsWithStatusAsync =
        ref.watch(eventsWithSubmissionStatusForTeamProvider((
      groupId: widget.groupId,
      teamId: widget.teamId!,
    )));

    return eventsWithStatusAsync.when(
      data: (eventsWithStatus) {
        // Filter by current tab status
        final filteredEvents = eventsWithStatus
            .where((eventWithStatus) =>
                eventWithStatus.event.status == _getSelectedStatus())
            .toList();

        return _buildTeamEventsListView(filteredEvents);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error),
    );
  }

  Widget _buildAttentionList() {
    final attentionEventsAsync =
        ref.watch(eventsThatNeedAttentionProvider(widget.groupId));

    return attentionEventsAsync.when(
      data: (attentionEvents) => _buildAttentionEventsListView(attentionEvents),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error),
    );
  }

  Widget _buildEventsListView(List<Event> events) {
    if (events.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return EventCardWithSubmissions(
            event: event,
            isAdminView: widget.isAdminView,
            onTap: () => _openEventDetails(event),
          );
        },
      ),
    );
  }

  Widget _buildTeamEventsListView(
      List<EventWithTeamSubmissionStatus> eventsWithStatus) {
    if (eventsWithStatus.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: eventsWithStatus.length,
        itemBuilder: (context, index) {
          final eventWithStatus = eventsWithStatus[index];
          return EventCardWithSubmissions(
            event: eventWithStatus.event,
            teamId: widget.teamId,
            onTap: () => _openEventDetails(eventWithStatus.event),
          );
        },
      ),
    );
  }

  Widget _buildAttentionEventsListView(
      List<EventNeedingAttention> attentionEvents) {
    if (attentionEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'All events are running smoothly!',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No events require immediate attention',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: attentionEvents.length,
        itemBuilder: (context, index) {
          final attentionEvent = attentionEvents[index];
          return _buildAttentionEventCard(attentionEvent);
        },
      ),
    );
  }

  Widget _buildAttentionEventCard(EventNeedingAttention attentionEvent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event header
            Row(
              children: [
                Expanded(
                  child: Text(
                    attentionEvent.event.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Icon(
                  Icons.warning,
                  color: Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Attention reasons
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: attentionEvent.reasons.map((reason) {
                return _buildAttentionReasonChip(context, reason);
              }).toList(),
            ),

            const SizedBox(height: 8),

            // Statistics
            Row(
              children: [
                Text(
                  'Submissions: ${attentionEvent.submissionCount}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (attentionEvent.pendingReviewCount > 0) ...[
                  const SizedBox(width: 16),
                  Text(
                    'Pending Reviews: ${attentionEvent.pendingReviewCount}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                        ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _openEventDetails(attentionEvent.event),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Event'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _viewSubmissions(attentionEvent.event),
                  icon: const Icon(Icons.list, size: 16),
                  label: const Text('View Submissions'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionReasonChip(
      BuildContext context, AttentionReason reason) {
    Color color;
    String label;
    IconData icon;

    switch (reason) {
      case AttentionReason.approachingDeadline:
        color = Colors.orange;
        label = 'Deadline Approaching';
        icon = Icons.schedule;
        break;
      case AttentionReason.pendingReviews:
        color = Colors.purple;
        label = 'Pending Reviews';
        icon = Icons.pending;
        break;
      case AttentionReason.lowSubmissionCount:
        color = Colors.red;
        label = 'Low Submissions';
        icon = Icons.trending_down;
        break;
      case AttentionReason.overdueReviews:
        color = Colors.red;
        label = 'Overdue Reviews';
        icon = Icons.access_time;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final statusName = _getSelectedStatus().value.replaceAll('_', ' ');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No $statusName events',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            widget.isAdminView
                ? 'Create your first event to get started'
                : 'Check back later for new events',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          if (widget.isAdminView) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _createNewEvent(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load events',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          SelectableText(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _refreshData(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  EventStatus _getSelectedStatus() {
    switch (_tabController.index) {
      case 0:
        return EventStatus.active;
      case 1:
        return EventStatus.scheduled;
      case 2:
        return EventStatus.completed;
      default:
        return EventStatus.active;
    }
  }

  void _refreshData() {
    // Invalidate all relevant providers to refresh data
    ref.invalidate(eventsByStatusProvider);
    ref.invalidate(eventsWithSubmissionStatusForTeamProvider);
    ref.invalidate(eventsThatNeedAttentionProvider);
    ref.invalidate(upcomingDeadlineEventsProvider);
  }

  void _openEventDetails(Event event) {
    // Navigate to event details screen
    // This would be implemented based on your navigation structure
    // You would navigate to EventDetailInnerPage here
    print('Open event details: ${event.title}');
  }

  void _viewSubmissions(Event event) {
    // Navigate to submissions list for this event
    // This would be implemented based on your navigation structure
    print('View submissions for event: ${event.title}');
  }

  void _createNewEvent(BuildContext context) {
    // Navigate to event creation screen
    // This would be implemented based on your navigation structure
    print('Create new event');
  }

  void _openDeadlineManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeadlineManagementScreen(
          groupId: widget.groupId,
        ),
      ),
    );
  }
}
