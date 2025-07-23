import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart' as app_user;
import '../models/member.dart';
import '../models/auth_state.dart';
import '../services/enhanced_auth_service.dart';
import '../services/remember_me_service.dart';
import '../repositories/user_repository.dart';
import '../repositories/member_repository.dart';
import '../repositories/repository_providers.dart';

// Using AuthenticationState from models/auth_state.dart

/// Authentication state notifier
class AuthStateNotifier extends StateNotifier<AuthenticationState> {
  final EnhancedAuthService _enhancedAuthService;
  final UserRepository _userRepository;
  final MemberRepository _memberRepository;
  final RememberMeService _rememberMeService;

  AuthStateNotifier({
    required EnhancedAuthService enhancedAuthService,
    required UserRepository userRepository,
    required MemberRepository memberRepository,
    required RememberMeService rememberMeService,
  })  : _enhancedAuthService = enhancedAuthService,
        _userRepository = userRepository,
        _memberRepository = memberRepository,
        _rememberMeService = rememberMeService,
        super(const AuthenticationState(status: AuthStatus.initial)) {
    _initializeAuthState();
  }

  /// Initialize authentication state by listening to auth changes
  void _initializeAuthState() {
    _enhancedAuthService.authStateChanges.listen((user) async {
      if (user != null) {
        await _handleUserSignedIn(user);
      } else {
        await _handleUserSignedOut();
      }
    });
    
    // Check for remember me token on startup
    _checkRememberMeToken();
  }

  /// Check for remember me token and auto-authenticate if valid
  Future<void> _checkRememberMeToken() async {
    try {
      final token = await _rememberMeService.getPersistentToken();
      if (token != null && token.isValid) {
        // Token exists and is valid, but we still need Firebase to authenticate
        // The actual authentication will happen through Firebase Auth state changes
        await _rememberMeService.refreshToken();
      }
    } catch (e) {
      // If there's an error with remember me token, just continue normally
    }
  }

