import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event.dart';
import '../../providers/event_providers.dart';
import '../../providers/deadline_providers.dart';
import '../submissions/widgets/deadline_status_widget.dart';
import '../submissions/widgets/deadline_countdown_widget.dart';

/// Screen for administrators to monitor and manage submission deadlines
class DeadlineManagementScreen extends ConsumerStatefulWidget {
  final String groupId;

  const DeadlineManagementScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<DeadlineManagementScreen> createState() => _DeadlineManagementScreenState();
}

class _DeadlineManagementScreenState extends ConsumerState<DeadlineManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final deadlineMonitoringState = ref.watch(deadlineMonitoringProvider);
    final upcomingDeadlinesAsync = ref.watch(upcomingDeadlineEventsProvider(
      UpcomingDeadlineParams(groupId: widget.groupId, daysAhead: 7),
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deadline Management'),
        actions: [
          // Monitoring toggle
          Switch(
            value: deadlineMonitoringState.isMonitoring,
            onChanged: (value) {
              if (value) {
                ref.read(deadlineMonitoringProvider.notifier).startMonitoring();
              } else {
                ref.read(deadlineMonitoringProvider.notifier).stopMonitoring();
              }
            },
          ),
          const SizedBox(width: 8),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(upcomingDeadlineEventsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Monitoring status card
          _buildMonitoringStatusCard(deadlineMonitoringState),
          
          // Events with upcoming deadlines
          Expanded(
            child: upcomingDeadlinesAsync.when(
              data: (events) => _buildEventsList(events),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorWidget(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringStatusCard(DeadlineMonitoringState state) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  state.isMonitoring ? Icons.monitor_heart : Icons.monitor_heart_outlined,
                  color: state.isMonitoring ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Deadline Monitoring',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: state.isMonitoring ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state.isMonitoring ? Colors.green : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    state.isMonitoring ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: state.isMonitoring ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              state.isMonitoring
                  ? 'Automatically monitoring deadlines and sending notifications'
                  : 'Deadline monitoring is disabled',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Error: ${state.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(deadlineMonitoringProvider.notifier).clearError();
                      },
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              ),
            ],
            if (state.isLoading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(List<Event> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No upcoming deadlines',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Events with deadlines in the next 7 days will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(Event event) {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (event.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.description,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                DeadlineStatusWidget(
                  event: event,
                  showTime: true,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Deadline countdown
            DeadlineCountdownWidget(
              event: event,
              compact: true,
            ),
            
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _viewSubmissions(event),
                  icon: const Icon(Icons.list, size: 16),
                  label: const Text('View Submissions'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _editEvent(event),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Event'),
                ),
                const Spacer(),
                if (event.submissionDeadline != null)
                  TextButton.icon(
                    onPressed: () => _extendDeadline(event),
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text('Extend'),
                  ),
              ],
            ),
          ],
        ),
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
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(upcomingDeadlineEventsProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _viewSubmissions(Event event) {
    // Navigate to submissions list for this event
    // This would be implemented based on your navigation structure
    print('View submissions for event: ${event.title}');
  }

  void _editEvent(Event event) {
    // Navigate to event edit screen
    // This would be implemented based on your navigation structure
    print('Edit event: ${event.title}');
  }

  void _extendDeadline(Event event) {
    // Show dialog to extend deadline
    _showExtendDeadlineDialog(event);
  }

  Future<void> _showExtendDeadlineDialog(Event event) async {
    final currentDeadline = event.submissionDeadline;
    if (currentDeadline == null) return;

    DateTime? newDeadline = currentDeadline;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Extend Deadline for ${event.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current deadline: ${_formatDateTime(currentDeadline)}'),
            const SizedBox(height: 16),
            const Text('Select new deadline:'),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  ListTile(
                    title: const Text('Extend by 1 hour'),
                    onTap: () {
                      newDeadline = currentDeadline.add(const Duration(hours: 1));
                      Navigator.of(context).pop(newDeadline);
                    },
                  ),
                  ListTile(
                    title: const Text('Extend by 4 hours'),
                    onTap: () {
                      newDeadline = currentDeadline.add(const Duration(hours: 4));
                      Navigator.of(context).pop(newDeadline);
                    },
                  ),
                  ListTile(
                    title: const Text('Extend by 1 day'),
                    onTap: () {
                      newDeadline = currentDeadline.add(const Duration(days: 1));
                      Navigator.of(context).pop(newDeadline);
                    },
                  ),
                  ListTile(
                    title: const Text('Custom date/time'),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: currentDeadline.add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(currentDeadline),
                        );
                        
                        if (time != null) {
                          newDeadline = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                          Navigator.of(context).pop(newDeadline);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _updateEventDeadline(event, result);
    }
  }

  Future<void> _updateEventDeadline(Event event, DateTime newDeadline) async {
    try {
      final eventService = ref.read(eventServiceProvider);
      await eventService.updateEventSchedule(
        event.id,
        submissionDeadline: newDeadline,
      );
      
      // Refresh the events list
      ref.invalidate(upcomingDeadlineEventsProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deadline extended to ${_formatDateTime(newDeadline)}'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update deadline: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}