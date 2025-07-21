import '../models/permission.dart';
import '../models/enums.dart';
import '../repositories/permission_repository.dart';

/// Service for managing role-based permissions and access control
class PermissionService {
  final PermissionRepository _permissionRepository;

  PermissionService({PermissionRepository? permissionRepository})
      : _permissionRepository = permissionRepository ?? PermissionRepository();

  // Permission management

  /// Create a new permission
  Future<Permission> createPermission({
    required String name,
    required String description,
    required PermissionType type,
    required String resource,
    Map<String, dynamic>? conditions,
  }) async {
    final now = DateTime.now();
    final permission = Permission(
      id: _generateId(),
      name: name,
      description: description,
      type: type,
      resource: resource,
      conditions: conditions,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    return await _permissionRepository.createPermission(permission);
  }

  /// Get permission by ID
  Future<Permission?> getPermissionById(String id) async {
    return await _permissionRepository.getPermissionById(id);
  }

  /// Get all active permissions
  Future<List<Permission>> getActivePermissions() async {
    return await _permissionRepository.getActivePermissions();
  }

  /// Get permissions by type
  Future<List<Permission>> getPermissionsByType(PermissionType type) async {
    return await _permissionRepository.getPermissionsByType(type);
  }

  /// Get permissions by resource
  Future<List<Permission>> getPermissionsByResource(String resource) async {
    return await _permissionRepository.getPermissionsByResource(resource);
  }

  /// Update permission
  Future<Permission> updatePermission(Permission permission) async {
    return await _permissionRepository.updatePermission(permission);
  }

  /// Deactivate permission
  Future<Permission> deactivatePermission(String permissionId) async {
    final permission = await getPermissionById(permissionId);
    if (permission == null) {
      throw Exception('Permission not found: $permissionId');
    }

    final deactivatedPermission = permission.copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );

    return await updatePermission(deactivatedPermission);
  }

  /// Delete permission
  Future<void> deletePermission(String permissionId) async {
    await _permissionRepository.deletePermission(permissionId);
  }

  // Role management

  /// Create a new role
  Future<Role> createRole({
    required String name,
    required String description,
    required List<String> permissionIds,
    DataVisibilityLevel defaultVisibility = DataVisibilityLevel.private,
    bool isSystemRole = false,
  }) async {
    final now = DateTime.now();
    final role = Role(
      id: _generateId(),
      name: name,
      description: description,
      permissionIds: permissionIds,
      defaultVisibility: defaultVisibility,
      isSystemRole: isSystemRole,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    return await _permissionRepository.createRole(role);
  }

  /// Get role by ID
  Future<Role?> getRoleById(String id) async {
    return await _permissionRepository.getRoleById(id);
  }

  /// Get all active roles
  Future<List<Role>> getActiveRoles() async {
    return await _permissionRepository.getActiveRoles();
  }

  /// Get system roles
  Future<List<Role>> getSystemRoles() async {
    return await _permissionRepository.getSystemRoles();
  }

  /// Update role
  Future<Role> updateRole(Role role) async {
    return await _permissionRepository.updateRole(role);
  }

  /// Add permission to role
  Future<Role> addPermissionToRole(String roleId, String permissionId) async {
    final role = await getRoleById(roleId);
    if (role == null) {
      throw Exception('Role not found: $roleId');
    }

    final updatedRole = role.addPermission(permissionId);
    return await updateRole(updatedRole);
  }

  /// Remove permission from role
  Future<Role> removePermissionFromRole(String roleId, String permissionId) async {
    final role = await getRoleById(roleId);
    if (role == null) {
      throw Exception('Role not found: $roleId');
    }

    final updatedRole = role.removePermission(permissionId);
    return await updateRole(updatedRole);
  }

  /// Deactivate role
  Future<Role> deactivateRole(String roleId) async {
    final role = await getRoleById(roleId);
    if (role == null) {
      throw Exception('Role not found: $roleId');
    }

    final deactivatedRole = role.copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );

    return await updateRole(deactivatedRole);
  }

  /// Delete role
  Future<void> deleteRole(String roleId) async {
    await _permissionRepository.deleteRole(roleId);
  }

  // Role assignment management

