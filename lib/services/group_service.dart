import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/enums.dart';

/// Service for managing groups and group memberships
/// 
/// Provides CRUD operations for groups and handles group membership
/// management including role assignments and invitations.
class GroupService {
  final FirebaseFirestore _firestore;
  
  GroupService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _groupsCollection => _firestore.collection('groups');
  CollectionReference get _groupMembersCollection => _firestore.collection('group_members');

  /// Create a new group
  Future<Group> createGroup({
    required String name,
    required String description,
    required GroupType groupType,
    required String createdBy,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final now = DateTime.now();
      final docRef = _groupsCollection.doc();
      
      final group = Group(
        id: docRef.id,
        name: name.trim(),
        description: description.trim(),
        groupType: groupType,
        settings: settings ?? {},
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      // Validate the group data
      final validation = group.validate();
      if (!validation.isValid) {
        throw ArgumentError('Invalid group data: ${validation.errors.join(', ')}');
      }

      // Create the group document
      await docRef.set(group.toJson());

      // Automatically add the creator as an admin
      await addMemberToGroup(
        groupId: group.id,
        memberId: createdBy,
        role: GroupRole.admin,
      );

      return group;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  /// Get a group by ID
  Future<Group?> getGroup(String groupId) async {
    try {
      final doc = await _groupsCollection.doc(groupId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return Group.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get group: $e');
    }
  }

  /// Update an existing group
  Future<Group> updateGroup({
    required String groupId,
    String? name,
    String? description,
    GroupType? groupType,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final existingGroup = await getGroup(groupId);
      if (existingGroup == null) {
        throw ArgumentError('Group not found: $groupId');
      }

      final updatedGroup = existingGroup.copyWith(
        name: name?.trim(),
        description: description?.trim(),
        groupType: groupType,
        settings: settings,
        updatedAt: DateTime.now(),
      );

      // Validate the updated group data
      final validation = updatedGroup.validate();
      if (!validation.isValid) {
        throw ArgumentError('Invalid group data: ${validation.errors.join(', ')}');
      }

      await _groupsCollection.doc(groupId).update(updatedGroup.toJson());
      return updatedGroup;
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }

  /// Delete a group and all its memberships
  Future<void> deleteGroup(String groupId) async {
    try {
      final batch = _firestore.batch();

      // Delete the group document
      batch.delete(_groupsCollection.doc(groupId));

      // Delete all group memberships
      final memberships = await _groupMembersCollection
          .where('groupId', isEqualTo: groupId)
          .get();

      for (final doc in memberships.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }

  /// Add a member to a group with a specific role
  Future<GroupMember> addMemberToGroup({
    required String groupId,
    required String memberId,
    required GroupRole role,
  }) async {
    try {
      // Check if membership already exists
      final existingMembership = await getGroupMembership(groupId, memberId);
      if (existingMembership != null) {
        throw ArgumentError('Member is already in this group');
      }

      final now = DateTime.now();
      final docRef = _groupMembersCollection.doc();
      
      final groupMember = GroupMember(
        id: docRef.id,
        groupId: groupId,
        memberId: memberId,
        role: role,
        joinedAt: now,
        createdAt: now,
      );

      // Validate the group member data
      final validation = groupMember.validate();
      if (!validation.isValid) {
        throw ArgumentError('Invalid group member data: ${validation.errors.join(', ')}');
      }

      await docRef.set(groupMember.toJson());
      return groupMember;
    } catch (e) {
      throw Exception('Failed to add member to group: $e');
    }
  }

  /// Remove a member from a group
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String memberId,
  }) async {
    try {
      final membership = await getGroupMembership(groupId, memberId);
      if (membership == null) {
        throw ArgumentError('Member is not in this group');
      }

      await _groupMembersCollection.doc(membership.id).delete();
    } catch (e) {
      throw Exception('Failed to remove member from group: $e');
    }
  }

  /// Update a member's role in a group
  Future<GroupMember> updateMemberRole({
    required String groupId,
    required String memberId,
    required GroupRole newRole,
  }) async {
    try {
      final membership = await getGroupMembership(groupId, memberId);
      if (membership == null) {
        throw ArgumentError('Member is not in this group');
      }

      final updatedMembership = membership.copyWith(role: newRole);
      
      // Validate the updated membership
      final validation = updatedMembership.validate();
      if (!validation.isValid) {
        throw ArgumentError('Invalid group member data: ${validation.errors.join(', ')}');
      }

      await _groupMembersCollection.doc(membership.id).update(updatedMembership.toJson());
      return updatedMembership;
    } catch (e) {
      throw Exception('Failed to update member role: $e');
    }
  }

  /// Get a specific group membership
  Future<GroupMember?> getGroupMembership(String groupId, String memberId) async {
    try {
      final query = await _groupMembersCollection
          .where('groupId', isEqualTo: groupId)
          .where('memberId', isEqualTo: memberId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      final data = query.docs.first.data() as Map<String, dynamic>;
      return GroupMember.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get group membership: $e');
    }
  }

  /// Get all groups for a specific member
  Future<List<Group>> getMemberGroups(String memberId) async {
    try {
      // First get all group memberships for the member
      final memberships = await _groupMembersCollection
          .where('memberId', isEqualTo: memberId)
          .get();

      if (memberships.docs.isEmpty) {
        return [];
      }

      // Get all group IDs
      final groupIds = memberships.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['groupId'] as String)
          .toList();

      // Fetch all groups in batches (Firestore 'in' query limit is 10)
      final groups = <Group>[];
      for (int i = 0; i < groupIds.length; i += 10) {
        final batch = groupIds.skip(i).take(10).toList();
        final query = await _groupsCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in query.docs) {
          final data = doc.data() as Map<String, dynamic>;
          groups.add(Group.fromJson(data));
        }
      }

      return groups;
    } catch (e) {
      throw Exception('Failed to get member groups: $e');
    }
  }

  /// Get all members of a group with their roles
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      final query = await _groupMembersCollection
          .where('groupId', isEqualTo: groupId)
          .orderBy('joinedAt')
          .get();

      return query.docs
          .map((doc) => GroupMember.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get group members: $e');
    }
  }

  /// Get groups by type
  Future<List<Group>> getGroupsByType(GroupType groupType) async {
    try {
      final query = await _groupsCollection
          .where('groupType', isEqualTo: groupType.value)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => Group.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get groups by type: $e');
    }
  }

  /// Check if a member has a specific role in a group
  Future<bool> hasRole({
    required String groupId,
    required String memberId,
    required GroupRole role,
  }) async {
    try {
      final membership = await getGroupMembership(groupId, memberId);
      return membership?.role == role;
    } catch (e) {
      return false;
    }
  }

  /// Check if a member is an admin of a group
  Future<bool> isGroupAdmin(String groupId, String memberId) async {
    return hasRole(groupId: groupId, memberId: memberId, role: GroupRole.admin);
  }

  /// Get all groups created by a specific member
  Future<List<Group>> getGroupsCreatedBy(String memberId) async {
    try {
      final query = await _groupsCollection
          .where('createdBy', isEqualTo: memberId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => Group.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get groups created by member: $e');
    }
  }

  /// Stream groups for real-time updates
  Stream<List<Group>> streamMemberGroups(String memberId) {
    try {
      return _groupMembersCollection
          .where('memberId', isEqualTo: memberId)
          .snapshots()
          .asyncMap((memberships) async {
            if (memberships.docs.isEmpty) {
              return <Group>[];
            }

            final groupIds = memberships.docs
                .map((doc) => (doc.data() as Map<String, dynamic>)['groupId'] as String)
                .toList();

            // Fetch groups in batches
            final groups = <Group>[];
            for (int i = 0; i < groupIds.length; i += 10) {
              final batch = groupIds.skip(i).take(10).toList();
              final query = await _groupsCollection
                  .where(FieldPath.documentId, whereIn: batch)
                  .get();

              for (final doc in query.docs) {
                final data = doc.data() as Map<String, dynamic>;
                groups.add(Group.fromJson(data));
              }
            }

            return groups;
          });
    } catch (e) {
      throw Exception('Failed to stream member groups: $e');
    }
  }

  /// Stream group members for real-time updates
  Stream<List<GroupMember>> streamGroupMembers(String groupId) {
    try {
      return _groupMembersCollection
          .where('groupId', isEqualTo: groupId)
          .orderBy('joinedAt')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => GroupMember.fromJson(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      throw Exception('Failed to stream group members: $e');
    }
  }
}