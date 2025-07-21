import '../models/enums.dart';

/// Configuration for multi-platform integrations
class IntegrationConfig {
  final String id;
  final String groupId;
  final IntegrationType type;
  final IntegrationStatus status;
  final Map<String, dynamic> settings;
  final Map<String, String> channelMappings; // notification type -> channel/recipient
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IntegrationConfig({
    required this.id,
    required this.groupId,
    required this.type,
    required this.status,
    required this.settings,
    required this.channelMappings,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IntegrationConfig.fromJson(Map<String, dynamic> json) {
    return IntegrationConfig(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      type: IntegrationType.fromString(json['type'] as String),
      status: IntegrationStatus.fromString(json['status'] as String),
      settings: Map<String, dynamic>.from(json['settings'] as Map),
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
      'status': status.value,
      'settings': settings,
      'channelMappings': channelMappings,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  IntegrationConfig copyWith({
    String? id,
    String? groupId,
    IntegrationType? type,
    IntegrationStatus? status,
    Map<String, dynamic>? settings,
    Map<String, String>? channelMappings,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IntegrationConfig(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      type: type ?? this.type,
      status: status ?? this.status,
      settings: settings ?? this.settings,
      channelMappings: channelMappings ?? this.channelMappings,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Microsoft Teams specific configuration
class TeamsIntegrationSettings {
  final String tenantId;
  final String clientId;
  final String clientSecret;
  final String teamId;
  final String channelId;
  final String? webhookUrl;

  const TeamsIntegrationSettings({
    required this.tenantId,
    required this.clientId,
    required this.clientSecret,
    required this.teamId,
    required this.channelId,
    this.webhookUrl,
  });

  factory TeamsIntegrationSettings.fromJson(Map<String, dynamic> json) {
    return TeamsIntegrationSettings(
      tenantId: json['tenantId'] as String,
      clientId: json['clientId'] as String,
      clientSecret: json['clientSecret'] as String,
      teamId: json['teamId'] as String,
      channelId: json['channelId'] as String,
      webhookUrl: json['webhookUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenantId': tenantId,
      'clientId': clientId,
      'clientSecret': clientSecret,
      'teamId': teamId,
      'channelId': channelId,
      'webhookUrl': webhookUrl,
    };
  }
}

/// Email integration settings
class EmailIntegrationSettings {
  final String smtpHost;
  final int smtpPort;
  final String username;
  final String password;
  final bool useTLS;
  final String fromEmail;
  final String fromName;
  final Map<String, String> templates; // template type -> template content

  const EmailIntegrationSettings({
    required this.smtpHost,
    required this.smtpPort,
    required this.username,
    required this.password,
    required this.useTLS,
    required this.fromEmail,
    required this.fromName,
    required this.templates,
  });

  factory EmailIntegrationSettings.fromJson(Map<String, dynamic> json) {
    return EmailIntegrationSettings(
      smtpHost: json['smtpHost'] as String,
      smtpPort: json['smtpPort'] as int,
      username: json['username'] as String,
      password: json['password'] as String,
      useTLS: json['useTLS'] as bool,
      fromEmail: json['fromEmail'] as String,
      fromName: json['fromName'] as String,
      templates: Map<String, String>.from(json['templates'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'smtpHost': smtpHost,
      'smtpPort': smtpPort,
      'username': username,
      'password': password,
      'useTLS': useTLS,
      'fromEmail': fromEmail,
      'fromName': fromName,
      'templates': templates,
    };
  }
}

/// Calendar integration settings
class CalendarIntegrationSettings {
  final String calendarId;
  final String accessToken;
  final String refreshToken;
  final DateTime tokenExpiry;
  final Map<String, bool> eventTypes; // event type -> enabled

  const CalendarIntegrationSettings({
    required this.calendarId,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenExpiry,
    required this.eventTypes,
  });

  factory CalendarIntegrationSettings.fromJson(Map<String, dynamic> json) {
    return CalendarIntegrationSettings(
      calendarId: json['calendarId'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenExpiry: DateTime.parse(json['tokenExpiry'] as String),
      eventTypes: Map<String, bool>.from(json['eventTypes'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calendarId': calendarId,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenExpiry': tokenExpiry.toIso8601String(),
      'eventTypes': eventTypes,
    };
  }
}