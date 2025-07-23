import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart' as app_user;
import '../models/enums.dart';

/// Custom authentication exceptions
class AuthenticationException implements Exception {
  final String message;
  final AuthErrorType type;
  final String? code;

  const AuthenticationException(
    this.message,
    this.type, {
    this.code,
  });

  @override
  String toString() => 'AuthenticationException: $message (${type.name})';
}



/// Authentication service interface
abstract class AuthService {
  /// Sign in with email and password
  Future<app_user.User> signInWithEmail(String email, String password);

  /// Sign in with phone number and verification code
  Future<app_user.User> signInWithPhone(String phone, String verificationCode);

  /// Sign in with Google
  Future<app_user.User> signInWithGoogle();

  /// Sign in with Slack OAuth code
  Future<app_user.User> signInWithSlack(String code);

  /// Sign out current user
  Future<void> signOut();

  /// Get current authenticated user
  app_user.User? get currentUser;

  /// Stream of authentication state changes
  Stream<app_user.User?> get authStateChanges;

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Create account with email and password
  Future<app_user.User> createUserWithEmailAndPassword(
    String email,
    String password,
  );

  /// Verify phone number and send OTP
  Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required Function(String verificationId) codeSent,
    required Function(firebase_auth.FirebaseAuthException) verificationFailed,
    Function(firebase_auth.PhoneAuthCredential)? verificationCompleted,
  });
}

