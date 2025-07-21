import 'validation.dart';
import 'enums.dart';

/// Helper class to distinguish between null and undefined values in copyWith
class _Undefined {
  const _Undefined();
}

/// Judge comment for private collaboration on submissions
/// 
/// Comments are visible only to judges and admins for the specific event.
/// This enables private discussion and collaboration during the judging process.
class JudgeComment {
  final String id;
  final String submissionId;
  final String eventId;
  final String judgeId; // Member ID of the judge who made the comment
  final String content;
  final JudgeCommentType type;
  final String? parentCommentId; // For threaded discussions
  final bool isPrivate; // Private to judges only vs visible to admins
  final DateTime createdAt;
  final DateTime updatedAt;

  const JudgeComment({
    required this.id,
    required this.submissionId,
    required this.eventId,
    required this.judgeId,
    required this.content,
    this.type = JudgeCommentType.general,
    this.parentCommentId,
    this.isPrivate = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create JudgeComment from JSON data
  factory JudgeComment.fromJson(Map<String, dynamic> json) {
    return JudgeComment(
      id: json['id'] as String,
      submissionId: json['submissionId'] as String,
      eventId: json['eventId'] as String,
      judgeId: json['judgeId'] as String,
      content: json['content'] as String,
      type: JudgeCommentType.fromString(json['type'] as String? ?? 'general'),
      parentCommentId: json['parentCommentId'] as String?,
      isPrivate: json['isPrivate'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert JudgeComment to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'submissionId': submissionId,
      'eventId': eventId,
      'judgeId': judgeId,
      'content': content,
      'type': type.value,
      'parentCommentId': parentCommentId,
      'isPrivate': isPrivate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of JudgeComment with updated fields
  JudgeComment copyWith({
    String? id,
    String? submissionId,
    String? eventId,
    String? judgeId,
    String? content,
    JudgeCommentType? type,
    String? parentCommentId,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JudgeComment(
      id: id ?? this.id,
      submissionId: submissionId ?? this.submissionId,
      eventId: eventId ?? this.eventId,
      judgeId: judgeId ?? this.judgeId,
      content: content ?? this.content,
      type: type ?? this.type,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if this is a reply to another comment
  bool get isReply => parentCommentId != null;

  /// Check if this is a top-level comment
  bool get isTopLevel => parentCommentId == null;

  /// Get content preview (first 100 characters)
  String get contentPreview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 97)}...';
  }

  /// Validate JudgeComment data
  ValidationResult validate() {
    final results = [
      Validators.validateId(id, 'Comment ID'),
      Validators.validateId(submissionId, 'Submission ID'),
      Validators.validateId(eventId, 'Event ID'),
      Validators.validateId(judgeId, 'Judge ID'),
      Validators.validateRequired(content, 'Comment content'),
      Validators.validateDate(createdAt, 'Created date'),
      Validators.validateDate(updatedAt, 'Updated date'),
    ];

    // Additional business logic validation
    final additionalErrors = <String>[];
    
    // Validate content length
    if (content.trim().isEmpty) {
      additionalErrors.add('Comment content cannot be empty');
    } else if (content.length > 5000) {
      additionalErrors.add('Comment content must not exceed 5000 characters');
    }
    
    // Validate parent comment ID if provided
    if (parentCommentId != null && parentCommentId!.isEmpty) {
      additionalErrors.add('Parent comment ID cannot be empty if provided');
    }
    
    // updatedAt should be after or equal to createdAt
    if (updatedAt.isBefore(createdAt)) {
      additionalErrors.add('Updated timestamp must be after or equal to creation timestamp');
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
    
    return other is JudgeComment &&
        other.id == id &&
        other.submissionId == submissionId &&
        other.eventId == eventId &&
        other.judgeId == judgeId &&
        other.content == content &&
        other.type == type &&
        other.parentCommentId == parentCommentId &&
        other.isPrivate == isPrivate &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      submissionId,
      eventId,
      judgeId,
      content,
      type,
      parentCommentId,
      isPrivate,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'JudgeComment(id: $id, submissionId: $submissionId, judgeId: $judgeId, type: ${type.value})';
  }
}

/// Judge assignment for events
/// 
/// Manages which judges are assigned to specific events and their permissions.
class JudgeAssignment {
  final String id;
  final String eventId;
  final String judgeId; // Member ID
  final String assignedBy; // Member ID of who assigned the judge
  final JudgeRole role;
  final List<String> permissions; // Specific permissions for this judge
  final bool isActive;
  final DateTime assignedAt;
  final DateTime? revokedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JudgeAssignment({
    required this.id,
    required this.eventId,
    required this.judgeId,
    required this.assignedBy,
    this.role = JudgeRole.judge,
    this.permissions = const [],
    this.isActive = true,
    required this.assignedAt,
    this.revokedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create JudgeAssignment from JSON data
  factory JudgeAssignment.fromJson(Map<String, dynamic> json) {
    final permissionsList = json['permissions'] as List? ?? [];
    return JudgeAssignment(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      judgeId: json['judgeId'] as String,
      assignedBy: json['assignedBy'] as String,
      role: JudgeRole.fromString(json['role'] as String? ?? 'judge'),
      permissions: permissionsList.cast<String>(),
      isActive: json['isActive'] as bool? ?? true,
      assignedAt: DateTime.parse(json['assignedAt'] as String),
      revokedAt: json['revokedAt'] != null ? DateTime.parse(json['revokedAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert JudgeAssignment to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'judgeId': judgeId,
      'assignedBy': assignedBy,
      'role': role.value,
      'permissions': permissions,
      'isActive': isActive,
      'assignedAt': assignedAt.toIso8601String(),
      'revokedAt': revokedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of JudgeAssignment with updated fields
  JudgeAssignment copyWith({
    String? id,
    String? eventId,
    String? judgeId,
    String? assignedBy,
    JudgeRole? role,
    List<String>? permissions,
    bool? isActive,
    DateTime? assignedAt,
    Object? revokedAt = const _Undefined(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JudgeAssignment(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      judgeId: judgeId ?? this.judgeId,
      assignedBy: assignedBy ?? this.assignedBy,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      assignedAt: assignedAt ?? this.assignedAt,
      revokedAt: revokedAt is _Undefined ? this.revokedAt : revokedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if judge has a specific permission
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  /// Add permission to judge
  JudgeAssignment addPermission(String permission) {
    if (permissions.contains(permission)) return this;
    
    final newPermissions = [...permissions, permission];
    return copyWith(
      permissions: newPermissions,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove permission from judge
  JudgeAssignment removePermission(String permission) {
    if (!permissions.contains(permission)) return this;
    
    final newPermissions = permissions.where((p) => p != permission).toList();
    return copyWith(
      permissions: newPermissions,
      updatedAt: DateTime.now(),
    );
  }

  /// Revoke judge assignment
  JudgeAssignment revoke() {
    return copyWith(
      isActive: false,
      revokedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Reactivate judge assignment
  JudgeAssignment reactivate() {
    return copyWith(
      isActive: true,
      revokedAt: null,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if assignment is currently active
  bool get isCurrentlyActive => isActive && revokedAt == null;

  /// Validate JudgeAssignment data
  ValidationResult validate() {
    final results = [
      Validators.validateId(id, 'Assignment ID'),
      Validators.validateId(eventId, 'Event ID'),
      Validators.validateId(judgeId, 'Judge ID'),
      Validators.validateId(assignedBy, 'Assigned by member ID'),
      Validators.validateDate(assignedAt, 'Assigned date'),
      Validators.validateDate(createdAt, 'Created date'),
      Validators.validateDate(updatedAt, 'Updated date'),
    ];

    // Additional business logic validation
    final additionalErrors = <String>[];
    
    // Validate revoked date if provided
    if (revokedAt != null && revokedAt!.isBefore(assignedAt)) {
      additionalErrors.add('Revoked date must be after assigned date');
    }
    
    // If revoked, should not be active
    if (revokedAt != null && isActive) {
      additionalErrors.add('Assignment cannot be active if revoked');
    }
    
    // updatedAt should be after or equal to createdAt
    if (updatedAt.isBefore(createdAt)) {
      additionalErrors.add('Updated timestamp must be after or equal to creation timestamp');
    }
    
    // assignedAt should be after or equal to createdAt
    if (assignedAt.isBefore(createdAt)) {
      additionalErrors.add('Assigned timestamp must be after or equal to creation timestamp');
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
    
    return other is JudgeAssignment &&
        other.id == id &&
        other.eventId == eventId &&
        other.judgeId == judgeId &&
        other.assignedBy == assignedBy &&
        other.role == role &&
        _listEquals(other.permissions, permissions) &&
        other.isActive == isActive &&
        other.assignedAt == assignedAt &&
        other.revokedAt == revokedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      eventId,
      judgeId,
      assignedBy,
      role,
      permissions.length,
      isActive,
      assignedAt,
      revokedAt,
      createdAt,
      updatedAt,
    );
  }

  /// Helper method to compare lists
  bool _listEquals(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    
    return true;
  }

  @override
  String toString() {
    return 'JudgeAssignment(id: $id, eventId: $eventId, judgeId: $judgeId, role: ${role.value}, active: $isActive)';
  }
}