import '../models/models.dart';
import '../repositories/group_repository.dart';

/// Service for checking user permissions and roles
class PermissionService {
  final GroupRepository _groupRepository;

  PermissionService({
    GroupRepository? groupRepository,
  }) : _groupRepository = groupRepository ?? GroupRepository();

  /// Check if a member can judge events in a group
  Future<bool> canJudgeInGroup(String memberId, String groupId) async {
    try {
      final membership =
          await _groupRepository.getGroupMembership(groupId, memberId);
      return membership?.canJudge ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if a member is an admin in a group
  Future<bool> isAdminInGroup(String memberId, String groupId) async {
    try {
      final membership =
          await _groupRepository.getGroupMembership(groupId, memberId);
      return membership?.isAdmin ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get member's role in a group
  Future<GroupRole?> getMemberRoleInGroup(
      String memberId, String groupId) async {
    try {
      final membership =
          await _groupRepository.getGroupMembership(groupId, memberId);
      return membership?.role;
    } catch (e) {
      return null;
    }
  }

  /// Check if a member has any of the specified roles in a group
  Future<bool> hasAnyRoleInGroup(
      String memberId, String groupId, List<GroupRole> roles) async {
    try {
      final membership =
          await _groupRepository.getGroupMembership(groupId, memberId);
      if (membership == null) return false;
      return roles.contains(membership.role);
    } catch (e) {
      return false;
    }
  }

  /// Check if a member can manage events in a group (admin only)
  Future<bool> canManageEventsInGroup(String memberId, String groupId) async {
    return await isAdminInGroup(memberId, groupId);
  }

  /// Check if a member can view judging dashboard for an event
  Future<bool> canAccessJudgingDashboard(
      String memberId, String groupId) async {
    return await canJudgeInGroup(memberId, groupId);
  }
}
