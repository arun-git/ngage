import '../models/enums.dart';

/// Calendar event for integration with external calendar systems
class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final List<String> attendees;
  final CalendarEventType eventType;
  final String? eventId; // Reference to Ngage event
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.attendees,
    required this.eventType,
    this.eventId,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      location: json['location'] as String?,
      attendees: List<String>.from(json['attendees'] as List),
      eventType: CalendarEventType.fromString(json['eventType'] as String),
      eventId: json['eventId'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'attendees': attendees,
      'eventType': eventType.value,
      'eventId': eventId,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    List<String>? attendees,
    CalendarEventType? eventType,
    String? eventId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      attendees: attendees ?? this.attendees,
      eventType: eventType ?? this.eventType,
      eventId: eventId ?? this.eventId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Email message for integration with email systems
class EmailMessage {
  final String id;
  final List<String> to;
  final List<String>? cc;
  final List<String>? bcc;
  final String subject;
  final String htmlBody;
  final String textBody;
  final EmailTemplateType templateType;
  final Map<String, dynamic> templateData;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime createdAt;

  const EmailMessage({
    required this.id,
    required this.to,
    this.cc,
    this.bcc,
    required this.subject,
    required this.htmlBody,
    required this.textBody,
    required this.templateType,
    required this.templateData,
    this.scheduledAt,
    this.sentAt,
    required this.createdAt,
  });

  factory EmailMessage.fromJson(Map<String, dynamic> json) {
    return EmailMessage(
      id: json['id'] as String,
      to: List<String>.from(json['to'] as List),
      cc: json['cc'] != null ? List<String>.from(json['cc'] as List) : null,
      bcc: json['bcc'] != null ? List<String>.from(json['bcc'] as List) : null,
      subject: json['subject'] as String,
      htmlBody: json['htmlBody'] as String,
      textBody: json['textBody'] as String,
      templateType: EmailTemplateType.fromString(json['templateType'] as String),
      templateData: Map<String, dynamic>.from(json['templateData'] as Map),
      scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt'] as String) : null,
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'to': to,
      'cc': cc,
      'bcc': bcc,
      'subject': subject,
      'htmlBody': htmlBody,
      'textBody': textBody,
      'templateType': templateType.value,
      'templateData': templateData,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}