import 'dart:async';
import '../models/event.dart';
import '../models/enums.dart';
import '../repositories/event_repository.dart';
import '../repositories/submission_repository.dart';
import 'notification_service.dart';

/// Service for managing submission deadlines and automatic enforcement
class DeadlineService {
  final EventRepository _eventRepository;
  final SubmissionRepository _submissionRepository;
  final NotificationService _notificationService;
  
  Timer? _deadlineMonitorTimer;
  final Map<String, Timer> _eventTimers = {};
  final Duration _checkInterval = const Duration(minutes: 1);

  DeadlineService(
    this._eventRepository,
    this._submissionRepository,
    this._notificationService,
  );

  /// Start the deadline monitoring system
  void startDeadlineMonitoring() {
    _deadlineMonitorTimer?.cancel();
    _deadlineMonitorTimer = Timer.periodic(_checkInterval, (_) {
      _checkAllEventDeadlines();
    });
  }

  /// Stop the deadline monitoring system
  void stopDeadlineMonitoring() {
    _deadlineMonitorTimer?.cancel();
    _deadlineMonitorTimer = null;
    
    // Cancel all individual event timers
    for (final timer in _eventTimers.values) {
      timer.cancel();
    }
    _eventTimers.clear();
  }

  /// Schedule deadline enforcement for a specific event
  Future<void> scheduleEventDeadlineEnforcement(Event event) async {
    if (event.submissionDeadline == null) return;
    
    final now = DateTime.now();
    final deadline = event.submissionDeadline!;
    
    // If deadline has already passed, enforce immediately
    if (now.isAfter(deadline)) {
      await _enforceDeadline(event);
      return;
    }
    
    // Cancel existing timer for this event
    _eventTimers[event.id]?.cancel();
    
    // Calculate time until deadline
    final timeUntilDeadline = deadline.difference(now);
    
    // Schedule deadline enforcement
    _eventTimers[event.id] = Timer(timeUntilDeadline, () {
      _enforceDeadline(event);
    });
    
    // Schedule notifications at various intervals before deadline
    await _scheduleDeadlineNotifications(event);
  }

  /// Cancel deadline enforcement for an event
  void cancelEventDeadlineEnforcement(String eventId) {
    _eventTimers[eventId]?.cancel();
    _eventTimers.remove(eventId);
  }

  /// Check all active events for deadline enforcement
  Future<void> _checkAllEventDeadlines() async {
    try {
      final activeEvents = await _eventRepository.getAllActiveEvents();
      
      for (final event in activeEvents) {
        if (event.submissionDeadline != null) {
          final now = DateTime.now();
          
          // Check if deadline has passed and submissions are still open
          if (now.isAfter(event.submissionDeadline!) && event.areSubmissionsOpen) {
            await _enforceDeadline(event);
          }
        }
      }
    } catch (e) {
      print('Error checking event deadlines: $e');
    }
  }

  /// Enforce deadline for an event by auto-closing submissions
  Future<void> _enforceDeadline(Event event) async {
    try {
      // Get all draft submissions for this event
      final draftSubmissions = await _submissionRepository.getDraftSubmissionsByEvent(event.id);
      
      // Auto-close draft submissions (mark as submitted if they have content)
      for (final submission in draftSubmissions) {
        if (submission.hasContent) {
          final submittedSubmission = submission.copyWith(
            status: SubmissionStatus.submitted,
            submittedAt: event.submissionDeadline,
            updatedAt: DateTime.now(),
          );
          await _submissionRepository.update(submittedSubmission);
          
          // Send notification about auto-submission
          await _notificationService.sendDeadlineAutoSubmissionNotification(
            submission: submittedSubmission,
            event: event,
          );
        } else {
          // Delete empty draft submissions
          await _submissionRepository.delete(submission.id);
        }
      }
      
      // Update event status if needed
      if (event.status == EventStatus.active) {
        final now = DateTime.now();
        EventStatus newStatus = EventStatus.active;
        
        // If event end time has also passed, mark as completed
        if (event.endTime != null && now.isAfter(event.endTime!)) {
          newStatus = EventStatus.completed;
        }
        
        if (newStatus != event.status) {
          final updatedEvent = event.copyWith(
            status: newStatus,
            updatedAt: now,
          );
          await _eventRepository.update(updatedEvent);
        }
      }
      
      // Send deadline passed notification
      await _notificationService.sendDeadlinePassedNotification(event);
      
      // Clean up timer
      _eventTimers.remove(event.id);
      
    } catch (e) {
      print('Error enforcing deadline for event ${event.id}: $e');
    }
  }

