import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'enhanced_auth_service.dart';
import 'auth_config_service.dart';
import 'slack_oauth_service.dart';

/// Comprehensive authentication manager that handles all authentication flows
class AuthManager {
  final EnhancedAuthService _enhancedAuthService;
  final StreamController<AuthEvent> _authEventController =
      StreamController<AuthEvent>.broadcast();

  AuthManager({required EnhancedAuthService enhancedAuthService})
      : _enhancedAuthService = enhancedAuthService;

  /// Stream of authentication events
  Stream<AuthEvent> get authEvents => _authEventController.stream;

  /// Get current authenticated user
  User? get currentUser => _enhancedAuthService.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _enhancedAuthService.authStateChanges;

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      _emitEvent(AuthEvent.signInStarted(AuthMethod.email));

      final result =
          await _enhancedAuthService.signInWithEmail(email, password);

      _emitEvent(AuthEvent.signInSuccess(AuthMethod.email, result.user));
      return result;
    } catch (e) {
      _emitEvent(AuthEvent.signInFailed(AuthMethod.email, e.toString()));
      rethrow;
    }
  }

  /// Create account with email and password
  Future<AuthResult> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      _emitEvent(AuthEvent.signUpStarted(AuthMethod.email));

      final result = await _enhancedAuthService.createUserWithEmailAndPassword(
          email, password);

      _emitEvent(AuthEvent.signUpSuccess(AuthMethod.email, result.user));
      return result;
    } catch (e) {
      _emitEvent(AuthEvent.signUpFailed(AuthMethod.email, e.toString()));
      rethrow;
    }
  }

  /// Sign in with phone number
  Future<AuthResult> signInWithPhone(
      String phone, String verificationCode) async {
    try {
      _emitEvent(AuthEvent.signInStarted(AuthMethod.phone));

      final result =
          await _enhancedAuthService.signInWithPhone(phone, verificationCode);

      _emitEvent(AuthEvent.signInSuccess(AuthMethod.phone, result.user));
      return result;
    } catch (e) {
      _emitEvent(AuthEvent.signInFailed(AuthMethod.phone, e.toString()));
      rethrow;
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      _emitEvent(AuthEvent.signInStarted(AuthMethod.google));

      final result = await _enhancedAuthService.signInWithGoogle();

      _emitEvent(AuthEvent.signInSuccess(AuthMethod.google, result.user));
      return result;
    } catch (e) {
      _emitEvent(AuthEvent.signInFailed(AuthMethod.google, e.toString()));
      rethrow;
    }
  }

  /// Sign in with Slack OAuth code
  Future<AuthResult> signInWithSlack(String code) async {
    try {
      _emitEvent(AuthEvent.signInStarted(AuthMethod.slack));

      final result = await _enhancedAuthService.signInWithSlack(code);

      _emitEvent(AuthEvent.signInSuccess(AuthMethod.slack, result.user));
      return result;
    } catch (e) {
      _emitEvent(AuthEvent.signInFailed(AuthMethod.slack, e.toString()));
      rethrow;
    }
  }

  /// Verify phone number
  Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required Function(String verificationId) codeSent,
    required Function(Exception) verificationFailed,
  }) async {
    try {
      _emitEvent(AuthEvent.phoneVerificationStarted(phoneNumber));

      await _enhancedAuthService.verifyPhoneNumber(
        phoneNumber,
        codeSent: (verificationId) {
          _emitEvent(
              AuthEvent.phoneVerificationCodeSent(phoneNumber, verificationId));
          codeSent(verificationId);
        },
        verificationFailed: (error) {
          _emitEvent(
              AuthEvent.phoneVerificationFailed(phoneNumber, error.toString()));
          verificationFailed(error);
        },
      );
    } catch (e) {
      _emitEvent(AuthEvent.phoneVerificationFailed(phoneNumber, e.toString()));
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _emitEvent(AuthEvent.passwordResetStarted(email));

      await _enhancedAuthService.sendPasswordResetEmail(email);

      _emitEvent(AuthEvent.passwordResetSent(email));
    } catch (e) {
      _emitEvent(AuthEvent.passwordResetFailed(email, e.toString()));
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      final currentUserId = currentUser?.id;
      _emitEvent(AuthEvent.signOutStarted(currentUserId));

      await _enhancedAuthService.signOut();

      _emitEvent(AuthEvent.signOutSuccess(currentUserId));
    } catch (e) {
      _emitEvent(AuthEvent.signOutFailed(e.toString()));
      rethrow;
    }
  }

  /// Handle OAuth callback (for deep linking)
  Future<void> handleOAuthCallback(Uri uri) async {
    try {
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        throw Exception('OAuth error: $error');
      }

      if (code == null) {
        throw Exception('No authorization code received');
      }

      // Determine OAuth provider based on state or other parameters
      if (state?.startsWith('slack_') == true) {
        await signInWithSlack(code);
      } else {
        throw Exception('Unknown OAuth provider');
      }
    } catch (e) {
      _emitEvent(AuthEvent.oauthCallbackFailed(uri.toString(), e.toString()));
      rethrow;
    }
  }

  /// Get Slack OAuth service if configured
  SlackOAuthService? getSlackOAuthService() {
    final config = AuthConfigService.getSlackConfig();
    return config != null ? SlackOAuthService(config) : null;
  }

  /// Check if authentication method is available
  bool isAuthMethodAvailable(AuthMethod method) {
    return AuthConfigService.isAuthMethodEnabled(method);
  }

  /// Get authentication configuration
  AuthConfig getAuthConfig() {
    return AuthConfigService.getConfig();
  }

  void _emitEvent(AuthEvent event) {
    if (!_authEventController.isClosed) {
      _authEventController.add(event);
    }
  }

  /// Dispose resources
  void dispose() {
    _authEventController.close();
  }
}

