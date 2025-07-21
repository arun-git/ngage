import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/event_service.dart';
import '../repositories/event_repository.dart';

/// Provider for EventRepository
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

/// Provider for EventService
final eventServiceProvider = Provider<EventService>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return EventService(eventRepository: repository);
});

/// Provider for streaming group events
final groupEventsStreamProvider = StreamProvider.family<List<Event>, String>((ref, groupId) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.streamGroupEvents(groupId);
});

/// Provider for streaming a single event
final eventStreamProvider = StreamProvider.family<Event?, String>((ref, eventId) {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.streamEvent(eventId);
});

/// Provider for getting group events (async)
final groupEventsProvider = FutureProvider.family<List<Event>, String>((ref, groupId) async {
  final eventService = ref.watch(eventServiceProvider);
  return await eventService.getGroupEvents(groupId);
});

/// Provider for getting a single event (async)
final eventProvider = FutureProvider.family<Event?, String>((ref, eventId) async {
  final eventService = ref.watch(eventServiceProvider);
  return await eventService.getEventById(eventId);
});

/// Provider for getting active events
final activeEventsProvider = FutureProvider.family<List<Event>, String>((ref, groupId) async {
  final eventService = ref.watch(eventServiceProvider);
  return await eventService.getActiveEvents(groupId);
});

/// Provider for getting scheduled events
final scheduledEventsProvider = FutureProvider.family<List<Event>, String>((ref, groupId) async {
  final eventService = ref.watch(eventServiceProvider);
  return await eventService.getScheduledEvents(groupId);
});

/// Provider for getting events by status
final eventsByStatusProvider = FutureProvider.family<List<Event>, EventsByStatusParams>((ref, params) async {
  final eventService = ref.watch(eventServiceProvider);
  return await eventService.getEventsByStatus(params.groupId, params.status);
});

/// Provider for getting team eligible events
final teamEligibleEventsProvider = FutureProvider.family<List<Event>, TeamEligibleEventsParams>((ref, params) async {
  final eventService = ref.watch(eventServiceProvider);
  return await eventService.getTeamEligibleEvents(params.groupId, params.teamId);
});

/// Provider for getting events with upcoming deadlines
final upcomingDeadlineEventsProvider = FutureProvider.family<List<Event>, UpcomingDeadlineParams>((ref, params) async {
  final eventService = ref.watch(eventServiceProvider);
  return await eventService.getEventsWithUpcomingDeadlines(params.groupId, daysAhead: params.daysAhead);
});

/// Provider for searching events
final searchEventsProvider = FutureProvider.family<List<Event>, SearchEventsParams>((ref, params) async {
  final eventService = ref.watch(eventServiceProvider);
  return await eventService.searchEvents(params.groupId, params.searchTerm);
});

/// Provider for getting teams accessible to an event
final eventAccessibleTeamsProvider = FutureProvider.family<List<String>, String>((ref, eventId) async {
  final eventService = ref.watch(eventServiceProvider);
  return await eventService.getEligibleTeams(eventId);
});

/// Provider for getting accessible events for a team
final teamAccessibleEventsProvider = FutureProvider.family<List<Event>, TeamAccessibleEventsParams>((ref, params) async {
  final eventService = ref.watch(eventServiceProvider);
  return await eventService.getAccessibleEventsForTeam(params.groupId, params.teamId);
});

/// State notifier for event form management
class EventFormNotifier extends StateNotifier<EventFormState> {
  final EventService _eventService;

  EventFormNotifier(this._eventService) : super(EventFormState.initial());

  /// Update form field
  void updateField(String field, dynamic value) {
    state = state.copyWith(
      formData: {...state.formData, field: value},
      errors: {...state.errors}..remove(field),
    );
  }

  /// Set form errors
  void setErrors(Map<String, String> errors) {
    state = state.copyWith(errors: errors);
  }

  /// Clear form
  void clearForm() {
    state = EventFormState.initial();
  }

  /// Load event for editing
  void loadEvent(Event event) {
    state = state.copyWith(
      formData: {
        'title': event.title,
        'description': event.description,
        'eventType': event.eventType,
        'startTime': event.startTime,
        'endTime': event.endTime,
        'submissionDeadline': event.submissionDeadline,
        'eligibleTeamIds': event.eligibleTeamIds,
        'judgingCriteria': event.judgingCriteria,
      },
      isEditing: true,
      editingEventId: event.id,
    );
  }

  /// Create event
  Future<Event?> createEvent(String groupId, String createdBy) async {
    state = state.copyWith(isLoading: true, errors: {});

    try {
      final event = await _eventService.createEvent(
        groupId: groupId,
        title: state.formData['title'] as String,
        description: state.formData['description'] as String,
        eventType: state.formData['eventType'] as EventType,
        createdBy: createdBy,
        startTime: state.formData['startTime'] as DateTime?,
        endTime: state.formData['endTime'] as DateTime?,
        submissionDeadline: state.formData['submissionDeadline'] as DateTime?,
        eligibleTeamIds: state.formData['eligibleTeamIds'] as List<String>?,
        judgingCriteria: state.formData['judgingCriteria'] as Map<String, dynamic>?,
      );

      state = state.copyWith(isLoading: false);
      return event;
    } catch (e) {
      final errors = _parseErrors(e);
      state = state.copyWith(isLoading: false, errors: errors);
      return null;
    }
  }

