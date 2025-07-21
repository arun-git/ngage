import 'enums.dart';

/// Notification model for the Ngage platform
/// 
/// Represents a notification that can be sent to users through various channels
/// including in-app notifications, email, and push notifications.
class Notification {
  final String id;
  final String recipientId; // Member ID
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data; // Additional context data
  final bool isRead;
  final List<NotificationChannel> channels; // Which channels to send through
  final NotificationPriority priority;
  final DateTime? scheduledAt; // For scheduled notifications
  final DateTime createdAt;
  final DateTime? readAt;

  const Notification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    this.channels = const [NotificationChannel.inApp],
    this.priority = NotificationPriority.normal,
    this.scheduledAt,
    required this.createdAt,
    this.readAt,
  });

  /// Create a copy of this notification with updated fields
  Notification copyWith({
    String? id,
    String? recipientId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    List<NotificationChannel>? channels,
    NotificationPriority? priority,
    DateTime? scheduledAt,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return Notification(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      channels: channels ?? this.channels,
      priority: priority ?? this.priority,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  /// Convert notification to JSON for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipientId': recipientId,
      'type': type.value,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'channels': channels.map((c) => c.value).toList(),
      'priority': priority.value,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  /// Create notification from JSON data
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      recipientId: json['recipientId'] as String,
      type: NotificationType.fromString(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      channels: (json['channels'] as List<dynamic>?)
          ?.map((c) => NotificationChannel.fromString(c as String))
          .toList() ?? [NotificationChannel.inApp],
      priority: NotificationPriority.fromString(json['priority'] as String? ?? 'normal'),
      scheduledAt: json['scheduledAt'] != null 
          ? DateTime.parse(json['scheduledAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null 
          ? DateTime.parse(json['readAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Notification &&
        other.id == id &&
        other.recipientId == recipientId &&
        other.type == type &&
        other.title == title &&
        other.message == message &&
        other.isRead == isRead;
  }

  @override
  int get hashCode {
    return Object.hash(id, recipientId, type, title, message, isRead);
  }

  @override
  String toString() {
    return 'Notification(id: $id, recipientId: $recipientId, type: $type, title: $title, isRead: $isRead)';
  }
}

/// Notification channels for multi-channel delivery
enum NotificationChannel {
  inApp('in_app'),
  email('email'),
  push('push');

  const NotificationChannel(this.value);
  final String value;

  static NotificationChannel fromString(String value) {
    return NotificationChannel.values.firstWhere(
      (channel) => channel.value == value,
      orElse: () => throw ArgumentError('Invalid NotificationChannel: $value'),
    );
  }
}

/// Notification priority levels
enum NotificationPriority {
  low('low'),
  normal('normal'),
  high('high'),
  urgent('urgent');

  const NotificationPriority(this.value);
  final String value;

  static NotificationPriority fromString(String value) {
    return NotificationPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => NotificationPriority.normal,
    );
  }
}

/// Notification preferences for users
class NotificationPreferences {
  final String memberId;
  final bool eventReminders;
  final bool deadlineAlerts;
  final bool resultAnnouncements;
  final bool leaderboardUpdates;
  final List<NotificationChannel> preferredChannels;
  final Map<NotificationType, bool> typePreferences;
  final DateTime updatedAt;

  const NotificationPreferences({
    required this.memberId,
    this.eventReminders = true,
    this.deadlineAlerts = true,
    this.resultAnnouncements = true,
    this.leaderboardUpdates = true,
    this.preferredChannels = const [NotificationChannel.inApp],
    this.typePreferences = const {},
    required this.updatedAt,
  });

  /// Convert preferences to JSON for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'eventReminders': eventReminders,
      'deadlineAlerts': deadlineAlerts,
      'resultAnnouncements': resultAnnouncements,
      'leaderboardUpdates': leaderboardUpdates,
      'preferredChannels': preferredChannels.map((c) => c.value).toList(),
      'typePreferences': typePreferences.map((k, v) => MapEntry(k.value, v)),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create preferences from JSON data
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      memberId: json['memberId'] as String,
      eventReminders: json['eventReminders'] as bool? ?? true,
      deadlineAlerts: json['deadlineAlerts'] as bool? ?? true,
      resultAnnouncements: json['resultAnnouncements'] as bool? ?? true,
      leaderboardUpdates: json['leaderboardUpdates'] as bool? ?? true,
      preferredChannels: (json['preferredChannels'] as List<dynamic>?)
          ?.map((c) => NotificationChannel.fromString(c as String))
          .toList() ?? [NotificationChannel.inApp],
      typePreferences: (json['typePreferences'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(NotificationType.fromString(k), v as bool))
          ?? {},
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Create a copy with updated fields
  NotificationPreferences copyWith({
    String? memberId,
    bool? eventReminders,
    bool? deadlineAlerts,
    bool? resultAnnouncements,
    bool? leaderboardUpdates,
    List<NotificationChannel>? preferredChannels,
    Map<NotificationType, bool>? typePreferences,
    DateTime? updatedAt,
  }) {
    return NotificationPreferences(
      memberId: memberId ?? this.memberId,
      eventReminders: eventReminders ?? this.eventReminders,
      deadlineAlerts: deadlineAlerts ?? this.deadlineAlerts,
      resultAnnouncements: resultAnnouncements ?? this.resultAnnouncements,
      leaderboardUpdates: leaderboardUpdates ?? this.leaderboardUpdates,
      preferredChannels: preferredChannels ?? this.preferredChannels,
      typePreferences: typePreferences ?? this.typePreferences,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}