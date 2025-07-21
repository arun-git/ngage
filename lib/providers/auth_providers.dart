import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart' as app_user;
import '../models/member.dart';
import '../services/enhanced_auth_service.dart';
import '../repositories/user_repository.dart';
import '../repositories/member_repository.dart';
import '../repositories/repository_providers.dart';

/// Authentication state enum
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Authentication state data
class AuthStateData {
  final AuthState state;
  final app_user.User? user;
  final List<Member>? memberProfiles;
  final Member? currentMember;
  final String? errorMessage;

  const AuthStateData({
    required this.state,
    this.user,
    this.memberProfiles,
    this.currentMember,
    this.errorMessage,
  });

  AuthStateData copyWith({
    AuthState? state,
    app_user.User? user,
    List<Member>? memberProfiles,
    Member? currentMember,
    String? errorMessage,
  }) {
    return AuthStateData(
      state: state ?? this.state,
      user: user ?? this.user,
      memberProfiles: memberProfiles ?? this.memberProfiles,
      currentMember: currentMember ?? this.currentMember,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isAuthenticated => state == AuthState.authenticated && user != null;
  bool get isLoading => state == AuthState.loading;
  bool get hasError => state == AuthState.error;
}

/// Authentication state notifier
class AuthStateNotifier extends StateNotifier<AuthStateData> {
  final EnhancedAuthService _enhancedAuthService;
  final UserRepository _userRepository;
  final MemberRepository _memberRepository;

  AuthStateNotifier({
    required EnhancedAuthService enhancedAuthService,
    required UserRepository userRepository,
    required MemberRepository memberRepository,
  })  : _enhancedAuthService = enhancedAuthService,
        _userRepository = userRepository,
        _memberRepository = memberRepository,
        super(const AuthStateData(state: AuthState.initial)) {
    _initializeAuthState();
  }

  /// Initialize authentication state by listening to auth changes
  void _initializeAuthState() {
    _enhancedAuthService.authStateChanges.listen((user) async {
      if (user != null) {
        await _handleUserSignedIn(user);
      } else {
        _handleUserSignedOut();
      }
    });
  }

  /// Handle user signed in
  Future<void> _handleUserSignedIn(app_user.User user) async {
    try {
      state = state.copyWith(state: AuthState.loading);

      // Get user's member profiles
      final memberProfiles = await _memberRepository.getUserMembers(user.id);
      
      // Get current member (default member)
      Member? currentMember;
      if (user.defaultMember != null) {
        currentMember = await _memberRepository.getMember(user.defaultMember!);
      } else if (memberProfiles.isNotEmpty) {
        currentMember = memberProfiles.first;
      }

      state = AuthStateData(
        state: AuthState.authenticated,
        user: user,
        memberProfiles: memberProfiles,
        currentMember: currentMember,
      );
    } catch (e) {
      state = AuthStateData(
        state: AuthState.error,
        errorMessage: 'Failed to load user data: $e',
      );
    }
  }

  /// Handle user signed out
  void _handleUserSignedOut() {
    state = const AuthStateData(state: AuthState.unauthenticated);
  }

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = state.copyWith(state: AuthState.loading);
      
      final result = await _enhancedAuthService.signInWithEmail(email, password);
      
      // State will be updated by the auth state changes listener
      // But we can update member profiles immediately if they were claimed
      if (result.claimedMembers.isNotEmpty) {
        state = state.copyWith(
          memberProfiles: result.claimedMembers,
          currentMember: result.claimedMembers.first,
        );
      }
    } catch (e) {
      state = AuthStateData(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Create account with email and password
  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    try {
      state = state.copyWith(state: AuthState.loading);
      
      final result = await _enhancedAuthService.createUserWithEmailAndPassword(email, password);
      
      // State will be updated by the auth state changes listener
      // But we can update member profiles immediately if they were claimed
      if (result.claimedMembers.isNotEmpty) {
        state = state.copyWith(
          memberProfiles: result.claimedMembers,
          currentMember: result.claimedMembers.first,
        );
      }
    } catch (e) {
      state = AuthStateData(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign in with phone number
  Future<void> signInWithPhone(String phone, String verificationCode) async {
    try {
      state = state.copyWith(state: AuthState.loading);
      
      final result = await _enhancedAuthService.signInWithPhone(phone, verificationCode);
      
      if (result.claimedMembers.isNotEmpty) {
        state = state.copyWith(
          memberProfiles: result.claimedMembers,
          currentMember: result.claimedMembers.first,
        );
      }
    } catch (e) {
      state = AuthStateData(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(state: AuthState.loading);
      
      final result = await _enhancedAuthService.signInWithGoogle();
      
      if (result.claimedMembers.isNotEmpty) {
        state = state.copyWith(
          memberProfiles: result.claimedMembers,
          currentMember: result.claimedMembers.first,
        );
      }
    } catch (e) {
      state = AuthStateData(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign in with Slack
  Future<void> signInWithSlack(String code) async {
    try {
      state = state.copyWith(state: AuthState.loading);
      
      final result = await _enhancedAuthService.signInWithSlack(code);
      
      if (result.claimedMembers.isNotEmpty) {
        state = state.copyWith(
          memberProfiles: result.claimedMembers,
          currentMember: result.claimedMembers.first,
        );
      }
    } catch (e) {
      state = AuthStateData(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _enhancedAuthService.signOut();
      // State will be updated by the auth state changes listener
    } catch (e) {
      state = AuthStateData(
        state: AuthState.error,
        errorMessage: 'Sign out failed: $e',
      );
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _enhancedAuthService.sendPasswordResetEmail(email);
    } catch (e) {
      state = AuthStateData(
        state: AuthState.error,
        errorMessage: 'Password reset failed: $e',
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
        state: AuthState.error,
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
        state: state.user != null ? AuthState.authenticated : AuthState.unauthenticated,
        errorMessage: null,
      );
    }
  }
}

/// Provider for authentication state
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthStateData>((ref) {
  final enhancedAuthService = ref.watch(enhancedAuthServiceProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  final memberRepository = ref.watch(memberRepositoryProvider);

  return AuthStateNotifier(
    enhancedAuthService: enhancedAuthService,
    userRepository: userRepository,
    memberRepository: memberRepository,
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