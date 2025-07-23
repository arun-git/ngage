import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as app_user;
import '../models/member.dart';
import 'auth_service.dart';
import 'member_claim_service.dart';
import '../repositories/user_repository.dart';
import '../repositories/repository_providers.dart';

/// Enhanced authentication result that includes claimed member profiles
class AuthResult {
  final app_user.User user;
  final List<Member> claimedMembers;
  final bool isNewUser;

  const AuthResult({
    required this.user,
    required this.claimedMembers,
    required this.isNewUser,
  });
}

/// Enhanced authentication service that handles user creation and member claiming
class EnhancedAuthService {
  final AuthService _authService;
  final MemberClaimService _memberClaimService;
  final UserRepository _userRepository;

  EnhancedAuthService({
    required AuthService authService,
    required MemberClaimService memberClaimService,
    required UserRepository userRepository,
  })  : _authService = authService,
        _memberClaimService = memberClaimService,
        _userRepository = userRepository;

  /// Sign in with email and handle member claiming
  Future<AuthResult> signInWithEmail(String email, String password) async {
    final firebaseUser = await _authService.signInWithEmail(email, password);
    return await _handleUserAuthentication(firebaseUser);
  }

  /// Create account with email and handle member claiming
  Future<AuthResult> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final firebaseUser = await _authService.createUserWithEmailAndPassword(
      email,
      password,
    );
    return await _handleUserAuthentication(firebaseUser, isNewUser: true);
  }

  /// Sign in with phone and handle member claiming
  Future<AuthResult> signInWithPhone(String phone, String verificationCode) async {
    final firebaseUser = await _authService.signInWithPhone(phone, verificationCode);
    return await _handleUserAuthentication(firebaseUser);
  }

  /// Sign in with Google and handle member claiming
  Future<AuthResult> signInWithGoogle() async {
    final firebaseUser = await _authService.signInWithGoogle();
    return await _handleUserAuthentication(firebaseUser);
  }

  /// Sign in with Slack and handle member claiming
  Future<AuthResult> signInWithSlack(String code) async {
    final firebaseUser = await _authService.signInWithSlack(code);
    return await _handleUserAuthentication(firebaseUser);
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  /// Verify phone number
  Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required Function(String verificationId) codeSent,
    required Function(firebase_auth.FirebaseAuthException) verificationFailed,
    Function(firebase_auth.PhoneAuthCredential)? verificationCompleted,
  }) async {
    await _authService.verifyPhoneNumber(
      phoneNumber,
      codeSent: codeSent,
      verificationFailed: verificationFailed,
      verificationCompleted: verificationCompleted,
    );
  }

  /// Get current authenticated user
  app_user.User? get currentUser => _authService.currentUser;

  /// Stream of authentication state changes
  Stream<app_user.User?> get authStateChanges => _authService.authStateChanges;

  /// Handle user authentication and member claiming process
  Future<AuthResult> _handleUserAuthentication(
    app_user.User firebaseUser, {
    bool isNewUser = false,
  }) async {
    try {
      // Check if user document exists in Firestore
      final existingUser = await _userRepository.getUser(firebaseUser.id);
      
      app_user.User user;
      List<Member> claimedMembers = [];

      if (existingUser == null) {
        // Create new user document in Firestore
        user = firebaseUser.copyWith(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _userRepository.createUser(user);
        isNewUser = true;
      } else {
        user = existingUser;
      }

      // Claim member profiles if this is a new user or if they don't have a default member
      if (isNewUser || user.defaultMember == null) {
        claimedMembers = await _memberClaimService.claimMemberProfiles(user);
        
        // If no members were claimed, create a basic member profile
        if (claimedMembers.isEmpty) {
          final basicMember = await _memberClaimService.createBasicMemberProfile(user);
          claimedMembers = [basicMember];
        }

        // Update user with default member if it was set during claiming
        if (claimedMembers.isNotEmpty && user.defaultMember == null) {
          user = user.copyWith(
            defaultMember: claimedMembers.first.id,
            updatedAt: DateTime.now(),
          );
          await _userRepository.updateUser(user);
        }
      } else {
        // For existing users, get their existing member profiles
        final existingMembers = await _memberClaimService.claimMemberProfiles(user);
        if (existingMembers.isNotEmpty) {
          claimedMembers = existingMembers;
        }
      }

      return AuthResult(
        user: user,
        claimedMembers: claimedMembers,
        isNewUser: isNewUser,
      );
    } catch (e) {
      // If user creation or member claiming fails, we should still return the Firebase user
      // but with empty claimed members list
      return AuthResult(
        user: firebaseUser,
        claimedMembers: [],
        isNewUser: isNewUser,
      );
    }
  }
}

/// Provider for EnhancedAuthService
final enhancedAuthServiceProvider = Provider<EnhancedAuthService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final memberClaimService = ref.watch(memberClaimServiceProvider);
  final userRepository = ref.watch(userRepositoryProvider);

  return EnhancedAuthService(
    authService: authService,
    memberClaimService: memberClaimService,
    userRepository: userRepository,
  );
});