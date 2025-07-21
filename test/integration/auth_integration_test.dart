import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ngage/models/enums.dart';

import 'package:ngage/services/auth_service.dart';
import 'package:ngage/services/enhanced_auth_service.dart';
import 'package:ngage/services/member_claim_service.dart';
import 'package:ngage/repositories/user_repository.dart';
import 'package:ngage/models/user.dart' as app_user;
import 'package:ngage/models/member.dart';

// Generate mocks
@GenerateMocks([
  firebase_auth.FirebaseAuth,
  firebase_auth.UserCredential,
  firebase_auth.User,
  GoogleSignIn,
  GoogleSignInAccount,
  GoogleSignInAuthentication,
  MemberClaimService,
  UserRepository,
])
import 'auth_integration_test.mocks.dart';

void main() {
  group('Authentication Integration Tests', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockMemberClaimService mockMemberClaimService;
    late MockUserRepository mockUserRepository;
    late FirebaseAuthService authService;
    late EnhancedAuthService enhancedAuthService;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      mockMemberClaimService = MockMemberClaimService();
      mockUserRepository = MockUserRepository();

      authService = FirebaseAuthService(
        firebaseAuth: mockFirebaseAuth,
        googleSignIn: mockGoogleSignIn,
      );

      enhancedAuthService = EnhancedAuthService(
        authService: authService,
        memberClaimService: mockMemberClaimService,
        userRepository: mockUserRepository,
      );
    });

    group('Email/Password Authentication', () {
      test('should sign in with valid email and password', () async {
        // Arrange
        final mockUser = MockUser();
        final mockUserCredential = MockUserCredential();
        
        when(mockUser.uid).thenReturn('test-uid');
        when(mockUser.email).thenReturn('test@example.com');
        when(mockUser.phoneNumber).thenReturn(null);
        when(mockUser.metadata).thenReturn(firebase_auth.UserMetadata(
          DateTime.now() as int,
          DateTime.now() as int,
        ));
        
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await authService.signInWithEmail('test@example.com', 'password123');

        // Assert
        expect(result.id, equals('test-uid'));
        expect(result.email, equals('test@example.com'));
        verify(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
      });

      test('should throw AuthenticationException for invalid credentials', () async {
        // Arrange
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'wrongpassword',
        )).thenThrow(firebase_auth.FirebaseAuthException(
          code: 'wrong-password',
          message: 'Wrong password',
        ));

        // Act & Assert
        expect(
          () => authService.signInWithEmail('test@example.com', 'wrongpassword'),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.invalidCredentials)),
        );
      });

      test('should create user with email and password', () async {
        // Arrange
        final mockUser = MockUser();
        final mockUserCredential = MockUserCredential();
        
        when(mockUser.uid).thenReturn('new-user-uid');
        when(mockUser.email).thenReturn('newuser@example.com');
        when(mockUser.phoneNumber).thenReturn(null);
        var userMetadata = firebase_auth.UserMetadata(
           DateTime.now() as int,
           DateTime.now() as int,
        );
        when(mockUser.metadata).thenReturn(userMetadata);
        
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'newuser@example.com',
          password: 'password123',
        )).thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await authService.createUserWithEmailAndPassword(
          'newuser@example.com',
          'password123',
        );

        // Assert
        expect(result.id, equals('new-user-uid'));
        expect(result.email, equals('newuser@example.com'));
        verify(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'newuser@example.com',
          password: 'password123',
        )).called(1);
      });

      test('should throw AuthenticationException for email already in use', () async {
        // Arrange
        when(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'existing@example.com',
          password: 'password123',
        )).thenThrow(firebase_auth.FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Email already in use',
        ));

        // Act & Assert
        expect(
          () => authService.createUserWithEmailAndPassword(
            'existing@example.com',
            'password123',
          ),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.emailAlreadyInUse)),
        );
      });
    });

    group('Google Sign-In Authentication', () {
      test('should sign in with Google successfully', () async {
        // Arrange
        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();
        final mockUser = MockUser();
        final mockUserCredential = MockUserCredential();

        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleUser);
        when(mockGoogleUser.authentication).thenAnswer((_) async => mockGoogleAuth);
        when(mockGoogleAuth.accessToken).thenReturn('access-token');
        when(mockGoogleAuth.idToken).thenReturn('id-token');

        when(mockUser.uid).thenReturn('google-user-uid');
        when(mockUser.email).thenReturn('googleuser@example.com');
        when(mockUser.phoneNumber).thenReturn(null);
        when(mockUser.metadata).thenReturn(firebase_auth.UserMetadata(
           DateTime.now() as int,
           DateTime.now() as int,
        ));

        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockFirebaseAuth.signInWithCredential(any))
            .thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await authService.signInWithGoogle();

        // Assert
        expect(result.id, equals('google-user-uid'));
        expect(result.email, equals('googleuser@example.com'));
        verify(mockGoogleSignIn.signIn()).called(1);
        verify(mockFirebaseAuth.signInWithCredential(any)).called(1);
      });

      test('should throw AuthenticationException when Google sign-in is cancelled', () async {
        // Arrange
        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => authService.signInWithGoogle(),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.operationNotAllowed)),
        );
      });
    });

    group('Phone Authentication', () {
      test('should verify phone number successfully', () async {
        // Arrange
        const phoneNumber = '+1234567890';
        const verificationId = 'verification-id';
        bool codeSentCalled = false;
        bool verificationFailedCalled = false;

        when(mockFirebaseAuth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: anyNamed('verificationCompleted'),
          verificationFailed: anyNamed('verificationFailed'),
          codeSent: anyNamed('codeSent'),
          codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        )).thenAnswer((invocation) async {
          final codeSent = invocation.namedArguments[#codeSent] as Function;
          codeSent(verificationId, 0);
        });

        // Act
        await authService.verifyPhoneNumber(
          phoneNumber,
          codeSent: (id) => codeSentCalled = true,
          verificationFailed: (e) => verificationFailedCalled = true,
        );

        // Assert
        expect(codeSentCalled, isTrue);
        expect(verificationFailedCalled, isFalse);
        verify(mockFirebaseAuth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: anyNamed('verificationCompleted'),
          verificationFailed: anyNamed('verificationFailed'),
          codeSent: anyNamed('codeSent'),
          codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        )).called(1);
      });

      test('should sign in with phone and verification code', () async {
        // Arrange
        const phoneNumber = '+1234567890';
        const verificationCode = '123456';
        const verificationId = 'verification-id';
        
        final mockUser = MockUser();
        final mockUserCredential = MockUserCredential();

        // First, simulate phone verification
        when(mockFirebaseAuth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: anyNamed('verificationCompleted'),
          verificationFailed: anyNamed('verificationFailed'),
          codeSent: anyNamed('codeSent'),
          codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
        )).thenAnswer((invocation) async {
          final codeSent = invocation.namedArguments[#codeSent] as Function;
          codeSent(verificationId, 0);
        });

        await authService.verifyPhoneNumber(
          phoneNumber,
          codeSent: (id) {},
          verificationFailed: (e) {},
        );

        // Now test sign in with code
        when(mockUser.uid).thenReturn('phone-user-uid');
        when(mockUser.email).thenReturn(null);
        when(mockUser.phoneNumber).thenReturn(phoneNumber);
        when(mockUser.metadata).thenReturn(firebase_auth.UserMetadata(
           DateTime.now() as int,
           DateTime.now() as int,
        ));

        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockFirebaseAuth.signInWithCredential(any))
            .thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await authService.signInWithPhone(phoneNumber, verificationCode);

        // Assert
        expect(result.id, equals('phone-user-uid'));
        expect(result.phone, equals(phoneNumber));
        verify(mockFirebaseAuth.signInWithCredential(any)).called(1);
      });

      test('should throw AuthenticationException when verification not initiated', () async {
        // Act & Assert
        expect(
          () => authService.signInWithPhone('+1234567890', '123456'),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.operationNotAllowed)),
        );
      });
    });

    group('Enhanced Authentication with Member Claiming', () {
      test('should claim member profiles on first sign in', () async {
        // Arrange
        final mockUser = MockUser();
        final mockUserCredential = MockUserCredential();
        final testUser = app_user.User(
          id: 'test-uid',
          email: 'test@example.com',
          phone: null,
          defaultMember: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final claimedMembers = [
          Member(
            id: 'member-1',
            userId: 'test-uid',
            email: 'test@example.com',
            phone: null,
            externalId: null,
            firstName: 'John',
            lastName: 'Doe',
            category: null,
            title: null,
            profilePhoto: null,
            bio: null,
            isActive: true,
            importedAt: null,
            claimedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockUser.uid).thenReturn('test-uid');
        when(mockUser.email).thenReturn('test@example.com');
        when(mockUser.phoneNumber).thenReturn(null);
        when(mockUser.metadata).thenReturn(firebase_auth.UserMetadata(
          DateTime.now() as int,
          DateTime.now() as int,
        ));

        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => mockUserCredential);

        when(mockUserRepository.getUser('test-uid')).thenAnswer((_) async => null);
        when(mockUserRepository.createUser(any)).thenAnswer((_) async {});
        when(mockUserRepository.updateUser(any)).thenAnswer((_) async {});
        when(mockMemberClaimService.claimMemberProfiles(any))
            .thenAnswer((_) async => claimedMembers);

        // Act
        final result = await enhancedAuthService.signInWithEmail('test@example.com', 'password123');

        // Assert
        expect(result.user.id, equals('test-uid'));
        expect(result.claimedMembers.length, equals(1));
        expect(result.claimedMembers.first.firstName, equals('John'));
        verify(mockMemberClaimService.claimMemberProfiles(any)).called(1);
        verify(mockUserRepository.createUser(any)).called(1);
      });

      test('should create basic member profile if no members claimed', () async {
        // Arrange
        final mockUser = MockUser();
        final mockUserCredential = MockUserCredential();
        final testUser = app_user.User(
          id: 'test-uid',
          email: 'test@example.com',
          phone: null,
          defaultMember: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final basicMember = Member(
          id: 'basic-member-1',
          userId: 'test-uid',
          email: 'test@example.com',
          phone: null,
          externalId: null,
          firstName: 'User',
          lastName: 'Test',
          category: null,
          title: null,
          profilePhoto: null,
          bio: null,
          isActive: true,
          importedAt: null,
          claimedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockUser.uid).thenReturn('test-uid');
        when(mockUser.email).thenReturn('test@example.com');
        when(mockUser.phoneNumber).thenReturn(null);
        when(mockUser.metadata).thenReturn(firebase_auth.UserMetadata(
           DateTime.now() as int,
           DateTime.now() as int,
        ));

        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => mockUserCredential);

        when(mockUserRepository.getUser('test-uid')).thenAnswer((_) async => null);
        when(mockUserRepository.createUser(any)).thenAnswer((_) async {});
        when(mockUserRepository.updateUser(any)).thenAnswer((_) async {});
        when(mockMemberClaimService.claimMemberProfiles(any))
            .thenAnswer((_) async => []);
        when(mockMemberClaimService.createBasicMemberProfile(any))
            .thenAnswer((_) async => basicMember);

        // Act
        final result = await enhancedAuthService.signInWithEmail('test@example.com', 'password123');

        // Assert
        expect(result.user.id, equals('test-uid'));
        expect(result.claimedMembers.length, equals(1));
        expect(result.claimedMembers.first.firstName, equals('User'));
        verify(mockMemberClaimService.claimMemberProfiles(any)).called(1);
        verify(mockMemberClaimService.createBasicMemberProfile(any)).called(1);
      });
    });

    group('Password Reset', () {
      test('should send password reset email successfully', () async {
        // Arrange
        const email = 'test@example.com';
        when(mockFirebaseAuth.sendPasswordResetEmail(email: email))
            .thenAnswer((_) async {});

        // Act
        await authService.sendPasswordResetEmail(email);

        // Assert
        verify(mockFirebaseAuth.sendPasswordResetEmail(email: email)).called(1);
      });

      test('should throw AuthenticationException for invalid email', () async {
        // Arrange
        const email = 'invalid@example.com';
        when(mockFirebaseAuth.sendPasswordResetEmail(email: email))
            .thenThrow(firebase_auth.FirebaseAuthException(
          code: 'user-not-found',
          message: 'User not found',
        ));

        // Act & Assert
        expect(
          () => authService.sendPasswordResetEmail(email),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.userNotFound)),
        );
      });
    });

    group('Sign Out', () {
      test('should sign out successfully', () async {
        // Arrange
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});

        // Act
        await authService.signOut();

        // Assert
        verify(mockFirebaseAuth.signOut()).called(1);
      });
    });

    group('Slack OAuth', () {
      test('should throw AuthenticationException for Slack OAuth (not implemented)', () async {
        // Act & Assert
        expect(
          () => authService.signInWithSlack('test-code'),
          throwsA(isA<AuthenticationException>()
              .having((e) => e.type, 'type', AuthErrorType.operationNotAllowed)),
        );
      });
    });
  });
}