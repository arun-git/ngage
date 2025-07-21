import 'dart:async';
import 'dart:math';
import '../models/models.dart';
import '../repositories/notification_repository.dart';

/// Comprehensive notification service with multi-channel support
/// 
/// Handles in-app notifications, email notifications, and push notifications
/// for various event types including reminders, deadlines, and results.
class NotificationService {
  final NotificationRepository _repository;
  final Map<NotificationChannel, NotificationChannelHandler> _channelHandlers;
  
  NotificationService({
    required NotificationRepository repository,
    Map<NotificationChannel, NotificationChannelHandler>? channelHandlers,
  }) : _repository = repository,
       _channelHandlers = channelHandlers ?? {};

  /// Register a channel handler for specific notification delivery
  void registerChannelHandler(NotificationChannel channel, NotificationChannelHandler handler) {
    _channelHandlers[channel] = handler;
  }

  /// Send a notification through specified channels
  Future<void> sendNotification(Notification notification) async {
    // Save notification to database first
    await _repository.createNotification(notification);

    // Get user preferences to determine which channels to use
    final preferences = await _repository.getNotificationPreferences(notification.recipientId) ??
        _repository.getDefaultPreferences(notification.recipientId);

    // Filter channels based on user preferences
    final enabledChannels = _getEnabledChannels(notification, preferences);

    // Send through each enabled channel
    for (final channel in enabledChannels) {
      final handler = _channelHandlers[channel];
      if (handler != null) {
        try {
          await handler.sendNotification(notification);
        } catch (e) {
          // Log error but don't fail the entire notification
          print('Failed to send notification through $channel: $e');
        }
      }
    }
  }

