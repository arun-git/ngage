import '../models/event.dart';
import '../models/submission.dart';
import '../models/enums.dart';
import 'event_service.dart';
import 'submission_service.dart';

/// Service that integrates event management with submission management
class EventSubmissionIntegrationService {
  final EventService _eventService;
  final SubmissionService _submissionService;

  EventSubmissionIntegrationService(
    this._eventService,
    this._submissionService,
  );

  /// Get event with submission statistics
  Future<EventWithSubmissionStats> getEventWithSubmissionStats(
      String eventId) async {
    final event = await _eventService.getEventById(eventId);
    if (event == null) {
      throw Exception('Event not found: $eventId');
    }

    final submissions = await _submissionService.getEventSubmissions(eventId);

    return EventWithSubmissionStats(
      event: event,
      totalSubmissions: submissions.length,
      draftSubmissions:
          submissions.where((s) => s.status == SubmissionStatus.draft).length,
      submittedSubmissions: submissions
          .where((s) => s.status == SubmissionStatus.submitted)
          .length,
      underReviewSubmissions: submissions
          .where((s) => s.status == SubmissionStatus.underReview)
          .length,
      approvedSubmissions: submissions
          .where((s) => s.status == SubmissionStatus.approved)
          .length,
      rejectedSubmissions: submissions
          .where((s) => s.status == SubmissionStatus.rejected)
          .length,
      submissions: submissions,
    );
  }

  /// Get team's submission for a specific event
  Future<Submission?> getTeamSubmissionForEvent(
      String eventId, String teamId) async {
    final submissions = await _submissionService.getEventSubmissions(eventId);
    try {
      return submissions.firstWhere((s) => s.teamId == teamId);
    } catch (e) {
      return null;
    }
  }

  /// Get member's submission for a specific event
  Future<Submission?> getMemberSubmissionForEvent(
      String eventId, String memberId) async {
    final submissions = await _submissionService.getEventSubmissions(eventId);
    try {
      return submissions.firstWhere((s) => s.submittedBy == memberId);
    } catch (e) {
      return null;
    }
  }

  /// Check if team can submit to event
  Future<bool> canTeamSubmitToEvent(String eventId, String teamId) async {
    final event = await _eventService.getEventById(eventId);
    if (event == null) return false;

    // Check if event allows submissions
    if (!event.areSubmissionsOpen) return false;

    // Check if team is eligible for the event
    if (!event.isTeamEligible(teamId)) return false;

    // Note: Removed the check for existing team submissions since we now allow
    // multiple individual submissions from the same team
    return true;
  }

  /// Check if member can submit to event
  Future<bool> canMemberSubmitToEvent(
      String eventId, String memberId, String teamId) async {
    final event = await _eventService.getEventById(eventId);
    if (event == null) return false;

    // Check if event allows submissions
    if (!event.areSubmissionsOpen) return false;

    // Check if team is eligible for the event
    if (!event.isTeamEligible(teamId)) return false;

    // Check if member has already submitted to this event
    final hasSubmitted =
        await _submissionService.hasMemberSubmitted(eventId, memberId);
    if (hasSubmitted) return false;

    return true;
  }

  /// Create submission for team in event
  Future<Submission> createSubmissionForEvent({
    required String eventId,
    required String teamId,
    required String submittedBy,
    Map<String, dynamic>? initialContent,
  }) async {
    // Verify team can submit
    final canSubmit = await canTeamSubmitToEvent(eventId, teamId);
    if (!canSubmit) {
      throw Exception('Team cannot submit to this event');
    }

    return await _submissionService.createSubmission(
      eventId: eventId,
      teamId: teamId,
      submittedBy: submittedBy,
      initialContent: initialContent,
    );
  }

  /// Get events with submission status for a team
  Future<List<EventWithTeamSubmissionStatus>>
      getEventsWithSubmissionStatusForTeam(
    String groupId,
    String teamId,
  ) async {
    final events = await _eventService.getTeamEligibleEvents(groupId, teamId);
    final results = <EventWithTeamSubmissionStatus>[];

    for (final event in events) {
      final submission = await getTeamSubmissionForEvent(event.id, teamId);
      final canSubmit = await canTeamSubmitToEvent(event.id, teamId);

      results.add(EventWithTeamSubmissionStatus(
        event: event,
        submission: submission,
        canSubmit: canSubmit,
        submissionStatus: submission?.status,
      ));
    }

    return results;
  }

