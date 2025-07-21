import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member.dart';

/// Repository for member data operations in Firestore
class MemberRepository {
  final FirebaseFirestore _firestore;
  static const String _collection = 'members';

  MemberRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create a new member document
  Future<Member> createMember(Member member) async {
    try {
      // Generate ID if not provided
      final docRef = member.id.isEmpty 
          ? _firestore.collection(_collection).doc()
          : _firestore.collection(_collection).doc(member.id);
      
      final memberWithId = member.copyWith(id: docRef.id);
      await docRef.set(memberWithId.toJson());
      
      return memberWithId;
    } catch (e) {
      throw Exception('Failed to create member: $e');
    }
  }

  /// Get member by ID
  Future<Member?> getMember(String memberId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(memberId).get();
      if (!doc.exists) return null;
      
      return Member.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get member: $e');
    }
  }

  /// Update member document
  Future<void> updateMember(Member member) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(member.id)
          .update(member.toJson());
    } catch (e) {
      throw Exception('Failed to update member: $e');
    }
  }

  /// Find unclaimed members by email or phone
  Future<List<Member>> findUnclaimedMembers(String email, String? phone) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isNull: true)
          .where('email', isEqualTo: email);

      final emailResults = await query.get();
      final members = emailResults.docs
          .map((doc) => Member.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // If phone is provided, also search by phone
      if (phone != null && phone.isNotEmpty) {
        final phoneQuery = _firestore
            .collection(_collection)
            .where('userId', isNull: true)
            .where('phone', isEqualTo: phone);

        final phoneResults = await phoneQuery.get();
        final phoneMembers = phoneResults.docs
            .map((doc) => Member.fromJson(doc.data()))
            .toList();

        // Combine results and remove duplicates
        final allMembers = [...members, ...phoneMembers];
        final uniqueMembers = <String, Member>{};
        for (final member in allMembers) {
          uniqueMembers[member.id] = member;
        }
        return uniqueMembers.values.toList();
      }

      return members;
    } catch (e) {
      throw Exception('Failed to find unclaimed members: $e');
    }
  }

  /// Get all members for a user
  Future<List<Member>> getUserMembers(String userId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs
          .map((doc) => Member.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user members: $e');
    }
  }

  /// Get all members (for duplicate checking during import)
  Future<List<Member>> getAllMembers() async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs
          .map((doc) => Member.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all members: $e');
    }
  }

  /// Claim member profile by updating userId
  Future<void> claimMember(String memberId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(memberId).update({
        'userId': userId,
        'claimedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to claim member: $e');
    }
  }

  /// Bulk create members (for import functionality)
  Future<void> bulkCreateMembers(List<Member> members) async {
    try {
      final batch = _firestore.batch();
      
      for (final member in members) {
        final docRef = _firestore.collection(_collection).doc(member.id);
        batch.set(docRef, member.toJson());
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk create members: $e');
    }
  }

  /// Delete member document
  Future<void> deleteMember(String memberId) async {
    try {
      await _firestore.collection(_collection).doc(memberId).delete();
    } catch (e) {
      throw Exception('Failed to delete member: $e');
    }
  }

  /// Stream member data changes
  Stream<Member?> streamMember(String memberId) {
    return _firestore
        .collection(_collection)
        .doc(memberId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Member.fromJson(doc.data()!);
    });
  }

  /// Stream all members for a user
  Stream<List<Member>> streamUserMembers(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Member.fromJson(doc.data()))
          .toList();
    });
  }

  /// Get member by ID (alias for getMember for consistency)
  Future<Member?> getById(String memberId) async {
    return getMember(memberId);
  }

  /// Get all members for a group
  Future<List<Member>> getGroupMembers(String groupId) async {
    try {
      // This is a simplified implementation
      // In a real app, you'd need to query through group membership
      final query = await _firestore
          .collection('group_members')
          .where('groupId', isEqualTo: groupId)
          .get();

      final memberIds = query.docs
          .map((doc) => doc.data()['memberId'] as String)
          .toList();

      if (memberIds.isEmpty) return [];

      // Get member details in batches (Firestore 'in' limit is 10)
      final members = <Member>[];
      for (int i = 0; i < memberIds.length; i += 10) {
        final batch = memberIds.skip(i).take(10).toList();
        final memberQuery = await _firestore
            .collection(_collection)
            .where(FieldPath.documentId, whereIn: batch)
            .where('isActive', isEqualTo: true)
            .get();

        final batchMembers = memberQuery.docs
            .map((doc) => Member.fromJson(doc.data()))
            .toList();
        
        members.addAll(batchMembers);
      }

      return members;
    } catch (e) {
      throw Exception('Failed to get group members: $e');
    }
  }

  /// Get all members for a team
  Future<List<Member>> getTeamMembers(String teamId) async {
    try {
      // Get team document to get member IDs
      final teamDoc = await _firestore
          .collection('teams')
          .doc(teamId)
          .get();

      if (!teamDoc.exists) return [];

      final teamData = teamDoc.data()!;
      final memberIds = List<String>.from(teamData['memberIds'] ?? []);

      if (memberIds.isEmpty) return [];

      // Get member details in batches (Firestore 'in' limit is 10)
      final members = <Member>[];
      for (int i = 0; i < memberIds.length; i += 10) {
        final batch = memberIds.skip(i).take(10).toList();
        final memberQuery = await _firestore
            .collection(_collection)
            .where(FieldPath.documentId, whereIn: batch)
            .where('isActive', isEqualTo: true)
            .get();

        final batchMembers = memberQuery.docs
            .map((doc) => Member.fromJson(doc.data()))
            .toList();
        
        members.addAll(batchMembers);
      }

      return members;
    } catch (e) {
      throw Exception('Failed to get team members: $e');
    }
  }

  /// Check if a member has a specific role in a group
  Future<bool> hasGroupRole(String memberId, String groupId, String role) async {
    try {
      final query = await _firestore
          .collection('group_members')
          .where('memberId', isEqualTo: memberId)
          .where('groupId', isEqualTo: groupId)
          .where('role', isEqualTo: role)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check group role: $e');
    }
  }

  /// Get all members with a specific role in a group
  Future<List<Member>> getGroupMembersByRole(String groupId, String role) async {
    try {
      // Get group member records with the specified role
      final query = await _firestore
          .collection('group_members')
          .where('groupId', isEqualTo: groupId)
          .where('role', isEqualTo: role)
          .get();

      final memberIds = query.docs
          .map((doc) => doc.data()['memberId'] as String)
          .toList();

      if (memberIds.isEmpty) return [];

      // Get member details in batches (Firestore 'in' limit is 10)
      final members = <Member>[];
      for (int i = 0; i < memberIds.length; i += 10) {
        final batch = memberIds.skip(i).take(10).toList();
        final memberQuery = await _firestore
            .collection(_collection)
            .where(FieldPath.documentId, whereIn: batch)
            .where('isActive', isEqualTo: true)
            .get();

        final batchMembers = memberQuery.docs
            .map((doc) => Member.fromJson(doc.data()))
            .toList();
        
        members.addAll(batchMembers);
      }

      return members;
    } catch (e) {
      throw Exception('Failed to get group members by role: $e');
    }
  }
}