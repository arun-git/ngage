import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/member.dart';
import '../repositories/member_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/repository_providers.dart';

/// Service for handling member profile claiming logic
abstract class MemberClaimService {
  /// Claim member profiles for a user based on email/phone matching
  Future<List<Member>> claimMemberProfiles(User user);

  /// Create a basic member profile for a new user
  Future<Member> createBasicMemberProfile(User user);

  /// Set the default member for a user
  Future<void> setDefaultMember(String userId, String memberId);
}

/// Implementation of member claiming service
class MemberClaimServiceImpl implements MemberClaimService {
  final MemberRepository _memberRepository;
  final UserRepository _userRepository;

  MemberClaimServiceImpl({
    required MemberRepository memberRepository,
    required UserRepository userRepository,
  })  : _memberRepository = memberRepository,
        _userRepository = userRepository;

  @override
  Future<List<Member>> claimMemberProfiles(User user) async {
    try {
      // Find unclaimed members matching user's email or phone
      final unclaimedMembers = await _memberRepository.findUnclaimedMembers(
        user.email,
        user.phone,
      );

      if (unclaimedMembers.isEmpty) {
        return [];
      }

      // Claim all matching members
      final claimedMembers = <Member>[];
      for (final member in unclaimedMembers) {
        await _memberRepository.claimMember(member.id, user.id);
        
        // Create updated member with claimed information
        final claimedMember = member.copyWith(
          userId: user.id,
          claimedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        claimedMembers.add(claimedMember);
      }

      // Set the first claimed member as default if user doesn't have one
      if (claimedMembers.isNotEmpty && user.defaultMember == null) {
        await setDefaultMember(user.id, claimedMembers.first.id);
      }

      return claimedMembers;
    } catch (e) {
      throw Exception('Failed to claim member profiles: $e');
    }
  }

  @override
  Future<Member> createBasicMemberProfile(User user) async {
    try {
      final now = DateTime.now();
      
      // Extract first and last name from email if possible
      final emailParts = user.email.split('@').first.split('.');
      final firstName = emailParts.isNotEmpty 
          ? _capitalize(emailParts.first) 
          : 'User';
      final lastName = emailParts.length > 1 
          ? _capitalize(emailParts.last) 
          : '';

      final member = Member(
        id: _generateMemberId(),
        userId: user.id,
        email: user.email,
        phone: user.phone,
        externalId: null,
        firstName: firstName,
        lastName: lastName,
        category: null,
        title: null,
        profilePhoto: null,
        bio: null,
        isActive: true,
        importedAt: null,
        claimedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      await _memberRepository.createMember(member);

      // Set as default member if user doesn't have one
      if (user.defaultMember == null) {
        await setDefaultMember(user.id, member.id);
      }

      return member;
    } catch (e) {
      throw Exception('Failed to create basic member profile: $e');
    }
  }

  @override
  Future<void> setDefaultMember(String userId, String memberId) async {
    try {
      await _userRepository.updateDefaultMember(userId, memberId);
    } catch (e) {
      throw Exception('Failed to set default member: $e');
    }
  }

  /// Generate a unique member ID
  String _generateMemberId() {
    return 'member_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }

  /// Generate a random string of specified length
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (index) => chars[random % chars.length]).join();
  }

  /// Capitalize first letter of a string
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}

/// Provider for MemberClaimService
final memberClaimServiceProvider = Provider<MemberClaimService>((ref) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  
  return MemberClaimServiceImpl(
    memberRepository: memberRepository,
    userRepository: userRepository,
  );
});