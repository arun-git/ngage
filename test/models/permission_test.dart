import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/permission.dart';
import '../../lib/models/enums.dart';

void main() {
  group('Permission Model', () {
    test('should create permission with all fields', () {
      // Arrange
      final now = DateTime.now();
      
      // Act
      final permission = Permission(
        id: 'perm_1',
        name: 'test.read',
        description: 'Test read permission',
        type: PermissionType.read,
        resource: 'test',
        conditions: {'scope': 'limited'},
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Assert
      expect(permission.id, equals('perm_1'));
      expect(permission.name, equals('test.read'));
      expect(permission.description, equals('Test read permission'));
      expect(permission.type, equals(PermissionType.read));
      expect(permission.resource, equals('test'));
      expect(permission.conditions?['scope'], equals('limited'));
      expect(permission.isActive, isTrue);
      expect(permission.createdAt, equals(now));
      expect(permission.updatedAt, equals(now));
    });

    test('should create permission copy with updated fields', () {
      // Arrange
      final original = Permission(
        id: 'perm_1',
        name: 'test.read',
        description: 'Original description',
        type: PermissionType.read,
        resource: 'test',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final updated = original.copyWith(
        description: 'Updated description',
        isActive: false,
      );

      // Assert
      expect(updated.id, equals(original.id));
      expect(updated.name, equals(original.name));
      expect(updated.description, equals('Updated description'));
      expect(updated.isActive, isFalse);
      expect(updated.type, equals(original.type));
      expect(updated.resource, equals(original.resource));
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final now = DateTime.now();
      final permission = Permission(
        id: 'perm_1',
        name: 'test.read',
        description: 'Test read permission',
        type: PermissionType.read,
        resource: 'test',
        conditions: {'scope': 'limited'},
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Act
      final json = permission.toJson();

      // Assert
      expect(json['id'], equals('perm_1'));
      expect(json['name'], equals('test.read'));
      expect(json['description'], equals('Test read permission'));
      expect(json['type'], equals('read'));
      expect(json['resource'], equals('test'));
      expect(json['conditions']['scope'], equals('limited'));
      expect(json['isActive'], isTrue);
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['updatedAt'], equals(now.toIso8601String()));
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final now = DateTime.now();
      final json = {
        'id': 'perm_1',
        'name': 'test.read',
        'description': 'Test read permission',
        'type': 'read',
        'resource': 'test',
        'conditions': {'scope': 'limited'},
        'isActive': true,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      // Act
      final permission = Permission.fromJson(json);

      // Assert
      expect(permission.id, equals('perm_1'));
      expect(permission.name, equals('test.read'));
      expect(permission.description, equals('Test read permission'));
      expect(permission.type, equals(PermissionType.read));
      expect(permission.resource, equals('test'));
      expect(permission.conditions?['scope'], equals('limited'));
      expect(permission.isActive, isTrue);
      expect(permission.createdAt, equals(now));
      expect(permission.updatedAt, equals(now));
    });

    test('should handle equality correctly', () {
      // Arrange
      final permission1 = Permission(
        id: 'perm_1',
        name: 'test.read',
        description: 'Test permission',
        type: PermissionType.read,
        resource: 'test',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final permission2 = Permission(
        id: 'perm_1',
        name: 'different.name',
        description: 'Different description',
        type: PermissionType.write,
        resource: 'different',
        isActive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final permission3 = Permission(
        id: 'perm_2',
        name: 'test.read',
        description: 'Test permission',
        type: PermissionType.read,
        resource: 'test',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(permission1, equals(permission2)); // Same ID
      expect(permission1, isNot(equals(permission3))); // Different ID
      expect(permission1.hashCode, equals(permission2.hashCode));
      expect(permission1.hashCode, isNot(equals(permission3.hashCode)));
    });
  });

  group('Role Model', () {
    test('should create role with all fields', () {
      // Arrange
      final now = DateTime.now();
      
      // Act
      final role = Role(
        id: 'role_1',
        name: 'Test Role',
        description: 'Test role description',
        permissionIds: ['perm_1', 'perm_2'],
        defaultVisibility: DataVisibilityLevel.group,
        isSystemRole: true,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Assert
      expect(role.id, equals('role_1'));
      expect(role.name, equals('Test Role'));
      expect(role.description, equals('Test role description'));
      expect(role.permissionIds, hasLength(2));
      expect(role.permissionIds, contains('perm_1'));
      expect(role.permissionIds, contains('perm_2'));
      expect(role.defaultVisibility, equals(DataVisibilityLevel.group));
      expect(role.isSystemRole, isTrue);
      expect(role.isActive, isTrue);
    });

    test('should add permission to role', () {
      // Arrange
      final role = Role(
        id: 'role_1',
        name: 'Test Role',
        description: 'Test role description',
        permissionIds: ['perm_1'],
        defaultVisibility: DataVisibilityLevel.group,
        isSystemRole: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final updatedRole = role.addPermission('perm_2');

      // Assert
      expect(updatedRole.permissionIds, hasLength(2));
      expect(updatedRole.permissionIds, contains('perm_1'));
      expect(updatedRole.permissionIds, contains('perm_2'));
    });

    test('should not add duplicate permission to role', () {
      // Arrange
      final role = Role(
        id: 'role_1',
        name: 'Test Role',
        description: 'Test role description',
        permissionIds: ['perm_1'],
        defaultVisibility: DataVisibilityLevel.group,
        isSystemRole: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final updatedRole = role.addPermission('perm_1');

      // Assert
      expect(updatedRole.permissionIds, hasLength(1));
      expect(updatedRole, equals(role)); // Should be unchanged
    });

    test('should remove permission from role', () {
      // Arrange
      final role = Role(
        id: 'role_1',
        name: 'Test Role',
        description: 'Test role description',
        permissionIds: ['perm_1', 'perm_2'],
        defaultVisibility: DataVisibilityLevel.group,
        isSystemRole: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final updatedRole = role.removePermission('perm_1');

      // Assert
      expect(updatedRole.permissionIds, hasLength(1));
      expect(updatedRole.permissionIds, contains('perm_2'));
      expect(updatedRole.permissionIds, isNot(contains('perm_1')));
    });

    test('should not change role when removing non-existent permission', () {
      // Arrange
      final role = Role(
        id: 'role_1',
        name: 'Test Role',
        description: 'Test role description',
        permissionIds: ['perm_1'],
        defaultVisibility: DataVisibilityLevel.group,
        isSystemRole: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final updatedRole = role.removePermission('perm_2');

      // Assert
      expect(updatedRole, equals(role)); // Should be unchanged
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final now = DateTime.now();
      final role = Role(
        id: 'role_1',
        name: 'Test Role',
        description: 'Test role description',
        permissionIds: ['perm_1', 'perm_2'],
        defaultVisibility: DataVisibilityLevel.group,
        isSystemRole: true,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Act
      final json = role.toJson();

      // Assert
      expect(json['id'], equals('role_1'));
      expect(json['name'], equals('Test Role'));
      expect(json['description'], equals('Test role description'));
      expect(json['permissionIds'], equals(['perm_1', 'perm_2']));
      expect(json['defaultVisibility'], equals('group'));
      expect(json['isSystemRole'], isTrue);
      expect(json['isActive'], isTrue);
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['updatedAt'], equals(now.toIso8601String()));
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final now = DateTime.now();
      final json = {
        'id': 'role_1',
        'name': 'Test Role',
        'description': 'Test role description',
        'permissionIds': ['perm_1', 'perm_2'],
        'defaultVisibility': 'group',
        'isSystemRole': true,
        'isActive': true,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      // Act
      final role = Role.fromJson(json);

      // Assert
      expect(role.id, equals('role_1'));
      expect(role.name, equals('Test Role'));
      expect(role.description, equals('Test role description'));
      expect(role.permissionIds, equals(['perm_1', 'perm_2']));
      expect(role.defaultVisibility, equals(DataVisibilityLevel.group));
      expect(role.isSystemRole, isTrue);
      expect(role.isActive, isTrue);
      expect(role.createdAt, equals(now));
      expect(role.updatedAt, equals(now));
    });
  });

  group('MemberRoleAssignment Model', () {
    test('should create role assignment with all fields', () {
      // Arrange
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 30));
      
      // Act
      final assignment = MemberRoleAssignment(
        id: 'assign_1',
        memberId: 'member_1',
        roleId: 'role_1',
        contextId: 'group_1',
        contextType: 'group',
        additionalPermissions: {'custom': 'permission'},
        isActive: true,
        assignedAt: now,
        expiresAt: expiresAt,
        createdAt: now,
        updatedAt: now,
      );

      // Assert
      expect(assignment.id, equals('assign_1'));
      expect(assignment.memberId, equals('member_1'));
      expect(assignment.roleId, equals('role_1'));
      expect(assignment.contextId, equals('group_1'));
      expect(assignment.contextType, equals('group'));
      expect(assignment.additionalPermissions?['custom'], equals('permission'));
      expect(assignment.isActive, isTrue);
      expect(assignment.assignedAt, equals(now));
      expect(assignment.expiresAt, equals(expiresAt));
    });

    test('should validate active assignment correctly', () {
      // Arrange
      final assignment = MemberRoleAssignment(
        id: 'assign_1',
        memberId: 'member_1',
        roleId: 'role_1',
        contextType: 'group',
        isActive: true,
        assignedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(assignment.isValid, isTrue);
    });

    test('should validate inactive assignment correctly', () {
      // Arrange
      final assignment = MemberRoleAssignment(
        id: 'assign_1',
        memberId: 'member_1',
        roleId: 'role_1',
        contextType: 'group',
        isActive: false,
        assignedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(assignment.isValid, isFalse);
    });

    test('should validate expired assignment correctly', () {
      // Arrange
      final assignment = MemberRoleAssignment(
        id: 'assign_1',
        memberId: 'member_1',
        roleId: 'role_1',
        contextType: 'group',
        isActive: true,
        assignedAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      // Act & Assert
      expect(assignment.isValid, isFalse);
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 30));
      final assignment = MemberRoleAssignment(
        id: 'assign_1',
        memberId: 'member_1',
        roleId: 'role_1',
        contextId: 'group_1',
        contextType: 'group',
        additionalPermissions: {'custom': 'permission'},
        isActive: true,
        assignedAt: now,
        expiresAt: expiresAt,
        createdAt: now,
        updatedAt: now,
      );

      // Act
      final json = assignment.toJson();

      // Assert
      expect(json['id'], equals('assign_1'));
      expect(json['memberId'], equals('member_1'));
      expect(json['roleId'], equals('role_1'));
      expect(json['contextId'], equals('group_1'));
      expect(json['contextType'], equals('group'));
      expect(json['additionalPermissions']['custom'], equals('permission'));
      expect(json['isActive'], isTrue);
      expect(json['assignedAt'], equals(now.toIso8601String()));
      expect(json['expiresAt'], equals(expiresAt.toIso8601String()));
      expect(json['createdAt'], equals(now.toIso8601String()));
      expect(json['updatedAt'], equals(now.toIso8601String()));
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 30));
      final json = {
        'id': 'assign_1',
        'memberId': 'member_1',
        'roleId': 'role_1',
        'contextId': 'group_1',
        'contextType': 'group',
        'additionalPermissions': {'custom': 'permission'},
        'isActive': true,
        'assignedAt': now.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      // Act
      final assignment = MemberRoleAssignment.fromJson(json);

      // Assert
      expect(assignment.id, equals('assign_1'));
      expect(assignment.memberId, equals('member_1'));
      expect(assignment.roleId, equals('role_1'));
      expect(assignment.contextId, equals('group_1'));
      expect(assignment.contextType, equals('group'));
      expect(assignment.additionalPermissions?['custom'], equals('permission'));
      expect(assignment.isActive, isTrue);
      expect(assignment.assignedAt, equals(now));
      expect(assignment.expiresAt, equals(expiresAt));
      expect(assignment.createdAt, equals(now));
      expect(assignment.updatedAt, equals(now));
    });

    test('should handle null expiration date', () {
      // Arrange
      final json = {
        'id': 'assign_1',
        'memberId': 'member_1',
        'roleId': 'role_1',
        'contextType': 'group',
        'isActive': true,
        'assignedAt': DateTime.now().toIso8601String(),
        'expiresAt': null,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Act
      final assignment = MemberRoleAssignment.fromJson(json);

      // Assert
      expect(assignment.expiresAt, isNull);
      expect(assignment.isValid, isTrue); // Should be valid without expiration
    });
  });
}