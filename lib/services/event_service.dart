import '../models/models.dart';
import '../repositories/event_repository.dart';

/// Service for event business logic and operations
/// 
/// Handles event lifecycle management, validation, and business rules.
/// Provides high-level operations for event management.
class EventService {
  final EventRepository _eventRepository;

  EventService({EventRepository? eventRepository})
      : _eventRepository = eventRepository ?? EventRepository();

  /// Create a new event
  Future<Event> createEvent({
    required String groupId,
    required String title,
    required String description,
    required EventType eventType,
    required String createdBy,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? submissionDeadline,
    List<String>? eligibleTeamIds,
    Map<String, dynamic>? judgingCriteria,
  }) async {
    // Generate unique ID
    final eventId = _generateEventId();
    final now = DateTime.now();

    // Create event object
    final event = Event(
      id: eventId,
      groupId: groupId,
      title: title.trim(),
      description: description.trim(),
      eventType: eventType,
      status: EventStatus.draft,
      startTime: startTime,
      endTime: endTime,
      submissionDeadline: submissionDeadline,
      eligibleTeamIds: eligibleTeamIds,
      judgingCriteria: judgingCriteria ?? {},
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );

    // Validate event
    final validation = event.validate();
    if (!validation.isValid) {
      throw ValidationException('Event validation failed', validation.errors);
    }

    // Additional business logic validation
    await _validateEventBusinessRules(event);

    // Save to repository
    await _eventRepository.createEvent(event);

    return event;
  }

  /// Get event by ID
  Future<Event?> getEventById(String eventId) async {
    return await _eventRepository.getEventById(eventId);
  }

  /// Update an existing event
  Future<Event> updateEvent(Event event) async {
    // Validate event
    final validation = event.validate();
    if (!validation.isValid) {
      throw ValidationException('Event validation failed', validation.errors);
    }

    // Additional business logic validation
    await _validateEventBusinessRules(event);

    // Update timestamp
    final updatedEvent = event.copyWith(updatedAt: DateTime.now());

    // Save to repository
    await _eventRepository.updateEvent(updatedEvent);

    return updatedEvent;
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    // Check if event exists
    final event = await _eventRepository.getEventById(eventId);
    if (event == null) {
      throw EventNotFoundException('Event not found: $eventId');
    }

    // Business rule: Can only delete draft events
    if (event.status != EventStatus.draft) {
      throw EventOperationException(
        'Cannot delete event with status: ${event.status.value}. Only draft events can be deleted.'
      );
    }

    await _eventRepository.deleteEvent(eventId);
  }

  /// Get all events for a group
  Future<List<Event>> getGroupEvents(String groupId) async {
    return await _eventRepository.getGroupEvents(groupId);
  }

  /// Schedule an event
  Future<Event> scheduleEvent(
    String eventId, {
    required DateTime startTime,
    required DateTime endTime,
    DateTime? submissionDeadline,
  }) async {
    final event = await _eventRepository.getEventById(eventId);
    if (event == null) {
      throw EventNotFoundException('Event not found: $eventId');
    }

    // Business rule: Can only schedule draft events
    if (event.status != EventStatus.draft) {
      throw EventOperationException(
        'Cannot schedule event with status: ${event.status.value}. Only draft events can be scheduled.'
      );
    }

    // Validate scheduling times
    _validateEventTimes(startTime, endTime, submissionDeadline);

    // Update event with scheduling information
    final scheduledEvent = event.copyWith(
      startTime: startTime,
      endTime: endTime,
      submissionDeadline: submissionDeadline,
      status: EventStatus.scheduled,
      updatedAt: DateTime.now(),
    );

    await _eventRepository.updateEvent(scheduledEvent);
    return scheduledEvent;
  }