  /// Update event
  Future<Event?> updateEvent() async {
    if (!state.isEditing || state.editingEventId == null) return null;

    state = state.copyWith(isLoading: true, errors: {});

    try {
      final currentEvent = await _eventService.getEventById(state.editingEventId!);
      if (currentEvent == null) {
        throw Exception('Event not found');
      }

      final updatedEvent = currentEvent.copyWith(
        title: state.formData['title'] as String,
        description: state.formData['description'] as String,
        eventType: state.formData['eventType'] as EventType,
        startTime: state.formData['startTime'] as DateTime?,
        endTime: state.formData['endTime'] as DateTime?,
        submissionDeadline: state.formData['submissionDeadline'] as DateTime?,
        eligibleTeamIds: state.formData['eligibleTeamIds'] as List<String>?,
        judgingCriteria: state.formData['judgingCriteria'] as Map<String, dynamic>?,
      );

      final result = await _eventService.updateEvent(updatedEvent);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      final errors = _parseErrors(e);
      state = state.copyWith(isLoading: false, errors: errors);
      return null;
    }
  }

  /// Parse errors from exceptions
  Map<String, String> _parseErrors(dynamic error) {
    if (error is ValidationException) {
      // Convert validation errors to field-specific errors
      final fieldErrors = <String, String>{};
      for (final errorMsg in error.errors) {
        if (errorMsg.contains('title')) {
          fieldErrors['title'] = errorMsg;
        } else if (errorMsg.contains('description')) {
          fieldErrors['description'] = errorMsg;
        } else if (errorMsg.contains('time')) {
          fieldErrors['schedule'] = errorMsg;
        } else {
          fieldErrors['general'] = errorMsg;
        }
      }
      return fieldErrors;
    }
    
    return {'general': error.toString()};
  }
}

/// Provider for event form state
final eventFormProvider = StateNotifierProvider<EventFormNotifier, EventFormState>((ref) {
  final eventService = ref.watch(eventServiceProvider);
  return EventFormNotifier(eventService);
});

/// State class for event form
class EventFormState {
  final Map<String, dynamic> formData;
  final Map<String, String> errors;
  final bool isLoading;
  final bool isEditing;
  final String? editingEventId;

  const EventFormState({
    required this.formData,
    required this.errors,
    required this.isLoading,
    required this.isEditing,
    this.editingEventId,
  });

  factory EventFormState.initial() {
    return const EventFormState(
      formData: {},
      errors: {},
      isLoading: false,
      isEditing: false,
    );
  }

  EventFormState copyWith({
    Map<String, dynamic>? formData,
    Map<String, String>? errors,
    bool? isLoading,
    bool? isEditing,
    String? editingEventId,
  }) {
    return EventFormState(
      formData: formData ?? this.formData,
      errors: errors ?? this.errors,
      isLoading: isLoading ?? this.isLoading,
      isEditing: isEditing ?? this.isEditing,
      editingEventId: editingEventId ?? this.editingEventId,
    );
  }
}

/// Parameter classes for providers
class EventsByStatusParams {
  final String groupId;
  final EventStatus status;

  const EventsByStatusParams({
    required this.groupId,
    required this.status,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventsByStatusParams &&
        other.groupId == groupId &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(groupId, status);
}

class TeamEligibleEventsParams {
  final String groupId;
  final String teamId;

  const TeamEligibleEventsParams({
    required this.groupId,
    required this.teamId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamEligibleEventsParams &&
        other.groupId == groupId &&
        other.teamId == teamId;
  }

  @override
  int get hashCode => Object.hash(groupId, teamId);
}

class UpcomingDeadlineParams {
  final String groupId;
  final int daysAhead;

  const UpcomingDeadlineParams({
    required this.groupId,
    this.daysAhead = 7,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpcomingDeadlineParams &&
        other.groupId == groupId &&
        other.daysAhead == daysAhead;
  }

  @override
  int get hashCode => Object.hash(groupId, daysAhead);
}

class SearchEventsParams {
  final String groupId;
  final String searchTerm;

  const SearchEventsParams({
    required this.groupId,
    required this.searchTerm,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchEventsParams &&
        other.groupId == groupId &&
        other.searchTerm == searchTerm;
  }

  @override
  int get hashCode => Object.hash(groupId, searchTerm);
}

class TeamAccessibleEventsParams {
  final String groupId;
  final String teamId;

  const TeamAccessibleEventsParams({
    required this.groupId,
    required this.teamId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamAccessibleEventsParams &&
        other.groupId == groupId &&
        other.teamId == teamId;
  }

  @override
  int get hashCode => Object.hash(groupId, teamId);
}