import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/submission.dart';
import '../models/enums.dart';
import '../services/event_submission_integration_service.dart';
import 'event_providers.dart';
import 'submission_providers.dart';

/// Provider for event-submission integration service
final eventSubmissionIntegrationServiceProvider =
    Provider<EventSubmissionIntegrationService>((ref) {
  final eventService = ref.watch(eventServiceProvider);
  final submissionService = ref.watch(submissionServiceProvider);

  return EventSubmissionIntegrationService(eventService, submissionService);
});

/// Provider for event with submission statistics
final eventWithSubmissionStatsProvider =
    FutureProvider.family<EventWithSubmissionStats, String>(
        (ref, eventId) async {
  final integrationService =
      ref.watch(eventSubmissionIntegrationServiceProvider);
  return await integrationService.getEventWithSubmissionStats(eventId);
});

/// Provider for team's submission for a specific event
final teamSubmissionForEventProvider =
    FutureProvider.family<Submission?, ({String eventId, String teamId})>(
        (ref, params) async {
  final integrationService =
      ref.watch(eventSubmissionIntegrationServiceProvider);
  return await integrationService.getTeamSubmissionForEvent(
      params.eventId, params.teamId);
});

/// Provider for member's submission for a specific event
final memberSubmissionForEventProvider =
    FutureProvider.family<Submission?, ({String eventId, String memberId})>(
        (ref, params) async {
  final integrationService =
      ref.watch(eventSubmissionIntegrationServiceProvider);
  return await integrationService.getMemberSubmissionForEvent(
      params.eventId, params.memberId);
});

/// Provider for checking if team can submit to event
final canTeamSubmitToEventProvider =
    FutureProvider.family<bool, ({String eventId, String teamId})>(
        (ref, params) async {
  final integrationService =
      ref.watch(eventSubmissionIntegrationServiceProvider);
  return await integrationService.canTeamSubmitToEvent(
      params.eventId, params.teamId);
});

/// Provider for checking if member can submit to event
final canMemberSubmitToEventProvider = FutureProvider.family<bool,
    ({String eventId, String memberId, String teamId})>((ref, params) async {
  final integrationService =
      ref.watch(eventSubmissionIntegrationServiceProvider);
  return await integrationService.canMemberSubmitToEvent(
      params.eventId, params.memberId, params.teamId);
});

/// Provider for events with submission status for a team
final eventsWithSubmissionStatusForTeamProvider = FutureProvider.family<
    List<EventWithTeamSubmissionStatus>,
    ({String groupId, String teamId})>((ref, params) async {
  final integrationService =
      ref.watch(eventSubmissionIntegrationServiceProvider);
  return await integrationService.getEventsWithSubmissionStatusForTeam(
      params.groupId, params.teamId);
});

/// Provider for submission statistics for multiple events
final submissionStatisticsForEventsProvider =
    FutureProvider.family<Map<String, SubmissionStatistics>, List<String>>(
        (ref, eventIds) async {
  final integrationService =
      ref.watch(eventSubmissionIntegrationServiceProvider);
  return await integrationService.getSubmissionStatisticsForEvents(eventIds);
});

/// Provider for events that need attention
final eventsThatNeedAttentionProvider =
    FutureProvider.family<List<EventNeedingAttention>, String>(
        (ref, groupId) async {
  final integrationService =
      ref.watch(eventSubmissionIntegrationServiceProvider);
  return await integrationService.getEventsThatNeedAttention(groupId);
});

/// Provider for submission timeline for an event
final submissionTimelineForEventProvider =
    FutureProvider.family<List<SubmissionTimelineEvent>, String>(
        (ref, eventId) async {
  final integrationService =
      ref.watch(eventSubmissionIntegrationServiceProvider);
  return await integrationService.getSubmissionTimelineForEvent(eventId);
});

/// Provider for event submission export
final eventSubmissionExportProvider =
    FutureProvider.family<EventSubmissionExport, String>((ref, eventId) async {
  final integrationService =
      ref.watch(eventSubmissionIntegrationServiceProvider);
  return await integrationService.exportEventSubmissions(eventId);
});

/// State notifier for managing event-submission operations
class EventSubmissionOperationsNotifier
    extends StateNotifier<EventSubmissionOperationsState> {
  final EventSubmissionIntegrationService _integrationService;
  final Ref _ref;

  EventSubmissionOperationsNotifier(this._integrationService, this._ref)
      : super(EventSubmissionOperationsState.initial());

  /// Create submission for team in event
  Future<Submission?> createSubmissionForEvent({
    required String eventId,
    required String teamId,
    required String submittedBy,
    Map<String, dynamic>? initialContent,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final submission = await _integrationService.createSubmissionForEvent(
        eventId: eventId,
        teamId: teamId,
        submittedBy: submittedBy,
        initialContent: initialContent,
      );

      // Invalidate relevant providers to refresh data
      _ref.invalidate(eventSubmissionsProvider(eventId));
      _ref.invalidate(eventSubmissionsStreamProvider(eventId));
      _ref.invalidate(
          teamSubmissionForEventProvider((eventId: eventId, teamId: teamId)));

      state = state.copyWith(
        isLoading: false,
        lastCreatedSubmission: submission,
        isSuccess: true,
      );

      return submission;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Bulk update submission statuses
  Future<void> bulkUpdateSubmissionStatuses(
    String eventId,
    Map<String, SubmissionStatus> submissionStatusUpdates,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _integrationService.bulkUpdateSubmissionStatuses(
          eventId, submissionStatusUpdates);

      // Invalidate relevant providers to refresh data
      _ref.invalidate(eventSubmissionsProvider(eventId));
      _ref.invalidate(eventSubmissionsStreamProvider(eventId));

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear state
  void clearState() {
    state = EventSubmissionOperationsState.initial();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear success flag
  void clearSuccess() {
    state = state.copyWith(isSuccess: false);
  }
}

/// State class for event-submission operations
class EventSubmissionOperationsState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final Submission? lastCreatedSubmission;

  const EventSubmissionOperationsState({
    required this.isLoading,
    required this.isSuccess,
    this.error,
    this.lastCreatedSubmission,
  });

  factory EventSubmissionOperationsState.initial() {
    return const EventSubmissionOperationsState(
      isLoading: false,
      isSuccess: false,
    );
  }

  EventSubmissionOperationsState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    Submission? lastCreatedSubmission,
  }) {
    return EventSubmissionOperationsState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error ?? this.error,
      lastCreatedSubmission:
          lastCreatedSubmission ?? this.lastCreatedSubmission,
    );
  }
}

/// Provider for event-submission operations state notifier
final eventSubmissionOperationsProvider = StateNotifierProvider<
    EventSubmissionOperationsNotifier, EventSubmissionOperationsState>((ref) {
  final integrationService =
      ref.watch(eventSubmissionIntegrationServiceProvider);
  return EventSubmissionOperationsNotifier(integrationService, ref);
});
