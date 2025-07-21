import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/permission.dart';
import '../models/enums.dart';

/// Repository for managing permissions and roles in Firestore
class PermissionRepository {
  final FirebaseFirestore _firestore;
  static const String _permissionsCollection = 'permissions';
  static const String _rolesCollection = 'roles';
  static const String _roleAssignmentsCollection = 'role_assignments';

  PermissionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Permission CRUD operations

  /// Create a new permission
  Future<Permission> createPermission(Permission permission) async {
    await _firestore
        .collection(_permissionsCollection)
        .doc(permission.id)
        .set(permission.toJson());
    return permission;
  }

  /// Get permission by ID
  Future<Permission?> getPermissionById(String id) async {
    final doc = await _firestore
        .collection(_permissionsCollection)
        .doc(id)
        .get();
    if (!doc.exists) return null;
    return Permission.fromJson(doc.data()!);
  }

  /// Get all active permissions
  Future<List<Permission>> getActivePermissions() async {
    final query = await _firestore
        .collection(_permissionsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();

    return query.docs
        .map((doc) => Permission.fromJson(doc.data()))
        .toList();
  }

  /// Get permissions by type
  Future<List<Permission>> getPermissionsByType(PermissionType type) async {
    final query = await _firestore
        .collection(_permissionsCollection)
        .where('type', isEqualTo: type.value)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();

    return query.docs
        .map((doc) => Permission.fromJson(doc.data()))
        .toList();
  }

  /// Get permissions by resource
  Future<List<Permission>> getPermissionsByResource(String resource) async {
    final query = await _firestore
        .collection(_permissionsCollection)
        .where('resource', isEqualTo: resource)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();

    return query.docs
        .map((doc) => Permission.fromJson(doc.data()))
        .toList();
  }

  /// Update permission
  Future<Permission> updatePermission(Permission permission) async {
    final updatedPermission = permission.copyWith(updatedAt: DateTime.now());
    await _firestore
        .collection(_permissionsCollection)
        .doc(permission.id)
        .update(updatedPermission.toJson());
    return updatedPermission;
  }

  /// Delete permission
  Future<void> deletePermission(String permissionId) async {
    await _firestore
        .collection(_permissionsCollection)
        .doc(permissionId)
        .delete();
  }

  // Role CRUD operations

  /// Create a new role
  Future<Role> createRole(Role role) async {
    await _firestore
        .collection(_rolesCollection)
        .doc(role.id)
        .set(role.toJson());
    return role;
  }

  /// Get role by ID
  Future<Role?> getRoleById(String id) async {
    final doc = await _firestore
        .collection(_rolesCollection)
        .doc(id)
        .get();
    if (!doc.exists) return null;
    return Role.fromJson(doc.data()!);
  }

  /// Get all active roles
  Future<List<Role>> getActiveRoles() async {
    final query = await _firestore
        .collection(_rolesCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();

    return query.docs
        .map((doc) => Role.fromJson(doc.data()))
        .toList();
  }

  /// Get system roles
  Future<List<Role>> getSystemRoles() async {
    final query = await _firestore
        .collection(_rolesCollection)
        .where('isSystemRole', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();

    return query.docs
        .map((doc) => Role.fromJson(doc.data()))
        .toList();
  }

  /// Update role
  Future<Role> updateRole(Role role) async {
    final updatedRole = role.copyWith(updatedAt: DateTime.now());
    await _firestore
        .collection(_rolesCollection)
        .doc(role.id)
        .update(updatedRole.toJson());
    return updatedRole;
  }

  /// Delete role
  Future<void> deleteRole(String roleId) async {
    await _firestore
        .collection(_rolesCollection)
        .doc(roleId)
        .delete();
  }

  // Role Assignment CRUD operations

  /// Create a new role assignment
  Future<MemberRoleAssignment> createRoleAssignment(MemberRoleAssignment assignment) async {
    await _firestore
        .collection(_roleAssignmentsCollection)
        .doc(assignment.id)
        .set(assignment.toJson());
    return assignment;
  }

  /// Get role assignment by ID
  Future<MemberRoleAssignment?> getRoleAssignmentById(String id) async {
    final doc = await _firestore
        .collection(_roleAssignmentsCollection)
        .doc(id)
        .get();
    if (!doc.exists) return null;
    return MemberRoleAssignment.fromJson(doc.data()!);
  }

  /// Get all role assignments for a member
  Future<List<MemberRoleAssignment>> getMemberRoleAssignments(String memberId) async {
    final query = await _firestore
        .collection(_roleAssignmentsCollection)
        .where('memberId', isEqualTo: memberId)
        .where('isActive', isEqualTo: true)
        .orderBy('assignedAt', descending: true)
        .get();

    return query.docs
        .map((doc) => MemberRoleAssignment.fromJson(doc.data()))
        .where((assignment) => assignment.isValid)
        .toList();
  }

  /// Get role assignments for a specific context
  Future<List<MemberRoleAssignment>> getContextRoleAssignments(
    String contextType, 
    String contextId
  ) async {
    final query = await _firestore
        .collection(_roleAssignmentsCollection)
        .where('contextType', isEqualTo: contextType)
        .where('contextId', isEqualTo: contextId)
        .where('isActive', isEqualTo: true)
        .orderBy('assignedAt', descending: true)
        .get();

    return query.docs
        .map((doc) => MemberRoleAssignment.fromJson(doc.data()))
        .where((assignment) => assignment.isValid)
        .toList();
  }

  /// Get member's role assignment for specific context
  Future<MemberRoleAssignment?> getMemberContextRoleAssignment(
    String memberId,
    String contextType,
    String? contextId,
  ) async {
    Query query = _firestore
        .collection(_roleAssignmentsCollection)
        .where('memberId', isEqualTo: memberId)
        .where('contextType', isEqualTo: contextType)
        .where('isActive', isEqualTo: true);

    if (contextId != null) {
      query = query.where('contextId', isEqualTo: contextId);
    }

    final result = await query
        .orderBy('assignedAt', descending: true)
        .limit(1)
        .get();

    if (result.docs.isEmpty) return null;
    
    final data = result.docs.first.data() as Map<String, dynamic>;
    final assignment = MemberRoleAssignment.fromJson(data);
    return assignment.isValid ? assignment : null;
  }

  /// Update role assignment
  Future<MemberRoleAssignment> updateRoleAssignment(MemberRoleAssignment assignment) async {
    final updatedAssignment = assignment.copyWith(updatedAt: DateTime.now());
    await _firestore
        .collection(_roleAssignmentsCollection)
        .doc(assignment.id)
        .update(updatedAssignment.toJson());
    return updatedAssignment;
  }

  /// Deactivate role assignment
  Future<MemberRoleAssignment> deactivateRoleAssignment(String assignmentId) async {
    final assignment = await getRoleAssignmentById(assignmentId);
    if (assignment == null) {
      throw Exception('Role assignment not found: $assignmentId');
    }

    final deactivatedAssignment = assignment.copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );

    return await updateRoleAssignment(deactivatedAssignment);
  }

  /// Delete role assignment
  Future<void> deleteRoleAssignment(String assignmentId) async {
    await _firestore
        .collection(_roleAssignmentsCollection)
        .doc(assignmentId)
        .delete();
  }

  // Complex queries

  /// Get all permissions for a member (through their roles)
  Future<List<Permission>> getMemberPermissions(String memberId) async {
    final assignments = await getMemberRoleAssignments(memberId);
    final roleIds = assignments.map((a) => a.roleId).toSet().toList();
    
    if (roleIds.isEmpty) return [];

    final roles = await Future.wait(
      roleIds.map((roleId) => getRoleById(roleId))
    );

    final permissionIds = <String>{};
    for (final role in roles) {
      if (role != null) {
        permissionIds.addAll(role.permissionIds);
      }
    }

    if (permissionIds.isEmpty) return [];

    final permissions = await Future.wait(
      permissionIds.map((permissionId) => getPermissionById(permissionId))
    );

    return permissions
        .where((permission) => permission != null && permission.isActive)
        .cast<Permission>()
        .toList();
  }

  /// Check if member has specific permission in context
  Future<bool> memberHasPermission(
    String memberId,
    String permissionName,
    String contextType,
    String? contextId,
  ) async {
    final assignment = await getMemberContextRoleAssignment(
      memberId, 
      contextType, 
      contextId
    );
    
    if (assignment == null) return false;

    final role = await getRoleById(assignment.roleId);
    if (role == null) return false;

    final permissions = await Future.wait(
      role.permissionIds.map((id) => getPermissionById(id))
    );

    return permissions.any((permission) => 
      permission != null && 
      permission.name == permissionName && 
      permission.isActive
    );
  }

  /// Get role assignment statistics
  Future<Map<String, dynamic>> getRoleAssignmentStatistics() async {
    final allAssignments = await _firestore
        .collection(_roleAssignmentsCollection)
        .get();
    
    final stats = <String, dynamic>{
      'total': allAssignments.docs.length,
      'active': 0,
      'expired': 0,
      'byContextType': <String, int>{},
      'byRole': <String, int>{},
    };

    final now = DateTime.now();
    
    for (final doc in allAssignments.docs) {
      final assignment = MemberRoleAssignment.fromJson(doc.data());
      
      if (assignment.isValid) {
        stats['active']++;
      } else {
        stats['expired']++;
      }

      // Count by context type
      final contextKey = assignment.contextType;
      stats['byContextType'][contextKey] = 
          (stats['byContextType'][contextKey] ?? 0) + 1;

      // Count by role
      final roleKey = assignment.roleId;
      stats['byRole'][roleKey] = (stats['byRole'][roleKey] ?? 0) + 1;
    }

    return stats;
  }
}