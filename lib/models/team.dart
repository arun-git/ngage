import 'validation.dart';

/// Team model
///
/// Represents a team within a group. Teams contain members and can have
/// a team lead. Teams can have optional maximum member limits and categorization.
class Team {
  final String id;
  final String groupId;
  final String name;
  final String description;
  final String teamLeadId; // Member ID
  final String? logoUrl; // Team logo URL
  final List<String> memberIds; // List of Member IDs
  final int? maxMembers;
  final String? teamType;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Team({
    required this.id,
    required this.groupId,
    required this.name,
    required this.description,
    required this.teamLeadId,
    this.logoUrl,
    this.memberIds = const [],
    this.maxMembers,
    this.teamType,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Team from JSON data
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      teamLeadId: json['teamLeadId'] as String,
      logoUrl: json['logoUrl'] as String?,
      memberIds: List<String>.from(json['memberIds'] as List? ?? []),
      maxMembers: json['maxMembers'] as int?,
      teamType: json['teamType'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert Team to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'name': name,
      'description': description,
      'teamLeadId': teamLeadId,
      'logoUrl': logoUrl,
      'memberIds': memberIds,
      'maxMembers': maxMembers,
      'teamType': teamType,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Team with updated fields
  Team copyWith({
    String? id,
    String? groupId,
    String? name,
    String? description,
    String? teamLeadId,
    String? logoUrl,
    List<String>? memberIds,
    int? maxMembers,
    String? teamType,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      description: description ?? this.description,
      teamLeadId: teamLeadId ?? this.teamLeadId,
      logoUrl: logoUrl ?? this.logoUrl,
      memberIds: memberIds ?? this.memberIds,
      maxMembers: maxMembers ?? this.maxMembers,
      teamType: teamType ?? this.teamType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get current member count
  int get memberCount => memberIds.length;

  /// Check if team is at capacity
  bool get isAtCapacity => maxMembers != null && memberCount >= maxMembers!;

  /// Check if team can accept more members
  bool get canAcceptMembers => !isAtCapacity;

  /// Check if a member is part of this team
  bool hasMember(String memberId) => memberIds.contains(memberId);

  /// Check if a member is the team lead
  bool isTeamLead(String memberId) => teamLeadId == memberId;

  /// Add a member to the team
  Team addMember(String memberId) {
    if (hasMember(memberId)) {
      return this; // Member already in team
    }

    if (isAtCapacity) {
      throw StateError('Team is at maximum capacity');
    }

    final newMemberIds = [...memberIds, memberId];
    return copyWith(memberIds: newMemberIds);
  }

  /// Remove a member from the team
  Team removeMember(String memberId) {
    if (!hasMember(memberId)) {
      return this; // Member not in team
    }

    if (isTeamLead(memberId)) {
      throw StateError('Cannot remove team lead. Assign new team lead first.');
    }

    final newMemberIds = memberIds.where((id) => id != memberId).toList();
    return copyWith(memberIds: newMemberIds);
  }

  /// Change team lead
  Team changeTeamLead(String newTeamLeadId) {
    // Ensure new team lead is a member of the team
    if (!hasMember(newTeamLeadId)) {
      throw ArgumentError('New team lead must be a member of the team');
    }

    return copyWith(teamLeadId: newTeamLeadId);
  }

  /// Validate Team data
  ValidationResult validate() {
    final results = [
      Validators.validateId(id, 'Team ID'),
      Validators.validateId(groupId, 'Group ID'),
      Validators.validateName(name, 'Team name'),
      Validators.validateDescription(description, maxLength: 1000),
      Validators.validateId(teamLeadId, 'Team lead ID'),
      Validators.validateDate(createdAt, 'Created date'),
      Validators.validateDate(updatedAt, 'Updated date'),
    ];

    // Additional business logic validation
    final additionalErrors = <String>[];

    if (name.length > 100) {
      additionalErrors.add('Team name must not exceed 100 characters');
    }

    if (description.isEmpty) {
      additionalErrors.add('Team description is required');
    }

    // Team lead must be in member list
    if (!memberIds.contains(teamLeadId)) {
      additionalErrors.add('Team lead must be a member of the team');
    }

    // Check max members constraint
    if (maxMembers != null) {
      if (maxMembers! < 1) {
        additionalErrors.add('Maximum members must be at least 1');
      }

      if (memberIds.length > maxMembers!) {
        additionalErrors.add('Team has more members than maximum allowed');
      }
    }

    // Check for duplicate member IDs
    if (memberIds.length != memberIds.toSet().length) {
      additionalErrors.add('Team cannot have duplicate members');
    }

    // Validate team type if provided
    if (teamType != null && teamType!.length > 50) {
      additionalErrors.add('Team type must not exceed 50 characters');
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

    return other is Team &&
        other.id == id &&
        other.groupId == groupId &&
        other.name == name &&
        other.description == description &&
        other.teamLeadId == teamLeadId &&
        other.logoUrl == logoUrl &&
        _listEquals(other.memberIds, memberIds) &&
        other.maxMembers == maxMembers &&
        other.teamType == teamType &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      groupId,
      name,
      description,
      teamLeadId,
      logoUrl,
      memberIds.join(','), // Simple hash for list
      maxMembers,
      teamType,
      isActive,
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
    return 'Team(id: $id, name: $name, groupId: $groupId, memberCount: $memberCount, isActive: $isActive)';
  }
}