  /// Get submission statistics for multiple events
  Future<Map<String, SubmissionStatistics>> getSubmissionStatisticsForEvents(
    List<String> eventIds,
  ) async {
    final statistics = <String, SubmissionStatistics>{};

    for (final eventId in eventIds) {
      final submissions = await _submissionService.getEventSubmissions(eventId);
      statistics[eventId] = SubmissionStatistics.fromSubmissions(submissions);
    }

    return statistics;
  }

  /// Get events that need attention (approaching deadlines, pending reviews, etc.)
  Future<List<EventNeedingAttention>> getEventsThatNeedAttention(
      String groupId) async {
    final events = await _eventService.getActiveEvents(groupId);
    final eventsNeedingAttention = <EventNeedingAttention>[];

    for (final event in events) {
      final reasons = <AttentionReason>[];
      final submissions =
          await _submissionService.getEventSubmissions(event.id);

      // Check for approaching deadline
      if (event.submissionDeadline != null) {
        final timeUntilDeadline =
            event.submissionDeadline!.difference(DateTime.now());
        if (timeUntilDeadline.inHours <= 24 && !timeUntilDeadline.isNegative) {
          reasons.add(AttentionReason.approachingDeadline);
        }
      }

      // Check for submissions under review
      final underReviewCount = submissions
          .where((s) => s.status == SubmissionStatus.underReview)
          .length;
      if (underReviewCount > 0) {
        reasons.add(AttentionReason.pendingReviews);
      }

      // Check for low submission count
      final submittedCount =
          submissions.where((s) => s.status != SubmissionStatus.draft).length;
      if (submittedCount == 0 && event.submissionDeadline != null) {
        final timeUntilDeadline =
            event.submissionDeadline!.difference(DateTime.now());
        if (timeUntilDeadline.inDays <= 3) {
          reasons.add(AttentionReason.lowSubmissionCount);
        }
      }

      if (reasons.isNotEmpty) {
        eventsNeedingAttention.add(EventNeedingAttention(
          event: event,
          reasons: reasons,
          submissionCount: submittedCount,
          pendingReviewCount: underReviewCount,
        ));
      }
    }

    return eventsNeedingAttention;
  }

  /// Bulk update submission statuses for an event
  Future<void> bulkUpdateSubmissionStatuses(
    String eventId,
    Map<String, SubmissionStatus> submissionStatusUpdates,
  ) async {
    for (final entry in submissionStatusUpdates.entries) {
      final submissionId = entry.key;
      final newStatus = entry.value;

      await _submissionService.updateSubmissionStatus(
        submissionId: submissionId,
        status: newStatus,
      );
    }
  }

  /// Get submission timeline for an event
  Future<List<SubmissionTimelineEvent>> getSubmissionTimelineForEvent(
      String eventId) async {
    final submissions = await _submissionService.getEventSubmissions(eventId);
    final timelineEvents = <SubmissionTimelineEvent>[];

    for (final submission in submissions) {
      // Add creation event
      timelineEvents.add(SubmissionTimelineEvent(
        timestamp: submission.createdAt,
        type: SubmissionTimelineEventType.created,
        submissionId: submission.id,
        teamId: submission.teamId,
        status: submission.status,
      ));

      // Add submission event if submitted
      if (submission.submittedAt != null) {
        timelineEvents.add(SubmissionTimelineEvent(
          timestamp: submission.submittedAt!,
          type: SubmissionTimelineEventType.submitted,
          submissionId: submission.id,
          teamId: submission.teamId,
          status: submission.status,
        ));
      }

      // Add status change events (this would require tracking status history)
      // For now, we'll just add the current status if it's not draft or submitted
      if (submission.status != SubmissionStatus.draft &&
          submission.status != SubmissionStatus.submitted) {
        timelineEvents.add(SubmissionTimelineEvent(
          timestamp: submission.updatedAt,
          type: SubmissionTimelineEventType.statusChanged,
          submissionId: submission.id,
          teamId: submission.teamId,
          status: submission.status,
        ));
      }
    }

    // Sort by timestamp
    timelineEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return timelineEvents;
  }

