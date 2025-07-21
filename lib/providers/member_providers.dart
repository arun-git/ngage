import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/member.dart';
import '../services/member_service.dart';
import 'auth_providers.dart';

/// Provider for current user's members
final userMembersProvider = StreamProvider.autoDispose<List<Member>>((ref) {
  final authState = ref.watch(authStateProvider);
  final memberService = ref.watch(memberServiceProvider);

  final user = authState.user;
  if (user == null) {
    return Stream.value(<Member>[]);
  }
  return memberService.streamUserMembers(user.id);
});

/// Provider for current active member (renamed to avoid conflict)
final activeMemberProvider = FutureProvider.autoDispose<Member?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final memberService = ref.watch(memberServiceProvider);

  final user = authState.user;
  if (user == null) return null;
  return await memberService.getCurrentMember(user.id);
});

/// Provider for a specific member by ID
final memberProvider = StreamProvider.autoDispose.family<Member?, String>((ref, memberId) {
  final memberService = ref.watch(memberServiceProvider);
  return memberService.streamMember(memberId);
});

/// State notifier for member profile management
class MemberProfileNotifier extends StateNotifier<AsyncValue<Member?>> {
  final MemberService _memberService;
  final Ref _ref;

  MemberProfileNotifier(this._memberService, this._ref) : super(const AsyncValue.loading());

  /// Load member profile
  Future<void> loadMember(String memberId) async {
    state = const AsyncValue.loading();
    try {
      final member = await _memberService.getMember(memberId);
      state = AsyncValue.data(member);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update member profile
  Future<void> updateProfile(String memberId, MemberUpdateData updateData) async {
    try {
      final updatedMember = await _memberService.updateMemberProfile(memberId, updateData);
      state = AsyncValue.data(updatedMember);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Switch default member
  Future<void> switchDefaultMember(String userId, String memberId) async {
    try {
      await _memberService.switchDefaultMember(userId, memberId);
      // Refresh current member provider
      _ref.invalidate(activeMemberProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Deactivate member
  Future<void> deactivateMember(String memberId) async {
    try {
      await _memberService.deactivateMember(memberId);
      // Refresh user members provider
      _ref.invalidate(userMembersProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Reactivate member
  Future<void> reactivateMember(String memberId) async {
    try {
      await _memberService.reactivateMember(memberId);
      // Refresh user members provider
      _ref.invalidate(userMembersProvider);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// Provider for member profile management
final memberProfileProvider = StateNotifierProvider.autoDispose<MemberProfileNotifier, AsyncValue<Member?>>((ref) {
  final memberService = ref.watch(memberServiceProvider);
  return MemberProfileNotifier(memberService, ref);
});

/// Provider for member switching functionality
class MemberSwitchNotifier extends StateNotifier<AsyncValue<void>> {
  final MemberService _memberService;
  final Ref _ref;

  MemberSwitchNotifier(this._memberService, this._ref) : super(const AsyncValue.data(null));

  /// Switch to a different member profile
  Future<void> switchMember(String userId, String memberId) async {
    state = const AsyncValue.loading();
    try {
      await _memberService.switchDefaultMember(userId, memberId);
      // Refresh relevant providers
      _ref.invalidate(activeMemberProvider);
      _ref.invalidate(userMembersProvider);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// Provider for member switching
final memberSwitchProvider = StateNotifierProvider.autoDispose<MemberSwitchNotifier, AsyncValue<void>>((ref) {
  final memberService = ref.watch(memberServiceProvider);
  return MemberSwitchNotifier(memberService, ref);
});