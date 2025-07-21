import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ngage/services/enhanced_auth_service.dart';
import 'package:ngage/services/auth_service.dart';
import 'package:ngage/services/member_claim_service.dart';
import 'package:ngage/repositories/user_repository.dart';
import 'package:ngage/models/user.dart' as app_user;
import 'package:ngage/models/member.dart';

// Generate mocks
@GenerateMocks([
  AuthService,
  MemberClaimService,
  UserRepository,
])
import 'enhanced_auth_service_test.mocks.dart';
import 'member_service_test.mocks.dart';

void main() {
  group('EnhancedAuthService', () {
    late MockAuthService mockAuthService;
    late MockMemberClaimService mockMemberClaimService;
    late MockUserRepository mockUserRepository;
    late EnhancedAuthService enhancedAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockMemberClaimService = MockMemberClaimService();
      mockUserRepository = MockUserRepository();
      enhancedAuthService = EnhancedAuthService(
        authService: mockAuthService,
        memberClaimService: mockMemberClaimService,
        userRepository: mockUserRepository,
      );
    });

    group('signInWithEmail', () {
      test('should handle existing user with default member', () async {
        // Arrange
        final firebaseUser = _createTestUser();
        final existingUser = firebaseUser.copyWith(defaultMember: 'member-1');
        
        when(mockAuthService.signInWithEmail('test@example.com', 'password123'))
            .thenAnswer((_) async => firebaseUser);
        when(mockUserRepository.getUser(firebaseUser.id))
            .thenAnswer((_) async => existingUser);

        // Act
        final result = await enhancedAuthService.signInWithEmail('test@example.com', 'password123');

        // Assert
        expect(result.user, equals(existingUser));
        expect(result.claimedMembers, isEmpty);
        expect(result.isNewUser, isFalse);
        verify(mockAuthService.signInWithEmail('test@example.com', 'password123')).called(1);
        verify(mockUserRepository.getUser(firebaseUser.id)).called(1);
        verifyNever(mockMemberClaimService.claimMemberProfiles(any));
      });

      test('should handle new user and claim member profiles', () async {
        // Arrange
        final firebaseUser = _createTestUser();
        final claimedMembers = [_createTestMember()];
        
        when(mockAuthService.signInWithEmail('test@example.com', 'password123'))
            .thenAnswer((_) async => firebaseUser);
        when(mockUserRepository.getUser(firebaseUser.id))
            .thenAnswer((_) async => null);
        when(mockUserRepository.createUser(any))
            .thenAnswer((_) async {});
        when(mockMemberClaimService.claimMemberProfiles(any))
            .thenAnswer((_) async => claimedMembers);
        when(mockUserRepository.updateUser(any))
            .thenAnswer((_) async {});

        // Act
        final result = await enhancedAuthService.signInWithEmail('test@example.com', 'password123');

        // Assert
        expect(result.user.id, equals(firebaseUser.id));
        expect(result.claimedMembers, equals(claimedMembers));
        expect(result.isNewUser, isTrue);
        verify(mockUserRepository.createUser(any)).called(1);
        verify(mockMemberClaimService.claimMemberProfiles(any)).called(1);
        verify(mockUserRepository.updateUser(any)).called(1);
      });

      test('should create basic member profile when no members are claimed', () async {
        // Arrange
        final firebaseUser = _createTestUser();
        final basicMember = _createTestMember();
        
        when(mockAuthService.signInWithEmail('test@example.com', 'password123'))
            .thenAnswer((_) async => firebaseUser);
        when(mockUserRepository.getUser(firebaseUser.id))
            .thenAnswer((_) async => null);
        when(mockUserRepository.createUser(any))
            .thenAnswer((_) async {});
        when(mockMemberClaimService.claimMemberProfiles(any))
            .thenAnswer((_) async => []);
        when(mockMemberClaimService.createBasicMemberProfile(any))
            .thenAnswer((_) async => basicMember);
        when(mockUserRepository.updateUser(any))
            .thenAnswer((_) async {});

        // Act
        final result = await enhancedAuthService.signInWithEmail('test@example.com', 'password123');

        // Assert
        expect(result.claimedMembers, contains(basicMember));
        verify(mockMemberClaimService.createBasicMemberProfile(any)).called(1);
      });

      test('should handle existing user without default member', () async {
        // Arrange
        final firebaseUser = _createTestUser();
        final existingUser = firebaseUser.copyWith(defaultMember: null);
        final claimedMembers = [_createTestMember()];
        
        when(mockAuthService.signInWithEmail('test@example.com', 'password123'))
            .thenAnswer((_) async => firebaseUser);
        when(mockUserRepository.getUser(firebaseUser.id))
            .thenAnswer((_) async => existingUser);
        when(mockMemberClaimService.claimMemberProfiles(any))
            .thenAnswer((_) async => claimedMembers);
        when(mockUserRepository.updateUser(any))
            .thenAnswer((_) async {});

        // Act
        final result = await enhancedAuthService.signInWithEmail('test@example.com', 'password123');

        // Assert
        expect(result.claimedMembers, equals(claimedMembers));
        verify(mockMemberClaimService.claimMemberProfiles(any)).called(1);
        verify(mockUserRepository.updateUser(any)).called(1);
      });

      test('should handle member claiming failure gracefully', () async {
        // Arrange
        final firebaseUser = _createTestUser();
        
        when(mockAuthService.signInWithEmail('test@example.com', 'password123'))
            .thenAnswer((_) async => firebaseUser);
        when(mockUserRepository.getUser(firebaseUser.id))
            .thenThrow(Exception('Database error'));

        // Act
        final result = await enhancedAuthService.signInWithEmail('test@example.com', 'password123');

        // Assert
        expect(result.user, equals(firebaseUser));
        expect(result.claimedMembers, isEmpty);
        expect(result.isNewUser, isFalse);
      });
    });

    group('createUserWithEmailAndPassword', () {
      test('should create new user and claim member profiles', () async {
        // Arrange
        final firebaseUser = _createTestUser();
        final claimedMembers = [_createTestMember()];
        
        when(mockAuthService.createUserWithEmailAndPassword('test@example.com', 'password123'))
            .thenAnswer((_) async => firebaseUser);
        when(mockUserRepository.getUser(firebaseUser.id))
            .thenAnswer((_) async => null);
        when(mockUserRepository.createUser(any))
            .thenAnswer((_) async {});
        when(mockMemberClaimService.claimMemberProfiles(any))
            .thenAnswer((_) async => claimedMembers);
        when(mockUserRepository.updateUser(any))
            .thenAnswer((_) async {});

        // Act
        final result = await enhancedAuthService.createUserWithEmailAndPassword('test@example.com', 'password123');

        // Assert
        expect(result.user.id, equals(firebaseUser.id));
        expect(result.claimedMembers, equals(claimedMembers));
        expect(result.isNewUser, isTrue);
        verify(mockUserRepository.createUser(any)).called(1);
        verify(mockMemberClaimService.claimMemberProfiles(any)).called(1);
      });
    });

    group('signOut', () {
      test('should call auth service signOut', () async {
        // Arrange
        when(mockAuthService.signOut()).thenAnswer((_) async {});

        // Act
        await enhancedAuthService.signOut();

        // Assert
        verify(mockAuthService.signOut()).called(1);
      });
    });

    group('sendPasswordResetEmail', () {
      test('should call auth service sendPasswordResetEmail', () async {
        // Arrange
        when(mockAuthService.sendPasswordResetEmail('test@example.com'))
            .thenAnswer((_) async {});

        // Act
        await enhancedAuthService.sendPasswordResetEmail('test@example.com');

        // Assert
        verify(mockAuthService.sendPasswordResetEmail('test@example.com')).called(1);
      });
    });

    group('currentUser', () {
      test('should return current user from auth service', () {
        // Arrange
        final user = _createTestUser();
        when(mockAuthService.currentUser).thenReturn(user);

        // Act
        final result = enhancedAuthService.currentUser;

        // Assert
        expect(result, equals(user));
      });
    });

    group('authStateChanges', () {
      test('should return auth state changes stream from auth service', () {
        // Arrange
        final user = _createTestUser();
        when(mockAuthService.authStateChanges)
            .thenAnswer((_) => Stream.value(user));

        // Act
        final stream = enhancedAuthService.authStateChanges;

        // Assert
        expect(stream, emits(user));
      });
    });
  });
}

// Helper functions
app_user.User _createTestUser() {
  final now = DateTime.now();
  return app_user.User(
    id: 'test-user-id',
    email: 'test@example.com',
    phone: null,
    defaultMember: null,
    createdAt: now,
    updatedAt: now,
  );
}

Member _createTestMember() {
  final now = DateTime.now();
  return Member(
    id: 'test-member-id',
    userId: 'test-user-id',
    email: 'test@example.com',
    phone: null,
    externalId: null,
    firstName: 'Test',
    lastName: 'User',
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
}