  /// Send event reminder notifications
  Future<void> sendEventReminder({
    required Event event,
    required List<String> memberIds,
    required Duration timeUntilEvent,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    final notifications = memberIds.map((memberId) => Notification(
      id: _generateNotificationId(),
      recipientId: memberId,
      type: NotificationType.eventReminder,
      title: 'Event Reminder: ${event.title}',
      message: 'Event "${event.title}" starts in ${_formatDuration(timeUntilEvent)}',
      data: {
        'eventId': event.id,
        'eventTitle': event.title,
        'eventStartTime': event.startTime?.toIso8601String(),
        'timeUntilEvent': timeUntilEvent.inMinutes,
      },
      channels: [NotificationChannel.inApp, NotificationChannel.push],
      priority: priority,
      createdAt: DateTime.now(),
    )).toList();

    await _repository.createNotificationsBatch(notifications);

    // Send through channels
    for (final notification in notifications) {
      await _sendThroughChannels(notification);
    }
  }

  /// Send deadline alert notifications with escalating urgency
  Future<void> sendDeadlineAlert({
    required Event event,
    required List<String> memberIds,
    required Duration timeUntilDeadline,
    bool isEscalated = false,
  }) async {
    final priority = _getDeadlinePriority(timeUntilDeadline, isEscalated);
    final urgencyText = _getUrgencyText(timeUntilDeadline);
    
    final notifications = memberIds.map((memberId) => Notification(
      id: _generateNotificationId(),
      recipientId: memberId,
      type: NotificationType.deadlineAlert,
      title: '$urgencyText: ${event.title} Deadline',
      message: 'Submission deadline for "${event.title}" is in ${_formatDuration(timeUntilDeadline)}',
      data: {
        'eventId': event.id,
        'eventTitle': event.title,
        'deadlineTime': event.submissionDeadline?.toIso8601String(),
        'timeUntilDeadline': timeUntilDeadline.inMinutes,
        'isEscalated': isEscalated,
      },
      channels: _getDeadlineChannels(timeUntilDeadline, isEscalated),
      priority: priority,
      createdAt: DateTime.now(),
    )).toList();

    await _repository.createNotificationsBatch(notifications);

    // Send through channels
    for (final notification in notifications) {
      await _sendThroughChannels(notification);
    }
  }

  /// Send result announcement notifications
  Future<void> sendResultAnnouncement({
    required Event event,
    required List<String> memberIds,
    required String resultSummary,
    Map<String, dynamic>? additionalData,
  }) async {
    final notifications = memberIds.map((memberId) => Notification(
      id: _generateNotificationId(),
      recipientId: memberId,
      type: NotificationType.resultAnnouncement,
      title: 'Results Available: ${event.title}',
      message: resultSummary,
      data: {
        'eventId': event.id,
        'eventTitle': event.title,
        'resultSummary': resultSummary,
        ...?additionalData,
      },
      channels: [NotificationChannel.inApp, NotificationChannel.email],
      priority: NotificationPriority.high,
      createdAt: DateTime.now(),
    )).toList();

    await _repository.createNotificationsBatch(notifications);

    // Send through channels
    for (final notification in notifications) {
      await _sendThroughChannels(notification);
    }
  }

  /// Send leaderboard update notifications
  Future<void> sendLeaderboardUpdate({
    required Event event,
    required List<String> memberIds,
    required String updateMessage,
    Map<String, dynamic>? leaderboardData,
  }) async {
    final notifications = memberIds.map((memberId) => Notification(
      id: _generateNotificationId(),
      recipientId: memberId,
      type: NotificationType.leaderboardUpdate,
      title: 'Leaderboard Update: ${event.title}',
      message: updateMessage,
      data: {
        'eventId': event.id,
        'eventTitle': event.title,
        'updateMessage': updateMessage,
        ...?leaderboardData,
      },
      channels: [NotificationChannel.inApp],
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
    )).toList();

    await _repository.createNotificationsBatch(notifications);

    // Send through channels
    for (final notification in notifications) {
      await _sendThroughChannels(notification);
    }
  }

  /// Send notification when submission is auto-closed due to deadline
  Future<void> sendDeadlineAutoCloseNotification(
    String memberId,
    Event event,
    Submission submission,
  ) async {
    final notification = Notification(
      id: _generateNotificationId(),
      recipientId: memberId,
      type: NotificationType.deadlineAlert,
      title: 'Submission Auto-Closed',
      message: 'Your submission for "${event.title}" was automatically closed due to deadline',
      data: {
        'eventId': event.id,
        'eventTitle': event.title,
        'submissionId': submission.id,
        'autoClosedAt': DateTime.now().toIso8601String(),
      },
      channels: [NotificationChannel.inApp, NotificationChannel.email],
      priority: NotificationPriority.high,
      createdAt: DateTime.now(),
    );

    await sendNotification(notification);
  }

  /// Send notification when deadline has passed to event organizers
  Future<void> sendDeadlinePassedNotification(
    Event event,
    int autoClosedCount,
  ) async {
    // This would typically go to event organizers/admins
    // For now, we'll send to the event creator
    final notification = Notification(
      id: _generateNotificationId(),
      recipientId: event.createdBy,
      type: NotificationType.deadlineAlert,
      title: 'Event Deadline Passed',
      message: 'Deadline for "${event.title}" has passed. $autoClosedCount submissions were auto-closed.',
      data: {
        'eventId': event.id,
        'eventTitle': event.title,
        'autoClosedCount': autoClosedCount,
        'deadlinePassed': DateTime.now().toIso8601String(),
      },
      channels: [NotificationChannel.inApp, NotificationChannel.email],
      priority: NotificationPriority.high,
      createdAt: DateTime.now(),
    );

    await sendNotification(notification);
  }

  /// Send deadline reminder notification to participants
  Future<void> sendDeadlineReminderNotification(
    String memberId,
    Event event,
    Duration timeRemaining,
  ) async {
    await sendDeadlineAlert(
      event: event,
      memberIds: [memberId],
      timeUntilDeadline: timeRemaining,
    );
  }

  /// Send deadline reminder to event organizers
  Future<void> sendOrganizerDeadlineReminder(
    Event event,
    Duration timeRemaining,
    int pendingSubmissions,
  ) async {
    final notification = Notification(
      id: _generateNotificationId(),
      recipientId: event.createdBy,
      type: NotificationType.deadlineAlert,
      title: 'Organizer Reminder: ${event.title}',
      message: 'Event deadline in ${_formatDuration(timeRemaining)}. $pendingSubmissions submissions pending.',
      data: {
        'eventId': event.id,
        'eventTitle': event.title,
        'timeRemaining': timeRemaining.inMinutes,
        'pendingSubmissions': pendingSubmissions,
      },
      channels: [NotificationChannel.inApp, NotificationChannel.email],
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
    );

    await sendNotification(notification);
  }

  /// Schedule notifications for future delivery
  Future<void> scheduleNotification(Notification notification) async {
    await _repository.createNotification(notification);
  }

  /// Process scheduled notifications that are ready to be sent
  Future<void> processScheduledNotifications() async {
    final scheduledNotifications = await _repository.getScheduledNotifications();
    
    for (final notification in scheduledNotifications) {
      await _sendThroughChannels(notification);
      // Remove the scheduled notification after sending
      await _repository.deleteNotification(notification.id);
    }
  }

  /// Get notifications for a member
  Future<List<Notification>> getMemberNotifications(String memberId, {int limit = 50}) async {
    return await _repository.getMemberNotifications(memberId, limit: limit);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _repository.markNotificationAsRead(notificationId);
  }

  /// Mark all notifications as read for a member
  Future<void> markAllAsRead(String memberId) async {
    await _repository.markAllNotificationsAsRead(memberId);
  }

  /// Get unread notifications count
  Future<int> getUnreadCount(String memberId) async {
    return await _repository.getUnreadNotificationsCount(memberId);
  }

  /// Stream of notifications for real-time updates
  Stream<List<Notification>> streamNotifications(String memberId) {
    return _repository.streamMemberNotifications(memberId);
  }

  /// Save notification preferences
  Future<void> saveNotificationPreferences(NotificationPreferences preferences) async {
    await _repository.saveNotificationPreferences(preferences);
  }

  /// Get notification preferences
  Future<NotificationPreferences> getNotificationPreferences(String memberId) async {
    return await _repository.getNotificationPreferences(memberId) ??
        _repository.getDefaultPreferences(memberId);
  }

  // Private helper methods

  List<NotificationChannel> _getEnabledChannels(
    Notification notification,
    NotificationPreferences preferences,
  ) {
    // Check if the notification type is enabled in preferences
    final typeEnabled = preferences.typePreferences[notification.type] ?? 
        _getDefaultTypePreference(notification.type, preferences);
    
    if (!typeEnabled) return [];

    // Return intersection of notification channels and user preferred channels
    return notification.channels
        .where((channel) => preferences.preferredChannels.contains(channel))
        .toList();
  }

  bool _getDefaultTypePreference(NotificationType type, NotificationPreferences preferences) {
    switch (type) {
      case NotificationType.eventReminder:
        return preferences.eventReminders;
      case NotificationType.deadlineAlert:
        return preferences.deadlineAlerts;
      case NotificationType.resultAnnouncement:
        return preferences.resultAnnouncements;
      case NotificationType.leaderboardUpdate:
        return preferences.leaderboardUpdates;
      case NotificationType.badgeAwarded:
        return preferences.badgeNotifications ?? true;
      case NotificationType.milestoneCompleted:
        return preferences.milestoneNotifications ?? true;
      case NotificationType.general:
        return true;
    }
  }

  Future<void> _sendThroughChannels(Notification notification) async {
    final preferences = await _repository.getNotificationPreferences(notification.recipientId) ??
        _repository.getDefaultPreferences(notification.recipientId);

    final enabledChannels = _getEnabledChannels(notification, preferences);

    for (final channel in enabledChannels) {
      final handler = _channelHandlers[channel];
      if (handler != null) {
        try {
          await handler.sendNotification(notification);
        } catch (e) {
          print('Failed to send notification through $channel: $e');
        }
      }
    }
  }

  NotificationPriority _getDeadlinePriority(Duration timeUntilDeadline, bool isEscalated) {
    if (isEscalated || timeUntilDeadline.inHours <= 1) {
      return NotificationPriority.urgent;
    } else if (timeUntilDeadline.inHours <= 6) {
      return NotificationPriority.high;
    } else if (timeUntilDeadline.inDays <= 1) {
      return NotificationPriority.normal;
    } else {
      return NotificationPriority.low;
    }
  }

  String _getUrgencyText(Duration timeUntilDeadline) {
    if (timeUntilDeadline.inMinutes <= 30) {
      return 'URGENT';
    } else if (timeUntilDeadline.inHours <= 2) {
      return 'CRITICAL';
    } else if (timeUntilDeadline.inHours <= 6) {
      return 'IMPORTANT';
    } else {
      return 'REMINDER';
    }
  }

  List<NotificationChannel> _getDeadlineChannels(Duration timeUntilDeadline, bool isEscalated) {
    if (isEscalated || timeUntilDeadline.inHours <= 1) {
      return [NotificationChannel.inApp, NotificationChannel.email, NotificationChannel.push];
    } else if (timeUntilDeadline.inHours <= 6) {
      return [NotificationChannel.inApp, NotificationChannel.push];
    } else {
      return [NotificationChannel.inApp];
    }
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

  String _generateNotificationId() {
    return 'notif_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
}

/// Abstract interface for notification channel handlers
abstract class NotificationChannelHandler {
  Future<void> sendNotification(Notification notification);
}

/// In-app notification handler
class InAppNotificationHandler implements NotificationChannelHandler {
  @override
  Future<void> sendNotification(Notification notification) async {
    // In-app notifications are handled by storing in database
    // and streaming to UI components
    print('In-app notification sent: ${notification.title}');
  }
}

/// Email notification handler
class EmailNotificationHandler implements NotificationChannelHandler {
  @override
  Future<void> sendNotification(Notification notification) async {
    // TODO: Implement actual email sending (e.g., using SendGrid, AWS SES)
    print('Email notification sent to ${notification.recipientId}: ${notification.title}');
  }
}

/// Push notification handler
class PushNotificationHandler implements NotificationChannelHandler {
  @override
  Future<void> sendNotification(Notification notification) async {
    // TODO: Implement actual push notification sending (e.g., using FCM)
    print('Push notification sent to ${notification.recipientId}: ${notification.title}');
  }
}