  /// Assign role to member
  Future<MemberRoleAssignment> assignRoleToMember({
    required String memberId,
    required String roleId,
    required String contextType,
    String? contextId,
    Map<String, dynamic>? additionalPermissions,
    DateTime? expiresAt,
  }) async {
    final now = DateTime.now();
    final assignment = MemberRoleAssignment(
      id: _generateId(),
      memberId: memberId,
      roleId: roleId,
      contextId: contextId,
      contextType: contextType,
      additionalPermissions: additionalPermissions,
      isActive: true,
      assignedAt: now,
      expiresAt: expiresAt,
      createdAt: now,
      updatedAt: now,
    );

    return await _permissionRepository.createRoleAssignment(assignment);
  }

  /// Get member's role assignments
  Future<List<MemberRoleAssignment>> getMemberRoleAssignments(String memberId) async {
    return await _permissionRepository.getMemberRoleAssignments(memberId);
  }

  /// Get role assignments for a context
  Future<List<MemberRoleAssignment>> getContextRoleAssignments(
    String contextType, 
    String contextId
  ) async {
    return await _permissionRepository.getContextRoleAssignments(contextType, contextId);
  }

  /// Get member's role assignment for specific context
  Future<MemberRoleAssignment?> getMemberContextRoleAssignment(
    String memberId,
    String contextType,
    String? contextId,
  ) async {
    return await _permissionRepository.getMemberContextRoleAssignment(
      memberId, 
      contextType, 
      contextId
    );
  }

  /// Update role assignment
  Future<MemberRoleAssignment> updateRoleAssignment(MemberRoleAssignment assignment) async {
    return await _permissionRepository.updateRoleAssignment(assignment);
  }

  /// Deactivate role assignment
  Future<MemberRoleAssignment> deactivateRoleAssignment(String assignmentId) async {
    return await _permissionRepository.deactivateRoleAssignment(assignmentId);
  }

  /// Delete role assignment
  Future<void> deleteRoleAssignment(String assignmentId) async {
    await _permissionRepository.deleteRoleAssignment(assignmentId);
  }

  // Permission checking

  /// Check if member has specific permission in context
  Future<bool> memberHasPermission(
    String memberId,
    String permissionName,
    String contextType,
    String? contextId,
  ) async {
    return await _permissionRepository.memberHasPermission(
      memberId, 
      permissionName, 
      contextType, 
      contextId
    );
  }

  /// Get all permissions for a member
  Future<List<Permission>> getMemberPermissions(String memberId) async {
    return await _permissionRepository.getMemberPermissions(memberId);
  }

  /// Check if member can access resource
  Future<bool> canAccessResource(
    String memberId,
    String resource,
    PermissionType permissionType,
    String contextType,
    String? contextId,
  ) async {
    final permissions = await getMemberPermissions(memberId);
    
    return permissions.any((permission) =>
      permission.resource == resource &&
      permission.type == permissionType &&
      permission.isActive
    );
  }

  /// Validate data visibility for member
  Future<bool> canViewData(
    String memberId,
    DataVisibilityLevel dataVisibility,
    String contextType,
    String? contextId,
  ) async {
    // Public data is always visible
    if (dataVisibility == DataVisibilityLevel.public) return true;

    // Get member's role assignment for context
    final assignment = await getMemberContextRoleAssignment(
      memberId, 
      contextType, 
      contextId
    );
    
    if (assignment == null) return false;

    final role = await getRoleById(assignment.roleId);
    if (role == null) return false;

    // Check if member's role visibility level allows access
    return _canAccessVisibilityLevel(role.defaultVisibility, dataVisibility);
  }

  /// Check if visibility level allows access to data
  bool _canAccessVisibilityLevel(
    DataVisibilityLevel memberLevel, 
    DataVisibilityLevel dataLevel
  ) {
    const visibilityHierarchy = {
      DataVisibilityLevel.public: 0,
      DataVisibilityLevel.group: 1,
      DataVisibilityLevel.team: 2,
      DataVisibilityLevel.private: 3,
      DataVisibilityLevel.admin: 4,
    };

    final memberLevelValue = visibilityHierarchy[memberLevel] ?? 0;
    final dataLevelValue = visibilityHierarchy[dataLevel] ?? 0;

    return memberLevelValue >= dataLevelValue;
  }

  // Security utilities

