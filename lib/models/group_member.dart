import 'enums.dart';
import 'validation.dart';

/// Group membership with roles
/// 
/// Represents the relationship between a member and a group, including
/// their role within that group and when they joined.
class GroupMember {
  final String id;
  final String groupId;
  final String memberId;
  final GroupRole role;
  final DateTime joinedAt;
  final DateTime createdAt;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.memberId,
    required this.role,
    required this.joinedAt,
    required this.createdAt,
  });

  /// Create GroupMember from JSON data
  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      memberId: json['memberId'] as String,
      role: GroupRole.fromString(json['role'] as String),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert GroupMember to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'memberId': memberId,
      'role': role.value,
      'joinedAt': joinedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy of GroupMember with updated fields
  GroupMember copyWith({
    String? id,
    String? groupId,
    String? memberId,
    GroupRole? role,
    DateTime? joinedAt,
    DateTime? createdAt,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      memberId: memberId ?? this.memberId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if member has admin privileges
  bool get isAdmin => role == GroupRole.admin;

  /// Check if member can judge events
  bool get canJudge => role == GroupRole.admin || role == GroupRole.judge;

  /// Check if member can lead teams
  bool get canLeadTeams => role == GroupRole.admin || role == GroupRole.teamLead;

  /// Validate GroupMember data
  ValidationResult validate() {
    final results = [
      Validators.validateId(id, 'GroupMember ID'),
      Validators.validateId(groupId, 'Group ID'),
      Validators.validateId(memberId, 'Member ID'),
      Validators.validateDate(joinedAt, 'Joined date'),
      Validators.validateDate(createdAt, 'Created date'),
    ];

    // Additional validation
    final additionalErrors = <String>[];
    
    // joinedAt should not be in the future
    if (joinedAt.isAfter(DateTime.now())) {
      additionalErrors.add('Joined date cannot be in the future');
    }
    
    // joinedAt should not be before createdAt
    if (joinedAt.isBefore(createdAt)) {
      additionalErrors.add('Joined date cannot be before created date');
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
    
    return other is GroupMember &&
        other.id == id &&
        other.groupId == groupId &&
        other.memberId == memberId &&
        other.role == role &&
        other.joinedAt == joinedAt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      groupId,
      memberId,
      role,
      joinedAt,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'GroupMember(id: $id, groupId: $groupId, memberId: $memberId, role: ${role.value})';
  }
}