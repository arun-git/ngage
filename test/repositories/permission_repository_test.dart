import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ngage/repositories/permission_repository.dart';
import 'package:ngage/models/permission.dart';
import 'package:ngage/models/enums.dart';

// Mock classes for Firestore
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

@GenerateMocks([])
void main() {
  group('PermissionRepository', () {
    late PermissionRepository repository;
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      repository = PermissionRepository(firestore: mockFirestore);
    });

    group('Permission CRUD Operations', () {
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

        when(mockFirestore.collection('permissions'))
            .thenReturn(mockCollection);
        when(mockCollection.doc(permission.id))
            .thenReturn(mockDocument);
        when(mockDocument.set(any))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.createPermission(permission);

        // Assert
        expect(result, equals(permission));
        verify(mockDocument.set(permission.toJson())).called(1);
      });

      test('should get permission by ID', () async {
        // Arrange
        final permissionData = {
          'id': 'perm_1',
          'name': 'test.read',
          'description': 'Test read permission',
          'type': 'read',
          'resource': 'test',
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final mockSnapshot = MockDocumentSnapshot();
        when(mockSnapshot.exists).thenReturn(true);
        when(mockSnapshot.data()).thenReturn(permissionData);

        when(mockFirestore.collection('permissions'))
            .thenReturn(mockCollection);
        when(mockCollection.doc('perm_1'))
            .thenReturn(mockDocument);
        when(mockDocument.get())
            .thenAnswer((_) async => mockSnapshot);

        // Act
        final result = await repository.getPermissionById('perm_1');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('perm_1'));
        expect(result.name, equals('test.read'));
      });

      test('should return null when permission not found', () async {
        // Arrange
        final mockSnapshot = MockDocumentSnapshot();
        when(mockSnapshot.exists).thenReturn(false);

        when(mockFirestore.collection('permissions'))
            .thenReturn(mockCollection);
        when(mockCollection.doc('nonexistent'))
            .thenReturn(mockDocument);
        when(mockDocument.get())
            .thenAnswer((_) async => mockSnapshot);

        // Act
        final result = await repository.getPermissionById('nonexistent');

        // Assert
        expect(result, isNull);
      });

      test('should update permission successfully', () async {
        // Arrange
        final permission = Permission(
          id: 'perm_1',
          name: 'test.read',
          description: 'Updated description',
          type: PermissionType.read,
          resource: 'test',
          isActive: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
        );

        when(mockFirestore.collection('permissions'))
            .thenReturn(mockCollection);
        when(mockCollection.doc(permission.id))
            .thenReturn(mockDocument);
        when(mockDocument.update(any))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.updatePermission(permission);

        // Assert
        expect(result.description, equals('Updated description'));
        verify(mockDocument.update(any)).called(1);
      });

      test('should delete permission successfully', () async {
        // Arrange
        when(mockFirestore.collection('permissions'))
            .thenReturn(mockCollection);
        when(mockCollection.doc('perm_1'))
            .thenReturn(mockDocument);
        when(mockDocument.delete())
            .thenAnswer((_) async {});

        // Act
        await repository.deletePermission('perm_1');

        // Assert
        verify(mockDocument.delete()).called(1);
      });
    });

    group('Role CRUD Operations', () {
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

        when(mockFirestore.collection('roles'))
            .thenReturn(mockCollection);
        when(mockCollection.doc(role.id))
            .thenReturn(mockDocument);
        when(mockDocument.set(any))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.createRole(role);

        // Assert
        expect(result, equals(role));
        verify(mockDocument.set(role.toJson())).called(1);
      });

      test('should get role by ID', () async {
        // Arrange
        final roleData = {
          'id': 'role_1',
          'name': 'Test Role',
          'description': 'Test role description',
          'permissionIds': ['perm_1', 'perm_2'],
          'defaultVisibility': 'group',
          'isSystemRole': false,
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final mockSnapshot = MockDocumentSnapshot();
        when(mockSnapshot.exists).thenReturn(true);
        when(mockSnapshot.data()).thenReturn(roleData);

        when(mockFirestore.collection('roles'))
            .thenReturn(mockCollection);
        when(mockCollection.doc('role_1'))
            .thenReturn(mockDocument);
        when(mockDocument.get())
            .thenAnswer((_) async => mockSnapshot);

        // Act
        final result = await repository.getRoleById('role_1');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('role_1'));
        expect(result.name, equals('Test Role'));
        expect(result.permissionIds, hasLength(2));
      });
    });

    group('Role Assignment Operations', () {
      test('should create role assignment successfully', () async {
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

        when(mockFirestore.collection('role_assignments'))
            .thenReturn(mockCollection);
        when(mockCollection.doc(assignment.id))
            .thenReturn(mockDocument);
        when(mockDocument.set(any))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.createRoleAssignment(assignment);

        // Assert
        expect(result, equals(assignment));
        verify(mockDocument.set(assignment.toJson())).called(1);
      });

      test('should get role assignment by ID', () async {
        // Arrange
        final assignmentData = {
          'id': 'assign_1',
          'memberId': 'member_1',
          'roleId': 'role_1',
          'contextType': 'group',
          'contextId': 'group_1',
          'isActive': true,
          'assignedAt': DateTime.now().toIso8601String(),
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final mockSnapshot = MockDocumentSnapshot();
        when(mockSnapshot.exists).thenReturn(true);
        when(mockSnapshot.data()).thenReturn(assignmentData);

        when(mockFirestore.collection('role_assignments'))
            .thenReturn(mockCollection);
        when(mockCollection.doc('assign_1'))
            .thenReturn(mockDocument);
        when(mockDocument.get())
            .thenAnswer((_) async => mockSnapshot);

        // Act
        final result = await repository.getRoleAssignmentById('assign_1');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('assign_1'));
        expect(result.memberId, equals('member_1'));
        expect(result.roleId, equals('role_1'));
      });

      test('should deactivate role assignment', () async {
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

        final mockSnapshot = MockDocumentSnapshot();
        when(mockSnapshot.exists).thenReturn(true);
        when(mockSnapshot.data()).thenReturn(assignment.toJson());

        when(mockFirestore.collection('role_assignments'))
            .thenReturn(mockCollection);
        when(mockCollection.doc('assign_1'))
            .thenReturn(mockDocument);
        when(mockDocument.get())
            .thenAnswer((_) async => mockSnapshot);
        when(mockDocument.update(any))
            .thenAnswer((_) async {});

        // Act
        final result = await repository.deactivateRoleAssignment('assign_1');

        // Assert
        expect(result.isActive, isFalse);
        verify(mockDocument.update(any)).called(1);
      });
    });

    group('Error Handling', () {
      test('should throw exception when role assignment not found for deactivation', () async {
        // Arrange
        final mockSnapshot = MockDocumentSnapshot();
        when(mockSnapshot.exists).thenReturn(false);

        when(mockFirestore.collection('role_assignments'))
            .thenReturn(mockCollection);
        when(mockCollection.doc('nonexistent'))
            .thenReturn(mockDocument);
        when(mockDocument.get())
            .thenAnswer((_) async => mockSnapshot);

        // Act & Assert
        expect(
          () => repository.deactivateRoleAssignment('nonexistent'),
          throwsException,
        );
      });
    });
  });
}