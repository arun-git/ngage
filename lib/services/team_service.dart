import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team.dart';
import '../models/group_member.dart';

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
  CollectionReference get _groupMembersCollection =>
      _firestore.collection('group_members');

  /// Create a new team within a group
  Future<Team> createTeam({
    required String groupId,
    required String name,
    required String description,
    required String teamLeadId,
    String? logoUrl,
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
        // Check if member is already assigned to another team in the group
        final isAssigned = await isMemberAssignedToTeam(groupId, memberId);
        if (isAssigned) {
          final existingTeam = await getMemberTeamInGroup(groupId, memberId);
          throw ArgumentError(
              'Member $memberId is already assigned to team "${existingTeam?.name}" in this group. A member can only be assigned to one team per group.');
        }
      }

      final now = DateTime.now();
      final docRef = _teamsCollection.doc();

      final team = Team(
        id: docRef.id,
        groupId: groupId,
        name: name.trim(),
        description: description.trim(),
        teamLeadId: teamLeadId,
        logoUrl: logoUrl,
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
        throw ArgumentError(
            'Invalid team data: ${validation.errors.join(', ')}');
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
    String? logoUrl,
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
        logoUrl: logoUrl,
        maxMembers: maxMembers,
        teamType: teamType?.trim(),
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      // Validate the updated team data
      final validation = updatedTeam.validate();
      if (!validation.isValid) {
        throw ArgumentError(
            'Invalid team data: ${validation.errors.join(', ')}');
      }

      await _teamsCollection.doc(teamId).update(updatedTeam.toJson());
      return updatedTeam;
    } catch (e) {
      throw Exception('Failed to update team: $e');
    }
  }

  /// Update team logo
  Future<Team> updateTeamLogo({
    required String teamId,
    String? logoUrl,
  }) async {
    try {
      final existingTeam = await getTeam(teamId);
      if (existingTeam == null) {
        throw ArgumentError('Team not found: $teamId');
      }

      final updatedTeam = existingTeam.copyWith(
        logoUrl: logoUrl,
        updatedAt: DateTime.now(),
      );

      await _teamsCollection.doc(teamId).update(updatedTeam.toJson());
      return updatedTeam;
    } catch (e) {
      throw Exception('Failed to update team logo: $e');
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

      // Check if member is already assigned to another team in the same group
      await _validateMemberNotInOtherTeams(team.groupId, memberId, teamId);

      // Check team capacity
      if (team.isAtCapacity) {
        throw StateError(
            'Team is at maximum capacity (${team.maxMembers} members)');
      }

      final updatedTeam =
          team.addMember(memberId).copyWith(updatedAt: DateTime.now());

      await _teamsCollection.doc(teamId).update(updatedTeam.toJson());
      return updatedTeam;
    } catch (e) {
      throw Exception('Failed to add member to team: $e');
    }
  }

  /// Add multiple members to a team (bulk operation)
  Future<Team> addMembersToTeam({
    required String teamId,
    required List<String> memberIds,
  }) async {
    try {
      final team = await getTeam(teamId);
      if (team == null) {
        throw ArgumentError('Team not found: $teamId');
      }

      // Validate all members are part of the group
      for (final memberId in memberIds) {
        await _validateGroupMembership(team.groupId, memberId);
      }

      // Filter out members already in team
      final newMemberIds =
          memberIds.where((id) => !team.hasMember(id)).toList();

      if (newMemberIds.isEmpty) {
        throw ArgumentError('All specified members are already in this team');
      }

      // Check if any members are already assigned to other teams in the same group
      for (final memberId in newMemberIds) {
        await _validateMemberNotInOtherTeams(team.groupId, memberId, teamId);
      }

      // Check team capacity
      final totalNewMembers = team.memberCount + newMemberIds.length;
      if (team.maxMembers != null && totalNewMembers > team.maxMembers!) {
        throw StateError(
            'Adding ${newMemberIds.length} members would exceed team capacity (${team.maxMembers} max)');
      }

      // Add all new members
      var updatedTeam = team;
      for (final memberId in newMemberIds) {
        updatedTeam = updatedTeam.addMember(memberId);
      }
      updatedTeam = updatedTeam.copyWith(updatedAt: DateTime.now());

      await _teamsCollection.doc(teamId).update(updatedTeam.toJson());
      return updatedTeam;
    } catch (e) {
      throw Exception('Failed to add members to team: $e');
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
        throw StateError(
            'Cannot remove team lead. Assign new team lead first.');
      }

      final updatedTeam =
          team.removeMember(memberId).copyWith(updatedAt: DateTime.now());

      await _teamsCollection.doc(teamId).update(updatedTeam.toJson());
      return updatedTeam;
    } catch (e) {
      throw Exception('Failed to remove member from team: $e');
    }
  }

  /// Remove multiple members from a team (bulk operation)
  Future<Team> removeMembersFromTeam({
    required String teamId,
    required List<String> memberIds,
  }) async {
    try {
      final team = await getTeam(teamId);
      if (team == null) {
        throw ArgumentError('Team not found: $teamId');
      }

      // Filter out members not in team and team lead
      final membersToRemove = memberIds
          .where((id) => team.hasMember(id) && !team.isTeamLead(id))
          .toList();

      if (membersToRemove.isEmpty) {
        throw ArgumentError(
            'No valid members to remove (members must be in team and not team lead)');
      }

      // Check if trying to remove team lead
      final teamLeadInList = memberIds.contains(team.teamLeadId);
      if (teamLeadInList) {
        throw StateError(
            'Cannot remove team lead. Assign new team lead first.');
      }

      // Remove all specified members
      var updatedTeam = team;
      for (final memberId in membersToRemove) {
        updatedTeam = updatedTeam.removeMember(memberId);
      }
      updatedTeam = updatedTeam.copyWith(updatedAt: DateTime.now());

      await _teamsCollection.doc(teamId).update(updatedTeam.toJson());
      return updatedTeam;
    } catch (e) {
      throw Exception('Failed to remove members from team: $e');
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

      final updatedTeam = team
          .changeTeamLead(newTeamLeadId)
          .copyWith(updatedAt: DateTime.now());

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

  /// Get available members for a team (group members not assigned to any team in the group)
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

      // Get all teams in the group to check for existing assignments
      final groupTeams = await getGroupTeams(team.groupId);

      // Create a set of all member IDs already assigned to teams in this group
      final assignedMemberIds = <String>{};
      for (final groupTeam in groupTeams) {
        assignedMemberIds.addAll(groupTeam.memberIds);
      }

      // Filter out members already assigned to any team in the group
      final availableMembers = groupMembers.docs
          .map(
              (doc) => GroupMember.fromJson(doc.data() as Map<String, dynamic>))
          .where((member) => !assignedMemberIds.contains(member.memberId))
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

      if (groupMembership.docs.isEmpty) return false;

      // Check if member is already assigned to another team in the same group
      try {
        await _validateMemberNotInOtherTeams(team.groupId, memberId, teamId);
        return true;
      } catch (e) {
        return false;
      }
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

  /// Get detailed team member information with their group roles
  Future<List<Map<String, dynamic>>> getTeamMemberDetails(String teamId) async {
    try {
      final team = await getTeam(teamId);
      if (team == null) {
        throw ArgumentError('Team not found: $teamId');
      }

      final memberDetails = <Map<String, dynamic>>[];

      for (final memberId in team.memberIds) {
        // Get group membership details
        final groupMembership = await _groupMembersCollection
            .where('groupId', isEqualTo: team.groupId)
            .where('memberId', isEqualTo: memberId)
            .limit(1)
            .get();

        if (groupMembership.docs.isNotEmpty) {
          final memberData =
              groupMembership.docs.first.data() as Map<String, dynamic>;
          memberDetails.add({
            'memberId': memberId,
            'isTeamLead': team.isTeamLead(memberId),
            'groupRole': memberData['role'],
            'joinedAt': memberData['joinedAt'],
            'memberData': memberData,
          });
        }
      }

      // Sort by team lead first, then by join date
      memberDetails.sort((a, b) {
        if (a['isTeamLead'] && !b['isTeamLead']) return -1;
        if (!a['isTeamLead'] && b['isTeamLead']) return 1;

        final aJoined = DateTime.parse(a['joinedAt'] as String);
        final bJoined = DateTime.parse(b['joinedAt'] as String);
        return aJoined.compareTo(bJoined);
      });

      return memberDetails;
    } catch (e) {
      throw Exception('Failed to get team member details: $e');
    }
  }

  /// Transfer team leadership with validation
  Future<Team> transferTeamLeadership({
    required String teamId,
    required String newTeamLeadId,
    String? reason,
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

      // Cannot transfer to current team lead
      if (team.isTeamLead(newTeamLeadId)) {
        throw ArgumentError('Member is already the team lead');
      }

      final updatedTeam = team
          .changeTeamLead(newTeamLeadId)
          .copyWith(updatedAt: DateTime.now());

      await _teamsCollection.doc(teamId).update(updatedTeam.toJson());

      // TODO: Add audit log for leadership transfer
      // await _logLeadershipTransfer(teamId, team.teamLeadId, newTeamLeadId, reason);

      return updatedTeam;
    } catch (e) {
      throw Exception('Failed to transfer team leadership: $e');
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

  /// Get unassigned members in a group (members not assigned to any team)
  Future<List<GroupMember>> getUnassignedMembersInGroup(String groupId) async {
    try {
      // Get all group members
      final groupMembers = await _groupMembersCollection
          .where('groupId', isEqualTo: groupId)
          .get();

      // Get all teams in the group
      final groupTeams = await getGroupTeams(groupId);

      // Create a set of all member IDs already assigned to teams
      final assignedMemberIds = <String>{};
      for (final team in groupTeams) {
        assignedMemberIds.addAll(team.memberIds);
      }

      // Filter out members already assigned to any team
      final unassignedMembers = groupMembers.docs
          .map(
              (doc) => GroupMember.fromJson(doc.data() as Map<String, dynamic>))
          .where((member) => !assignedMemberIds.contains(member.memberId))
          .toList();

      return unassignedMembers;
    } catch (e) {
      throw Exception('Failed to get unassigned members in group: $e');
    }
  }

  /// Check if a member is already assigned to any team in a group
  Future<bool> isMemberAssignedToTeam(String groupId, String memberId) async {
    try {
      final memberTeams = await _teamsCollection
          .where('groupId', isEqualTo: groupId)
          .where('memberIds', arrayContains: memberId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return memberTeams.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check member team assignment: $e');
    }
  }

  /// Get the team a member is assigned to in a specific group (if any)
  Future<Team?> getMemberTeamInGroup(String groupId, String memberId) async {
    try {
      final memberTeams = await _teamsCollection
          .where('groupId', isEqualTo: groupId)
          .where('memberIds', arrayContains: memberId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (memberTeams.docs.isEmpty) {
        return null;
      }

      final data = memberTeams.docs.first.data() as Map<String, dynamic>;
      return Team.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get member team in group: $e');
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

  /// Private helper to validate member is not assigned to other teams in the group
  Future<void> _validateMemberNotInOtherTeams(
      String groupId, String memberId, String excludeTeamId) async {
    final memberTeams = await _teamsCollection
        .where('groupId', isEqualTo: groupId)
        .where('memberIds', arrayContains: memberId)
        .where('isActive', isEqualTo: true)
        .get();

    // Check if member is in any other team (excluding the current team)
    for (final doc in memberTeams.docs) {
      if (doc.id != excludeTeamId) {
        final teamData = doc.data() as Map<String, dynamic>;
        final teamName = teamData['name'] as String;
        throw ArgumentError(
            'Member $memberId is already assigned to team "$teamName" in this group. A member can only be assigned to one team per group.');
      }
    }
  }
}