  /// Schedule notifications at various intervals before deadline
  Future<void> _scheduleDeadlineNotifications(Event event) async {
    if (event.submissionDeadline == null) return;
    
    final now = DateTime.now();
    final deadline = event.submissionDeadline!;
    
    // Define notification intervals (in minutes before deadline)
    final notificationIntervals = [
      const Duration(days: 1),    // 24 hours before
      const Duration(hours: 4),   // 4 hours before
      const Duration(hours: 1),   // 1 hour before
      const Duration(minutes: 15), // 15 minutes before
    ];
    
    for (final interval in notificationIntervals) {
      final notificationTime = deadline.subtract(interval);
      
      // Only schedule if notification time is in the future
      if (now.isBefore(notificationTime)) {
        final timeUntilNotification = notificationTime.difference(now);
        
        Timer(timeUntilNotification, () {
          _sendDeadlineReminderNotification(event, interval);
        });
      }
    }
  }

  /// Send deadline reminder notification
  Future<void> _sendDeadlineReminderNotification(Event event, Duration timeRemaining) async {
    try {
      await _notificationService.sendDeadlineReminderNotification(
        event: event,
        timeRemaining: timeRemaining,
      );
    } catch (e) {
      print('Error sending deadline reminder for event ${event.id}: $e');
    }
  }

  /// Get time remaining until deadline for an event
  Duration? getTimeUntilDeadline(Event event) {
    return event.timeUntilDeadline;
  }

  /// Check if deadline has passed for an event
  bool hasDeadlinePassed(Event event) {
    if (event.submissionDeadline == null) return false;
    return DateTime.now().isAfter(event.submissionDeadline!);
  }

  /// Get deadline status for an event
  DeadlineStatus getDeadlineStatus(Event event) {
    if (event.submissionDeadline == null) {
      return DeadlineStatus.noDeadline;
    }
    
    final now = DateTime.now();
    final deadline = event.submissionDeadline!;
    
    if (now.isAfter(deadline)) {
      return DeadlineStatus.passed;
    }
    
    final timeRemaining = deadline.difference(now);
    
    if (timeRemaining.inMinutes <= 15) {
      return DeadlineStatus.critical; // 15 minutes or less
    } else if (timeRemaining.inHours <= 1) {
      return DeadlineStatus.urgent; // 1 hour or less
    } else if (timeRemaining.inHours <= 4) {
      return DeadlineStatus.warning; // 4 hours or less
    } else if (timeRemaining.inDays <= 1) {
      return DeadlineStatus.approaching; // 24 hours or less
    } else {
      return DeadlineStatus.normal;
    }
  }

  /// Format time remaining as human-readable string
  String formatTimeRemaining(Duration? timeRemaining) {
    if (timeRemaining == null) return 'No deadline';
    
    if (timeRemaining.isNegative) return 'Deadline passed';
    
    final days = timeRemaining.inDays;
    final hours = timeRemaining.inHours % 24;
    final minutes = timeRemaining.inMinutes % 60;
    
    if (days > 0) {
      if (hours > 0) {
        return '${days}d ${hours}h remaining';
      } else {
        return '${days}d remaining';
      }
    } else if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m remaining';
      } else {
        return '${hours}h remaining';
      }
    } else {
      return '${minutes}m remaining';
    }
  }

  /// Get countdown text for UI display
  String getCountdownText(Event event) {
    final timeRemaining = getTimeUntilDeadline(event);
    return formatTimeRemaining(timeRemaining);
  }

  /// Dispose of the service and clean up resources
  void dispose() {
    stopDeadlineMonitoring();
  }
}

/// Enum for deadline status levels
enum DeadlineStatus {
  noDeadline,
  normal,
  approaching, // 24 hours or less
  warning,     // 4 hours or less
  urgent,      // 1 hour or less
  critical,    // 15 minutes or less
  passed,
}

extension DeadlineStatusExtension on DeadlineStatus {
  String get displayName {
    switch (this) {
      case DeadlineStatus.noDeadline:
        return 'No Deadline';
      case DeadlineStatus.normal:
        return 'Normal';
      case DeadlineStatus.approaching:
        return 'Approaching';
      case DeadlineStatus.warning:
        return 'Warning';
      case DeadlineStatus.urgent:
        return 'Urgent';
      case DeadlineStatus.critical:
        return 'Critical';
      case DeadlineStatus.passed:
        return 'Passed';
    }
  }
  
  bool get isUrgent => this == DeadlineStatus.urgent || this == DeadlineStatus.critical;
  bool get requiresAttention => index >= DeadlineStatus.warning.index && this != DeadlineStatus.passed;
}