  /// Initialize default system roles and permissions
  Future<void> initializeSystemRoles() async {
    await _createDefaultPermissions();
    await _createDefaultRoles();
  }

  /// Create default permissions
  Future<void> _createDefaultPermissions() async {
    final defaultPermissions = [
      // Group permissions
      {'name': 'group.read', 'description': 'View group information', 'type': PermissionType.read, 'resource': 'group'},
      {'name': 'group.write', 'description': 'Edit group information', 'type': PermissionType.write, 'resource': 'group'},
      {'name': 'group.admin', 'description': 'Administer group', 'type': PermissionType.admin, 'resource': 'group'},
      
      // Event permissions
      {'name': 'event.read', 'description': 'View events', 'type': PermissionType.read, 'resource': 'event'},
      {'name': 'event.write', 'description': 'Create and edit events', 'type': PermissionType.write, 'resource': 'event'},
      {'name': 'event.judge', 'description': 'Judge event submissions', 'type': PermissionType.judge, 'resource': 'event'},
      
      // Submission permissions
      {'name': 'submission.read', 'description': 'View submissions', 'type': PermissionType.read, 'resource': 'submission'},
      {'name': 'submission.write', 'description': 'Create submissions', 'type': PermissionType.write, 'resource': 'submission'},
      {'name': 'submission.moderate', 'description': 'Moderate submissions', 'type': PermissionType.moderate, 'resource': 'submission'},
      
      // Member permissions
      {'name': 'member.read', 'description': 'View member profiles', 'type': PermissionType.read, 'resource': 'member'},
      {'name': 'member.write', 'description': 'Edit member profiles', 'type': PermissionType.write, 'resource': 'member'},
      {'name': 'member.admin', 'description': 'Administer members', 'type': PermissionType.admin, 'resource': 'member'},
    ];

    for (final permData in defaultPermissions) {
      try {
        await createPermission(
          name: permData['name'] as String,
          description: permData['description'] as String,
          type: permData['type'] as PermissionType,
          resource: permData['resource'] as String,
        );
      } catch (e) {
        // Permission might already exist, continue
        print('Permission ${permData['name']} already exists or failed to create: $e');
      }
    }
  }

  /// Create default roles
  Future<void> _createDefaultRoles() async {
    final permissions = await getActivePermissions();
    final permissionMap = {for (var p in permissions) p.name: p.id};

    final defaultRoles = [
      {
        'name': 'Group Admin',
        'description': 'Full administrative access to group',
        'permissions': ['group.admin', 'event.write', 'member.admin', 'submission.moderate'],
        'visibility': DataVisibilityLevel.admin,
        'isSystem': true,
      },
      {
        'name': 'Judge',
        'description': 'Can judge event submissions',
        'permissions': ['event.read', 'submission.read', 'event.judge'],
        'visibility': DataVisibilityLevel.group,
        'isSystem': true,
      },
      {
        'name': 'Team Lead',
        'description': 'Can manage team members and submissions',
        'permissions': ['group.read', 'event.read', 'submission.write', 'member.read'],
        'visibility': DataVisibilityLevel.team,
        'isSystem': true,
      },
      {
        'name': 'Member',
        'description': 'Basic member access',
        'permissions': ['group.read', 'event.read', 'submission.write'],
        'visibility': DataVisibilityLevel.group,
        'isSystem': true,
      },
    ];

    for (final roleData in defaultRoles) {
      try {
        final permissionIds = (roleData['permissions'] as List<String>)
            .map((name) => permissionMap[name])
            .where((id) => id != null)
            .cast<String>()
            .toList();

        await createRole(
          name: roleData['name'] as String,
          description: roleData['description'] as String,
          permissionIds: permissionIds,
          defaultVisibility: roleData['visibility'] as DataVisibilityLevel,
          isSystemRole: roleData['isSystem'] as bool,
        );
      } catch (e) {
        // Role might already exist, continue
        print('Role ${roleData['name']} already exists or failed to create: $e');
      }
    }
  }

  /// Get role assignment statistics
  Future<Map<String, dynamic>> getRoleAssignmentStatistics() async {
    return await _permissionRepository.getRoleAssignmentStatistics();
  }

  /// Generate unique ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (1000 + (999 * (DateTime.now().microsecond / 1000000)).round()).toString();
  }}
