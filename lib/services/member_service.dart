import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/member.dart';
import '../repositories/member_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/repository_providers.dart';
import 'member_claim_service.dart';

/// Data class for member profile updates
class MemberUpdateData {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? category;
  final String? title;
  final String? profilePhoto;
  final String? bio;

  const MemberUpdateData({
    this.firstName,
    this.lastName,
    this.phone,
    this.category,
    this.title,
    this.profilePhoto,
    this.bio,
  });

  /// Check if any field has been updated
  bool get hasUpdates => 
      firstName != null ||
      lastName != null ||
      phone != null ||
      category != null ||
      title != null ||
      profilePhoto != null ||
      bio != null;
}

/// Service for member profile management operations
abstract class MemberService {
  /// Get all member profiles for a user
  Future<List<Member>> getUserMembers(String userId);

  /// Get the current active member for a user
  Future<Member?> getCurrentMember(String userId);

  /// Switch the default member for a user
  Future<void> switchDefaultMember(String userId, String memberId);

  /// Update member profile information
  Future<Member> updateMemberProfile(String memberId, MemberUpdateData updateData);

  /// Get a specific member by ID
  Future<Member?> getMember(String memberId);

  /// Stream member profile changes
  Stream<Member?> streamMember(String memberId);

  /// Stream all members for a user
  Stream<List<Member>> streamUserMembers(String userId);

  /// Delete a member profile (soft delete by setting isActive to false)
  Future<void> deactivateMember(String memberId);

  /// Reactivate a member profile
  Future<void> reactivateMember(String memberId);
}

/// Implementation of member service
class MemberServiceImpl implements MemberService {
  final MemberRepository _memberRepository;
  final UserRepository _userRepository;
  final MemberClaimService _memberClaimService;

  MemberServiceImpl({
    required MemberRepository memberRepository,
    required UserRepository userRepository,
    required MemberClaimService memberClaimService,
  })  : _memberRepository = memberRepository,
        _userRepository = userRepository,
        _memberClaimService = memberClaimService;

  @override
  Future<List<Member>> getUserMembers(String userId) async {
    try {
      return await _memberRepository.getUserMembers(userId);
    } catch (e) {
      throw Exception('Failed to get user members: $e');
    }
  }

  @override
  Future<Member?> getCurrentMember(String userId) async {
    try {
      // Get user to find default member
      final user = await _userRepository.getUser(userId);
      if (user?.defaultMember == null) {
        return null;
      }

      return await _memberRepository.getMember(user!.defaultMember!);
    } catch (e) {
      throw Exception('Failed to get current member: $e');
    }
  }

  @override
  Future<void> switchDefaultMember(String userId, String memberId) async {
    try {
      // Verify the member belongs to the user
      final member = await _memberRepository.getMember(memberId);
      if (member == null) {
        throw Exception('Member not found');
      }

      if (member.userId != userId) {
        throw Exception('Member does not belong to user');
      }

      if (!member.isActive) {
        throw Exception('Cannot set inactive member as default');
      }

      // Update user's default member
      await _memberClaimService.setDefaultMember(userId, memberId);
    } catch (e) {
      throw Exception('Failed to switch default member: $e');
    }
  }

  @override
  Future<Member> updateMemberProfile(String memberId, MemberUpdateData updateData) async {
    try {
      if (!updateData.hasUpdates) {
        throw Exception('No updates provided');
      }

      // Get current member
      final currentMember = await _memberRepository.getMember(memberId);
      if (currentMember == null) {
        throw Exception('Member not found');
      }

      // Create updated member
      final updatedMember = currentMember.copyWith(
        firstName: updateData.firstName ?? currentMember.firstName,
        lastName: updateData.lastName ?? currentMember.lastName,
        phone: updateData.phone ?? currentMember.phone,
        category: updateData.category ?? currentMember.category,
        title: updateData.title ?? currentMember.title,
        profilePhoto: updateData.profilePhoto ?? currentMember.profilePhoto,
        bio: updateData.bio ?? currentMember.bio,
        updatedAt: DateTime.now(),
      );

      // Validate updated member
      final validation = updatedMember.validate();
      if (!validation.isValid) {
        throw Exception('Invalid member data: ${validation.errors.join(', ')}');
      }

      // Update in repository
      await _memberRepository.updateMember(updatedMember);

      return updatedMember;
    } catch (e) {
      throw Exception('Failed to update member profile: $e');
    }
  }

  @override
  Future<Member?> getMember(String memberId) async {
    try {
      return await _memberRepository.getMember(memberId);
    } catch (e) {
      throw Exception('Failed to get member: $e');
    }
  }

  @override
  Stream<Member?> streamMember(String memberId) {
    return _memberRepository.streamMember(memberId);
  }

  @override
  Stream<List<Member>> streamUserMembers(String userId) {
    return _memberRepository.streamUserMembers(userId);
  }

  @override
  Future<void> deactivateMember(String memberId) async {
    try {
      final member = await _memberRepository.getMember(memberId);
      if (member == null) {
        throw Exception('Member not found');
      }

      final deactivatedMember = member.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );

      await _memberRepository.updateMember(deactivatedMember);
    } catch (e) {
      throw Exception('Failed to deactivate member: $e');
    }
  }

  @override
  Future<void> reactivateMember(String memberId) async {
    try {
      final member = await _memberRepository.getMember(memberId);
      if (member == null) {
        throw Exception('Member not found');
      }

      final reactivatedMember = member.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );

      await _memberRepository.updateMember(reactivatedMember);
    } catch (e) {
      throw Exception('Failed to reactivate member: $e');
    }
  }
}

/// Provider for MemberService
final memberServiceProvider = Provider<MemberService>((ref) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  final memberClaimService = ref.watch(memberClaimServiceProvider);
  
  return MemberServiceImpl(
    memberRepository: memberRepository,
    userRepository: userRepository,
    memberClaimService: memberClaimService,
  );
});