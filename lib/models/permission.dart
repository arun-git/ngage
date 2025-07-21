import '../models/enums.dart';

/// Represents a permission for role-based access control
class Permission {
  final String id;
  final String name;
  final String description;
  final PermissionType type;
  final String resource;
  final Map<String, dynamic>? conditions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Permission({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.resource,
    this.conditions,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this permission with updated fields
  Permission copyWith({
    String? id,
    String? name,
    String? description,
    PermissionType? type,
    String? resource,
    Map<String, dynamic>? conditions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Permission(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      resource: resource ?? this.resource,
      conditions: conditions ?? this.conditions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.value,
      'resource': resource,
      'conditions': conditions,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON (Firestore document)
  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: PermissionType.fromString(json['type'] as String),
      resource: json['resource'] as String,
      conditions: json['conditions'] as Map<String, dynamic>?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Permission && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Permission(id: $id, name: $name, type: ${type.value}, resource: $resource)';
  }
}

/// Represents a role with associated permissions
class Role {
  final String id;
  final String name;
  final String description;
  final List<String> permissionIds;
  final DataVisibilityLevel defaultVisibility;
  final bool isSystemRole;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Role({
    required this.id,
    required this.name,
    required this.description,
    required this.permissionIds,
    required this.defaultVisibility,
    required this.isSystemRole,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this role with updated fields
  Role copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? permissionIds,
    DataVisibilityLevel? defaultVisibility,
    bool? isSystemRole,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Role(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      permissionIds: permissionIds ?? this.permissionIds,
      defaultVisibility: defaultVisibility ?? this.defaultVisibility,
      isSystemRole: isSystemRole ?? this.isSystemRole,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Add permission to role
  Role addPermission(String permissionId) {
    if (permissionIds.contains(permissionId)) return this;
    return copyWith(
      permissionIds: [...permissionIds, permissionId],
      updatedAt: DateTime.now(),
    );
  }

  /// Remove permission from role
  Role removePermission(String permissionId) {
    if (!permissionIds.contains(permissionId)) return this;
    return copyWith(
      permissionIds: permissionIds.where((id) => id != permissionId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Convert to JSON for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'permissionIds': permissionIds,
      'defaultVisibility': defaultVisibility.value,
      'isSystemRole': isSystemRole,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON (Firestore document)
  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      permissionIds: List<String>.from(json['permissionIds'] as List),
      defaultVisibility: DataVisibilityLevel.fromString(json['defaultVisibility'] as String),
      isSystemRole: json['isSystemRole'] as bool,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Role && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Role(id: $id, name: $name, permissions: ${permissionIds.length})';
  }
}

/// Represents a member's role assignment in a specific context
class MemberRoleAssignment {
  final String id;
  final String memberId;
  final String roleId;
  final String? contextId; // Group ID, Event ID, etc.
  final String contextType; // 'group', 'event', 'global'
  final Map<String, dynamic>? additionalPermissions;
  final bool isActive;
  final DateTime assignedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MemberRoleAssignment({
    required this.id,
    required this.memberId,
    required this.roleId,
    this.contextId,
    required this.contextType,
    this.additionalPermissions,
    required this.isActive,
    required this.assignedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this assignment with updated fields
  MemberRoleAssignment copyWith({
    String? id,
    String? memberId,
    String? roleId,
    String? contextId,
    String? contextType,
    Map<String, dynamic>? additionalPermissions,
    bool? isActive,
    DateTime? assignedAt,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemberRoleAssignment(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      roleId: roleId ?? this.roleId,
      contextId: contextId ?? this.contextId,
      contextType: contextType ?? this.contextType,
      additionalPermissions: additionalPermissions ?? this.additionalPermissions,
      isActive: isActive ?? this.isActive,
      assignedAt: assignedAt ?? this.assignedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if assignment is currently valid
  bool get isValid {
    if (!isActive) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  /// Convert to JSON for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'roleId': roleId,
      'contextId': contextId,
      'contextType': contextType,
      'additionalPermissions': additionalPermissions,
      'isActive': isActive,
      'assignedAt': assignedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON (Firestore document)
  factory MemberRoleAssignment.fromJson(Map<String, dynamic> json) {
    return MemberRoleAssignment(
      id: json['id'] as String,
      memberId: json['memberId'] as String,
      roleId: json['roleId'] as String,
      contextId: json['contextId'] as String?,
      contextType: json['contextType'] as String,
      additionalPermissions: json['additionalPermissions'] as Map<String, dynamic>?,
      isActive: json['isActive'] as bool,
      assignedAt: DateTime.parse(json['assignedAt'] as String),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt'] as String) 
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemberRoleAssignment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MemberRoleAssignment(id: $id, memberId: $memberId, roleId: $roleId, contextType: $contextType)';
  }
}