/// Authentication events for monitoring and analytics
abstract class AuthEvent {
  final DateTime timestamp;
  final AuthMethod? method;

  const AuthEvent({required this.timestamp, this.method});

  // Sign in events
  factory AuthEvent.signInStarted(AuthMethod method) = _SignInStarted;
  factory AuthEvent.signInSuccess(AuthMethod method, User user) =
      _SignInSuccess;
  factory AuthEvent.signInFailed(AuthMethod method, String error) =
      _SignInFailed;

  // Sign up events
  factory AuthEvent.signUpStarted(AuthMethod method) = _SignUpStarted;
  factory AuthEvent.signUpSuccess(AuthMethod method, User user) =
      _SignUpSuccess;
  factory AuthEvent.signUpFailed(AuthMethod method, String error) =
      _SignUpFailed;

  // Sign out events
  factory AuthEvent.signOutStarted(String? userId) = _SignOutStarted;
  factory AuthEvent.signOutSuccess(String? userId) = _SignOutSuccess;
  factory AuthEvent.signOutFailed(String error) = _SignOutFailed;

  // Phone verification events
  factory AuthEvent.phoneVerificationStarted(String phoneNumber) =
      _PhoneVerificationStarted;
  factory AuthEvent.phoneVerificationCodeSent(
      String phoneNumber, String verificationId) = _PhoneVerificationCodeSent;
  factory AuthEvent.phoneVerificationFailed(String phoneNumber, String error) =
      _PhoneVerificationFailed;

  // Password reset events
  factory AuthEvent.passwordResetStarted(String email) = _PasswordResetStarted;
  factory AuthEvent.passwordResetSent(String email) = _PasswordResetSent;
  factory AuthEvent.passwordResetFailed(String email, String error) =
      _PasswordResetFailed;

  // OAuth callback events
  factory AuthEvent.oauthCallbackFailed(String uri, String error) =
      _OAuthCallbackFailed;
}

// Event implementations
class _SignInStarted extends AuthEvent {
  _SignInStarted(AuthMethod method)
      : super(timestamp: DateTime.now(), method: method);
}

class _SignInSuccess extends AuthEvent {
  final User user;
  _SignInSuccess(AuthMethod method, this.user)
      : super(timestamp: DateTime.now(), method: method);
}

class _SignInFailed extends AuthEvent {
  final String error;
  _SignInFailed(AuthMethod method, this.error)
      : super(timestamp: DateTime.now(), method: method);
}

class _SignUpStarted extends AuthEvent {
  _SignUpStarted(AuthMethod method)
      : super(timestamp: DateTime.now(), method: method);
}

class _SignUpSuccess extends AuthEvent {
  final User user;
  _SignUpSuccess(AuthMethod method, this.user)
      : super(timestamp: DateTime.now(), method: method);
}

class _SignUpFailed extends AuthEvent {
  final String error;
  _SignUpFailed(AuthMethod method, this.error)
      : super(timestamp: DateTime.now(), method: method);
}

class _SignOutStarted extends AuthEvent {
  final String? userId;
  _SignOutStarted(this.userId) : super(timestamp: DateTime.now());
}

class _SignOutSuccess extends AuthEvent {
  final String? userId;
  _SignOutSuccess(this.userId) : super(timestamp: DateTime.now());
}

class _SignOutFailed extends AuthEvent {
  final String error;
  _SignOutFailed(this.error) : super(timestamp: DateTime.now());
}

class _PhoneVerificationStarted extends AuthEvent {
  final String phoneNumber;
  _PhoneVerificationStarted(this.phoneNumber)
      : super(timestamp: DateTime.now(), method: AuthMethod.phone);
}

class _PhoneVerificationCodeSent extends AuthEvent {
  final String phoneNumber;
  final String verificationId;
  _PhoneVerificationCodeSent(this.phoneNumber, this.verificationId)
      : super(timestamp: DateTime.now(), method: AuthMethod.phone);
}

class _PhoneVerificationFailed extends AuthEvent {
  final String phoneNumber;
  final String error;
  _PhoneVerificationFailed(this.phoneNumber, this.error)
      : super(timestamp: DateTime.now(), method: AuthMethod.phone);
}

class _PasswordResetStarted extends AuthEvent {
  final String email;
  _PasswordResetStarted(this.email)
      : super(timestamp: DateTime.now(), method: AuthMethod.email);
}

class _PasswordResetSent extends AuthEvent {
  final String email;
  _PasswordResetSent(this.email)
      : super(timestamp: DateTime.now(), method: AuthMethod.email);
}

class _PasswordResetFailed extends AuthEvent {
  final String email;
  final String error;
  _PasswordResetFailed(this.email, this.error)
      : super(timestamp: DateTime.now(), method: AuthMethod.email);
}

class _OAuthCallbackFailed extends AuthEvent {
  final String uri;
  final String error;
  _OAuthCallbackFailed(this.uri, this.error) : super(timestamp: DateTime.now());
}

/// Provider for AuthManager
final authManagerProvider = Provider<AuthManager>((ref) {
  final enhancedAuthService = ref.watch(enhancedAuthServiceProvider);
  return AuthManager(enhancedAuthService: enhancedAuthService);
});

/// Provider for authentication events stream
final authEventsProvider = StreamProvider<AuthEvent>((ref) {
  final authManager = ref.watch(authManagerProvider);
  return authManager.authEvents;
});
