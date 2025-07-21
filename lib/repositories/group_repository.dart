import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/enums.dart';

/// Repository for group data access
/// 
/// Provides a data access layer for groups and group memberships,
/// abstracting Firebase Firestore operations.
class GroupRepository {
  final FirebaseFirestore _firestore;
  
  GroupRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _groupsCollection => _firestore.collection('groups');
  CollectionReference get _groupMembersCollection => _firestore.collection('group_members');

  /// Create a new group document
  Future<void> createGroup(Group group) async {
    try {
      await _groupsCollection.doc(group.id).set(group.toJson());
    } catch (e) {
      throw Exception('Failed to create group in database: $e');
    }
  }

  /// Get a group by ID
  Future<Group?> getGroupById(String groupId) async {
    try {
      final doc = await _groupsCollection.doc(groupId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return Group.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get group from database: $e');
    }
  }

  /// Update a group document
  Future<void> updateGroup(Group group) async {
    try {
      await _groupsCollection.doc(group.id).update(group.toJson());
    } catch (e) {
      throw Exception('Failed to update group in database: $e');
    }
  }

  /// Delete a group document
  Future<void> deleteGroup(String groupId) async {
    try {
      await _groupsCollection.doc(groupId).delete();
    } catch (e) {
      throw Exception('Failed to delete group from database: $e');
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
      throw Exception('Failed to get groups by type from database: $e');
    }
  }

  /// Get groups created by a specific member
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
      throw Exception('Failed to get groups created by member from database: $e');
    }
  }

  /// Get groups by IDs (batch fetch)
  Future<List<Group>> getGroupsByIds(List<String> groupIds) async {
    try {
      if (groupIds.isEmpty) {
        return [];
      }

      final groups = <Group>[];
      
      // Firestore 'in' query limit is 10, so we need to batch
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
      throw Exception('Failed to get groups by IDs from database: $e');
    }
  }

  /// Create a group membership
  Future<void> createGroupMembership(GroupMember groupMember) async {
    try {
      await _groupMembersCollection.doc(groupMember.id).set(groupMember.toJson());
    } catch (e) {
      throw Exception('Failed to create group membership in database: $e');
    }
  }

  /// Get a group membership by group and member IDs
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
      throw Exception('Failed to get group membership from database: $e');
    }
  }

  /// Update a group membership
  Future<void> updateGroupMembership(GroupMember groupMember) async {
    try {
      await _groupMembersCollection.doc(groupMember.id).update(groupMember.toJson());
    } catch (e) {
      throw Exception('Failed to update group membership in database: $e');
    }
  }

  /// Delete a group membership
  Future<void> deleteGroupMembership(String membershipId) async {
    try {
      await _groupMembersCollection.doc(membershipId).delete();
    } catch (e) {
      throw Exception('Failed to delete group membership from database: $e');
    }
  }

  /// Get all memberships for a group
  Future<List<GroupMember>> getGroupMemberships(String groupId) async {
    try {
      final query = await _groupMembersCollection
          .where('groupId', isEqualTo: groupId)
          .orderBy('joinedAt')
          .get();

      return query.docs
          .map((doc) => GroupMember.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get group memberships from database: $e');
    }
  }

  /// Get all memberships for a member
  Future<List<GroupMember>> getMemberGroupMemberships(String memberId) async {
    try {
      final query = await _groupMembersCollection
          .where('memberId', isEqualTo: memberId)
          .get();

      return query.docs
          .map((doc) => GroupMember.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get member group memberships from database: $e');
    }
  }

  /// Delete all memberships for a group (used when deleting a group)
  Future<void> deleteAllGroupMemberships(String groupId) async {
    try {
      final batch = _firestore.batch();
      
      final memberships = await _groupMembersCollection
          .where('groupId', isEqualTo: groupId)
          .get();

      for (final doc in memberships.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all group memberships from database: $e');
    }
  }

  /// Stream groups for real-time updates
  Stream<List<Group>> streamGroupsByIds(List<String> groupIds) {
    try {
      if (groupIds.isEmpty) {
        return Stream.value([]);
      }

      // For simplicity, we'll stream the first 10 groups
      // In a production app, you might want to implement pagination
      final batchIds = groupIds.take(10).toList();
      
      return _groupsCollection
          .where(FieldPath.documentId, whereIn: batchIds)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Group.fromJson(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      throw Exception('Failed to stream groups from database: $e');
    }
  }

  /// Stream group memberships for real-time updates
  Stream<List<GroupMember>> streamGroupMemberships(String groupId) {
    try {
      return _groupMembersCollection
          .where('groupId', isEqualTo: groupId)
          .orderBy('joinedAt')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => GroupMember.fromJson(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      throw Exception('Failed to stream group memberships from database: $e');
    }
  }

  /// Stream member's group memberships for real-time updates
  Stream<List<GroupMember>> streamMemberGroupMemberships(String memberId) {
    try {
      return _groupMembersCollection
          .where('memberId', isEqualTo: memberId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => GroupMember.fromJson(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      throw Exception('Failed to stream member group memberships from database: $e');
    }
  }
}