  /// Update event status
  Future<Event> updateEventStatus(String eventId, EventStatus newStatus) async {
    final event = await _eventRepository.getEventById(eventId);
    if (event == null) {
      throw EventNotFoundException('Event not found: $eventId');
    }

    // Validate status transition
    _validateStatusTransition(event.status, newStatus);

    // Additional validation for specific status changes
    if (newStatus == EventStatus.active) {
      if (event.startTime == null) {
        throw EventOperationException('Cannot activate event without start time');
      }
    }

    if (newStatus == EventStatus.scheduled) {
      if (event.startTime == null || event.endTime == null) {
        throw EventOperationException('Cannot schedule event without start and end times');
      }
    }

    await _eventRepository.updateEventStatus(eventId, newStatus);
    
    return event.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  /// Activate an event
  Future<Event> activateEvent(String eventId) async {
    return await updateEventStatus(eventId, EventStatus.active);
  }

  /// Complete an event
  Future<Event> completeEvent(String eventId) async {
    return await updateEventStatus(eventId, EventStatus.completed);
  }

  /// Cancel an event
  Future<Event> cancelEvent(String eventId) async {
    return await updateEventStatus(eventId, EventStatus.cancelled);
  }

  /// Clone an event with enhanced options
  Future<Event> cloneEvent(String eventId, {
    String? newTitle,
    String? newDescription,
    String? createdBy,
    String? targetGroupId,
    List<String>? newEligibleTeamIds,
    bool preserveSchedule = false,
    bool preserveAccessControl = true,
  }) async {
    final originalEvent = await _eventRepository.getEventById(eventId);
    if (originalEvent == null) {
      throw EventNotFoundException('Event not found: $eventId');
    }

    // Determine target group (can clone to different group)
    final groupId = targetGroupId ?? originalEvent.groupId;

    // Handle access control for cross-group cloning
    List<String>? eligibleTeamIds;
    if (preserveAccessControl && targetGroupId == null) {
      // Same group - preserve original access control
      eligibleTeamIds = originalEvent.eligibleTeamIds;
    } else if (newEligibleTeamIds != null) {
      // Explicitly provided team IDs
      eligibleTeamIds = newEligibleTeamIds;
    } else {
      // Cross-group clone or reset access - make it open
      eligibleTeamIds = null;
    }

    // Create new event based on original
    final clonedEvent = await createEvent(
      groupId: groupId,
      title: newTitle ?? '${originalEvent.title} (Copy)',
      description: newDescription ?? originalEvent.description,
      eventType: originalEvent.eventType,
      createdBy: createdBy ?? originalEvent.createdBy,
      startTime: preserveSchedule ? originalEvent.startTime : null,
      endTime: preserveSchedule ? originalEvent.endTime : null,
      submissionDeadline: preserveSchedule ? originalEvent.submissionDeadline : null,
      eligibleTeamIds: eligibleTeamIds,
      judgingCriteria: Map<String, dynamic>.from(originalEvent.judgingCriteria),
    );

    return clonedEvent;
  }

  /// Update event access control
  Future<Event> updateEventAccess(String eventId, {
    List<String>? eligibleTeamIds,
  }) async {
    final event = await _eventRepository.getEventById(eventId);
    if (event == null) {
      throw EventNotFoundException('Event not found: $eventId');
    }

    // Validate team IDs exist in the group if provided
    if (eligibleTeamIds != null && eligibleTeamIds.isNotEmpty) {
      await _validateTeamEligibility(event.groupId, eligibleTeamIds);
    }

    await _eventRepository.updateEventAccess(eventId, eligibleTeamIds: eligibleTeamIds);
    
    return event.copyWith(
      eligibleTeamIds: eligibleTeamIds,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if a team can access an event
  Future<bool> canTeamAccessEvent(String eventId, String teamId) async {
    final event = await _eventRepository.getEventById(eventId);
    if (event == null) return false;
    
    return event.isTeamEligible(teamId);
  }

  /// Get teams eligible for an event
  Future<List<String>> getEligibleTeams(String eventId) async {
    final event = await _eventRepository.getEventById(eventId);
    if (event == null) {
      throw EventNotFoundException('Event not found: $eventId');
    }
    
    if (event.isOpenEvent) {
      // Return all teams in the group
      return await _eventRepository.getAllGroupTeamIds(event.groupId);
    }
    
    return event.eligibleTeamIds ?? [];
  }

  /// Set event prerequisites
  Future<Event> setEventPrerequisites(String eventId, {
    List<String>? prerequisiteEventIds,
    Map<String, dynamic>? customPrerequisites,
  }) async {
    final event = await _eventRepository.getEventById(eventId);
    if (event == null) {
      throw EventNotFoundException('Event not found: $eventId');
    }

    // Validate prerequisite events exist
    if (prerequisiteEventIds != null) {
      for (final prereqId in prerequisiteEventIds) {
        final prereqEvent = await _eventRepository.getEventById(prereqId);
        if (prereqEvent == null) {
          throw EventValidationException('Prerequisite event not found: $prereqId');
        }
        if (prereqEvent.groupId != event.groupId) {
          throw EventValidationException('Prerequisite events must be in the same group');
        }
      }
    }

    // Update judging criteria with prerequisites
    final updatedCriteria = Map<String, dynamic>.from(event.judgingCriteria);
    if (prerequisiteEventIds != null) {
      updatedCriteria['prerequisites'] = prerequisiteEventIds;
    }
    if (customPrerequisites != null) {
      updatedCriteria.addAll(customPrerequisites);
    }

    final updatedEvent = event.copyWith(
      judgingCriteria: updatedCriteria,
      updatedAt: DateTime.now(),
    );

    await _eventRepository.updateEvent(updatedEvent);
    return updatedEvent;
  }

  /// Check if a team meets event prerequisites
  Future<bool> doesTeamMeetPrerequisites(String eventId, String teamId) async {
    final event = await _eventRepository.getEventById(eventId);
    if (event == null) return false;

    final prerequisites = event.getJudgingCriterion<List<dynamic>>('prerequisites');
    if (prerequisites == null || prerequisites.isEmpty) {
      return true; // No prerequisites
    }

    // Check if team has completed all prerequisite events
    for (final prereqId in prerequisites) {
      if (prereqId is String) {
        final hasCompleted = await _eventRepository.hasTeamCompletedEvent(prereqId, teamId);
        if (!hasCompleted) {
          return false;
        }
      }
    }

    return true;
  }

  /// Get events accessible to a team (considering prerequisites and access control)
  Future<List<Event>> getAccessibleEventsForTeam(String groupId, String teamId) async {
    final allEvents = await _eventRepository.getGroupEvents(groupId);
    final accessibleEvents = <Event>[];

    for (final event in allEvents) {
      // Check basic access control
      if (!event.isTeamEligible(teamId)) {
        continue;
      }

      // Check prerequisites
      final meetsPrerequisites = await doesTeamMeetPrerequisites(event.id, teamId);
      if (!meetsPrerequisites) {
        continue;
      }

      accessibleEvents.add(event);
    }

    return accessibleEvents;
  }

  /// Get events by status
  Future<List<Event>> getEventsByStatus(String groupId, EventStatus status) async {
    return await _eventRepository.getEventsByStatus(groupId, status);
  }

  /// Get active events
  Future<List<Event>> getActiveEvents(String groupId) async {
    return await _eventRepository.getActiveEvents(groupId);
  }

  /// Get scheduled events
  Future<List<Event>> getScheduledEvents(String groupId) async {
    return await _eventRepository.getScheduledEvents(groupId);
  }

  /// Get events that a team is eligible for
  Future<List<Event>> getTeamEligibleEvents(String groupId, String teamId) async {
    return await _eventRepository.getTeamEligibleEvents(groupId, teamId);
  }

  /// Get events with upcoming deadlines
  Future<List<Event>> getEventsWithUpcomingDeadlines(String groupId, {int daysAhead = 7}) async {
    return await _eventRepository.getEventsWithUpcomingDeadlines(groupId, daysAhead: daysAhead);
  }

  /// Stream events for real-time updates
  Stream<List<Event>> streamGroupEvents(String groupId) {
    return _eventRepository.streamGroupEvents(groupId);
  }

  /// Stream a single event for real-time updates
  Stream<Event?> streamEvent(String eventId) {
    return _eventRepository.streamEvent(eventId);
  }

  /// Search events by title
  Future<List<Event>> searchEvents(String groupId, String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      return await getGroupEvents(groupId);
    }
    return await _eventRepository.searchEventsByTitle(groupId, searchTerm);
  }

  /// Update event schedule
  Future<Event> updateEventSchedule(
    String eventId, {
    DateTime? startTime,
    DateTime? endTime,
    DateTime? submissionDeadline,
  }) async {
    final event = await _eventRepository.getEventById(eventId);
    if (event == null) {
      throw EventNotFoundException('Event not found: $eventId');
    }

    // Validate new times
    final newStartTime = startTime ?? event.startTime;
    final newEndTime = endTime ?? event.endTime;
    final newSubmissionDeadline = submissionDeadline ?? event.submissionDeadline;

    if (newStartTime != null && newEndTime != null) {
      _validateEventTimes(newStartTime, newEndTime, newSubmissionDeadline);
    }

    await _eventRepository.updateEventSchedule(
      eventId,
      startTime: startTime,
      endTime: endTime,
      submissionDeadline: submissionDeadline,
    );

    return event.copyWith(
      startTime: startTime ?? event.startTime,
      endTime: endTime ?? event.endTime,
      submissionDeadline: submissionDeadline ?? event.submissionDeadline,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if submissions are currently open for an event
  Future<bool> areSubmissionsOpen(String eventId) async {
    final event = await _eventRepository.getEventById(eventId);
    if (event == null) return false;
    
    return event.areSubmissionsOpen;
  }

  /// Get time remaining until submission deadline
  Future<Duration?> getTimeUntilDeadline(String eventId) async {
    final event = await _eventRepository.getEventById(eventId);
    if (event == null) return null;
    
    return event.timeUntilDeadline;
  }

  /// Private helper methods

  /// Generate a unique event ID
  String _generateEventId() {
    return 'event_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }

  /// Generate random string for ID
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (index) => chars[random % chars.length]).join();
  }

  /// Validate event business rules
  Future<void> _validateEventBusinessRules(Event event) async {
    // Check if group exists (this would require GroupService dependency)
    // For now, we'll assume the group exists if groupId is provided
    
    // Validate eligible teams exist if specified
    if (event.eligibleTeamIds != null && event.eligibleTeamIds!.isNotEmpty) {
      await _validateTeamEligibility(event.groupId, event.eligibleTeamIds!);
    }
    
    // Additional business rules can be added here
  }

  /// Validate that teams exist in the group
  Future<void> _validateTeamEligibility(String groupId, List<String> teamIds) async {
    // This would typically validate against TeamService
    // For now, we'll delegate to the repository
    final validTeams = await _eventRepository.validateTeamsInGroup(groupId, teamIds);
    final invalidTeams = teamIds.where((id) => !validTeams.contains(id)).toList();
    
    if (invalidTeams.isNotEmpty) {
      throw EventValidationException(
        'Invalid team IDs for group $groupId: ${invalidTeams.join(', ')}'
      );
    }
  }

  /// Validate event times
  void _validateEventTimes(DateTime startTime, DateTime endTime, DateTime? submissionDeadline) {
    if (endTime.isBefore(startTime)) {
      throw EventValidationException('End time must be after start time');
    }

    if (submissionDeadline != null) {
      if (submissionDeadline.isBefore(startTime)) {
        throw EventValidationException('Submission deadline must be after start time');
      }
      if (submissionDeadline.isAfter(endTime)) {
        throw EventValidationException('Submission deadline must be before end time');
      }
    }

    // Business rule: Events must be at least 1 hour long
    if (endTime.difference(startTime).inMinutes < 60) {
      throw EventValidationException('Events must be at least 1 hour long');
    }

    // Business rule: Cannot schedule events in the past
    final now = DateTime.now();
    if (startTime.isBefore(now.subtract(const Duration(minutes: 5)))) {
      throw EventValidationException('Cannot schedule events in the past');
    }
  }

  /// Validate status transitions
  void _validateStatusTransition(EventStatus currentStatus, EventStatus newStatus) {
    // Define valid status transitions
    final validTransitions = <EventStatus, List<EventStatus>>{
      EventStatus.draft: [EventStatus.scheduled, EventStatus.cancelled],
      EventStatus.scheduled: [EventStatus.active, EventStatus.cancelled, EventStatus.draft],
      EventStatus.active: [EventStatus.completed, EventStatus.cancelled],
      EventStatus.completed: [], // No transitions from completed
      EventStatus.cancelled: [EventStatus.draft], // Can reactivate cancelled draft events
    };

    final allowedTransitions = validTransitions[currentStatus] ?? [];
    
    if (!allowedTransitions.contains(newStatus)) {
      throw EventOperationException(
        'Invalid status transition from ${currentStatus.value} to ${newStatus.value}'
      );
    }
  }
}

/// Custom exceptions for event operations
class EventNotFoundException implements Exception {
  final String message;
  EventNotFoundException(this.message);
  
  @override
  String toString() => 'EventNotFoundException: $message';
}

class EventOperationException implements Exception {
  final String message;
  EventOperationException(this.message);
  
  @override
  String toString() => 'EventOperationException: $message';
}

class EventValidationException implements Exception {
  final String message;
  EventValidationException(this.message);
  
  @override
  String toString() => 'EventValidationException: $message';
}

class ValidationException implements Exception {
  final String message;
  final List<String> errors;
  ValidationException(this.message, this.errors);
  
  @override
  String toString() => 'ValidationException: $message - ${errors.join(', ')}';
}