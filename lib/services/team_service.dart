import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team.dart';
import '../models/group_member.dart';
import '../models/enums.dart';

/// Service for managing teams within groups
/// 
/// Provides CRUD operations for teams and handles team membership
/// management including member assignment and team lead management.
class TeamService {
  final FirebaseFirestore _firestore;
  
  TeamService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _teamsCollection => _firestore.collection('teams');
  CollectionReference get _groupMembersCollection => _firestore.collection('group_members');

  /// Create a new team within a group
  Future<Team> createTeam({
    required String groupId,
    required String name,
    required String description,
    required String teamLeadId,
    List<String>? initialMemberIds,
    int? maxMembers,
    String? teamType,
  }) async {
    try {
      // Validate that team lead is a member of the group
      await _validateGroupMembership(groupId, teamLeadId);
      
      // Validate initial members are part of the group
      final memberIds = initialMemberIds ?? [];
      if (!memberIds.contains(teamLeadId)) {
        memberIds.add(teamLeadId); // Ensure team lead is in member list
      }
      
      for (final memberId in memberIds) {
        await _validateGroupMembership(groupId, memberId);
      }

      final now = DateTime.now();
      final docRef = _teamsCollection.doc();
      
      final team = Team(
        id: docRef.id,
        groupId: groupId,
        name: name.trim(),
        description: description.trim(),
        teamLeadId: teamLeadId,
        memberIds: memberIds,
        maxMembers: maxMembers,
        teamType: teamType?.trim(),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Validate the team data
      final validation = team.validate();
      if (!validation.isValid) {
        throw ArgumentError('Invalid team data: ${validation.errors.join(', ')}');
      }

      // Create the team document
      await docRef.set(team.toJson());

      return team;
    } catch (e) {
      throw Exception('Failed to create team: $e');
    }
  }

  /// Get a team by ID
  Future<Team?> getTeam(String teamId) async {
    try {
      final doc = await _teamsCollection.doc(teamId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return Team.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get team: $e');
    }
  }

  /// Update an existing team
  Future<Team> updateTeam({
    required String teamId,
    String? name,
    String? description,
    String? teamLeadId,
    int? maxMembers,
    String? teamType,
    bool? isActive,
  }) async {
    try {
      final existingTeam = await getTeam(teamId);
      if (existingTeam == null) {
        throw ArgumentError('Team not found: $teamId');
      }

      // If changing team lead, validate they are a group member and team member
      if (teamLeadId != null && teamLeadId != existingTeam.teamLeadId) {
        await _validateGroupMembership(existingTeam.groupId, teamLeadId);
        if (!existingTeam.hasMember(teamLeadId)) {
          throw ArgumentError('New team lead must be a member of the team');
        }
      }

      final updatedTeam = existingTeam.copyWith(
        name: name?.trim(),
        description: description?.trim(),
        teamLeadId: teamLeadId,
        maxMembers: maxMembers,
        teamType: teamType?.trim(),
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      // Validate the updated team data
      final validation = updatedTeam.validate();
      if (!validation.isValid) {
        throw ArgumentError('Invalid team data: ${validation.errors.join(', ')}');
      }

      await _teamsCollection.doc(teamId).update(updatedTeam.toJson());
      return updatedTeam;
    } catch (e) {
      throw Exception('Failed to update team: $e');
    }
  }

  /// Delete a team
  Future<void> deleteTeam(String teamId) async {
    try {
      await _teamsCollection.doc(teamId).delete();
    } catch (e) {
      throw Exception('Failed to delete team: $e');
    }
  }

  /// Add a member to a team
  Future<Team> addMemberToTeam({
    required String teamId,
    required String memberId,
  }) async {
    try {
      final team = await getTeam(teamId);
      if (team == null) {
        throw ArgumentError('Team not found: $teamId');
      }

      // Validate member is part of the group
      await _validateGroupMembership(team.groupId, memberId);

      // Check if member is already in team
      if (team.hasMember(memberId)) {
        throw ArgumentError('Member is already in this team');
      }

      // Check team capacity
      if (team.isAtCapacity) {
        throw StateError('Team is at maximum capacity (${team.maxMembers} members)');
      }

      final updatedTeam = team.addMember(memberId).copyWith(updatedAt: DateTime.now());
      
      await _teamsCollection.doc(teamId).update(updatedTeam.toJson());
      return updatedTeam;
    } catch (e) {
      throw Exception('Failed to add member to team: $e');
    }
  }

  /// Remove a member from a team
  Future<Team> removeMemberFromTeam({
    required String teamId,
    required String memberId,
  }) async {
    try {
      final team = await getTeam(teamId);
      if (team == null) {
        throw ArgumentError('Team not found: $teamId');
      }

      // Check if member is in team
      if (!team.hasMember(memberId)) {
        throw ArgumentError('Member is not in this team');
      }

      // Cannot remove team lead directly
      if (team.isTeamLead(memberId)) {
        throw StateError('Cannot remove team lead. Assign new team lead first.');
      }

      final updatedTeam = team.removeMember(memberId).copyWith(updatedAt: DateTime.now());
      
      await _teamsCollection.doc(teamId).update(updatedTeam.toJson());
      return updatedTeam;
    } catch (e) {
      throw Exception('Failed to remove member from team: $e');
    }
  }

  /// Change team lead
  Future<Team> changeTeamLead({
    required String teamId,
    required String newTeamLeadId,
  }) async {
    try {
      final team = await getTeam(teamId);
      if (team == null) {
        throw ArgumentError('Team not found: $teamId');
      }

      // Validate new team lead is a group member
      await _validateGroupMembership(team.groupId, newTeamLeadId);

      // Validate new team lead is a team member
      if (!team.hasMember(newTeamLeadId)) {
        throw ArgumentError('New team lead must be a member of the team');
      }

      final updatedTeam = team.changeTeamLead(newTeamLeadId).copyWith(updatedAt: DateTime.now());
      
      await _teamsCollection.doc(teamId).update(updatedTeam.toJson());
      return updatedTeam;
    } catch (e) {
      throw Exception('Failed to change team lead: $e');
    }
  }

  /// Get all teams in a group
  Future<List<Team>> getGroupTeams(String groupId) async {
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
      throw Exception('Failed to get group teams: $e');
    }
  }

  /// Get teams where a member is the team lead
  Future<List<Team>> getTeamsLedBy(String memberId) async {
    try {
      final query = await _teamsCollection
          .where('teamLeadId', isEqualTo: memberId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt')
          .get();

      return query.docs
          .map((doc) => Team.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get teams led by member: $e');
    }
  }

  /// Get teams where a member is a participant (including as team lead)
  Future<List<Team>> getTeamsForMember(String memberId) async {
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
      throw Exception('Failed to get teams for member: $e');
    }
  }

  /// Get available members for a team (group members not in the team)
  Future<List<GroupMember>> getAvailableMembersForTeam(String teamId) async {
    try {
      final team = await getTeam(teamId);
      if (team == null) {
        throw ArgumentError('Team not found: $teamId');
      }

      // Get all group members
      final groupMembers = await _groupMembersCollection
          .where('groupId', isEqualTo: team.groupId)
          .get();

      // Filter out members already in the team
      final availableMembers = groupMembers.docs
          .map((doc) => GroupMember.fromJson(doc.data() as Map<String, dynamic>))
          .where((member) => !team.hasMember(member.memberId))
          .toList();

      return availableMembers;
    } catch (e) {
      throw Exception('Failed to get available members for team: $e');
    }
  }

  /// Check if a member can be added to a team
  Future<bool> canAddMemberToTeam(String teamId, String memberId) async {
    try {
      final team = await getTeam(teamId);
      if (team == null) return false;

      // Check if member is already in team
      if (team.hasMember(memberId)) return false;

      // Check team capacity
      if (team.isAtCapacity) return false;

      // Check if member is part of the group
      final groupMembership = await _groupMembersCollection
          .where('groupId', isEqualTo: team.groupId)
          .where('memberId', isEqualTo: memberId)
          .limit(1)
          .get();

      return groupMembership.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get team statistics
  Future<Map<String, dynamic>> getTeamStats(String teamId) async {
    try {
      final team = await getTeam(teamId);
      if (team == null) {
        throw ArgumentError('Team not found: $teamId');
      }

      return {
        'memberCount': team.memberCount,
        'maxMembers': team.maxMembers,
        'isAtCapacity': team.isAtCapacity,
        'canAcceptMembers': team.canAcceptMembers,
        'teamLeadId': team.teamLeadId,
        'isActive': team.isActive,
        'createdAt': team.createdAt,
        'updatedAt': team.updatedAt,
      };
    } catch (e) {
      throw Exception('Failed to get team stats: $e');
    }
  }

  /// Stream teams for real-time updates
  Stream<List<Team>> streamGroupTeams(String groupId) {
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
      throw Exception('Failed to stream group teams: $e');
    }
  }

  /// Stream teams for a member
  Stream<List<Team>> streamTeamsForMember(String memberId) {
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
      throw Exception('Failed to stream teams for member: $e');
    }
  }

  /// Private helper to validate group membership
  Future<void> _validateGroupMembership(String groupId, String memberId) async {
    final membership = await _groupMembersCollection
        .where('groupId', isEqualTo: groupId)
        .where('memberId', isEqualTo: memberId)
        .limit(1)
        .get();

    if (membership.docs.isEmpty) {
      throw ArgumentError('Member $memberId is not part of group $groupId');
    }
  }
}