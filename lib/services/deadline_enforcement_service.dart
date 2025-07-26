import 'dart:async';
import '../models/event.dart';
import '../models/enums.dart';
import '../repositories/event_repository.dart';
import '../repositories/submission_repository.dart';
import 'notification_service.dart';

/// Service for enforcing submission deadlines and managing deadline notifications
class DeadlineEnforcementService {
  final EventRepository _eventRepository;
  final SubmissionRepository _submissionRepository;
  final NotificationService _notificationService;

  Timer? _deadlineTimer;
  final Map<String, Timer> _eventTimers = {};
  final Map<String, Timer> _notificationTimers = {};

  DeadlineEnforcementService(
    this._eventRepository,
    this._submissionRepository,
    this._notificationService,
  );

  /// Start monitoring deadlines for all active events
  Future<void> startDeadlineMonitoring() async {
    // Stop any existing monitoring
    stopDeadlineMonitoring();

    // Start periodic check for deadlines every minute
    _deadlineTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkAllDeadlines(),
    );

    // Initial check
    await _checkAllDeadlines();
  }

  /// Stop all deadline monitoring
  void stopDeadlineMonitoring() {
    _deadlineTimer?.cancel();
    _deadlineTimer = null;

    // Cancel all event-specific timers
    for (final timer in _eventTimers.values) {
      timer.cancel();
    }
    _eventTimers.clear();

    // Cancel all notification timers
    for (final timer in _notificationTimers.values) {
      timer.cancel();
    }
    _notificationTimers.clear();
  }

  /// Check deadlines for all active events
  Future<void> _checkAllDeadlines() async {
    try {
      final activeEvents = await _eventRepository.getAllActiveEvents();

      for (final event in activeEvents) {
        if (event.submissionDeadline != null) {
          await _processEventDeadline(event);
        }
      }
    } catch (e) {
      print('Error checking deadlines: $e');
    }
  }

  /// Process deadline for a specific event
  Future<void> _processEventDeadline(Event event) async {
    final deadline = event.submissionDeadline!;
    final now = DateTime.now();

    // Check if deadline has passed
    if (now.isAfter(deadline)) {
      await _enforceDeadline(event);
      return;
    }

    // Schedule deadline enforcement
    _scheduleDeadlineEnforcement(event);

    // Schedule notifications
    await _scheduleDeadlineNotifications(event);
  }

  /// Schedule automatic deadline enforcement
  void _scheduleDeadlineEnforcement(Event event) {
    final eventId = event.id;
    final deadline = event.submissionDeadline!;
    final now = DateTime.now();

    // Cancel existing timer for this event
    _eventTimers[eventId]?.cancel();

    // Calculate time until deadline
    final timeUntilDeadline = deadline.difference(now);

    if (timeUntilDeadline.isNegative) {
      // Deadline has already passed, enforce immediately
      _enforceDeadline(event);
      return;
    }

    // Schedule enforcement at deadline
    _eventTimers[eventId] = Timer(timeUntilDeadline, () {
      _enforceDeadline(event);
      _eventTimers.remove(eventId);
    });
  }

  /// Enforce deadline by auto-closing submissions
  Future<void> _enforceDeadline(Event event) async {
    try {
      print('Enforcing deadline for event: ${event.title}');

      // Get all draft submissions for this event
      final submissions = await _submissionRepository.getByEventId(event.id);
      final draftSubmissions =
          submissions.where((s) => s.status == SubmissionStatus.draft).toList();

      // Auto-close draft submissions
      for (final submission in draftSubmissions) {
        try {
          // Only auto-close if submission has content
          if (submission.hasContent) {
            final closedSubmission = submission.copyWith(
              status: SubmissionStatus.submitted,
              submittedAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await _submissionRepository.update(closedSubmission);

            // Send notification to submitter
            await _notificationService.sendDeadlineAutoCloseNotification(
              submission.submittedBy,
              event,
              submission,
            );
          } else {
            // Delete empty draft submissions
            await _submissionRepository.delete(submission.id);
          }
        } catch (e) {
          print('Error processing submission ${submission.id}: $e');
        }
      }

      // Send deadline passed notification to event organizers
      await _notificationService.sendDeadlinePassedNotification(
        event,
        draftSubmissions.length,
      );
    } catch (e) {
      print('Error enforcing deadline for event ${event.id}: $e');
    }
  }

  /// Schedule deadline notifications
  Future<void> _scheduleDeadlineNotifications(Event event) async {
    final deadline = event.submissionDeadline!;
    final now = DateTime.now();
    final eventId = event.id;

    // Define notification intervals (in hours before deadline)
    final notificationIntervals = [
      const Duration(hours: 24), // 1 day before
      const Duration(hours: 4), // 4 hours before
      const Duration(hours: 1), // 1 hour before
      const Duration(minutes: 15), // 15 minutes before
    ];

    for (final interval in notificationIntervals) {
      final notificationTime = deadline.subtract(interval);

      // Skip if notification time has already passed
      if (now.isAfter(notificationTime)) continue;

      final timeUntilNotification = notificationTime.difference(now);
      final timerKey = '${eventId}_${interval.inMinutes}';

      // Cancel existing timer
      _notificationTimers[timerKey]?.cancel();

      // Schedule notification
      _notificationTimers[timerKey] = Timer(timeUntilNotification, () {
        _sendDeadlineReminder(event, interval);
        _notificationTimers.remove(timerKey);
      });
    }
  }

  /// Send deadline reminder notification
  Future<void> _sendDeadlineReminder(
      Event event, Duration timeRemaining) async {
    try {
      // Get all teams participating in the event
      final submissions = await _submissionRepository.getByEventId(event.id);
      final participatingTeamIds =
          submissions.map((s) => s.teamId).toSet().toList();

      // Send reminders to teams with draft submissions
      final draftSubmissions =
          submissions.where((s) => s.status == SubmissionStatus.draft).toList();

      for (final submission in draftSubmissions) {
        await _notificationService.sendDeadlineReminderNotification(
          submission.submittedBy,
          event,
          timeRemaining,
        );
      }

      // Send reminder to event organizers
      await _notificationService.sendOrganizerDeadlineReminder(
        event,
        timeRemaining,
        draftSubmissions.length,
      );
    } catch (e) {
      print('Error sending deadline reminder for event ${event.id}: $e');
    }
  }

  /// Get time remaining until deadline for an event
  Duration? getTimeUntilDeadline(Event event) {
    if (event.submissionDeadline == null) return null;

    final now = DateTime.now();
    final deadline = event.submissionDeadline!;

    if (now.isAfter(deadline)) return Duration.zero;

    return deadline.difference(now);
  }

  /// Check if deadline has passed for an event
  bool hasDeadlinePassed(Event event) {
    if (event.submissionDeadline == null) return false;

    final now = DateTime.now();
    return now.isAfter(event.submissionDeadline!);
  }

  /// Get deadline status for an event
  DeadlineStatus getDeadlineStatus(Event event) {
    if (event.submissionDeadline == null) {
      return DeadlineStatus.noDeadline;
    }

    final timeRemaining = getTimeUntilDeadline(event);
    if (timeRemaining == null || timeRemaining.isNegative) {
      return DeadlineStatus.passed;
    }

    if (timeRemaining.inMinutes <= 15) {
      return DeadlineStatus.critical; // 15 minutes or less
    } else if (timeRemaining.inHours <= 1) {
      return DeadlineStatus.urgent; // 1 hour or less
    } else if (timeRemaining.inHours <= 4) {
      return DeadlineStatus.warning; // 4 hours or less
    } else if (timeRemaining.inHours <= 24) {
      return DeadlineStatus.approaching; // 24 hours or less
    } else {
      return DeadlineStatus.normal;
    }
  }

  /// Format time remaining as human-readable string
  String formatTimeRemaining(Duration timeRemaining) {
    if (timeRemaining.isNegative) return 'Deadline passed';

    final days = timeRemaining.inDays;
    final hours = timeRemaining.inHours % 24;
    final minutes = timeRemaining.inMinutes % 60;

    if (days > 0) {
      return '$days day${days == 1 ? '' : 's'}, $hours hour${hours == 1 ? '' : 's'}';
    } else if (hours > 0) {
      return '$hours hour${hours == 1 ? '' : 's'}, $minutes minute${minutes == 1 ? '' : 's'}';
    } else {
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    }
  }

  /// Dispose of the service and clean up resources
  void dispose() {
    stopDeadlineMonitoring();
  }
}

/// Enum for deadline status
enum DeadlineStatus {
  noDeadline,
  normal,
  approaching, // 24 hours or less
  warning, // 4 hours or less
  urgent, // 1 hour or less
  critical, // 15 minutes or less
  passed,
}
