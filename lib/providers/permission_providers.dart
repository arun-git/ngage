import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/permission_service.dart';
import '../models/enums.dart';

/// Provider for PermissionService
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

/// Provider to check if a member can judge in a group
final canJudgeInGroupProvider =
    FutureProvider.family<bool, ({String memberId, String groupId})>(
  (ref, params) async {
    final permissionService = ref.read(permissionServiceProvider);
    return await permissionService.canJudgeInGroup(
        params.memberId, params.groupId);
  },
);

/// Provider to check if a member is admin in a group
final isAdminInGroupProvider =
    FutureProvider.family<bool, ({String memberId, String groupId})>(
  (ref, params) async {
    final permissionService = ref.read(permissionServiceProvider);
    return await permissionService.isAdminInGroup(
        params.memberId, params.groupId);
  },
);

/// Provider to get member's role in a group
final memberRoleInGroupProvider =
    FutureProvider.family<GroupRole?, ({String memberId, String groupId})>(
  (ref, params) async {
    final permissionService = ref.read(permissionServiceProvider);
    return await permissionService.getMemberRoleInGroup(
        params.memberId, params.groupId);
  },
);

/// Provider to check if member can access judging dashboard
final canAccessJudgingDashboardProvider =
    FutureProvider.family<bool, ({String memberId, String groupId})>(
  (ref, params) async {
    final permissionService = ref.read(permissionServiceProvider);
    return await permissionService.canAccessJudgingDashboard(
        params.memberId, params.groupId);
  },
);
