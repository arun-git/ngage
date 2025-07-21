import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ngage/services/group_service.dart';
import 'package:ngage/models/group.dart';
import 'package:ngage/models/group_member.dart';
import 'package:ngage/models/enums.dart';

void main() {
  group('GroupService', () {
    late GroupService groupService;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      groupService = GroupService(firestore: fakeFirestore);
    });

    group('createGroup', () {
      test('should create a group successfully', () async {
        // Arrange
        const name = 'Test Group';
        const description = 'Test Description';
        const groupType = GroupType.corporate;
        const createdBy = 'member123';

        // Act
        final result = await groupService.createGroup(
          name: name,
          description: description,
          groupType: groupType,
          createdBy: createdBy,
        );

        // Assert
        expect(result.name, equals(name));
        expect(result.description, equals(description));
        expect(result.groupType, equals(groupType));
        expect(result.createdBy, equals(createdBy));
        expect(result.id, isNotEmpty);

        // Verify group was saved to Firestore
        final doc = await fakeFirestore.collection('groups').doc(result.id).get();
        expect(doc.exists, isTrue);

        // Verify creator was added as admin
        final memberships = await fakeFirestore
            .collection('group_members')
            .where('groupId', isEqualTo: result.id)
            .where('memberId', isEqualTo: createdBy)
            .get();
        expect(memberships.docs.length, equals(1));
        
        final membership = GroupMember.fromJson(
          memberships.docs.first.data() as Map<String, dynamic>,
        );
        expect(membership.role, equals(GroupRole.admin));
      });

      test('should throw error for invalid group data', () async {
        // Arrange & Act & Assert
        expect(
          () => groupService.createGroup(
            name: '', // Invalid empty name
            description: 'Test Description',
            groupType: GroupType.corporate,
            createdBy: 'member123',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('getGroup', () {
      test('should return group when it exists', () async {
        // Arrange
        final group = Group(
          id: 'group123',
          name: 'Test Group',
          description: 'Test Description',
          groupType: GroupType.corporate,
          createdBy: 'member123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await fakeFirestore.collection('groups').doc(group.id).set(group.toJson());

        // Act
        final result = await groupService.getGroup(group.id);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(group.id));
        expect(result.name, equals(group.name));
      });

      test('should return null when group does not exist', () async {
        // Act
        final result = await groupService.getGroup('nonexistent');

        // Assert
        expect(result, isNull);
      });
    });

    group('updateGroup', () {
      test('should update group successfully', () async {
        // Arrange
        final originalGroup = Group(
          id: 'group123',
          name: 'Original Name',
          description: 'Original Description',
          groupType: GroupType.corporate,
          createdBy: 'member123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await fakeFirestore.collection('groups').doc(originalGroup.id).set(originalGroup.toJson());

        const newName = 'Updated Name';
        const newDescription = 'Updated Description';

        // Act
        final result = await groupService.updateGroup(
          groupId: originalGroup.id,
          name: newName,
          description: newDescription,
        );

        // Assert
        expect(result.name, equals(newName));
        expect(result.description, equals(newDescription));
        expect(result.groupType, equals(originalGroup.groupType));
        expect(result.updatedAt.isAfter(originalGroup.updatedAt), isTrue);
      });

      test('should throw error when group does not exist', () async {
        // Act & Assert
        expect(
          () => groupService.updateGroup(
            groupId: 'nonexistent',
            name: 'New Name',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('deleteGroup', () {
      test('should delete group and all memberships', () async {
        // Arrange
        final group = Group(
          id: 'group123',
          name: 'Test Group',
          description: 'Test Description',
          groupType: GroupType.corporate,
          createdBy: 'member123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await fakeFirestore.collection('groups').doc(group.id).set(group.toJson());

        // Add some memberships
        final membership1 = GroupMember(
          id: 'membership1',
          groupId: group.id,
          memberId: 'member1',
          role: GroupRole.admin,
          joinedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        final membership2 = GroupMember(
          id: 'membership2',
          groupId: group.id,
          memberId: 'member2',
          role: GroupRole.member,
          joinedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await fakeFirestore.collection('group_members').doc(membership1.id).set(membership1.toJson());
        await fakeFirestore.collection('group_members').doc(membership2.id).set(membership2.toJson());

        // Act
        await groupService.deleteGroup(group.id);

        // Assert
        final groupDoc = await fakeFirestore.collection('groups').doc(group.id).get();
        expect(groupDoc.exists, isFalse);

        final memberships = await fakeFirestore
            .collection('group_members')
            .where('groupId', isEqualTo: group.id)
            .get();
        expect(memberships.docs.length, equals(0));
      });
    });

    group('addMemberToGroup', () {
      test('should add member to group successfully', () async {
        // Arrange
        const groupId = 'group123';
        const memberId = 'member456';
        const role = GroupRole.member;

        // Act
        final result = await groupService.addMemberToGroup(
          groupId: groupId,
          memberId: memberId,
          role: role,
        );

        // Assert
        expect(result.groupId, equals(groupId));
        expect(result.memberId, equals(memberId));
        expect(result.role, equals(role));
        expect(result.id, isNotEmpty);

        // Verify membership was saved to Firestore
        final doc = await fakeFirestore.collection('group_members').doc(result.id).get();
        expect(doc.exists, isTrue);
      });

      test('should throw error when member is already in group', () async {
        // Arrange
        const groupId = 'group123';
        const memberId = 'member456';
        const role = GroupRole.member;

        // Add member first time
        await groupService.addMemberToGroup(
          groupId: groupId,
          memberId: memberId,
          role: role,
        );

        // Act & Assert
        expect(
          () => groupService.addMemberToGroup(
            groupId: groupId,
            memberId: memberId,
            role: role,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('removeMemberFromGroup', () {
      test('should remove member from group successfully', () async {
        // Arrange
        const groupId = 'group123';
        const memberId = 'member456';
        const role = GroupRole.member;

        // Add member first
        await groupService.addMemberToGroup(
          groupId: groupId,
          memberId: memberId,
          role: role,
        );

        // Act
        await groupService.removeMemberFromGroup(
          groupId: groupId,
          memberId: memberId,
        );

        // Assert
        final memberships = await fakeFirestore
            .collection('group_members')
            .where('groupId', isEqualTo: groupId)
            .where('memberId', isEqualTo: memberId)
            .get();
        expect(memberships.docs.length, equals(0));
      });

      test('should throw error when member is not in group', () async {
        // Act & Assert
        expect(
          () => groupService.removeMemberFromGroup(
            groupId: 'group123',
            memberId: 'nonexistent',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('updateMemberRole', () {
      test('should update member role successfully', () async {
        // Arrange
        const groupId = 'group123';
        const memberId = 'member456';
        const originalRole = GroupRole.member;
        const newRole = GroupRole.teamLead;

        // Add member first
        await groupService.addMemberToGroup(
          groupId: groupId,
          memberId: memberId,
          role: originalRole,
        );

        // Act
        final result = await groupService.updateMemberRole(
          groupId: groupId,
          memberId: memberId,
          newRole: newRole,
        );

        // Assert
        expect(result.role, equals(newRole));
        expect(result.groupId, equals(groupId));
        expect(result.memberId, equals(memberId));
      });

      test('should throw error when member is not in group', () async {
        // Act & Assert
        expect(
          () => groupService.updateMemberRole(
            groupId: 'group123',
            memberId: 'nonexistent',
            newRole: GroupRole.admin,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('getGroupMembers', () {
      test('should return all group members', () async {
        // Arrange
        const groupId = 'group123';
        
        final membership1 = GroupMember(
          id: 'membership1',
          groupId: groupId,
          memberId: 'member1',
          role: GroupRole.admin,
          joinedAt: DateTime.now().subtract(const Duration(days: 2)),
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        );

        final membership2 = GroupMember(
          id: 'membership2',
          groupId: groupId,
          memberId: 'member2',
          role: GroupRole.member,
          joinedAt: DateTime.now().subtract(const Duration(days: 1)),
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        await fakeFirestore.collection('group_members').doc(membership1.id).set(membership1.toJson());
        await fakeFirestore.collection('group_members').doc(membership2.id).set(membership2.toJson());

        // Act
        final result = await groupService.getGroupMembers(groupId);

        // Assert
        expect(result.length, equals(2));
        expect(result.first.joinedAt.isBefore(result.last.joinedAt), isTrue); // Ordered by joinedAt
      });

      test('should return empty list when no members', () async {
        // Act
        final result = await groupService.getGroupMembers('empty_group');

        // Assert
        expect(result, isEmpty);
      });
    });

    group('isGroupAdmin', () {
      test('should return true when member is admin', () async {
        // Arrange
        const groupId = 'group123';
        const memberId = 'member456';

        await groupService.addMemberToGroup(
          groupId: groupId,
          memberId: memberId,
          role: GroupRole.admin,
        );

        // Act
        final result = await groupService.isGroupAdmin(groupId, memberId);

        // Assert
        expect(result, isTrue);
      });

      test('should return false when member is not admin', () async {
        // Arrange
        const groupId = 'group123';
        const memberId = 'member456';

        await groupService.addMemberToGroup(
          groupId: groupId,
          memberId: memberId,
          role: GroupRole.member,
        );

        // Act
        final result = await groupService.isGroupAdmin(groupId, memberId);

        // Assert
        expect(result, isFalse);
      });

      test('should return false when member is not in group', () async {
        // Act
        final result = await groupService.isGroupAdmin('group123', 'nonexistent');

        // Assert
        expect(result, isFalse);
      });
    });
  });
}