import '../models/event.dart';
import '../models/submission.dart';

/// Service for sending various types of notifications
class NotificationService {
  /// Send notification when submission is auto-closed due to deadline
  Future<void> sendDeadlineAutoCloseNotification(
    String memberId,
    Event event,
    Submission submission,
  ) async {
    // TODO: Implement actual notification sending
    // This could be in-app notifications, email, push notifications, etc.
    print(
        'Sending auto-close notification to member $memberId for event ${event.title}');
  }

  /// Send notification when deadline has passed to event organizers
  Future<void> sendDeadlinePassedNotification(
    Event event,
    int autoClosedCount,
  ) async {
    // TODO: Implement actual notification sending
    print(
        'Deadline passed for event ${event.title}. Auto-closed $autoClosedCount submissions.');
  }

  /// Send deadline reminder notification to participants
  Future<void> sendDeadlineReminderNotification(
    String memberId,
    Event event,
    Duration timeRemaining,
  ) async {
    // TODO: Implement actual notification sending
    print(
        'Sending deadline reminder to member $memberId for event ${event.title}. Time remaining: ${_formatDuration(timeRemaining)}');
  }

  /// Send deadline reminder to event organizers
  Future<void> sendOrganizerDeadlineReminder(
    Event event,
    Duration timeRemaining,
    int pendingSubmissions,
  ) async {
    // TODO: Implement actual notification sending
    print(
        'Organizer reminder for event ${event.title}. Time remaining: ${_formatDuration(timeRemaining)}, Pending: $pendingSubmissions');
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '$days day${days == 1 ? '' : 's'}, $hours hour${hours == 1 ? '' : 's'}';
    } else if (hours > 0) {
      return '$hours hour${hours == 1 ? '' : 's'}, $minutes minute${minutes == 1 ? '' : 's'}';
    } else {
      return '$minutes minute${minutes == 1 ? '' : 's'}';
    }
  }
}
