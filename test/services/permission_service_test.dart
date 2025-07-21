import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/services/permission_service.dart';
import '../../lib/repositories/permission_repository.dart';
import '../../lib/models/permission.dart';
import '../../lib/models/enums.dart';

import 'permission_service_test.mocks.dart';

@GenerateMocks([PermissionRepository])
void main() {
  group('PermissionService', () {
    late PermissionService permissionService;
    late MockPermissionRepository mockRepository;

    setUp(() {
      mockRepository = MockPermissionRepository();
      permissionService = PermissionService(permissionRepository: mockRepository);
    });

    group('Permission Management', () {
      test('should create permission successfully', () async {
        // Arrange
        final permission = Permission(
          id: 'perm_1',
          name: 'test.read',
          description: 'Test read permission',
          type: PermissionType.read,
          resource: 'test',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.createPermission(any))
            .thenAnswer((_) async => permission);

        // Act
        final result = await permissionService.createPermission(
          name: 'test.read',
          description: 'Test read permission',
          type: PermissionType.read,
          resource: 'test',
        );

        // Assert
        expect(result.name, equals('test.read'));
        expect(result.type, equals(PermissionType.read));
        expect(result.resource, equals('test'));
        verify(mockRepository.createPermission(any)).called(1);
      });

      test('should get permission by ID', () async {
        // Arrange
        final permission = Permission(
          id: 'perm_1',
          name: 'test.read',
          description: 'Test read permission',
          type: PermissionType.read,
          resource: 'test',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getPermissionById('perm_1'))
            .thenAnswer((_) async => permission);

        // Act
        final result = await permissionService.getPermissionById('perm_1');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('perm_1'));
        verify(mockRepository.getPermissionById('perm_1')).called(1);
      });

      test('should get permissions by type', () async {
        // Arrange
        final permissions = [
          Permission(
            id: 'perm_1',
            name: 'test.read',
            description: 'Test read permission',
            type: PermissionType.read,
            resource: 'test',
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getPermissionsByType(PermissionType.read))
            .thenAnswer((_) async => permissions);

        // Act
        final result = await permissionService.getPermissionsByType(PermissionType.read);

        // Assert
        expect(result, hasLength(1));
        expect(result.first.type, equals(PermissionType.read));
        verify(mockRepository.getPermissionsByType(PermissionType.read)).called(1);
      });

      test('should deactivate permission', () async {
        // Arrange
        final permission = Permission(
          id: 'perm_1',
          name: 'test.read',
          description: 'Test read permission',
          type: PermissionType.read,
          resource: 'test',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final deactivatedPermission = permission.copyWith(
          isActive: false,
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getPermissionById('perm_1'))
            .thenAnswer((_) async => permission);
        when(mockRepository.updatePermission(any))
            .thenAnswer((_) async => deactivatedPermission);

        // Act
        final result = await permissionService.deactivatePermission('perm_1');

        // Assert
        expect(result.isActive, isFalse);
        verify(mockRepository.getPermissionById('perm_1')).called(1);
        verify(mockRepository.updatePermission(any)).called(1);
      });
    });

    group('Role Management', () {
      test('should create role successfully', () async {
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

        when(mockRepository.createRole(any))
            .thenAnswer((_) async => role);

        // Act
        final result = await permissionService.createRole(
          name: 'Test Role',
          description: 'Test role description',
          permissionIds: ['perm_1', 'perm_2'],
          defaultVisibility: DataVisibilityLevel.group,
        );

        // Assert
        expect(result.name, equals('Test Role'));
        expect(result.permissionIds, hasLength(2));
        expect(result.defaultVisibility, equals(DataVisibilityLevel.group));
        verify(mockRepository.createRole(any)).called(1);
      });

      test('should add permission to role', () async {
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

        final updatedRole = role.addPermission('perm_2');

        when(mockRepository.getRoleById('role_1'))
            .thenAnswer((_) async => role);
        when(mockRepository.updateRole(any))
            .thenAnswer((_) async => updatedRole);

        // Act
        final result = await permissionService.addPermissionToRole('role_1', 'perm_2');

        // Assert
        expect(result.permissionIds, contains('perm_2'));
        expect(result.permissionIds, hasLength(2));
        verify(mockRepository.getRoleById('role_1')).called(1);
        verify(mockRepository.updateRole(any)).called(1);
      });

      test('should remove permission from role', () async {
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

        final updatedRole = role.removePermission('perm_2');

        when(mockRepository.getRoleById('role_1'))
            .thenAnswer((_) async => role);
        when(mockRepository.updateRole(any))
            .thenAnswer((_) async => updatedRole);

        // Act
        final result = await permissionService.removePermissionFromRole('role_1', 'perm_2');

        // Assert
        expect(result.permissionIds, isNot(contains('perm_2')));
        expect(result.permissionIds, hasLength(1));
        verify(mockRepository.getRoleById('role_1')).called(1);
        verify(mockRepository.updateRole(any)).called(1);
      });
    });

    group('Role Assignment Management', () {
      test('should assign role to member', () async {
        // Arrange
        final assignment = MemberRoleAssignment(
          id: 'assign_1',
          memberId: 'member_1',
          roleId: 'role_1',
          contextType: 'group',
          contextId: 'group_1',
          isActive: true,
          assignedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.createRoleAssignment(any))
            .thenAnswer((_) async => assignment);

        // Act
        final result = await permissionService.assignRoleToMember(
          memberId: 'member_1',
          roleId: 'role_1',
          contextType: 'group',
          contextId: 'group_1',
        );

        // Assert
        expect(result.memberId, equals('member_1'));
        expect(result.roleId, equals('role_1'));
        expect(result.contextType, equals('group'));
        expect(result.contextId, equals('group_1'));
        verify(mockRepository.createRoleAssignment(any)).called(1);
      });

      test('should get member role assignments', () async {
        // Arrange
        final assignments = [
          MemberRoleAssignment(
            id: 'assign_1',
            memberId: 'member_1',
            roleId: 'role_1',
            contextType: 'group',
            contextId: 'group_1',
            isActive: true,
            assignedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getMemberRoleAssignments('member_1'))
            .thenAnswer((_) async => assignments);

        // Act
        final result = await permissionService.getMemberRoleAssignments('member_1');

        // Assert
        expect(result, hasLength(1));
        expect(result.first.memberId, equals('member_1'));
        verify(mockRepository.getMemberRoleAssignments('member_1')).called(1);
      });
    });

    group('Permission Checking', () {
      test('should check member permission correctly', () async {
        // Arrange
        when(mockRepository.memberHasPermission(
          'member_1', 
          'group.read', 
          'group', 
          'group_1'
        )).thenAnswer((_) async => true);

        // Act
        final result = await permissionService.memberHasPermission(
          'member_1',
          'group.read',
          'group',
          'group_1',
        );

        // Assert
        expect(result, isTrue);
        verify(mockRepository.memberHasPermission(
          'member_1', 
          'group.read', 
          'group', 
          'group_1'
        )).called(1);
      });

      test('should validate data visibility correctly', () async {
        // Arrange
        final assignment = MemberRoleAssignment(
          id: 'assign_1',
          memberId: 'member_1',
          roleId: 'role_1',
          contextType: 'group',
          contextId: 'group_1',
          isActive: true,
          assignedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final role = Role(
          id: 'role_1',
          name: 'Admin',
          description: 'Admin role',
          permissionIds: ['perm_1'],
          defaultVisibility: DataVisibilityLevel.admin,
          isSystemRole: true,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getMemberContextRoleAssignment(
          'member_1', 
          'group', 
          'group_1'
        )).thenAnswer((_) async => assignment);
        when(mockRepository.getRoleById('role_1'))
            .thenAnswer((_) async => role);

        // Act
        final result = await permissionService.canViewData(
          'member_1',
          DataVisibilityLevel.group,
          'group',
          'group_1',
        );

        // Assert
        expect(result, isTrue);
        verify(mockRepository.getMemberContextRoleAssignment(
          'member_1', 
          'group', 
          'group_1'
        )).called(1);
        verify(mockRepository.getRoleById('role_1')).called(1);
      });

      test('should allow access to public data', () async {
        // Act
        final result = await permissionService.canViewData(
          'member_1',
          DataVisibilityLevel.public,
          'group',
          'group_1',
        );

        // Assert
        expect(result, isTrue);
        verifyNever(mockRepository.getMemberContextRoleAssignment(any, any, any));
      });
    });

    group('Error Handling', () {
      test('should throw exception when permission not found for deactivation', () async {
        // Arrange
        when(mockRepository.getPermissionById('nonexistent'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => permissionService.deactivatePermission('nonexistent'),
          throwsException,
        );
      });

      test('should throw exception when role not found for adding permission', () async {
        // Arrange
        when(mockRepository.getRoleById('nonexistent'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => permissionService.addPermissionToRole('nonexistent', 'perm_1'),
          throwsException,
        );
      });
    });
  });
}