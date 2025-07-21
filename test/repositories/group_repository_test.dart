import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ngage/repositories/group_repository.dart';
import 'package:ngage/models/group.dart';
import 'package:ngage/models/group_member.dart';
import 'package:ngage/models/enums.dart';

void main() {
  group('GroupRepository', () {
    late GroupRepository groupRepository;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      groupRepository = GroupRepository(firestore: fakeFirestore);
    });

    group('Group CRUD Operations', () {
      test('should create group successfully', () async {
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

        // Act
        await groupRepository.createGroup(group);

        // Assert
        final doc = await fakeFirestore.collection('groups').doc(group.id).get();
        expect(doc.exists, isTrue);
        
        final retrievedGroup = Group.fromJson(doc.data() as Map<String, dynamic>);
        expect(retrievedGroup.id, equals(group.id));
        expect(retrievedGroup.name, equals(group.name));
      });

      test('should get group by ID successfully', () async {
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
        final result = await groupRepository.getGroupById(group.id);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(group.id));
        expect(result.name, equals(group.name));
      });

      test('should return null when group does not exist', () async {
        // Act
        final result = await groupRepository.getGroupById('nonexistent');

        // Assert
        expect(result, isNull);
      });

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

        final updatedGroup = originalGroup.copyWith(
          name: 'Updated Name',
          description: 'Updated Description',
          updatedAt: DateTime.now(),
        );

        // Act
        await groupRepository.updateGroup(updatedGroup);

        // Assert
        final doc = await fakeFirestore.collection('groups').doc(originalGroup.id).get();
        final retrievedGroup = Group.fromJson(doc.data() as Map<String, dynamic>);
        
        expect(retrievedGroup.name, equals('Updated Name'));
        expect(retrievedGroup.description, equals('Updated Description'));
      });

      test('should delete group successfully', () async {
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
        await groupRepository.deleteGroup(group.id);

        // Assert
        final doc = await fakeFirestore.collection('groups').doc(group.id).get();
        expect(doc.exists, isFalse);
      });
    });

    group('Group Queries', () {
      test('should get groups by type', () async {
        // Arrange
        final corporateGroup = Group(
          id: 'corp1',
          name: 'Corporate Group',
          description: 'Description',
          groupType: GroupType.corporate,
          createdBy: 'member1',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        );

        final educationalGroup = Group(
          id: 'edu1',
          name: 'Educational Group',
          description: 'Description',
          groupType: GroupType.educational,
          createdBy: 'member2',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        await fakeFirestore.collection('groups').doc(corporateGroup.id).set(corporateGroup.toJson());
        await fakeFirestore.collection('groups').doc(educationalGroup.id).set(educationalGroup.toJson());

        // Act
        final corporateGroups = await groupRepository.getGroupsByType(GroupType.corporate);
        final educationalGroups = await groupRepository.getGroupsByType(GroupType.educational);

        // Assert
        expect(corporateGroups.length, equals(1));
        expect(corporateGroups.first.groupType, equals(GroupType.corporate));
        
        expect(educationalGroups.length, equals(1));
        expect(educationalGroups.first.groupType, equals(GroupType.educational));
      });

      test('should get groups created by member', () async {
        // Arrange
        const creatorId = 'creator123';
        
        final group1 = Group(
          id: 'group1',
          name: 'Group 1',
          description: 'Description',
          groupType: GroupType.corporate,
          createdBy: creatorId,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        );

        final group2 = Group(
          id: 'group2',
          name: 'Group 2',
          description: 'Description',
          groupType: GroupType.educational,
          createdBy: creatorId,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        final otherGroup = Group(
          id: 'other',
          name: 'Other Group',
          description: 'Description',
          groupType: GroupType.social,
          createdBy: 'other_creator',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await fakeFirestore.collection('groups').doc(group1.id).set(group1.toJson());
        await fakeFirestore.collection('groups').doc(group2.id).set(group2.toJson());
        await fakeFirestore.collection('groups').doc(otherGroup.id).set(otherGroup.toJson());

        // Act
        final createdGroups = await groupRepository.getGroupsCreatedBy(creatorId);

        // Assert
        expect(createdGroups.length, equals(2));
        expect(createdGroups.every((g) => g.createdBy == creatorId), isTrue);
        // Should be ordered by createdAt descending (newest first)
        expect(createdGroups.first.createdAt.isAfter(createdGroups.last.createdAt), isTrue);
      });

      test('should get groups by IDs', () async {
        // Arrange
        final group1 = Group(
          id: 'group1',
          name: 'Group 1',
          description: 'Description',
          groupType: GroupType.corporate,
          createdBy: 'member1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final group2 = Group(
          id: 'group2',
          name: 'Group 2',
          description: 'Description',
          groupType: GroupType.educational,
          createdBy: 'member2',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final group3 = Group(
          id: 'group3',
          name: 'Group 3',
          description: 'Description',
          groupType: GroupType.social,
          createdBy: 'member3',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await fakeFirestore.collection('groups').doc(group1.id).set(group1.toJson());
        await fakeFirestore.collection('groups').doc(group2.id).set(group2.toJson());
        await fakeFirestore.collection('groups').doc(group3.id).set(group3.toJson());

        // Act
        final groups = await groupRepository.getGroupsByIds(['group1', 'group3']);

        // Assert
        expect(groups.length, equals(2));
        expect(groups.any((g) => g.id == 'group1'), isTrue);
        expect(groups.any((g) => g.id == 'group3'), isTrue);
        expect(groups.any((g) => g.id == 'group2'), isFalse);
      });

      test('should return empty list for empty IDs list', () async {
        // Act
        final groups = await groupRepository.getGroupsByIds([]);

        // Assert
        expect(groups, isEmpty);
      });
    });

    group('Group Membership Operations', () {
      test('should create group membership successfully', () async {
        // Arrange
        final membership = GroupMember(
          id: 'membership123',
          groupId: 'group123',
          memberId: 'member456',
          role: GroupRole.member,
          joinedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        // Act
        await groupRepository.createGroupMembership(membership);

        // Assert
        final doc = await fakeFirestore.collection('group_members').doc(membership.id).get();
        expect(doc.exists, isTrue);
        
        final retrievedMembership = GroupMember.fromJson(doc.data() as Map<String, dynamic>);
        expect(retrievedMembership.id, equals(membership.id));
        expect(retrievedMembership.groupId, equals(membership.groupId));
        expect(retrievedMembership.memberId, equals(membership.memberId));
      });

      test('should get group membership successfully', () async {
        // Arrange
        final membership = GroupMember(
          id: 'membership123',
          groupId: 'group123',
          memberId: 'member456',
          role: GroupRole.member,
          joinedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await fakeFirestore.collection('group_members').doc(membership.id).set(membership.toJson());

        // Act
        final result = await groupRepository.getGroupMembership(membership.groupId, membership.memberId);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(membership.id));
        expect(result.groupId, equals(membership.groupId));
        expect(result.memberId, equals(membership.memberId));
      });

      test('should return null when membership does not exist', () async {
        // Act
        final result = await groupRepository.getGroupMembership('nonexistent_group', 'nonexistent_member');

        // Assert
        expect(result, isNull);
      });

      test('should update group membership successfully', () async {
        // Arrange
        final originalMembership = GroupMember(
          id: 'membership123',
          groupId: 'group123',
          memberId: 'member456',
          role: GroupRole.member,
          joinedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await fakeFirestore.collection('group_members').doc(originalMembership.id).set(originalMembership.toJson());

        final updatedMembership = originalMembership.copyWith(role: GroupRole.teamLead);

        // Act
        await groupRepository.updateGroupMembership(updatedMembership);

        // Assert
        final doc = await fakeFirestore.collection('group_members').doc(originalMembership.id).get();
        final retrievedMembership = GroupMember.fromJson(doc.data() as Map<String, dynamic>);
        
        expect(retrievedMembership.role, equals(GroupRole.teamLead));
      });

      test('should delete group membership successfully', () async {
        // Arrange
        final membership = GroupMember(
          id: 'membership123',
          groupId: 'group123',
          memberId: 'member456',
          role: GroupRole.member,
          joinedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await fakeFirestore.collection('group_members').doc(membership.id).set(membership.toJson());

        // Act
        await groupRepository.deleteGroupMembership(membership.id);

        // Assert
        final doc = await fakeFirestore.collection('group_members').doc(membership.id).get();
        expect(doc.exists, isFalse);
      });

      test('should get all group memberships', () async {
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

        final otherMembership = GroupMember(
          id: 'other',
          groupId: 'other_group',
          memberId: 'member3',
          role: GroupRole.member,
          joinedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await fakeFirestore.collection('group_members').doc(membership1.id).set(membership1.toJson());
        await fakeFirestore.collection('group_members').doc(membership2.id).set(membership2.toJson());
        await fakeFirestore.collection('group_members').doc(otherMembership.id).set(otherMembership.toJson());

        // Act
        final memberships = await groupRepository.getGroupMemberships(groupId);

        // Assert
        expect(memberships.length, equals(2));
        expect(memberships.every((m) => m.groupId == groupId), isTrue);
        // Should be ordered by joinedAt
        expect(memberships.first.joinedAt.isBefore(memberships.last.joinedAt), isTrue);
      });

      test('should get member group memberships', () async {
        // Arrange
        const memberId = 'member123';
        
        final membership1 = GroupMember(
          id: 'membership1',
          groupId: 'group1',
          memberId: memberId,
          role: GroupRole.admin,
          joinedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        final membership2 = GroupMember(
          id: 'membership2',
          groupId: 'group2',
          memberId: memberId,
          role: GroupRole.member,
          joinedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        final otherMembership = GroupMember(
          id: 'other',
          groupId: 'group3',
          memberId: 'other_member',
          role: GroupRole.member,
          joinedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await fakeFirestore.collection('group_members').doc(membership1.id).set(membership1.toJson());
        await fakeFirestore.collection('group_members').doc(membership2.id).set(membership2.toJson());
        await fakeFirestore.collection('group_members').doc(otherMembership.id).set(otherMembership.toJson());

        // Act
        final memberships = await groupRepository.getMemberGroupMemberships(memberId);

        // Assert
        expect(memberships.length, equals(2));
        expect(memberships.every((m) => m.memberId == memberId), isTrue);
      });

      test('should delete all group memberships', () async {
        // Arrange
        const groupId = 'group123';
        
        final membership1 = GroupMember(
          id: 'membership1',
          groupId: groupId,
          memberId: 'member1',
          role: GroupRole.admin,
          joinedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        final membership2 = GroupMember(
          id: 'membership2',
          groupId: groupId,
          memberId: 'member2',
          role: GroupRole.member,
          joinedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        final otherMembership = GroupMember(
          id: 'other',
          groupId: 'other_group',
          memberId: 'member3',
          role: GroupRole.member,
          joinedAt: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await fakeFirestore.collection('group_members').doc(membership1.id).set(membership1.toJson());
        await fakeFirestore.collection('group_members').doc(membership2.id).set(membership2.toJson());
        await fakeFirestore.collection('group_members').doc(otherMembership.id).set(otherMembership.toJson());

        // Act
        await groupRepository.deleteAllGroupMemberships(groupId);

        // Assert
        final remainingMemberships = await fakeFirestore
            .collection('group_members')
            .where('groupId', isEqualTo: groupId)
            .get();
        expect(remainingMemberships.docs.length, equals(0));

        // Other group memberships should remain
        final otherDoc = await fakeFirestore.collection('group_members').doc(otherMembership.id).get();
        expect(otherDoc.exists, isTrue);
      });
    });
  });
}