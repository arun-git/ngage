import '../models/models.dart';
import 'event_service.dart';

/// Service for managing automatic event status transitions
/// 
/// Handles the logic for determining appropriate event status based on
/// date ranges and current time.
class EventStatusManager {
  final EventService _eventService;

  EventStatusManager({EventService? eventService})
      : _eventService = eventService ?? EventService();

  /// Determine the appropriate status for an event based on its date range
  EventStatus determineAppropriateStatus(Event event) {
    final now = DateTime.now();
    
    // If no start/end times are set, keep as draft
    if (event.startTime == null || event.endTime == null) {
      return EventStatus.draft;
    }
    
    final startTime = event.startTime!;
    final endTime = event.endTime!;
    
    // If event has ended, it should be completed
    if (now.isAfter(endTime)) {
      return EventStatus.completed;
    }
    
    // If event has started but not ended, it should be active
    if (now.isAfter(startTime) && now.isBefore(endTime)) {
      return EventStatus.active;
    }
    
    // If event is scheduled for the future, it should be scheduled
    if (now.isBefore(startTime)) {
      return EventStatus.scheduled;
    }
    
    // Default fallback
    return EventStatus.draft;
  }

  /// Move a draft event to the appropriate status based on its date range
  Future<Event> promoteDraftEvent(String eventId) async {
    final event = await _eventService.getEventById(eventId);
    if (event == null) {
      throw EventNotFoundException('Event not found: $eventId');
    }

    // Only promote draft events
    if (event.status != EventStatus.draft) {
      throw EventOperationException(
        'Can only promote draft events. Current status: ${event.status.value}'
      );
    }

    final appropriateStatus = determineAppropriateStatus(event);
    
    // If the appropriate status is still draft, no change needed
    if (appropriateStatus == EventStatus.draft) {
      return event;
    }

    // Update the event status
    return await _eventService.updateEventStatus(eventId, appropriateStatus);
  }

  /// Bulk promote multiple draft events
  Future<List<Event>> promoteDraftEvents(List<String> eventIds) async {
    final promotedEvents = <Event>[];
    
    for (final eventId in eventIds) {
      try {
        final promotedEvent = await promoteDraftEvent(eventId);
        promotedEvents.add(promotedEvent);
      } catch (e) {
        // Log error but continue with other events
        print('Failed to promote event $eventId: $e');
      }
    }
    
    return promotedEvents;
  }

  /// Schedule a draft event with specific date/time
  Future<Event> scheduleDraftEvent(
    String eventId, {
    required DateTime startTime,
    required DateTime endTime,
    DateTime? submissionDeadline,
  }) async {
    // First schedule the event (this will set it to scheduled status)
    final scheduledEvent = await _eventService.scheduleEvent(
      eventId,
      startTime: startTime,
      endTime: endTime,
      submissionDeadline: submissionDeadline,
    );

    // Then check if it should be promoted to active based on current time
    final appropriateStatus = determineAppropriateStatus(scheduledEvent);
    
    if (appropriateStatus != scheduledEvent.status) {
      return await _eventService.updateEventStatus(eventId, appropriateStatus);
    }
    
    return scheduledEvent;
  }

  /// Check if an event needs status update based on current time
  bool needsStatusUpdate(Event event) {
    final appropriateStatus = determineAppropriateStatus(event);
    return appropriateStatus != event.status;
  }

  /// Get all events that need status updates
  Future<List<Event>> getEventsNeedingStatusUpdate(String groupId) async {
    final allEvents = await _eventService.getGroupEvents(groupId);
    
    return allEvents.where((event) => needsStatusUpdate(event)).toList();
  }

  /// Automatically update all events that need status changes
  Future<List<Event>> autoUpdateEventStatuses(String groupId) async {
    final eventsNeedingUpdate = await getEventsNeedingStatusUpdate(groupId);
    final updatedEvents = <Event>[];
    
    for (final event in eventsNeedingUpdate) {
      try {
        final appropriateStatus = determineAppropriateStatus(event);
        final updatedEvent = await _eventService.updateEventStatus(
          event.id, 
          appropriateStatus
        );
        updatedEvents.add(updatedEvent);
      } catch (e) {
        print('Failed to update event ${event.id}: $e');
      }
    }
    
    return updatedEvents;
  }

  /// Validate that an event can be promoted from draft
  bool canPromoteFromDraft(Event event) {
    if (event.status != EventStatus.draft) return false;
    if (event.startTime == null || event.endTime == null) return false;
    
    // Additional validation rules can be added here
    return true;
  }
}

/// Extension methods for Event to make status management easier
extension EventStatusExtensions on Event {
  /// Check if this event can be promoted from draft status
  bool get canBePromoted => EventStatusManager().canPromoteFromDraft(this);
  
  /// Get the appropriate status for this event based on current time
  EventStatus get appropriateStatus => EventStatusManager().determineAppropriateStatus(this);
  
  /// Check if this event needs a status update
  bool get needsStatusUpdate => EventStatusManager().needsStatusUpdate(this);
}