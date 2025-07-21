import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ngage/services/auth_service.dart';
import 'package:ngage/models/user.dart' as app_user;

// Generate mocks for Firebase Auth classes
@GenerateMocks([
  firebase_auth.FirebaseAuth,
  firebase_auth.User,
  firebase_auth.UserCredential,
  firebase_auth.UserMetadata,
])
import 'auth_service_test.mocks.dart';

void main() {
  group('FirebaseAuthService', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockFirebaseUser;
    late MockUserCredential mockUserCredential;
    late MockUserMetadata mockUserMetadata;
    late FirebaseAuthService authService;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockFirebaseUser = MockUser();
      mockUserCredential = MockUserCredential();
      mockUserMetadata = MockUserMetadata();
      authService = FirebaseAuthService(firebaseAuth: mockFirebaseAuth);

      // Setup default mock behavior
      when(mockFirebaseUser.uid).thenReturn('test-user-id');
      when(mockFirebaseUser.email).thenReturn('test@example.com');
      when(mockFirebaseUser.phoneNumber).thenReturn(null);
      when(mockFirebaseUser.metadata).thenReturn(mockUserMetadata);
      when(mockUserMetadata.creationTime).thenReturn(DateTime(2024, 1, 1));
      when(mockUserCredential.user).thenReturn(mockFirebaseUser);
    });

    group('signInWithEmail', () {
      test('should return User when sign in is successful', () async {
        // Arrange
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await authService.signInWithEmail(
          'test@example.com',
          'password123',
        );

        // Assert
        expect(result, isA<app_user.User>());
        expect(result.id, equals('test-user-id'));
        expect(result.email, equals('test@example.com'));
        verify(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
      });

      test('should throw AuthenticationException when user not found', () async {
        // Arrange
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(firebase_auth.FirebaseAuthException(
          code: 'user-not-found',
          message: 'User not found',
        ));

        // Act & Assert
        expect(
          () => authService.signInWithEmail('test@example.com', 'password123'),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.userNotFound)
              .having((e) => e.message, 'message', 'No user found with this email address.')),
        );
      });

      test('should throw AuthenticationException when password is wrong', () async {
        // Arrange
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(firebase_auth.FirebaseAuthException(
          code: 'wrong-password',
          message: 'Wrong password',
        ));

        // Act & Assert
        expect(
          () => authService.signInWithEmail('test@example.com', 'wrongpassword'),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.invalidCredentials)
              .having((e) => e.message, 'message', 'Incorrect password.')),
        );
      });

      test('should throw AuthenticationException when email is invalid', () async {
        // Arrange
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(firebase_auth.FirebaseAuthException(
          code: 'invalid-email',
          message: 'Invalid email',
        ));

        // Act & Assert
        expect(
          () => authService.signInWithEmail('invalid-email', 'password123'),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.invalidEmail)
              .having((e) => e.message, 'message', 'Invalid email address format.')),
        );
      });

      test('should throw AuthenticationException when no user returned', () async {
        // Arrange
        when(mockUserCredential.user).thenReturn(null);
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockUserCredential);

        // Act & Assert
        expect(
          () => authService.signInWithEmail('test@example.com', 'password123'),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.unknown)
              .having((e) => e.message, 'message', contains('Sign in failed - no user returned'))),
        );
      });
    });

    group('createUserWithEmailAndPassword', () {
      test('should return User when account creation is successful', () async {
        // Arrange
        when(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await authService.createUserWithEmailAndPassword(
          'test@example.com',
          'password123',
        );

        // Assert
        expect(result, isA<app_user.User>());
        expect(result.id, equals('test-user-id'));
        expect(result.email, equals('test@example.com'));
        verify(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
      });

      test('should throw AuthenticationException when email already in use', () async {
        // Arrange
        when(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(firebase_auth.FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Email already in use',
        ));

        // Act & Assert
        expect(
          () => authService.createUserWithEmailAndPassword('test@example.com', 'password123'),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.emailAlreadyInUse)
              .having((e) => e.message, 'message', 'An account already exists with this email address.')),
        );
      });

      test('should throw AuthenticationException when password is weak', () async {
        // Arrange
        when(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(firebase_auth.FirebaseAuthException(
          code: 'weak-password',
          message: 'Weak password',
        ));

        // Act & Assert
        expect(
          () => authService.createUserWithEmailAndPassword('test@example.com', '123'),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.weakPassword)
              .having((e) => e.message, 'message', 'Password is too weak. Please choose a stronger password.')),
        );
      });
    });

    group('signOut', () {
      test('should call Firebase signOut', () async {
        // Arrange
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});

        // Act
        await authService.signOut();

        // Assert
        verify(mockFirebaseAuth.signOut()).called(1);
      });

      test('should throw AuthenticationException when signOut fails', () async {
        // Arrange
        when(mockFirebaseAuth.signOut()).thenThrow(Exception('Sign out failed'));

        // Act & Assert
        expect(
          () => authService.signOut(),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.unknown)),
        );
      });
    });

    group('sendPasswordResetEmail', () {
      test('should call Firebase sendPasswordResetEmail', () async {
        // Arrange
        when(mockFirebaseAuth.sendPasswordResetEmail(email: anyNamed('email')))
            .thenAnswer((_) async {});

        // Act
        await authService.sendPasswordResetEmail('test@example.com');

        // Assert
        verify(mockFirebaseAuth.sendPasswordResetEmail(email: 'test@example.com'))
            .called(1);
      });

      test('should throw AuthenticationException when email is invalid', () async {
        // Arrange
        when(mockFirebaseAuth.sendPasswordResetEmail(email: anyNamed('email')))
            .thenThrow(firebase_auth.FirebaseAuthException(
          code: 'invalid-email',
          message: 'Invalid email',
        ));

        // Act & Assert
        expect(
          () => authService.sendPasswordResetEmail('invalid-email'),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.invalidEmail)),
        );
      });
    });

    group('currentUser', () {
      test('should return null when no user is signed in', () {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        // Act
        final result = authService.currentUser;

        // Assert
        expect(result, isNull);
      });

      test('should return User when user is signed in', () {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);

        // Act
        final result = authService.currentUser;

        // Assert
        expect(result, isA<app_user.User>());
        expect(result!.id, equals('test-user-id'));
        expect(result.email, equals('test@example.com'));
      });
    });

    group('authStateChanges', () {
      test('should emit null when user signs out', () async {
        // Arrange
        when(mockFirebaseAuth.authStateChanges())
            .thenAnswer((_) => Stream.value(null));

        // Act
        final stream = authService.authStateChanges;

        // Assert
        expect(await stream.first, isNull);
      });

      test('should emit User when user signs in', () async {
        // Arrange
        when(mockFirebaseAuth.authStateChanges())
            .thenAnswer((_) => Stream.value(mockFirebaseUser));

        // Act
        final stream = authService.authStateChanges;

        // Assert
        final result = await stream.first;
        expect(result, isA<app_user.User>());
        expect(result!.id, equals('test-user-id'));
      });
    });

    group('verifyPhoneNumber', () {
      test('should call Firebase verifyPhoneNumber with correct parameters', () async {
        // Arrange
        var codeSentCalled = false;
        var verificationFailedCalled = false;

        when(mockFirebaseAuth.verifyPhoneNumber(
          phoneNumber: anyNamed('phoneNumber'),
          verificationCompleted: anyNamed('verificationCompleted'),
          verificationFailed: anyNamed('verificationFailed'),
          codeSent: anyNamed('codeSent'),
          codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        )).thenAnswer((invocation) async {
          // Simulate code sent callback
          final codeSent = invocation.namedArguments[#codeSent] as Function;
          codeSent('verification-id', 123);
        });

        // Act
        await authService.verifyPhoneNumber(
          '+1234567890',
          codeSent: (verificationId) {
            codeSentCalled = true;
            expect(verificationId, equals('verification-id'));
          },
          verificationFailed: (exception) {
            verificationFailedCalled = true;
          },
        );

        // Assert
        expect(codeSentCalled, isTrue);
        expect(verificationFailedCalled, isFalse);
        verify(mockFirebaseAuth.verifyPhoneNumber(
          phoneNumber: '+1234567890',
          verificationCompleted: anyNamed('verificationCompleted'),
          verificationFailed: anyNamed('verificationFailed'),
          codeSent: anyNamed('codeSent'),
          codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        )).called(1);
      });
    });

    group('signInWithPhone', () {
      test('should throw AuthenticationException indicating implementation needed', () async {
        // Act & Assert
        expect(
          () => authService.signInWithPhone('+1234567890', '123456'),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.operationNotAllowed)
              .having((e) => e.message, 'message', contains('Phone authentication requires proper verification flow'))),
        );
      });
    });

    group('signInWithGoogle', () {
      test('should throw AuthenticationException indicating not implemented', () async {
        // Act & Assert
        expect(
          () => authService.signInWithGoogle(),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.operationNotAllowed)
              .having((e) => e.message, 'message', 'Google Sign-In not yet implemented')),
        );
      });
    });

    group('signInWithSlack', () {
      test('should throw AuthenticationException indicating not implemented', () async {
        // Act & Assert
        expect(
          () => authService.signInWithSlack('slack-code'),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.operationNotAllowed)
              .having((e) => e.message, 'message', 'Slack OAuth not yet implemented')),
        );
      });
    });

    group('_handleFirebaseAuthException', () {
      test('should handle user-disabled error correctly', () async {
        // Arrange
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(firebase_auth.FirebaseAuthException(
          code: 'user-disabled',
          message: 'User disabled',
        ));

        // Act & Assert
        expect(
          () => authService.signInWithEmail('test@example.com', 'password123'),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.userDisabled)
              .having((e) => e.message, 'message', 'This user account has been disabled.')),
        );
      });

      test('should handle too-many-requests error correctly', () async {
        // Arrange
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(firebase_auth.FirebaseAuthException(
          code: 'too-many-requests',
          message: 'Too many requests',
        ));

        // Act & Assert
        expect(
          () => authService.signInWithEmail('test@example.com', 'password123'),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.tooManyRequests)
              .having((e) => e.message, 'message', 'Too many failed attempts. Please try again later.')),
        );
      });

      test('should handle network-request-failed error correctly', () async {
        // Arrange
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(firebase_auth.FirebaseAuthException(
          code: 'network-request-failed',
          message: 'Network error',
        ));

        // Act & Assert
        expect(
          () => authService.signInWithEmail('test@example.com', 'password123'),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.networkError)
              .having((e) => e.message, 'message', 'Network error. Please check your connection and try again.')),
        );
      });

      test('should handle unknown error correctly', () async {
        // Arrange
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(firebase_auth.FirebaseAuthException(
          code: 'unknown-error',
          message: 'Unknown error occurred',
        ));

        // Act & Assert
        expect(
          () => authService.signInWithEmail('test@example.com', 'password123'),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.unknown)
              .having((e) => e.message, 'message', 'Unknown error occurred')),
        );
      });
    });
  });
}