  /// Export event submissions data
  Future<EventSubmissionExport> exportEventSubmissions(String eventId) async {
    final event = await _eventService.getEventById(eventId);
    if (event == null) {
      throw Exception('Event not found: $eventId');
    }

    final submissions = await _submissionService.getEventSubmissions(eventId);

    return EventSubmissionExport(
      event: event,
      submissions: submissions,
      exportedAt: DateTime.now(),
      statistics: SubmissionStatistics.fromSubmissions(submissions),
    );
  }
}

/// Data classes for integration

class EventWithSubmissionStats {
  final Event event;
  final int totalSubmissions;
  final int draftSubmissions;
  final int submittedSubmissions;
  final int underReviewSubmissions;
  final int approvedSubmissions;
  final int rejectedSubmissions;
  final List<Submission> submissions;

  EventWithSubmissionStats({
    required this.event,
    required this.totalSubmissions,
    required this.draftSubmissions,
    required this.submittedSubmissions,
    required this.underReviewSubmissions,
    required this.approvedSubmissions,
    required this.rejectedSubmissions,
    required this.submissions,
  });

  double get submissionRate {
    if (totalSubmissions == 0) return 0.0;
    return submittedSubmissions / totalSubmissions;
  }

  bool get hasSubmissions => totalSubmissions > 0;
  bool get hasPendingReviews => underReviewSubmissions > 0;
}

class EventWithTeamSubmissionStatus {
  final Event event;
  final Submission? submission;
  final bool canSubmit;
  final SubmissionStatus? submissionStatus;

  EventWithTeamSubmissionStatus({
    required this.event,
    this.submission,
    required this.canSubmit,
    this.submissionStatus,
  });

  bool get hasSubmission => submission != null;
  bool get hasSubmitted => submission?.isSubmitted == true;
  bool get isDraft => submission?.isDraft == true;
}

class SubmissionStatistics {
  final int total;
  final int draft;
  final int submitted;
  final int underReview;
  final int approved;
  final int rejected;

  SubmissionStatistics({
    required this.total,
    required this.draft,
    required this.submitted,
    required this.underReview,
    required this.approved,
    required this.rejected,
  });

  factory SubmissionStatistics.fromSubmissions(List<Submission> submissions) {
    return SubmissionStatistics(
      total: submissions.length,
      draft:
          submissions.where((s) => s.status == SubmissionStatus.draft).length,
      submitted: submissions
          .where((s) => s.status == SubmissionStatus.submitted)
          .length,
      underReview: submissions
          .where((s) => s.status == SubmissionStatus.underReview)
          .length,
      approved: submissions
          .where((s) => s.status == SubmissionStatus.approved)
          .length,
      rejected: submissions
          .where((s) => s.status == SubmissionStatus.rejected)
          .length,
    );
  }

  double get completionRate {
    if (total == 0) return 0.0;
    return (submitted + underReview + approved + rejected) / total;
  }

  double get approvalRate {
    final reviewed = underReview + approved + rejected;
    if (reviewed == 0) return 0.0;
    return approved / reviewed;
  }
}

class EventNeedingAttention {
  final Event event;
  final List<AttentionReason> reasons;
  final int submissionCount;
  final int pendingReviewCount;

  EventNeedingAttention({
    required this.event,
    required this.reasons,
    required this.submissionCount,
    required this.pendingReviewCount,
  });
}

enum AttentionReason {
  approachingDeadline,
  pendingReviews,
  lowSubmissionCount,
  overdueReviews,
}

class SubmissionTimelineEvent {
  final DateTime timestamp;
  final SubmissionTimelineEventType type;
  final String submissionId;
  final String teamId;
  final SubmissionStatus status;

  SubmissionTimelineEvent({
    required this.timestamp,
    required this.type,
    required this.submissionId,
    required this.teamId,
    required this.status,
  });
}

enum SubmissionTimelineEventType {
  created,
  submitted,
  statusChanged,
}

class EventSubmissionExport {
  final Event event;
  final List<Submission> submissions;
  final DateTime exportedAt;
  final SubmissionStatistics statistics;

  EventSubmissionExport({
    required this.event,
    required this.submissions,
    required this.exportedAt,
    required this.statistics,
  });
}
