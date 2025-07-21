import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/event_providers.dart';

/// Screen for managing event prerequisites and gating logic
class EventPrerequisitesScreen extends ConsumerStatefulWidget {
  final Event event;

  const EventPrerequisitesScreen({
    super.key,
    required this.event,
  });

  @override
  ConsumerState<EventPrerequisitesScreen> createState() => _EventPrerequisitesScreenState();
}

class _EventPrerequisitesScreenState extends ConsumerState<EventPrerequisitesScreen> {
  late List<String> _prerequisiteEventIds;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final prerequisites = widget.event.getJudgingCriterion<List<dynamic>>('prerequisites');
    _prerequisiteEventIds = prerequisites?.cast<String>() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final groupEventsAsync = ref.watch(groupEventsProvider(widget.event.groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Prerequisites'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Info Card
            _buildEventInfoCard(),
            
            const SizedBox(height: 24),
            
            // Prerequisites Explanation
            _buildExplanationCard(),
            
            const SizedBox(height: 24),
            
            // Prerequisites Management
            groupEventsAsync.when(
              data: (events) => _buildPrerequisitesSection(events),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorCard(error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getEventTypeIcon(widget.event.eventType),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.event.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.event.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'About Prerequisites',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Prerequisites control which teams can access this event. Teams must complete all prerequisite events before they can participate in this event.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '• Only completed events can be set as prerequisites\n'
              '• Teams must have submitted to prerequisite events\n'
              '• Prerequisites are checked in real-time',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrerequisitesSection(List<Event> allEvents) {
    // Filter out the current event and only show completed events
    final availableEvents = allEvents
        .where((event) => 
            event.id != widget.event.id && 
            event.status == EventStatus.completed)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Prerequisites
        _buildCurrentPrerequisites(allEvents),
        
        const SizedBox(height: 24),
        
        // Add Prerequisites
        _buildAddPrerequisites(availableEvents),
      ],
    );
  }

  Widget _buildCurrentPrerequisites(List<Event> allEvents) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Prerequisites',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_prerequisiteEventIds.length} event${_prerequisiteEventIds.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_prerequisiteEventIds.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.public,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No prerequisites set - all teams can access this event',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ..._prerequisiteEventIds.map((eventId) {
                final event = allEvents.firstWhere(
                  (e) => e.id == eventId,
                  orElse: () => Event(
                    id: eventId,
                    groupId: widget.event.groupId,
                    title: 'Unknown Event',
                    description: 'Event not found',
                    eventType: EventType.competition,
                    createdBy: '',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      _getEventTypeIcon(event.eventType),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(event.title),
                    subtitle: Text(_getStatusLabel(event.status)),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setState(() {
                          _prerequisiteEventIds.remove(eventId);
                          _hasChanges = true;
                        });
                      },
                      tooltip: 'Remove prerequisite',
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddPrerequisites(List<Event> availableEvents) {
    final unselectedEvents = availableEvents
        .where((event) => !_prerequisiteEventIds.contains(event.id))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Prerequisites',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (unselectedEvents.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No completed events available to add as prerequisites',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                'Select completed events to add as prerequisites:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              
              const SizedBox(height: 12),
              
              ...unselectedEvents.map((event) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      _getEventTypeIcon(event.eventType),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(event.title),
                    subtitle: Text('${_getStatusLabel(event.status)} • ${_formatDateTime(event.updatedAt)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: () {
                        setState(() {
                          _prerequisiteEventIds.add(event.id);
                          _hasChanges = true;
                        });
                      },
                      tooltip: 'Add as prerequisite',
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final (color, backgroundColor) = _getStatusColors();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusLabel(widget.event.status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildErrorCard(Object error) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Error loading events: $error',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(eventServiceProvider).setEventPrerequisites(
        widget.event.id,
        prerequisiteEventIds: _prerequisiteEventIds.isEmpty ? null : _prerequisiteEventIds,
      );

      if (mounted) {
        setState(() {
          _hasChanges = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prerequisites updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update prerequisites: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  (Color, Color) _getStatusColors() {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (widget.event.status) {
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
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}