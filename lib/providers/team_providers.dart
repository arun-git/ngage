import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/team_service.dart';
import '../repositories/team_repository.dart';
import '../models/team.dart';
import '../models/group_member.dart';

/// Provider for TeamRepository
final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return TeamRepository();
});

/// Provider for TeamService
final teamServiceProvider = Provider<TeamService>((ref) {
  return TeamService();
});

/// Provider for teams in a specific group
final groupTeamsProvider = StreamProvider.family<List<Team>, String>((ref, groupId) {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.streamGroupTeams(groupId);
});

/// Provider for teams where a member participates
final memberTeamsProvider = StreamProvider.family<List<Team>, String>((ref, memberId) {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.streamTeamsForMember(memberId);
});

/// Provider for a specific team
final teamProvider = StreamProvider.family<Team?, String>((ref, teamId) {
  final teamRepository = ref.watch(teamRepositoryProvider);
  return teamRepository.streamTeamById(teamId);
});

/// Provider for available members for a team
final availableMembersProvider = FutureProvider.family<List<GroupMember>, String>((ref, teamId) {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.getAvailableMembersForTeam(teamId);
});

/// Provider for team statistics
final teamStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, teamId) {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.getTeamStats(teamId);
});

/// Provider for teams led by a specific member
final teamsLedByMemberProvider = FutureProvider.family<List<Team>, String>((ref, memberId) {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.getTeamsLedBy(memberId);
});

/// State notifier for team creation
class TeamCreationNotifier extends StateNotifier<AsyncValue<Team?>> {
  TeamCreationNotifier(this._teamService) : super(const AsyncValue.data(null));

  final TeamService _teamService;

  Future<void> createTeam({
    required String groupId,
    required String name,
    required String description,
    required String teamLeadId,
    List<String>? initialMemberIds,
    int? maxMembers,
    String? teamType,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final team = await _teamService.createTeam(
        groupId: groupId,
        name: name,
        description: description,
        teamLeadId: teamLeadId,
        initialMemberIds: initialMemberIds,
        maxMembers: maxMembers,
        teamType: teamType,
      );
      
      state = AsyncValue.data(team);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for team creation state
final teamCreationProvider = StateNotifierProvider<TeamCreationNotifier, AsyncValue<Team?>>((ref) {
  final teamService = ref.watch(teamServiceProvider);
  return TeamCreationNotifier(teamService);
});

/// State notifier for team management operations
class TeamManagementNotifier extends StateNotifier<AsyncValue<String?>> {
  TeamManagementNotifier(this._teamService) : super(const AsyncValue.data(null));

  final TeamService _teamService;

  Future<void> addMemberToTeam(String teamId, String memberId) async {
    state = const AsyncValue.loading();
    
    try {
      await _teamService.addMemberToTeam(teamId: teamId, memberId: memberId);
      state = const AsyncValue.data('Member added successfully');
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addMembersToTeam(String teamId, List<String> memberIds) async {
    state = const AsyncValue.loading();
    
    try {
      await _teamService.addMembersToTeam(teamId: teamId, memberIds: memberIds);
      final count = memberIds.length;
      state = AsyncValue.data('$count member${count == 1 ? '' : 's'} added successfully');
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeMemberFromTeam(String teamId, String memberId) async {
    state = const AsyncValue.loading();
    
    try {
      await _teamService.removeMemberFromTeam(teamId: teamId, memberId: memberId);
      state = const AsyncValue.data('Member removed successfully');
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeMembersFromTeam(String teamId, List<String> memberIds) async {
    state = const AsyncValue.loading();
    
    try {
      await _teamService.removeMembersFromTeam(teamId: teamId, memberIds: memberIds);
      final count = memberIds.length;
      state = AsyncValue.data('$count member${count == 1 ? '' : 's'} removed successfully');
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> changeTeamLead(String teamId, String newTeamLeadId) async {
    state = const AsyncValue.loading();
    
    try {
      await _teamService.changeTeamLead(teamId: teamId, newTeamLeadId: newTeamLeadId);
      state = const AsyncValue.data('Team lead changed successfully');
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> transferTeamLeadership(String teamId, String newTeamLeadId, {String? reason}) async {
    state = const AsyncValue.loading();
    
    try {
      await _teamService.transferTeamLeadership(
        teamId: teamId, 
        newTeamLeadId: newTeamLeadId,
        reason: reason,
      );
      state = const AsyncValue.data('Team leadership transferred successfully');
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateTeam({
    required String teamId,
    String? name,
    String? description,
    String? teamLeadId,
    int? maxMembers,
    String? teamType,
    bool? isActive,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _teamService.updateTeam(
        teamId: teamId,
        name: name,
        description: description,
        teamLeadId: teamLeadId,
        maxMembers: maxMembers,
        teamType: teamType,
        isActive: isActive,
      );
      state = const AsyncValue.data('Team updated successfully');
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteTeam(String teamId) async {
    state = const AsyncValue.loading();
    
    try {
      await _teamService.deleteTeam(teamId);
      state = const AsyncValue.data('Team deleted successfully');
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for team management operations
final teamManagementProvider = StateNotifierProvider<TeamManagementNotifier, AsyncValue<String?>>((ref) {
  final teamService = ref.watch(teamServiceProvider);
  return TeamManagementNotifier(teamService);
});

/// Provider to check if a member can be added to a team
final canAddMemberProvider = FutureProvider.family<bool, ({String teamId, String memberId})>((ref, params) {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.canAddMemberToTeam(params.teamId, params.memberId);
});

/// Provider for detailed team member information
final teamMemberDetailsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, teamId) {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.getTeamMemberDetails(teamId);
});