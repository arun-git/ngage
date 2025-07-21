import 'enums.dart';

/// Generic integration configuration for different platforms
class Integration {
  final String id;
  final String groupId;
  final IntegrationType type;
  final String name;
  final Map<String, dynamic> configuration;
  final Map<String, String> channelMappings; // notification type -> channel/recipient ID
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Integration({
    required this.id,
    required this.groupId,
    required this.type,
    required this.name,
    required this.configuration,
    required this.channelMappings,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Integration.fromJson(Map<String, dynamic> json) {
    return Integration(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      type: IntegrationType.fromString(json['type'] as String),
      name: json['name'] as String,
      configuration: Map<String, dynamic>.from(json['configuration'] as Map),
      channelMappings: Map<String, String>.from(json['channelMappings'] as Map),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'type': type.value,
      'name': name,
      'configuration': configuration,
      'channelMappings': channelMappings,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Integration copyWith({
    String? id,
    String? groupId,
    IntegrationType? type,
    String? name,
    Map<String, dynamic>? configuration,
    Map<String, String>? channelMappings,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Integration(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      type: type ?? this.type,
      name: name ?? this.name,
      configuration: configuration ?? this.configuration,
      channelMappings: channelMappings ?? this.channelMappings,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Microsoft Teams integration configuration
class TeamsIntegration {
  final String id;
  final String groupId;
  final String tenantId;
  final String teamId;
  final String teamName;
  final String accessToken;
  final String? refreshToken;
  final Map<String, String> channelMappings;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TeamsIntegration({
    required this.id,
    required this.groupId,
    required this.tenantId,
    required this.teamId,
    required this.teamName,
    required this.accessToken,
    this.refreshToken,
    required this.channelMappings,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamsIntegration.fromJson(Map<String, dynamic> json) {
    return TeamsIntegration(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      tenantId: json['tenantId'] as String,
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      channelMappings: Map<String, String>.from(json['channelMappings'] as Map),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'tenantId': tenantId,
      'teamId': teamId,
      'teamName': teamName,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'channelMappings': channelMappings,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  TeamsIntegration copyWith({
    String? id,
    String? groupId,
    String? tenantId,
    String? teamId,
    String? teamName,
    String? accessToken,
    String? refreshToken,
    Map<String, String>? channelMappings,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamsIntegration(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      tenantId: tenantId ?? this.tenantId,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      channelMappings: channelMappings ?? this.channelMappings,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Calendar integration configuration
class CalendarIntegration {
  final String id;
  final String groupId;
  final CalendarProvider provider;
  final String accessToken;
  final String? refreshToken;
  final String calendarId;
  final String calendarName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CalendarIntegration({
    required this.id,
    required this.groupId,
    required this.provider,
    required this.accessToken,
    this.refreshToken,
    required this.calendarId,
    required this.calendarName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalendarIntegration.fromJson(Map<String, dynamic> json) {
    return CalendarIntegration(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      provider: CalendarProvider.fromString(json['provider'] as String),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      calendarId: json['calendarId'] as String,
      calendarName: json['calendarName'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'provider': provider.value,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'calendarId': calendarId,
      'calendarName': calendarName,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CalendarIntegration copyWith({
    String? id,
    String? groupId,
    CalendarProvider? provider,
    String? accessToken,
    String? refreshToken,
    String? calendarId,
    String? calendarName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarIntegration(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      provider: provider ?? this.provider,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      calendarId: calendarId ?? this.calendarId,
      calendarName: calendarName ?? this.calendarName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Email integration configuration
class EmailIntegration {
  final String id;
  final String groupId;
  final EmailProvider provider;
  final Map<String, dynamic> configuration;
  final List<String> recipientEmails;
  final Map<String, List<String>> notificationMappings; // notification type -> email list
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EmailIntegration({
    required this.id,
    required this.groupId,
    required this.provider,
    required this.configuration,
    required this.recipientEmails,
    required this.notificationMappings,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmailIntegration.fromJson(Map<String, dynamic> json) {
    return EmailIntegration(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      provider: EmailProvider.fromString(json['provider'] as String),
      configuration: Map<String, dynamic>.from(json['configuration'] as Map),
      recipientEmails: List<String>.from(json['recipientEmails'] as List),
      notificationMappings: Map<String, List<String>>.from(
        (json['notificationMappings'] as Map).map(
          (key, value) => MapEntry(key as String, List<String>.from(value as List)),
        ),
      ),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'provider': provider.value,
      'configuration': configuration,
      'recipientEmails': recipientEmails,
      'notificationMappings': notificationMappings,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  EmailIntegration copyWith({
    String? id,
    String? groupId,
    EmailProvider? provider,
    Map<String, dynamic>? configuration,
    List<String>? recipientEmails,
    Map<String, List<String>>? notificationMappings,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmailIntegration(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      provider: provider ?? this.provider,
      configuration: configuration ?? this.configuration,
      recipientEmails: recipientEmails ?? this.recipientEmails,
      notificationMappings: notificationMappings ?? this.notificationMappings,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Generic notification message for multi-platform support
class NotificationMessage {
  final String title;
  final String content;
  final NotificationType type;
  final Map<String, dynamic>? metadata;
  final DateTime? scheduledAt;
  final List<String>? recipients;

  const NotificationMessage({
    required this.title,
    required this.content,
    required this.type,
    this.metadata,
    this.scheduledAt,
    this.recipients,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'type': type.value,
      'metadata': metadata,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'recipients': recipients,
    };
  }
}

/// Calendar event for integration
class CalendarEvent {
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final List<String>? attendees;
  final Map<String, dynamic>? metadata;

  const CalendarEvent({
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.attendees,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'attendees': attendees,
      'metadata': metadata,
    };
  }
}

/// Teams channel information
class TeamsChannel {
  final String id;
  final String name;
  final String description;
  final bool isPrivate;
  final bool isMember;

  const TeamsChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.isPrivate,
    required this.isMember,
  });

  factory TeamsChannel.fromJson(Map<String, dynamic> json) {
    return TeamsChannel(
      id: json['id'] as String,
      name: json['displayName'] as String,
      description: json['description'] as String? ?? '',
      isPrivate: json['membershipType'] == 'private',
      isMember: json['isMember'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': name,
      'description': description,
      'membershipType': isPrivate ? 'private' : 'standard',
      'isMember': isMember,
    };
  }
}

/// Teams message for sending notifications
class TeamsMessage {
  final String channelId;
  final String content;
  final String? subject;
  final List<TeamsAttachment>? attachments;
  final Map<String, dynamic>? metadata;

  const TeamsMessage({
    required this.channelId,
    required this.content,
    this.subject,
    this.attachments,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'body': {
        'contentType': 'html',
        'content': content,
      },
      if (subject != null) 'subject': subject,
      if (attachments != null)
        'attachments': attachments!.map((a) => a.toJson()).toList(),
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Teams message attachment
class TeamsAttachment {
  final String contentType;
  final String content;
  final String? name;

  const TeamsAttachment({
    required this.contentType,
    required this.content,
    this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'contentType': contentType,
      'content': content,
      if (name != null) 'name': name,
    };
  }
}