import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/group_service.dart';
import '../repositories/group_repository.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/enums.dart';

/// Provider for GroupRepository
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository();
});

/// Provider for GroupService
final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService();
});

/// Provider for getting groups by member ID
final memberGroupsProvider =
    FutureProvider.family<List<Group>, String>((ref, memberId) async {
  final groupService = ref.read(groupServiceProvider);
  return groupService.getMemberGroups(memberId);
});

/// Provider for getting a specific group by ID
final groupProvider =
    FutureProvider.family<Group?, String>((ref, groupId) async {
  final groupService = ref.read(groupServiceProvider);
  return groupService.getGroup(groupId);
});

/// Provider for getting group members
final groupMembersProvider =
    FutureProvider.family<List<GroupMember>, String>((ref, groupId) async {
  final groupService = ref.read(groupServiceProvider);
  return groupService.getGroupMembers(groupId);
});

/// Provider for getting groups by type
final groupsByTypeProvider =
    FutureProvider.family<List<Group>, GroupType>((ref, groupType) async {
  final groupService = ref.read(groupServiceProvider);
  return groupService.getGroupsByType(groupType);
});

/// Provider for getting groups created by a member
final groupsCreatedByProvider =
    FutureProvider.family<List<Group>, String>((ref, memberId) async {
  final groupService = ref.read(groupServiceProvider);
  return groupService.getGroupsCreatedBy(memberId);
});

/// Provider for checking if a member is a group admin
final isGroupAdminProvider =
    FutureProvider.family<bool, ({String groupId, String memberId})>(
        (ref, params) async {
  final groupService = ref.read(groupServiceProvider);
  return groupService.isGroupAdmin(params.groupId, params.memberId);
});

/// Provider for getting a specific group membership
final groupMembershipProvider =
    FutureProvider.family<GroupMember?, ({String groupId, String memberId})>(
        (ref, params) async {
  final groupService = ref.read(groupServiceProvider);
  return groupService.getGroupMembership(params.groupId, params.memberId);
});

/// Stream provider for real-time group updates for a member
final memberGroupsStreamProvider =
    StreamProvider.family<List<Group>, String>((ref, memberId) {
  final groupService = ref.read(groupServiceProvider);
  return groupService.streamMemberGroups(memberId);
});

/// Stream provider for real-time group member updates
final groupMembersStreamProvider =
    StreamProvider.family<List<GroupMember>, String>((ref, groupId) {
  final groupService = ref.read(groupServiceProvider);
  return groupService.streamGroupMembers(groupId);
});

/// State notifier for managing group creation and updates
class GroupNotifier extends StateNotifier<AsyncValue<Group?>> {
  final GroupService _groupService;

  GroupNotifier(this._groupService) : super(const AsyncValue.data(null));

  /// Create a new group
  Future<Group> createGroup({
    required String name,
    required String description,
    required GroupType groupType,
    required String createdBy,
    String? imageUrl,
    Map<String, dynamic>? settings,
  }) async {
    state = const AsyncValue.loading();

    try {
      final group = await _groupService.createGroup(
        name: name,
        description: description,
        groupType: groupType,
        createdBy: createdBy,
        imageUrl: imageUrl,
        settings: settings,
      );

      state = AsyncValue.data(group);
      return group;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Update an existing group
  Future<Group> updateGroup({
    required String groupId,
    String? name,
    String? description,
    GroupType? groupType,
    String? imageUrl,
    Map<String, dynamic>? settings,
  }) async {
    state = const AsyncValue.loading();

    try {
      final group = await _groupService.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        groupType: groupType,
        imageUrl: imageUrl,
        settings: settings,
      );

      state = AsyncValue.data(group);
      return group;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Update group image
  Future<Group> updateGroupImage({
    required String groupId,
    String? imageUrl,
  }) async {
    state = const AsyncValue.loading();

    try {
      final group = await _groupService.updateGroupImage(
        groupId: groupId,
        imageUrl: imageUrl,
      );

      state = AsyncValue.data(group);
      return group;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Update group image
  /* Future<Group> updateGroupImage({
    required String groupId,
    String? imageUrl,
  }) async {
    return updateGroup(
      groupId: groupId,
      imageUrl: imageUrl,
    );
  }*/

  /// Delete a group
  Future<void> deleteGroup(String groupId) async {
    state = const AsyncValue.loading();

    try {
      await _groupService.deleteGroup(groupId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Clear the current state
  void clear() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for GroupNotifier
final groupNotifierProvider =
    StateNotifierProvider<GroupNotifier, AsyncValue<Group?>>((ref) {
  final groupService = ref.read(groupServiceProvider);
  return GroupNotifier(groupService);
});

/// State notifier for managing group memberships
class GroupMembershipNotifier extends StateNotifier<AsyncValue<GroupMember?>> {
  final GroupService _groupService;

  GroupMembershipNotifier(this._groupService)
      : super(const AsyncValue.data(null));

  /// Add a member to a group
  Future<GroupMember> addMemberToGroup({
    required String groupId,
    required String memberId,
    required GroupRole role,
  }) async {
    state = const AsyncValue.loading();

    try {
      final membership = await _groupService.addMemberToGroup(
        groupId: groupId,
        memberId: memberId,
        role: role,
      );

      state = AsyncValue.data(membership);
      return membership;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Remove a member from a group
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String memberId,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _groupService.removeMemberFromGroup(
        groupId: groupId,
        memberId: memberId,
      );

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Update a member's role in a group
  Future<GroupMember> updateMemberRole({
    required String groupId,
    required String memberId,
    required GroupRole newRole,
  }) async {
    state = const AsyncValue.loading();

    try {
      final membership = await _groupService.updateMemberRole(
        groupId: groupId,
        memberId: memberId,
        newRole: newRole,
      );

      state = AsyncValue.data(membership);
      return membership;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Clear the current state
  void clear() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for GroupMembershipNotifier
final groupMembershipNotifierProvider =
    StateNotifierProvider<GroupMembershipNotifier, AsyncValue<GroupMember?>>(
        (ref) {
  final groupService = ref.read(groupServiceProvider);
  return GroupMembershipNotifier(groupService);
});