/// Firebase authentication service implementation
class FirebaseAuthService implements AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn? _googleSignIn;
  
  // Store verification ID for phone authentication
  String? _verificationId;

  FirebaseAuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(
          clientId: '205876580925-e6e9j1ib8as4dvan0g67e4v70kah8bcu.apps.googleusercontent.com',
        );

  @override
  Future<app_user.User> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw const AuthenticationException(
          'Sign in failed - no user returned',
          AuthErrorType.unknown,
        );
      }

      return _convertFirebaseUser(credential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthenticationException(
        'Unexpected error during email sign in: $e',
        AuthErrorType.unknown,
      );
    }
  }

  @override
  Future<app_user.User> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw const AuthenticationException(
          'Account creation failed - no user returned',
          AuthErrorType.unknown,
        );
      }

      return _convertFirebaseUser(credential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthenticationException(
        'Unexpected error during account creation: $e',
        AuthErrorType.unknown,
      );
    }
  }

  @override
  Future<app_user.User> signInWithPhone(
    String phone,
    String verificationCode,
  ) async {
    try {
      if (_verificationId == null) {
        throw const AuthenticationException(
          'Phone verification not initiated. Please call verifyPhoneNumber first.',
          AuthErrorType.operationNotAllowed,
        );
      }

      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: verificationCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw const AuthenticationException(
          'Phone sign in failed - no user returned',
          AuthErrorType.unknown,
        );
      }

      return _convertFirebaseUser(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      throw AuthenticationException(
        'Unexpected error during phone sign in: $e',
        AuthErrorType.unknown,
      );
    }
  }

  @override
  Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required Function(String verificationId) codeSent,
    required Function(firebase_auth.FirebaseAuthException) verificationFailed,
    Function(firebase_auth.PhoneAuthCredential)? verificationCompleted,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted ?? (credential) async {
          // Auto-verification completed, sign in automatically
          try {
            await _firebaseAuth.signInWithCredential(credential);
          } catch (e) {
            // Handle auto-verification error
          }
        },
        verificationFailed: verificationFailed,
        codeSent: (String verificationId, int? resendToken) {
          // Store verification ID for later use
          _verificationId = verificationId;
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Store verification ID even on timeout
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      throw AuthenticationException(
        'Phone verification failed: $e',
        AuthErrorType.unknown,
      );
    }
  }

  @override
  Future<app_user.User> signInWithGoogle() async {
    try {
      if (_googleSignIn == null) {
        throw const AuthenticationException(
          'Google Sign-In is not configured. Please configure Google Sign-In client ID.',
          AuthErrorType.operationNotAllowed,
        );
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      
      if (googleUser == null) {
        throw const AuthenticationException(
          'Google Sign-In was cancelled by user',
          AuthErrorType.operationNotAllowed,
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw const AuthenticationException(
          'Google Sign-In failed - no user returned',
          AuthErrorType.unknown,
        );
      }

      return _convertFirebaseUser(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      throw AuthenticationException(
        'Unexpected error during Google sign in: $e',
        AuthErrorType.unknown,
      );
    }
  }

  @override
  Future<app_user.User> signInWithSlack(String code) async {
    try {
      // Note: This is a simplified implementation for demonstration
      // In production, you should:
      // 1. Use a backend service to handle Slack OAuth
      // 2. Create Firebase custom tokens on the backend
      // 3. Return the custom token to sign in with Firebase
      
      throw const AuthenticationException(
        'Slack OAuth requires backend implementation with custom tokens. '
        'Please implement a backend service to handle Slack OAuth flow and '
        'create Firebase custom tokens.',
        AuthErrorType.operationNotAllowed,
      );
      
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      throw AuthenticationException(
        'Unexpected error during Slack sign in: $e',
        AuthErrorType.unknown,
      );
    }
  }



  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AuthenticationException(
        'Sign out failed: $e',
        AuthErrorType.unknown,
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw AuthenticationException(
        'Password reset failed: $e',
        AuthErrorType.unknown,
      );
    }
  }

  @override
  app_user.User? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    return firebaseUser != null ? _convertFirebaseUser(firebaseUser) : null;
  }

  @override
  Stream<app_user.User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null ? _convertFirebaseUser(firebaseUser) : null;
    });
  }

  /// Convert Firebase User to app User model
  app_user.User _convertFirebaseUser(firebase_auth.User firebaseUser) {
    final now = DateTime.now();
    return app_user.User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      phone: firebaseUser.phoneNumber,
      defaultMember: null, // Will be set after member profile claiming
      createdAt: firebaseUser.metadata.creationTime ?? now,
      updatedAt: now,
    );
  }

  /// Handle Firebase Auth exceptions and convert to custom exceptions
  AuthenticationException _handleFirebaseAuthException(
    firebase_auth.FirebaseAuthException e,
  ) {
    AuthErrorType errorType;
    String message;

    switch (e.code) {
      case 'user-not-found':
        errorType = AuthErrorType.userNotFound;
        message = 'No user found with this email address.';
        break;
      case 'wrong-password':
        errorType = AuthErrorType.invalidCredentials;
        message = 'Incorrect password.';
        break;
      case 'invalid-email':
        errorType = AuthErrorType.invalidEmail;
        message = 'Invalid email address format.';
        break;
      case 'user-disabled':
        errorType = AuthErrorType.userDisabled;
        message = 'This user account has been disabled.';
        break;
      case 'too-many-requests':
        errorType = AuthErrorType.tooManyRequests;
        message = 'Too many failed attempts. Please try again later.';
        break;
      case 'operation-not-allowed':
        errorType = AuthErrorType.operationNotAllowed;
        message = 'This sign-in method is not enabled.';
        break;
      case 'weak-password':
        errorType = AuthErrorType.weakPassword;
        message = 'Password is too weak. Please choose a stronger password.';
        break;
      case 'email-already-in-use':
        errorType = AuthErrorType.emailAlreadyInUse;
        message = 'An account already exists with this email address.';
        break;
      case 'network-request-failed':
        errorType = AuthErrorType.networkError;
        message = 'Network error. Please check your connection and try again.';
        break;
      default:
        errorType = AuthErrorType.unknown;
        message = e.message ?? 'An unknown authentication error occurred.';
    }

    return AuthenticationException(message, errorType, code: e.code);
  }
}

/// Provider for the authentication service
final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService();
});