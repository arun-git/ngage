import 'enums.dart';
import 'validation.dart';

/// Event model
/// 
/// Represents an event within a group. Events can be competitions, challenges,
/// or surveys. They have a lifecycle with different statuses and can be restricted
/// to specific teams.
class Event {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final EventType eventType;
  final EventStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? submissionDeadline;
  final List<String>? eligibleTeamIds;
  final Map<String, dynamic> judgingCriteria;
  final String createdBy; // Member ID
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.eventType,
    this.status = EventStatus.draft,
    this.startTime,
    this.endTime,
    this.submissionDeadline,
    this.eligibleTeamIds,
    this.judgingCriteria = const {},
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Event from JSON data
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      eventType: EventType.fromString(json['eventType'] as String),
      status: EventStatus.fromString(json['status'] as String),
      startTime: json['startTime'] != null 
          ? DateTime.parse(json['startTime'] as String) 
          : null,
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime'] as String) 
          : null,
      submissionDeadline: json['submissionDeadline'] != null 
          ? DateTime.parse(json['submissionDeadline'] as String) 
          : null,
      eligibleTeamIds: json['eligibleTeamIds'] != null
          ? List<String>.from(json['eligibleTeamIds'] as List)
          : null,
      judgingCriteria: Map<String, dynamic>.from(json['judgingCriteria'] as Map? ?? {}),
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert Event to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'title': title,
      'description': description,
      'eventType': eventType.value,
      'status': status.value,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'submissionDeadline': submissionDeadline?.toIso8601String(),
      'eligibleTeamIds': eligibleTeamIds,
      'judgingCriteria': judgingCriteria,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Event with updated fields
  Event copyWith({
    String? id,
    String? groupId,
    String? title,
    String? description,
    EventType? eventType,
    EventStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? submissionDeadline,
    List<String>? eligibleTeamIds,
    Map<String, dynamic>? judgingCriteria,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventType: eventType ?? this.eventType,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      submissionDeadline: submissionDeadline ?? this.submissionDeadline,
      eligibleTeamIds: eligibleTeamIds ?? this.eligibleTeamIds,
      judgingCriteria: judgingCriteria ?? this.judgingCriteria,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if event is open to all teams
  bool get isOpenEvent => eligibleTeamIds == null || eligibleTeamIds!.isEmpty;

  /// Check if event is restricted to specific teams
  bool get isRestrictedEvent => !isOpenEvent;

  /// Check if a team is eligible for this event
  bool isTeamEligible(String teamId) {
    return isOpenEvent || eligibleTeamIds!.contains(teamId);
  }

  /// Check if event is currently active
  bool get isActive => status == EventStatus.active;

  /// Check if event is completed
  bool get isCompleted => status == EventStatus.completed;

  /// Check if event is cancelled
  bool get isCancelled => status == EventStatus.cancelled;

  /// Check if event is in draft status
  bool get isDraft => status == EventStatus.draft;

  /// Check if event is scheduled
  bool get isScheduled => status == EventStatus.scheduled;

  /// Check if submissions are currently open
  bool get areSubmissionsOpen {
    if (!isActive) return false;
    
    final now = DateTime.now();
    
    // Check if we're within the event time window
    if (startTime != null && now.isBefore(startTime!)) return false;
    if (endTime != null && now.isAfter(endTime!)) return false;
    
    // Check if submission deadline has passed
    if (submissionDeadline != null && now.isAfter(submissionDeadline!)) return false;
    
    return true;
  }

  /// Get time remaining until submission deadline
  Duration? get timeUntilDeadline {
    if (submissionDeadline == null) return null;
    
    final now = DateTime.now();
    if (now.isAfter(submissionDeadline!)) return null;
    
    return submissionDeadline!.difference(now);
  }

  /// Get a judging criterion value
  T? getJudgingCriterion<T>(String key, [T? defaultValue]) {
    final value = judgingCriteria[key];
    if (value is T) return value;
    return defaultValue;
  }

  /// Create a new Event with updated judging criteria
  Event updateJudgingCriterion(String key, dynamic value) {
    final newCriteria = Map<String, dynamic>.from(judgingCriteria);
    newCriteria[key] = value;
    return copyWith(judgingCriteria: newCriteria);
  }

  /// Validate Event data
  ValidationResult validate() {
    final results = [
      Validators.validateId(id, 'Event ID'),
      Validators.validateId(groupId, 'Group ID'),
      Validators.validateName(title, 'Event title'),
      Validators.validateDescription(description, maxLength: 2000),
      Validators.validateId(createdBy, 'Created by member ID'),
      Validators.validateDate(createdAt, 'Created date'),
      Validators.validateDate(updatedAt, 'Updated date'),
    ];

    // Additional business logic validation
    final additionalErrors = <String>[];
    
    if (title.length > 200) {
      additionalErrors.add('Event title must not exceed 200 characters');
    }
    
    if (description.isEmpty) {
      additionalErrors.add('Event description is required');
    }
    
    // Date validation
    if (startTime != null && endTime != null) {
      if (endTime!.isBefore(startTime!)) {
        additionalErrors.add('End time must be after start time');
      }
    }
    
    if (submissionDeadline != null) {
      if (startTime != null && submissionDeadline!.isBefore(startTime!)) {
        additionalErrors.add('Submission deadline must be after start time');
      }
      
      if (endTime != null && submissionDeadline!.isAfter(endTime!)) {
        additionalErrors.add('Submission deadline must be before end time');
      }
    }
    
    // Status validation
    if (status == EventStatus.scheduled && (startTime == null || endTime == null)) {
      additionalErrors.add('Scheduled events must have start and end times');
    }
    
    if (status == EventStatus.active && startTime == null) {
      additionalErrors.add('Active events must have a start time');
    }
    
    // Eligible teams validation
    if (eligibleTeamIds != null) {
      if (eligibleTeamIds!.isEmpty) {
        additionalErrors.add('If eligible teams are specified, at least one team must be included');
      }
      
      // Check for duplicates
      if (eligibleTeamIds!.length != eligibleTeamIds!.toSet().length) {
        additionalErrors.add('Eligible teams list cannot contain duplicates');
      }
    }

    final baseValidation = Validators.combine(results);
    
    if (additionalErrors.isNotEmpty) {
      final allErrors = [...baseValidation.errors, ...additionalErrors];
      return ValidationResult.invalid(allErrors);
    }
    
    return baseValidation;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Event &&
        other.id == id &&
        other.groupId == groupId &&
        other.title == title &&
        other.description == description &&
        other.eventType == eventType &&
        other.status == status &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.submissionDeadline == submissionDeadline &&
        _listEquals(other.eligibleTeamIds, eligibleTeamIds) &&
        _mapEquals(other.judgingCriteria, judgingCriteria) &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      groupId,
      title,
      description,
      eventType,
      status,
      startTime,
      endTime,
      submissionDeadline,
      eligibleTeamIds?.join(','),
      judgingCriteria.toString(),
      createdBy,
      createdAt,
      updatedAt,
    );
  }

  /// Helper method to compare lists
  bool _listEquals(List<String>? list1, List<String>? list2) {
    if (list1 == null && list2 == null) return true;
    if (list1 == null || list2 == null) return false;
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    
    return true;
  }

  /// Helper method to compare maps
  bool _mapEquals(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    
    return true;
  }

  @override
  String toString() {
    return 'Event(id: $id, title: $title, eventType: ${eventType.value}, status: ${status.value}, groupId: $groupId)';
  }
}