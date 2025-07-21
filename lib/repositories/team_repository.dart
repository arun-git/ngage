import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team.dart';

/// Repository for team data access
/// 
/// Provides a data access layer for teams, abstracting Firebase Firestore operations.
class TeamRepository {
  final FirebaseFirestore _firestore;
  
  TeamRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _teamsCollection => _firestore.collection('teams');

  /// Create a new team document
  Future<void> createTeam(Team team) async {
    try {
      await _teamsCollection.doc(team.id).set(team.toJson());
    } catch (e) {
      throw Exception('Failed to create team in database: $e');
    }
  }

  /// Get a team by ID
  Future<Team?> getTeamById(String teamId) async {
    try {
      final doc = await _teamsCollection.doc(teamId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return Team.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get team from database: $e');
    }
  }

  /// Update a team document
  Future<void> updateTeam(Team team) async {
    try {
      await _teamsCollection.doc(team.id).update(team.toJson());
    } catch (e) {
      throw Exception('Failed to update team in database: $e');
    }
  }

  /// Delete a team document
  Future<void> deleteTeam(String teamId) async {
    try {
      await _teamsCollection.doc(teamId).delete();
    } catch (e) {
      throw Exception('Failed to delete team from database: $e');
    }
  }

  /// Get teams by group ID
  Future<List<Team>> getTeamsByGroupId(String groupId) async {
    try {
      final query = await _teamsCollection
          .where('groupId', isEqualTo: groupId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt')
          .get();

      return query.docs
          .map((doc) => Team.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get teams by group ID from database: $e');
    }
  }

  /// Get teams where a member is the team lead
  Future<List<Team>> getTeamsByTeamLead(String teamLeadId) async {
    try {
      final query = await _teamsCollection
          .where('teamLeadId', isEqualTo: teamLeadId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt')
          .get();

      return query.docs
          .map((doc) => Team.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get teams by team lead from database: $e');
    }
  }

  /// Get teams where a member is a participant
  Future<List<Team>> getTeamsByMember(String memberId) async {
    try {
      final query = await _teamsCollection
          .where('memberIds', arrayContains: memberId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt')
          .get();

      return query.docs
          .map((doc) => Team.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get teams by member from database: $e');
    }
  }

  /// Get teams by type within a group
  Future<List<Team>> getTeamsByType(String groupId, String teamType) async {
    try {
      final query = await _teamsCollection
          .where('groupId', isEqualTo: groupId)
          .where('teamType', isEqualTo: teamType)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt')
          .get();

      return query.docs
          .map((doc) => Team.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get teams by type from database: $e');
    }
  }

  /// Get teams by IDs (batch fetch)
  Future<List<Team>> getTeamsByIds(List<String> teamIds) async {
    try {
      if (teamIds.isEmpty) {
        return [];
      }

      final teams = <Team>[];
      
      // Firestore 'in' query limit is 10, so we need to batch
      for (int i = 0; i < teamIds.length; i += 10) {
        final batch = teamIds.skip(i).take(10).toList();
        final query = await _teamsCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in query.docs) {
          final data = doc.data() as Map<String, dynamic>;
          teams.add(Team.fromJson(data));
        }
      }

      return teams;
    } catch (e) {
      throw Exception('Failed to get teams by IDs from database: $e');
    }
  }

  /// Stream teams for real-time updates by group
  Stream<List<Team>> streamTeamsByGroupId(String groupId) {
    try {
      return _teamsCollection
          .where('groupId', isEqualTo: groupId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Team.fromJson(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      throw Exception('Failed to stream teams by group ID from database: $e');
    }
  }

  /// Stream teams for a member
  Stream<List<Team>> streamTeamsByMember(String memberId) {
    try {
      return _teamsCollection
          .where('memberIds', arrayContains: memberId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Team.fromJson(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      throw Exception('Failed to stream teams by member from database: $e');
    }
  }

  /// Stream a single team for real-time updates
  Stream<Team?> streamTeamById(String teamId) {
    try {
      return _teamsCollection
          .doc(teamId)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists) {
              return null;
            }
            final data = snapshot.data() as Map<String, dynamic>;
            return Team.fromJson(data);
          });
    } catch (e) {
      throw Exception('Failed to stream team by ID from database: $e');
    }
  }

  /// Get team count by group
  Future<int> getTeamCountByGroup(String groupId) async {
    try {
      final query = await _teamsCollection
          .where('groupId', isEqualTo: groupId)
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      return query.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get team count by group from database: $e');
    }
  }

  /// Get active teams count for a member
  Future<int> getActiveTeamCountForMember(String memberId) async {
    try {
      final query = await _teamsCollection
          .where('memberIds', arrayContains: memberId)
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      return query.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get active team count for member from database: $e');
    }
  }

  /// Soft delete a team (set isActive to false)
  Future<void> softDeleteTeam(String teamId) async {
    try {
      await _teamsCollection.doc(teamId).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to soft delete team from database: $e');
    }
  }

  /// Reactivate a soft-deleted team
  Future<void> reactivateTeam(String teamId) async {
    try {
      await _teamsCollection.doc(teamId).update({
        'isActive': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to reactivate team from database: $e');
    }
  }
}