  /// Handle user signed in
  Future<void> _handleUserSignedIn(app_user.User user) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, isLoading: true);

      // Get user's member profiles
      final memberProfiles = await _memberRepository.getUserMembers(user.id);
      
      // Get current member (default member)
      Member? currentMember;
      if (user.defaultMember != null) {
        currentMember = await _memberRepository.getMember(user.defaultMember!);
      } else if (memberProfiles.isNotEmpty) {
        currentMember = memberProfiles.first;
      }

      // If no member profile exists, create a basic one
      if (currentMember == null && memberProfiles.isEmpty) {
        try {
          final basicMember = await _memberRepository.createMember(Member(
            id: '',
            userId: user.id,
            email: user.email,
            phone: user.phone,
            externalId: null,
            firstName: _extractFirstName(user.email),
            lastName: _extractLastName(user.email),
            category: null,
            title: null,
            profilePhoto: null,
            bio: null,
            isActive: true,
            importedAt: null,
            claimedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));

          // Update user with default member
          final updatedUser = user.copyWith(
            defaultMember: basicMember.id,
            updatedAt: DateTime.now(),
          );
          await _userRepository.updateUser(updatedUser);

          currentMember = basicMember;
          memberProfiles.add(basicMember);
          
          state = AuthenticationState(
            status: AuthStatus.authenticated,
            user: updatedUser,
            memberProfiles: [basicMember],
            currentMember: basicMember,
            isLoading: false,
          );
          return;
        } catch (memberError) {
          // If member creation fails, continue with authentication but log the error
          print('Failed to create basic member profile: $memberError');
        }
      }

      state = AuthenticationState(
        status: AuthStatus.authenticated,
        user: user,
        memberProfiles: memberProfiles,
        currentMember: currentMember,
        isLoading: false,
      );
    } catch (e) {
      state = AuthenticationState(
        status: AuthStatus.error,
        errorMessage: 'Failed to load user data: $e',
        isLoading: false,
      );
    }
  }

  /// Extract first name from email
  String _extractFirstName(String email) {
    final emailParts = email.split('@').first.split('.');
    return emailParts.isNotEmpty 
        ? _capitalize(emailParts.first) 
        : 'User';
  }

  /// Extract last name from email
  String _extractLastName(String email) {
    final emailParts = email.split('@').first.split('.');
    return emailParts.length > 1 
        ? _capitalize(emailParts.last) 
        : '';
  }

  /// Capitalize first letter of a string
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Handle user signed out
  Future<void> _handleUserSignedOut() async {
    // Clear remember me token on sign out
    await _rememberMeService.clearPersistentToken();
    state = const AuthenticationState(status: AuthStatus.unauthenticated);
  }

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password, {bool rememberMe = false}) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, isLoading: true);
      
      final result = await _enhancedAuthService.signInWithEmail(email, password);
      
      // Store remember me token if requested
      if (rememberMe) {
        await _rememberMeService.storePersistentToken(result.user.id);
      }
      
      // Update state immediately with authentication success
      state = AuthenticationState(
        status: AuthStatus.authenticated,
        user: result.user,
        memberProfiles: result.claimedMembers,
        currentMember: result.claimedMembers.isNotEmpty ? result.claimedMembers.first : null,
        isLoading: false,
      );
    } catch (e) {
      state = AuthenticationState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Create account with email and password
  Future<void> createUserWithEmailAndPassword(String email, String password, {bool rememberMe = false}) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, isLoading: true);
      
      final result = await _enhancedAuthService.createUserWithEmailAndPassword(email, password);
      
      // Store remember me token if requested
      if (rememberMe) {
        await _rememberMeService.storePersistentToken(result.user.id);
      }
      
      // Update state immediately with authentication success
      state = AuthenticationState(
        status: AuthStatus.authenticated,
        user: result.user,
        memberProfiles: result.claimedMembers,
        currentMember: result.claimedMembers.isNotEmpty ? result.claimedMembers.first : null,
        isLoading: false,
      );
    } catch (e) {
      state = AuthenticationState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Sign in with phone number
  Future<void> signInWithPhone(String phone, String verificationCode) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, isLoading: true);
      
      final result = await _enhancedAuthService.signInWithPhone(phone, verificationCode);
      
      if (result.claimedMembers.isNotEmpty) {
        state = state.copyWith(
          memberProfiles: result.claimedMembers,
          currentMember: result.claimedMembers.first,
          isLoading: false,
        );
      }
    } catch (e) {
      state = AuthenticationState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(status: AuthStatus.loading, isLoading: true);
      
      final result = await _enhancedAuthService.signInWithGoogle();
      
      if (result.claimedMembers.isNotEmpty) {
        state = state.copyWith(
          memberProfiles: result.claimedMembers,
          currentMember: result.claimedMembers.first,
          isLoading: false,
        );
      }
    } catch (e) {
      state = AuthenticationState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Sign in with Slack
  Future<void> signInWithSlack(String code) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, isLoading: true);
      
      final result = await _enhancedAuthService.signInWithSlack(code);
      
      if (result.claimedMembers.isNotEmpty) {
        state = state.copyWith(
          memberProfiles: result.claimedMembers,
          currentMember: result.claimedMembers.first,
          isLoading: false,
        );
      }
    } catch (e) {
      state = AuthenticationState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _enhancedAuthService.signOut();
      // State will be updated by the auth state changes listener
    } catch (e) {
      state = AuthenticationState(
        status: AuthStatus.error,
        errorMessage: 'Sign out failed: $e',
        isLoading: false,
      );
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, isLoading: true);
      await _enhancedAuthService.sendPasswordResetEmail(email);
      state = state.copyWith(
        status: AuthStatus.passwordResetSent,
        isLoading: false,
      );
    } catch (e) {
      state = AuthenticationState(
        status: AuthStatus.error,
        errorMessage: 'Password reset failed: $e',
        isLoading: false,
      );
    }
  }

  /// Switch to a different member profile
  Future<void> switchMemberProfile(String memberId) async {
    try {
      if (state.user == null) return;

      // Update user's default member
      await _userRepository.updateDefaultMember(state.user!.id, memberId);
      
      // Get the new current member
      final newCurrentMember = await _memberRepository.getMember(memberId);
      
      // Update user object with new default member
      final updatedUser = state.user!.copyWith(
        defaultMember: memberId,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        user: updatedUser,
        currentMember: newCurrentMember,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to switch member profile: $e',
      );
    }
  }

  /// Verify phone number
  Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required Function(String verificationId) codeSent,
    required Function(Exception) verificationFailed,
  }) async {
    try {
      await _enhancedAuthService.verifyPhoneNumber(
        phoneNumber,
        codeSent: codeSent,
        verificationFailed: (e) => verificationFailed(e),
      );
    } catch (e) {
      verificationFailed(Exception('Phone verification failed: $e'));
    }
  }

  /// Clear error state
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(
        status: state.user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        errorMessage: null,
      );
    }
  }
}

/// Provider for authentication state
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthenticationState>((ref) {
  final enhancedAuthService = ref.watch(enhancedAuthServiceProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  final memberRepository = ref.watch(memberRepositoryProvider);
  final rememberMeService = ref.watch(rememberMeServiceProvider);

  return AuthStateNotifier(
    enhancedAuthService: enhancedAuthService,
    userRepository: userRepository,
    memberRepository: memberRepository,
    rememberMeService: rememberMeService,
  );
});

/// Provider for current authenticated user
final currentUserProvider = Provider<app_user.User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user;
});

/// Provider for current member profile
final currentMemberProvider = Provider<Member?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.currentMember;
});

/// Provider for user's member profiles
final memberProfilesProvider = Provider<List<Member>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.memberProfiles ?? [];
});

/// Provider for authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isAuthenticated;
});

/// Provider for loading status
final isAuthLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isLoading;
});

/// Provider for error status
final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.errorMessage;
});